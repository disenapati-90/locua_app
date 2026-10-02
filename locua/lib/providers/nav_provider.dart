// nav_provider.dart
// Tracks which bottom-nav tab is active, plus two independent "pending
// deep-link" channels other screens can queue for the destination tab to
// consume: pendingTheme (-> Learn) and pendingLanguageGroup (-> Origins,
// ADDED this session, mirrors the theme mechanism exactly).

import 'package:flutter/material.dart';

class NavProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  String? _pendingTheme;
  int _themeRequestId = 0;

  // ADDED: Origins equivalent of pendingTheme/themeRequestId.
  String? _pendingLanguageGroup;
  int _languageGroupRequestId = 0;

  List<String>? _pendingPracticeWords;
  int _practiceRequestId = 0;

  int get selectedIndex => _selectedIndex;
  String? get pendingTheme => _pendingTheme;
  int get themeRequestId => _themeRequestId;
  String? get pendingLanguageGroup => _pendingLanguageGroup;
  int get languageGroupRequestId => _languageGroupRequestId;
  List<String>? get pendingPracticeWords => _pendingPracticeWords;
  int get practiceRequestId => _practiceRequestId;

  void setIndex(int index, {String? theme, String? languageGroup}) {
    _selectedIndex = index;
    if (theme != null) {
      _pendingTheme = theme;
      _themeRequestId++;
    } else {
      _pendingTheme = null;
    }
    if (languageGroup != null) {
      _pendingLanguageGroup = languageGroup;
      _languageGroupRequestId++;
    } else {
      _pendingLanguageGroup = null;
    }
    notifyListeners();
  }

  void clearPendingTheme() {
    _pendingTheme = null;
  }

  void clearPendingLanguageGroup() {
    _pendingLanguageGroup = null;
  }

  void openPracticeWithWords(List<String> words) {
    _selectedIndex = 2;
    _pendingPracticeWords = words;
    _practiceRequestId++;
    notifyListeners();
  }

  void clearPendingPracticeWords() {
    _pendingPracticeWords = null;
  }
}