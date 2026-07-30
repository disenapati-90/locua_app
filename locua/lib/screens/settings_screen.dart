// settings_screen.dart
// Placeholder for the Settings tab. Will later show theme switcher,
// reminders toggle, and Remove Ads purchase button (Day 13).
// Note: theme toggle already works globally (built Day 1) — we'll move
// the toggle button here permanently once this screen is built out.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          // Temporary theme toggle button, moved here from the old placeholder home screen.
          ElevatedButton(
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            child: const Text('Toggle Theme'),
          ),
        ],
      ),
    );
  }
}