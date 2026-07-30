// learn_screen.dart
// Placeholder for the Learn tab. Will later show themed story episodes
// with word highlights and Easy/Medium/Hard tabs (Day 6).

import 'package:flutter/material.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Learn', style: Theme.of(context).textTheme.titleLarge),
    );
  }
}