// learn_screen.dart
// Real Learn screen: shows story sentences grouped by theme/episode,
// with the target word tappable to reveal its definition, synonyms,
// and antonyms. Includes Easy/Medium/Hard level filter tabs.
//
// Also listens for NavProvider.pendingTheme — if Home sent the user here
// targeting a specific theme (via Resume or a theme-rail card), this
// screen resets the level filter to "all" (so the target theme can't be
// hidden by a stale filter) and auto-scrolls to that theme's first card.
// Uses themeRequestId (not the theme name) to detect "is this a new
// request", so tapping the same theme twice in a row still scrolls.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../services/word_service.dart';
import 'package:flutter/gestures.dart';
import '../services/tts_service.dart';
import '../providers/nav_provider.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String _selectedLevel = 'all';
  final Set<String> _revealedWords = {};

  // Persists across rebuilds intentionally — each theme's key is created
  // once and reused, not regenerated every build.
  final Map<String, GlobalKey> _themeKeys = {};

  // Sentinel so the very first pending theme (requestId 0 or above) always
  // triggers on initial load.
  int _handledRequestId = -1;

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavProvider>();
    final pendingTheme = navProvider.pendingTheme;
    final requestId = navProvider.themeRequestId;

    return FutureBuilder<List<Word>>(
      future: WordService.loadWords(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (pendingTheme != null && requestId != _handledRequestId) {
          _handledRequestId = requestId;
          _goToTheme(pendingTheme, navProvider);
        }

        final words = snapshot.data!
            .where((w) => _selectedLevel == 'all' || w.level == _selectedLevel)
            .toList();

        // Ensure every theme present has a stable key (won't overwrite
        // existing ones — word bank is static so this only ever adds).
        for (final w in words) {
          _themeKeys.putIfAbsent(w.theme, () => GlobalKey());
        }

        return Column(
          children: [
            // ---- Level filter tabs ----
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
            // ---- Story cards list ----
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: words.length,
                itemBuilder: (context, index) {
                  final w = words[index];
                  final isRevealed = _revealedWords.contains(w.word);
                  final isFirstOfTheme =
                      index == 0 || words[index - 1].theme != w.theme;

                  final card = Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${w.theme} · Episode ${w.storyEpisode}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 8),
                          _buildHighlightedSentence(context, w),
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

                  return isFirstOfTheme
                      ? KeyedSubtree(key: _themeKeys[w.theme], child: card)
                      : card;
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _goToTheme(String theme, NavProvider navProvider) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_selectedLevel != 'all') {
        setState(() => _selectedLevel = 'all');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToTheme(theme);
        });
      } else {
        _scrollToTheme(theme);
      }
      navProvider.clearPendingTheme();
    });
  }

  void _scrollToTheme(String theme) {
    final key = _themeKeys[theme];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }

  Widget _levelChip(String value, String label) {
    final isSelected = _selectedLevel == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedLevel = value),
    );
  }

  Widget _buildHighlightedSentence(BuildContext context, Word w) {
    final sentence = w.sentence;
    final wordIndex = sentence.toLowerCase().indexOf(w.word.toLowerCase());

    if (wordIndex == -1) {
      return Text(sentence, style: Theme.of(context).textTheme.bodyLarge);
    }

    final before = sentence.substring(0, wordIndex);
    final match = sentence.substring(wordIndex, wordIndex + w.word.length);
    final after = sentence.substring(wordIndex + w.word.length);

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyLarge,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dashed,
            ),
            recognizer: (TapGestureRecognizer()
              ..onTap = () {
                setState(() {
                  if (_revealedWords.contains(w.word)) {
                    _revealedWords.remove(w.word);
                  } else {
                    _revealedWords.add(w.word);
                  }
                });
              }),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}