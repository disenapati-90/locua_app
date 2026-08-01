// main_shell.dart
// The app's main navigation shell: a bottom nav bar with 6 tabs.
// Tab selection now lives in NavProvider (not local state) so other
// screens — like Home's "Resume Story" button — can switch tabs too.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nav_provider.dart';
import '../screens/home_screen.dart';
import '../screens/learn_screen.dart';
import '../screens/practice_screen.dart';
import '../screens/origins_screen.dart';
import '../screens/vault_screen.dart';
import '../screens/settings_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    LearnScreen(),
    PracticeScreen(),
    OriginsScreen(),
    VaultScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavProvider>();

    return Scaffold(
      appBar: AppBar(
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
          index: navProvider.selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navProvider.selectedIndex,
        onDestinationSelected: (index) => navProvider.setIndex(index),
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