// main_shell.dart
// The app's main navigation shell: bottom nav bar with 6 tabs, plus the
// SINGLE app-wide back-button handler.
//
// Session 7 Phase 2: back handling centralized here via
// BackHandlerRegistry (see that file for why — IndexedStack keeps every
// tab mounted at once, so per-screen PopScopes conflicted).
//
// Session 7 Phase 4: added a `_isHandlingPop` guard. On Flutter WEB
// specifically, PopScope intercepts the browser's history "pop" event,
// and a very fast second back-press can arrive before the first one's
// history-state sync finishes — letting it leak through to the browser's
// real back navigation and skip our step-back/exit-confirm logic
// entirely. This guard ignores any back-press that arrives while one is
// already being handled (e.g. the confirm dialog is still open), which
// meaningfully tightens this. NOTE: this is a web-specific quirk in how
// PopScope interacts with browser history — it should not occur on a
// compiled native Android build, where back-press interception happens
// at the OS level with no browser history layer involved. Worth
// re-testing on a real APK once available, rather than relying solely on
// the web preview to judge back-button behavior.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:provider/provider.dart';
import '../providers/nav_provider.dart';
import '../screens/home_screen.dart';
import '../screens/learn_screen.dart';
import '../screens/practice_screen.dart';
import '../screens/origins_screen.dart';
import '../screens/vault_screen.dart';
import '../screens/settings_screen.dart';
import 'back_handler_registry.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const List<Widget> _screens = [
    HomeScreen(),
    LearnScreen(),
    PracticeScreen(),
    OriginsScreen(),
    VaultScreen(),
    SettingsScreen(),
  ];

  bool _isHandlingPop = false;

  Future<void> _confirmExit(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exit Locua?'),
        content: const Text('Are you sure you want to close the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  Future<void> _handlePop(BuildContext context, NavProvider navProvider) async {
    if (_isHandlingPop) return; // ignore overlapping back-presses
    _isHandlingPop = true;
    try {
      final handler = BackHandlerRegistry.handlerFor(navProvider.selectedIndex);
      final steppedBack = handler?.call() ?? false;
      if (!steppedBack) {
        await _confirmExit(context);
      }
    } finally {
      _isHandlingPop = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handlePop(context, navProvider);
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 56,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/icon_512.png', height: 32),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LOCUA', style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    'WORDS GROW WORLDS',
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
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
      ),
    );
  }
}