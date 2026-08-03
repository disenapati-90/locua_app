// progress_provider.dart
// Central place that reads/writes Progress data from Hive, exposes
// simple stats (streak, % complete, words learned, accuracy, weak words),
// and figures out which words are actually DUE for review today, based
// on real spaced-repetition scheduling (not just question count).

import 'package:flutter/material.dart';
import '../models/progress.dart';
import '../models/app_meta.dart';
import '../models/word.dart';
import '../services/storage_service.dart';

class ProgressProvider extends ChangeNotifier {
  List<Progress> get allProgress => StorageService.progressBox.values.toList();

  int get wordsLearnedCount => allProgress.where((p) => p.learned).length;

  // Streak is now read live from the persisted AppMeta record instead of
  // an in-memory placeholder — it survives app restarts.
  int get currentStreak => StorageService.getOrCreateAppMeta().currentStreak;
  int get longestStreak => StorageService.getOrCreateAppMeta().longestStreak;

  ProgressProvider() {
    _updateStreakForAppOpen();
  }

  // Runs once when the app starts (provider is created at startup via
  // MultiProvider in main.dart). Compares today's date to the last time
  // the app was opened:
  //   - same calendar day  -> no change, already counted today
  //   - exactly 1 day later -> streak continues, +1
  //   - more than 1 day gap (or first-ever open) -> streak resets to 1
  void _updateStreakForAppOpen() {
    final meta = StorageService.getOrCreateAppMeta();
    final today = _dateOnly(DateTime.now());

    if (meta.lastOpenDate == null) {
      // First time the app has ever been opened.
      meta.currentStreak = 1;
      meta.longestStreak = 1;
      meta.lastOpenDate = today;
      meta.save();
      return;
    }

    final lastOpen = _dateOnly(meta.lastOpenDate!);
    final daysSinceLastOpen = today.difference(lastOpen).inDays;

    if (daysSinceLastOpen == 0) {
      // Already opened today — no change, don't double-count.
      return;
    } else if (daysSinceLastOpen == 1) {
      // Opened exactly one day after the last visit — streak continues.
      meta.currentStreak += 1;
    } else {
      // Gap of 2+ days — streak broken, restart at 1.
      meta.currentStreak = 1;
    }

    if (meta.currentStreak > meta.longestStreak) {
      meta.longestStreak = meta.currentStreak;
    }
    meta.lastOpenDate = today;
    meta.save();
  }

  // Strips the time component so date comparisons aren't thrown off by
  // hours/minutes (e.g. opening at 11pm vs 1am the next day).
  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

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

  // Overall accuracy across every attempt ever made, as a percentage.
  double get overallAccuracy {
    final all = allProgress;
    if (all.isEmpty) return 0.0;
    final totalAttempts = all.fold(0, (sum, p) => sum + p.totalAttempts);
    final totalCorrect = all.fold(0, (sum, p) => sum + p.correctAttempts);
    if (totalAttempts == 0) return 0.0;
    return (totalCorrect / totalAttempts) * 100;
  }

  // Words that have been attempted but are struggling — answered at
  // least twice, with less than 50% accuracy. These are the "weak words"
  // worth highlighting to the user.
  List<Progress> get weakWords {
    return allProgress
        .where((p) => p.totalAttempts >= 2 && (p.correctAttempts / p.totalAttempts) < 0.5)
        .toList();
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