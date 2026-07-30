// home_screen.dart
// Placeholder for the Home tab. Will later show streak, progress ring,
// and "continue learning" card (Day 4). For now just confirms navigation works.

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Home', style: Theme.of(context).textTheme.titleLarge),
    );
  }
}