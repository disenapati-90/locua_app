// nav_provider.dart
// Tracks which bottom-nav tab is currently active, shared across the app.
// Also carries an optional "pending theme" — set when another screen (like
// Home's Resume button or a theme-rail card) wants Learn to jump straight
// to a specific theme instead of just opening on whatever it last showed.
//
// themeRequestId increments on every setIndex(..., theme: ...) call, even
// if the theme name repeats (e.g. tapping "Startup Life" twice in a row).
// LearnScreen compares against THIS id, not the theme string, so a repeat
// tap on the same theme still triggers a fresh scroll instead of being
// mistaken for "already handled."

import 'package:flutter/material.dart';

class NavProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  String? _pendingTheme;
  int _themeRequestId = 0;

  int get selectedIndex => _selectedIndex;
  String? get pendingTheme => _pendingTheme;
  int get themeRequestId => _themeRequestId;

  void setIndex(int index, {String? theme}) {
    _selectedIndex = index;
    if (theme != null) {
      _pendingTheme = theme;
      _themeRequestId++;
    } else {
      // Manual tab taps (bottom nav) carry no theme — clears any stale
      // pending target so switching tabs by hand never triggers an old
      // queued scroll.
      _pendingTheme = null;
    }
    notifyListeners();
  }

  void clearPendingTheme() {
    _pendingTheme = null;
  }
}