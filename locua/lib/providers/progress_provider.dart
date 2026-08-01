// progress_provider.dart
// Central place that reads/writes Progress data from Hive and exposes
// simple stats (streak, % complete, words learned) to any screen that needs them.

import 'package:flutter/material.dart';
import '../models/progress.dart';
import '../services/storage_service.dart';

class ProgressProvider extends ChangeNotifier {
  // Returns all saved progress entries.
  List<Progress> get allProgress => StorageService.progressBox.values.toList();

  // Counts how many words are marked "learned" (mastered).
  int get wordsLearnedCount =>
      allProgress.where((p) => p.learned).length;

  // Simple streak placeholder — real streak logic (consecutive days used)
  // will be added once we track daily app-open events. For now, returns a
  // stored value we can update manually to prove the UI works.
  int currentStreak = 0;

  void incrementStreakForTesting() {
    currentStreak += 1;
    notifyListeners();
  }
}