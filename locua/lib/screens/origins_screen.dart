// origins_screen.dart
// Real Origins screen: flashcard browse of foreign-origin words, filterable
// by language, with pronunciation via TTS and a "mark as learned" toggle.
// Phonetic spelling (originSpelling) is always shown as text, since TTS
// quality/availability varies by language — audio is a supplement, not
// the only pronunciation reference.

import 'package:flutter/material.dart';
import '../models/origin_word.dart';
import '../services/origin_service.dart';
import '../services/tts_service.dart';

class OriginsScreen extends StatefulWidget {
  const OriginsScreen({super.key});

  @override
  State<OriginsScreen> createState() => _OriginsScreenState();
}

class _OriginsScreenState extends State<OriginsScreen> {
  String _selectedLanguage = 'All';
  final Set<String> _learnedWords = {}; // simple in-memory toggle for now

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OriginWord>>(
      future: OriginService.loadOriginWords(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allWords = snapshot.data!;
        // Build the list of unique languages present, for the filter chips.
        final languages = ['All', ...{for (var w in allWords) w.originLanguage}];

        final filtered = _selectedLanguage == 'All'
            ? allWords
            : allWords.where((w) => w.originLanguage == _selectedLanguage).toList();

        return Column(
          children: [
            // ---- Language filter chips ----
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: languages.map((lang) {
                  final isSelected = _selectedLanguage == lang;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(lang),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedLanguage = lang),
                    ),
                  );
                }).toList(),
              ),
            ),
            // ---- Word cards ----
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final w = filtered[index];
                  final isLearned = _learnedWords.contains(w.word);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${w.originLanguage} · ${w.originSpelling}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 6),
                          Text(w.word, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(w.meaning, style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: 6),
                          Text(w.funFact,
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Pronunciation button — speaks the origin spelling
                              // using the word's own locale.
                              OutlinedButton.icon(
                                onPressed: () => TtsService.speak(
                                  w.originSpelling,
                                  locale: w.pronunciationLocale,
                                ),
                                icon: const Icon(Icons.volume_up, size: 18),
                                label: const Text('Hear pronunciation'),
                              ),
                              const SizedBox(width: 8),
                              // Mark as learned toggle
                              FilterChip(
                                label: Text(isLearned ? 'Learned ✓' : 'Mark as learned'),
                                selected: isLearned,
                                onSelected: (_) {
                                  setState(() {
                                    if (isLearned) {
                                      _learnedWords.remove(w.word);
                                    } else {
                                      _learnedWords.add(w.word);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
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
}