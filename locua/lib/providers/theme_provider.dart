// theme_provider.dart
// Defines Locua's two brand themes (Emerald & Gold, Midnight & Gold)
// and a ChangeNotifier that lets any screen switch between them live.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Simple enum to represent which theme is currently active.
// Using an enum (instead of raw strings) avoids typos like "emerlad" breaking things silently.
enum AppThemeOption { emerald, midnight }

// ---------------------------------------------------------------------------
// THEME 1: Emerald & Gold
// Deep forest green background with gold accents — the primary brand theme,
// based on the finalized Locua logo (column + laurel wreath + language ring).
// ---------------------------------------------------------------------------
final ThemeData emeraldTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0B2B22), // bg
  colorScheme: const ColorScheme.dark(
    surface: Color(0xFF163C2E),      // surface (cards)
    primary: Color(0xFFC9A227),      // gold (buttons, highlights)
    secondary: Color(0xFFE4C158),    // gold-bright (accents)
    onSurface: Color(0xFFF5EFD9),    // text primary
  ),
  // Headings use Playfair Display (elegant serif, matches the wordmark)
  textTheme: TextTheme(
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFFF5EFD9),
    ),
    titleLarge: GoogleFonts.playfairDisplay(
      fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFFF5EFD9),
    ),
    // Body text uses Inter (clean, highly readable for definitions/riddles)
    bodyMedium: GoogleFonts.inter(
      fontSize: 14, color: const Color(0xFFA8C3B5), // text secondary
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 14, color: const Color(0xFFF5EFD9), // text primary
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0B2B22),
    elevation: 0,
  ),
);

// ---------------------------------------------------------------------------
// THEME 2: Midnight & Gold
// Deep navy background with a slightly cooler gold — the secondary theme,
// same premium feel, different mood. User picks this in Settings.
// ---------------------------------------------------------------------------
final ThemeData midnightTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0D1B2A), // bg
  colorScheme: const ColorScheme.dark(
    surface: Color(0xFF142238),      // surface (cards)
    primary: Color(0xFFC6A15B),      // gold (buttons, highlights)
    secondary: Color(0xFFDEB975),    // gold-bright (accents)
    onSurface: Color(0xFFF2EFEA),    // text primary
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFFF2EFEA),
    ),
    titleLarge: GoogleFonts.playfairDisplay(
      fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFFF2EFEA),
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14, color: const Color(0xFF8FA3BF), // text secondary
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 14, color: const Color(0xFFF2EFEA), // text primary
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0D1B2A),
    elevation: 0,
  ),
);

// ---------------------------------------------------------------------------
// ThemeProvider: holds which theme is currently active and notifies the
// whole app to rebuild when it changes. Any screen can call
// context.read<ThemeProvider>().toggleTheme() to switch themes instantly.
//
// NOTE: this is in-memory only for now (resets on app restart).
// On Day 3, once Hive is wired in, we'll persist the choice so the user's
// theme selection survives closing/reopening the app.
// ---------------------------------------------------------------------------
class ThemeProvider extends ChangeNotifier {
  AppThemeOption _current = AppThemeOption.emerald; // default theme

  AppThemeOption get current => _current;

  // Returns the actual ThemeData object matching the current selection.
  ThemeData get themeData =>
      _current == AppThemeOption.emerald ? emeraldTheme : midnightTheme;

  // Switches to a specific theme.
  void setTheme(AppThemeOption option) {
    _current = option;
    notifyListeners(); // tells every listening widget to rebuild with new theme
  }

  // Convenience toggle between the two themes.
  void toggleTheme() {
    _current = _current == AppThemeOption.emerald
        ? AppThemeOption.midnight
        : AppThemeOption.emerald;
    notifyListeners();
  }
}