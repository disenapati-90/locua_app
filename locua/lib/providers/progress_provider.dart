// progress_provider.dart
// Central place that reads/writes Progress data from Hive, exposes
// simple stats (streak, % complete, words learned), and — new for Day 7 —
// figures out which words are actually DUE for review today, based on
// real spaced-repetition scheduling (not just question count).

import 'package:flutter/material.dart';
import '../models/progress.dart';
import '../models/word.dart';
import '../services/storage_service.dart';

class ProgressProvider extends ChangeNotifier {
  List<Progress> get allProgress => StorageService.progressBox.values.toList();

  int get wordsLearnedCount => allProgress.where((p) => p.learned).length;

  int currentStreak = 0;
  void incrementStreakForTesting() {
    currentStreak += 1;
    notifyListeners();
  }

  // Finds (or creates) the Progress entry for a given word.
  // Every word starts with no progress until it's first reviewed.
  Progress getOrCreateProgress(String word) {
    final box = StorageService.progressBox;
    final existing = box.values.where((p) => p.word == word);
    if (existing.isNotEmpty) return existing.first;

    final fresh = Progress(word: word); // defaults: interval 1 day, streak 0
    box.add(fresh);
    return fresh;
  }

  // Returns only the words that are DUE for review today — this is the
  // real SRS logic. A word with no progress yet (never reviewed) counts
  // as due, since it needs its first review.
  List<Word> getDueWords(List<Word> allWords) {
    final now = DateTime.now();
    return allWords.where((w) {
      final progress = getOrCreateProgress(w.word);
      if (progress.nextReviewDue == null) return true; // never reviewed = due now
      return progress.nextReviewDue!.isBefore(now) ||
          progress.nextReviewDue!.isAtSameMomentAs(now);
    }).toList();
  }

  // Call when the user answers correctly in Word Detective.
  Future<void> markCorrect(String word) async {
    final progress = getOrCreateProgress(word);
    progress.markCorrect(); // logic already defined in progress.dart
    await progress.save(); // writes the change back to Hive
    notifyListeners();
  }

  // Call when the user answers incorrectly.
  Future<void> markIncorrect(String word) async {
    final progress = getOrCreateProgress(word);
    progress.markIncorrect();
    await progress.save();
    notifyListeners();
  }
}