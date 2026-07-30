// main.dart
// Entry point of the Locua app.
// Sets up the ThemeProvider so the whole app can react to theme changes,
// and loads MainShell — the bottom-nav shell with all 6 screens.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/main_shell.dart';

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
      home: const MainShell(),
    );
  }
}