// learn_screen.dart
// Restructured Learn screen: 3-level flow (theme grid -> episode list ->
// reader). Consumes NavProvider's pendingTheme/themeRequestId for Home's
// deep-links. Caches the word-bank Future in initState instead of
// reloading it every build, since watching NavProvider means this screen
// rebuilds on every tab switch app-wide (IndexedStack keeps it mounted).
//
// CHANGED this session: registers a stepBack() handler with
// BackHandlerRegistry (tab index 1), which Origins already did but Learn
// never did — this was the actual cause of the hardware back button
// jumping straight to the exit-confirmation dialog on the Learn tab
// instead of stepping reader->episodes->themes first. _goBack() (used by
// the on-screen back arrow) and the new _stepBack() (used by the
// registry) now share the same step-down logic.

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../services/word_service.dart';
import '../providers/nav_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/word_check_sheet.dart';
import '../widgets/back_handler_registry.dart';

class _Episode {
  final String theme;
  final int number;
  final List<Word> words;
  _Episode({required this.theme, required this.number, required this.words});
  String get title => 'Episode $number';
}

class _Theme {
  final String name;
  final List<_Episode> episodes;
  _Theme({required this.name, required this.episodes});
  int get totalWords => episodes.fold(0, (sum, e) => sum + e.words.length);
  List<Word> get allWords => episodes.expand((e) => e.words).toList();
}

enum _Level { themes, episodes, reader }

IconData _iconForTheme(String themeName) {
  final lower = themeName.toLowerCase();
  const map = <String, IconData>{
    'job interview': Icons.business_center,
    'interview': Icons.business_center,
    'startup': Icons.rocket_launch,
    'courtroom': Icons.gavel,
    'medical': Icons.local_hospital,
    'political': Icons.campaign,
    'museum': Icons.museum,
    'space': Icons.satellite_alt,
    'restaurant': Icons.restaurant,
    'wedding': Icons.celebration,
    'wildlife': Icons.pets,
    'cybersecurity': Icons.security,
    'college': Icons.school,
    'university': Icons.school,
    'travel': Icons.flight,
    'sports': Icons.sports_soccer,
    'cooking': Icons.soup_kitchen,
    'finance': Icons.account_balance,
    'financial': Icons.account_balance,
    'adoption': Icons.family_restroom,
    'archaeolog': Icons.explore,
    'diplomatic': Icons.handshake,
    'negotiation': Icons.handshake,
    'divorce': Icons.gavel,
    'esports': Icons.sports_esports,
    'fraud': Icons.gavel,
    'investigation': Icons.search,
  };
  for (final entry in map.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return Icons.menu_book;
}

const List<Color> _themeAccentColors = [
  Color(0xFFE0A233), Color(0xFF4F8FE0), Color(0xFF4FAE7C),
  Color(0xFFD1568C), Color(0xFF3FB6B0), Color(0xFFD1594F), Color(0xFF8B6FD1),
];

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  // ADDED: Learn is bottom-nav tab index 1 (Home=0, Learn=1, Practice=2,
  // Origins=3, Vault=4, Settings=5) — must match MainShell's order.
  static const int _tabIndex = 1;

  _Level _nav = _Level.themes;
  _Theme? _activeTheme;
  _Episode? _activeEpisode;
  final List<String> _revealedInOrder = [];
  bool _devMode = false;
  List<Word> _allWordsCache = [];

  late Future<List<Word>> _wordsFuture;

  int _lastHandledThemeRequestId = -1;

  @override
  void initState() {
    super.initState();
    // ADDED: register this screen's step-back logic so the app-wide
    // back button steps reader->episodes->themes before ever reaching
    // the exit-confirmation dialog.
    BackHandlerRegistry.register(_tabIndex, _stepBack);
    _wordsFuture = WordService.loadWords();
  }

  @override
  void dispose() {
    // ADDED: mirrors OriginsScreen — always unregister so a stale
    // handler can't linger after this screen is gone.
    BackHandlerRegistry.unregister(_tabIndex);
    super.dispose();
  }

  List<_Theme> _buildThemes(List<Word> words) {
    final byTheme = <String, Map<int, List<Word>>>{};
    for (final w in words) {
      byTheme.putIfAbsent(w.theme, () => {});
      byTheme[w.theme]!.putIfAbsent(w.storyEpisode, () => []);
      byTheme[w.theme]![w.storyEpisode]!.add(w);
    }
    return byTheme.entries.map((themeEntry) {
      final episodes = themeEntry.value.entries.map((epEntry) {
        return _Episode(theme: themeEntry.key, number: epEntry.key, words: epEntry.value);
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

  /// Used by the on-screen back arrow (AppBar-style). Unconditionally
  /// steps down one level; does nothing if already at the top.
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

  /// ADDED: used by BackHandlerRegistry for the hardware/gesture back
  /// button. Same step-down logic as _goBack(), but reports whether it
  /// actually stepped back (true) or was already at the top level with
  /// nothing further to step back through (false) — MainShell uses that
  /// return value to decide whether to show the exit-confirmation dialog.
  bool _stepBack() {
    if (_nav == _Level.reader) {
      setState(() {
        _nav = _Level.episodes;
        _activeEpisode = null;
        _revealedInOrder.clear();
      });
      return true;
    } else if (_nav == _Level.episodes) {
      setState(() {
        _nav = _Level.themes;
        _activeTheme = null;
      });
      return true;
    }
    return false;
  }

  List<String> _pickDistractors(Word current) {
    final others = _allWordsCache.where((w) => w.word != current.word).map((w) => w.definition).toList()..shuffle();
    return others.take(2).toList();
  }

  void _openWordCheck(Word w) {
    final order = _activeEpisode!.words.map((x) => x.word).toList();
    final alreadyRevealed = _revealedInOrder.contains(w.word);
    final nextExpected = order[_revealedInOrder.length.clamp(0, order.length - 1)];

    if (!alreadyRevealed && !_devMode && w.word != nextExpected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Read from the top — reveal words in order'), duration: Duration(milliseconds: 1400)),
      );
      return;
    }

    final data = WordCheckData(
      word: w.word,
      correctMeaning: w.definition,
      distractorMeanings: _pickDistractors(w),
      synonyms: w.synonyms,
      antonyms: w.antonyms,
      pronunciationText: w.word,
    );

    showWordCheckSheet(
      context: context,
      data: data,
      startAtDetail: alreadyRevealed,
      onComplete: () {
        setState(() {
          if (!_revealedInOrder.contains(w.word)) _revealedInOrder.add(w.word);
        });
      },
    );
  }

  void _unlockAll() {
    setState(() {
      _revealedInOrder..clear()..addAll(_activeEpisode!.words.map((w) => w.word));
    });
  }

  void _continueToWordDetective() {
    context.read<NavProvider>().setIndex(2);
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavProvider>();

    return FutureBuilder<List<Word>>(
      future: _wordsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        _allWordsCache = snapshot.data!;
        final themes = _buildThemes(snapshot.data!);

        if (navProvider.pendingTheme != null &&
            navProvider.themeRequestId != _lastHandledThemeRequestId) {
          _lastHandledThemeRequestId = navProvider.themeRequestId;
          final targetName = navProvider.pendingTheme;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final match = themes.where((t) => t.name == targetName);
            if (match.isNotEmpty) _openTheme(match.first);
            navProvider.clearPendingTheme();
          });
        }

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
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack)
          else
            const SizedBox(width: 48),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          if (kDebugMode && _nav == _Level.reader)
            Row(children: [
              Text('Dev', style: Theme.of(context).textTheme.labelSmall),
              Switch(value: _devMode, onChanged: (v) => setState(() => _devMode = v)),
            ]),
        ],
      ),
    );
  }

  Widget _buildThemeGrid(BuildContext context, List<_Theme> themes) {
    final progressProvider = context.watch<ProgressProvider>();
    final progressByWord = {for (final p in progressProvider.allProgress) p.word: p};
    bool isLearned(String word) => progressByWord[word]?.learned ?? false;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.95,
      ),
      itemCount: themes.length,
      itemBuilder: (context, i) {
        final t = themes[i];
        final learned = t.allWords.where((w) => isLearned(w.word)).length;
        return _ThemeTile(
          theme: t,
          learnedCount: learned,
          accentColor: _themeAccentColors[i % _themeAccentColors.length],
          onTap: () => _openTheme(t),
        );
      },
    );
  }

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

  Widget _buildReader(BuildContext context) {
    final words = _activeEpisode!.words;
    final nextExpected = _revealedInOrder.length < words.length ? words[_revealedInOrder.length].word : null;
    final allDone = _revealedInOrder.length >= words.length;

    return Column(
      children: [
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
                          ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
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
              child: TextButton.icon(onPressed: _unlockAll, icon: const Icon(Icons.bolt, size: 16), label: const Text('Unlock all words')),
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
                        const SizedBox(height: 10),
                        const Divider(),
                        Row(children: [
                          Icon(Icons.check_circle_outline, size: 16, color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 6),
                          Text('Reviewed — tap the word to check again', style: Theme.of(context).textTheme.bodySmall),
                        ]),
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
              onPressed: allDone ? _continueToWordDetective : null,
              child: Text(allDone ? 'Continue to Word Detective' : 'Tap the highlighted word to continue'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightedSentence(BuildContext context, Word w, bool isRevealed, bool locked) {
    final sentence = w.sentence;
    final wordIndex = sentence.toLowerCase().indexOf(w.word.toLowerCase());
    if (wordIndex == -1) {
      return Text(sentence, style: Theme.of(context).textTheme.bodyLarge);
    }
    final before = sentence.substring(0, wordIndex);
    final match = sentence.substring(wordIndex, wordIndex + w.word.length);
    final after = sentence.substring(wordIndex + w.word.length);
    final color = locked
        ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
        : Theme.of(context).colorScheme.secondary;

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyLarge,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: TextStyle(
              color: color, fontWeight: FontWeight.bold, decoration: TextDecoration.underline,
              decorationStyle: locked ? TextDecorationStyle.dotted : TextDecorationStyle.solid,
            ),
            recognizer: TapGestureRecognizer()..onTap = () => _openWordCheck(w),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final _Theme theme;
  final int learnedCount;
  final Color accentColor;
  final VoidCallback onTap;
  const _ThemeTile({required this.theme, required this.learnedCount, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final total = theme.totalWords;
    final percent = total == 0 ? 0.0 : learnedCount / total;
    final percentLabel = '${(percent * 100).round()}%';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor.withValues(alpha: 0.22), border: Border.all(color: accentColor, width: 2.5)),
                child: Icon(_iconForTheme(theme.name), color: accentColor, size: 20),
              ),
              const SizedBox(height: 10),
              Text(theme.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('$learnedCount/$total ${total == 1 ? "word" : "words"} · $percentLabel', style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(value: percent.clamp(0.0, 1.0), minHeight: 5, valueColor: AlwaysStoppedAnimation(accentColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}