// learn_screen.dart
// Restructured Learn screen (Session 5): was a single flat scrollable list
// of all words for the selected level. Now a 3-level flow matching the
// validated HTML mockup:
//   L1 — grid of theme tiles (progress-at-a-glance)
//   L2 — episode list within the selected theme
//   L3 — episode reader: each word's sentence is a "beat", tap to reveal
//        definition/synonyms/antonyms, IN ORDER (sequential gating) —
//        later words are visible but locked until earlier ones are read.
//
// Content note: word_bank.json still has one sentence per word (no
// multi-beat narration yet), so each L3 "beat" is just that word's
// sentence. Story episodes are grouped from the flat word list by
// (theme, storyEpisode) rather than a new JSON schema — no content
// migration needed.
//
// Dev Mode: a debug-only toggle (kDebugMode-gated) that lets you reveal
// words in any order and jump straight to "episode complete" while
// testing, without re-reading every episode from the top each time.

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/word.dart';
import '../services/word_service.dart';
import '../services/tts_service.dart';

/// One episode = all words sharing the same theme + storyEpisode number.
class _Episode {
  final String theme;
  final int number;
  final List<Word> words;
  _Episode({required this.theme, required this.number, required this.words});

  String get title => 'Episode $number';
}

/// One theme = all words sharing the same theme name, grouped into episodes.
class _Theme {
  final String name;
  final List<_Episode> episodes;
  _Theme({required this.name, required this.episodes});

  int get totalWords => episodes.fold(0, (sum, e) => sum + e.words.length);
}

enum _Level { themes, episodes, reader }

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String _selectedLevel = 'all'; // easy/medium/hard filter, applies at L1
  _Level _nav = _Level.themes;
  _Theme? _activeTheme;
  _Episode? _activeEpisode;

  // Sequential reveal state for the currently open episode.
  final List<String> _revealedInOrder = [];
  bool _devMode = false;

  List<_Theme> _buildThemes(List<Word> words) {
    final filtered = words
        .where((w) => _selectedLevel == 'all' || w.level == _selectedLevel)
        .toList();

    final byTheme = <String, Map<int, List<Word>>>{};
    for (final w in filtered) {
      byTheme.putIfAbsent(w.theme, () => {});
      byTheme[w.theme]!.putIfAbsent(w.storyEpisode, () => []);
      byTheme[w.theme]![w.storyEpisode]!.add(w);
    }

    return byTheme.entries.map((themeEntry) {
      final episodes = themeEntry.value.entries.map((epEntry) {
        return _Episode(
          theme: themeEntry.key,
          number: epEntry.key,
          words: epEntry.value,
        );
      }).toList()
        ..sort((a, b) => a.number.compareTo(b.number));
      return _Theme(name: themeEntry.key, episodes: episodes);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  void _openTheme(_Theme t) {
    setState(() {
      _activeTheme = t;
      _nav = _Level.episodes;
    });
  }

  void _openEpisode(_Episode e) {
    setState(() {
      _activeEpisode = e;
      _revealedInOrder.clear();
      _nav = _Level.reader;
    });
  }

  void _goBack() {
    setState(() {
      if (_nav == _Level.reader) {
        _nav = _Level.episodes;
        _activeEpisode = null;
        _revealedInOrder.clear();
      } else if (_nav == _Level.episodes) {
        _nav = _Level.themes;
        _activeTheme = null;
      }
    });
  }

  void _revealWord(String word) {
    final order = _activeEpisode!.words.map((w) => w.word).toList();
    final nextExpected = order[_revealedInOrder.length.clamp(0, order.length - 1)];

    if (!_devMode && word != nextExpected && !_revealedInOrder.contains(word)) {
      // Out-of-order tap in sequential mode: just nudge, don't reveal.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Read from the top — reveal words in order'),
          duration: Duration(milliseconds: 1400),
        ),
      );
      return;
    }
    setState(() {
      if (!_revealedInOrder.contains(word)) _revealedInOrder.add(word);
    });
  }

  void _unlockAll() {
    setState(() {
      _revealedInOrder
        ..clear()
        ..addAll(_activeEpisode!.words.map((w) => w.word));
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Word>>(
      future: WordService.loadWords(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final themes = _buildThemes(snapshot.data!);

        return Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: switch (_nav) {
                _Level.themes => _buildThemeGrid(context, themes),
                _Level.episodes => _buildEpisodeList(context),
                _Level.reader => _buildReader(context),
              },
            ),
          ],
        );
      },
    );
  }

  // ---------------- Header (back button + dev toggle) ----------------

  Widget _buildHeader(BuildContext context) {
    final title = switch (_nav) {
      _Level.themes => 'Learn',
      _Level.episodes => _activeTheme?.name ?? '',
      _Level.reader => _activeEpisode?.title ?? '',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          if (_nav != _Level.themes)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBack,
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (kDebugMode && _nav == _Level.reader)
            Row(
              children: [
                Text('Dev', style: Theme.of(context).textTheme.labelSmall),
                Switch(
                  value: _devMode,
                  onChanged: (v) => setState(() => _devMode = v),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ---------------- L1: theme tiles ----------------

  Widget _buildThemeGrid(BuildContext context, List<_Theme> themes) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              _levelChip('all', 'All'),
              const SizedBox(width: 8),
              _levelChip('easy', 'Easy'),
              const SizedBox(width: 8),
              _levelChip('medium', 'Medium'),
              const SizedBox(width: 8),
              _levelChip('hard', 'Hard'),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: themes.length,
            itemBuilder: (context, i) {
              final t = themes[i];
              return _ThemeTile(theme: t, onTap: () => _openTheme(t));
            },
          ),
        ),
      ],
    );
  }

  Widget _levelChip(String value, String label) {
    final isSelected = _selectedLevel == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedLevel = value),
    );
  }

  // ---------------- L2: episode list ----------------

  Widget _buildEpisodeList(BuildContext context) {
    final episodes = _activeTheme!.episodes;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: episodes.length,
      itemBuilder: (context, i) {
        final e = episodes[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(child: Text('${e.number}')),
            title: Text(e.title),
            subtitle: Text('${e.words.length} words'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openEpisode(e),
          ),
        );
      },
    );
  }

  // ---------------- L3: episode reader (sequential reveal) ----------------

  Widget _buildReader(BuildContext context) {
    final words = _activeEpisode!.words;
    final nextExpected = _revealedInOrder.length < words.length
        ? words[_revealedInOrder.length].word
        : null;
    final allDone = _revealedInOrder.length >= words.length;

    return Column(
      children: [
        // Progress dots
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: words.map((w) {
              final done = _revealedInOrder.contains(w.word);
              final current = w.word == nextExpected;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: done
                      ? Theme.of(context).colorScheme.secondary
                      : current
                          ? Theme.of(context).colorScheme.secondary.withOpacity(0.5)
                          : Theme.of(context).colorScheme.surfaceVariant,
                ),
              );
            }).toList(),
          ),
        ),
        if (_devMode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _unlockAll,
                icon: const Icon(Icons.bolt, size: 16),
                label: const Text('Unlock all words'),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: words.length,
            itemBuilder: (context, index) {
              final w = words[index];
              final isRevealed = _revealedInOrder.contains(w.word);
              final isNext = w.word == nextExpected;
              final locked = !isRevealed && !isNext && !_devMode;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHighlightedSentence(context, w, isRevealed, locked),
                      if (isRevealed) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        Text(w.word.toUpperCase(),
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(w.definition,
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 8),
                        Text('Synonyms: ${w.synonyms.join(", ")}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text('Antonyms: ${w.antonyms.join(", ")}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => TtsService.speak(w.word),
                          icon: const Icon(Icons.volume_up, size: 18),
                          label: const Text('Hear pronunciation'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: allDone
                  ? () {
                      // TODO: hand off to Word Detective for these words
                      // once that screen exists — mirrors mockup's
                      // "Continue to Word Detective" CTA.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Continue to Word Detective (TODO)')),
                      );
                    }
                  : null,
              child: Text(allDone
                  ? 'Continue to Word Detective'
                  : 'Tap the highlighted word to continue'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightedSentence(
      BuildContext context, Word w, bool isRevealed, bool locked) {
    final sentence = w.sentence;
    final wordIndex = sentence.toLowerCase().indexOf(w.word.toLowerCase());

    if (wordIndex == -1) {
      return Text(sentence, style: Theme.of(context).textTheme.bodyLarge);
    }

    final before = sentence.substring(0, wordIndex);
    final match = sentence.substring(wordIndex, wordIndex + w.word.length);
    final after = sentence.substring(wordIndex + w.word.length);

    final color = locked
        ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)
        : Theme.of(context).colorScheme.secondary;

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyLarge,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationStyle:
                  locked ? TextDecorationStyle.dotted : TextDecorationStyle.solid,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _revealWord(w.word),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final _Theme theme;
  final VoidCallback onTap;
  const _ThemeTile({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(theme.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              Text('${theme.episodes.length} episodes · ${theme.totalWords} words',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}