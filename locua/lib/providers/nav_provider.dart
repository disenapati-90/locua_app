// nav_provider.dart
// Tracks which bottom-nav tab is currently active, shared across the app.
// This lets any screen (like Home's "Resume Story" button) programmatically
// switch tabs, instead of the tab index being trapped inside MainShell alone.

import 'package:flutter/material.dart';

class NavProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}