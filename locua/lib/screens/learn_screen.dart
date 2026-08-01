// learn_screen.dart
// Real Learn screen: shows story sentences grouped by theme/episode,
// with the target word tappable to reveal its definition, synonyms,
// and antonyms. Includes Easy/Medium/Hard level filter tabs.

import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/word_service.dart';
import 'package:flutter/gestures.dart';
import '../services/tts_service.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  // Currently selected difficulty filter. "all" shows every level.
  String _selectedLevel = 'all';

  // Tracks which words are currently "revealed" (definition shown),
  // keyed by the word text itself.
  final Set<String> _revealedWords = {};

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Word>>(
      future: WordService.loadWords(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter by selected level (unless "all" is chosen).
        final words = snapshot.data!
            .where((w) => _selectedLevel == 'all' || w.level == _selectedLevel)
            .toList();

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

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Theme + episode label
                          Text(
                            '${w.theme} · Episode ${w.storyEpisode}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 8),
                          // Story sentence with the target word tappable
                          _buildHighlightedSentence(context, w),
                          // Definition/synonyms/antonyms — only shown once tapped
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
          ],
        );
      },
    );
  }

  // Builds a filter chip for a given level value.
  Widget _levelChip(String value, String label) {
    final isSelected = _selectedLevel == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedLevel = value),
    );
  }

  // Renders the story sentence, splitting out the target word so it can
  // be styled distinctly and tapped to reveal its definition.
  Widget _buildHighlightedSentence(BuildContext context, Word w) {
    final sentence = w.sentence;
    final wordIndex = sentence.toLowerCase().indexOf(w.word.toLowerCase());

    // Fallback: if the word isn't found in the sentence text exactly
    // (e.g. different tense), just show the plain sentence.
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
            // Tapping the highlighted word toggles reveal on/off
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