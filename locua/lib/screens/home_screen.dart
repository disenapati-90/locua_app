// home_screen.dart
// TEMPORARY test version — loads word_bank.json and lists the words,
// just to confirm Step 1-5 worked. Will be replaced with the real
// Home screen design (streak, progress ring, continue-learning card) on Day 4.

import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/word_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Word>>(
      future: WordService.loadWords(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final words = snapshot.data!;
        return ListView.builder(
          itemCount: words.length,
          itemBuilder: (context, index) {
            final w = words[index];
            return ListTile(
              title: Text(w.word, style: Theme.of(context).textTheme.titleLarge),
              subtitle: Text('${w.definition} • ${w.level}'),
            );
          },
        );
      },
    );
  }
}