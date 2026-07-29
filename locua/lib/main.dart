// main.dart
// Entry point of the Locua app.
// Sets up the ThemeProvider so the whole app can react to theme changes,
// and shows a temporary placeholder Home screen just to prove the branding
// (colors, fonts, theme switching) works before we build the real screens.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(
    // ChangeNotifierProvider makes ThemeProvider available to every widget
    // below it in the tree, without passing it manually screen to screen.
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const LocuaApp(),
    ),
  );
}

class LocuaApp extends StatelessWidget {
  const LocuaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the ThemeProvider so this widget rebuilds whenever the theme changes.
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Locua',
      debugShowCheckedModeBanner: false, // hides the red "DEBUG" ribbon
      theme: themeProvider.themeData, // pulls current theme live
      home: const PlaceholderHomeScreen(),
    );
  }
}

// Temporary screen — will be replaced by the real Home screen (Day 4).
// Just here to visually confirm both themes render correctly.
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        // SafeArea-friendly by default via Scaffold/AppBar combo.
        title: Text('LOCUA', style: Theme.of(context).textTheme.displayLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        // SafeArea ensures content never overlaps system UI —
        // status bar at top, Android nav buttons at bottom.
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Words grow worlds.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Text(
                'Current theme: ${themeProvider.current.name}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                // Tapping this proves theme switching works live, no restart needed.
                onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                child: const Text('Toggle Theme'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}