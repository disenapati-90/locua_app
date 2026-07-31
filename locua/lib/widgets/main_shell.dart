// main_shell.dart
// The app's main navigation shell: a bottom nav bar with 6 tabs,
// switching between Home, Learn, Practice, Origins, Vault, Settings.
//
// Uses IndexedStack (not Navigator) so switching tabs doesn't rebuild
// screens from scratch each time — each tab keeps its own state alive
// in the background, which matters later for things like an in-progress
// story or an active timer not resetting when you switch away and back.

import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/learn_screen.dart';
import '../screens/practice_screen.dart';
import '../screens/origins_screen.dart';
import '../screens/vault_screen.dart';
import '../screens/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Tracks which tab is currently selected (0 = Home, 1 = Learn, etc.)
  int _selectedIndex = 0;

  // The actual screen widgets, in the same order as the nav bar items below.
  final List<Widget> _screens = const [
    HomeScreen(),
    LearnScreen(),
    PracticeScreen(),
    OriginsScreen(),
    VaultScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SafeArea wraps the body so content never overlaps the phone's
      // status bar (top) or system nav buttons (bottom) — confirmed
      // working correctly per our earlier discussion.
      appBar: AppBar(
        // Logo placeholder — shows the real Locua mark, not just text.
        // Swap this asset later if the logo gets refined.
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/icon_512.png', height: 32),
            const SizedBox(width: 10),
            Text('LOCUA', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index); // switches the visible tab
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Learn'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Practice'),
          NavigationDestination(icon: Icon(Icons.public_outlined), selectedIcon: Icon(Icons.public), label: 'Origins'),
          NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories), label: 'Vault'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}