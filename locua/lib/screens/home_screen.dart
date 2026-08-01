// home_screen.dart
// Real Home screen: streak counter, progress ring (% of word bank learned),
// and a "continue learning" card. Pulls live data from ProgressProvider
// and the word bank, instead of the temporary test list from Day 3.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../services/word_service.dart';
import '../providers/progress_provider.dart';
import '../providers/nav_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();

    return FutureBuilder<List<Word>>(
      future: WordService.loadWords(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final totalWords = snapshot.data!.length;
        final learnedCount = progressProvider.wordsLearnedCount;
        final percent = totalWords == 0 ? 0.0 : learnedCount / totalWords;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Progress ring + streak row ----
              Row(
                children: [
                  SizedBox(
                    width: 74,
                    height: 74,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: percent,
                          strokeWidth: 6,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text('${(percent * 100).round()}%',
                            style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${progressProvider.currentStreak} day streak',
                          style: Theme.of(context).textTheme.titleLarge),
                      Text('$learnedCount / $totalWords words learned',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ---- Continue Learning card ----
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CONTINUE LEARNING',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(height: 6),
                      Text(
                        snapshot.data!.isNotEmpty
                            ? snapshot.data!.first.theme
                            : 'No words yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          context.read<NavProvider>().setIndex(1); // jumps to Learn tab
                        
                        },
                        child: const Text('Resume Story'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}