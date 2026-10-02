// progress_provider.dart
// Central place that reads/writes Progress data from Hive, exposes
// simple stats (streak, % complete, words learned, accuracy, weak words),
// and figures out which words are actually DUE for review today, based
// on real spaced-repetition scheduling (not just question count).

import 'package:flutter/material.dart';
import '../models/progress.dart';
import '../models/word.dart';
import '../services/storage_service.dart';

class ProgressProvider extends ChangeNotifier {
  List<Progress> get allProgress => StorageService.progressBox.values.toList();

  int get wordsLearnedCount => allProgress.where((p) => p.learned).length;

  int get currentStreak => StorageService.getOrCreateAppMeta().currentStreak;
  int get longestStreak => StorageService.getOrCreateAppMeta().longestStreak;

  ProgressProvider() {
    _updateStreakForAppOpen();
  }

  void _updateStreakForAppOpen() {
    final meta = StorageService.getOrCreateAppMeta();
    final today = _dateOnly(DateTime.now());

    if (meta.lastOpenDate == null) {
      meta.currentStreak = 1;
      meta.longestStreak = 1;
      meta.lastOpenDate = today;
      meta.save();
      return;
    }

    final lastOpen = _dateOnly(meta.lastOpenDate!);
    final daysSinceLastOpen = today.difference(lastOpen).inDays;

    if (daysSinceLastOpen == 0) {
      return;
    } else if (daysSinceLastOpen == 1) {
      meta.currentStreak += 1;
    } else {
      meta.currentStreak = 1;
    }

    if (meta.currentStreak > meta.longestStreak) {
      meta.longestStreak = meta.currentStreak;
    }
    meta.lastOpenDate = today;
    meta.save();
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Progress getOrCreateProgress(String word) {
    final box = StorageService.progressBox;
    final existing = box.values.where((p) => p.word == word);
    if (existing.isNotEmpty) return existing.first;

    final fresh = Progress(word: word);
    box.add(fresh);
    return fresh;
  }

  double get overallAccuracy {
    final all = allProgress;
    if (all.isEmpty) return 0.0;
    final totalAttempts = all.fold(0, (sum, p) => sum + p.totalAttempts);
    final totalCorrect = all.fold(0, (sum, p) => sum + p.correctAttempts);
    if (totalAttempts == 0) return 0.0;
    return (totalCorrect / totalAttempts) * 100;
  }

  List<Progress> get weakWords {
    return allProgress
        .where((p) => p.totalAttempts >= 2 && (p.correctAttempts / p.totalAttempts) < 0.5)
        .toList();
  }

  List<Word> getDueWords(List<Word> allWords) {
    final now = DateTime.now();
    return allWords.where((w) {
      final progress = getOrCreateProgress(w.word);
      if (progress.nextReviewDue == null) return true;
      return progress.nextReviewDue!.isBefore(now) ||
          progress.nextReviewDue!.isAtSameMomentAs(now);
    }).toList();
  }

  Future<void> markCorrect(String word) async {
    final progress = getOrCreateProgress(word);
    progress.markCorrect();
    await progress.save();
    notifyListeners();
  }

  Future<void> markIncorrect(String word) async {
    final progress = getOrCreateProgress(word);
    progress.markIncorrect();
    await progress.save();
    notifyListeners();
  }
}