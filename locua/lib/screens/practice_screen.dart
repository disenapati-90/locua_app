// practice_screen.dart
// Placeholder for the Practice tab. Will later show Word Detective riddles
// driven by real spaced-repetition (SRS) scheduling (Day 7).

import 'package:flutter/material.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Practice', style: Theme.of(context).textTheme.titleLarge),
    );
  }
}