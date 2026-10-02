// theme_provider.dart
// Defines Locua's two brand themes (Emerald & Gold, Midnight & Gold)
// and a ChangeNotifier that lets any screen switch between them live.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Simple enum to represent which theme is currently active.
enum AppThemeOption { emerald, midnight }

// ---------------------------------------------------------------------------
// THEME 1: Emerald & Gold (High-Contrast Editorial)
// ---------------------------------------------------------------------------
final ThemeData emeraldTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF040E0B), // Ultra-deep matte onyx emerald
  colorScheme: const ColorScheme.dark(
    surface: Color(0xFF0E241E),      // Lighter surface card depth
    primary: Color(0xFFD4AF37),      // True crisp antique gold
    secondary: Color(0xFFF3E5AB),    // Elegant vanilla gold highlight
    secondaryContainer: Color(0xFFD4AF37), // Linked to ensure branded accent container pills
    onSurface: Color(0xFFFAF6E6),    // Parchment high-readability text
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 26, 
      fontWeight: FontWeight.w800, 
      color: const Color(0xFFFAF6E6),
      letterSpacing: -0.5,
    ),
    titleLarge: GoogleFonts.playfairDisplay(
      fontSize: 20, 
      fontWeight: FontWeight.w700, 
      color: const Color(0xFFFAF6E6),
      letterSpacing: 0.2,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 15, 
      fontWeight: FontWeight.w500,
      color: const Color(0xFFFAF6E6), 
      height: 1.55, // POLISHED: Generous editorial line-height ratio
      letterSpacing: 0.15,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 13, 
      fontWeight: FontWeight.w400,
      color: const Color(0xFF85AFA2), // High-contrast sage secondary text
      height: 1.45,
      letterSpacing: 0.1,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF040E0B),
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF0E241E),
    elevation: 4,
    shadowColor: const Color(0xFF040E0B).withOpacity(0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
        topRight: Radius.circular(10),
        bottomLeft: Radius.circular(10),
      ),
      side: BorderSide(color: Color(0xFFD4AF37), width: 1.2),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF16372D),
    labelStyle: GoogleFonts.inter(color: const Color(0xFF85AFA2)),
    hintStyle: GoogleFonts.inter(color: const Color(0xFF85AFA2).withOpacity(0.6)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
    ),
  ),
);

// ---------------------------------------------------------------------------
// THEME 2: Midnight & Gold (High-Contrast Academic)
// ---------------------------------------------------------------------------
final ThemeData midnightTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF050B12), // Deep cosmic black-indigo
  colorScheme: const ColorScheme.dark(
    surface: Color(0xFF101B2B),      // Layered deep slate blue surface
    primary: Color(0xFFCBA358),      // Premium architectural brass gold
    secondary: Color(0xFFEEDBB2),    // Crisp champagne accent gold
    secondaryContainer: Color(0xFFCBA358),
    onSurface: Color(0xFFF9F8F6),    // Pure contrast silver text
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 26, 
      fontWeight: FontWeight.w800, 
      color: const Color(0xFFF9F8F6),
      letterSpacing: -0.5,
    ),
    titleLarge: GoogleFonts.playfairDisplay(
      fontSize: 20, 
      fontWeight: FontWeight.w700, 
      color: const Color(0xFFF9F8F6),
      letterSpacing: 0.2,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 15, 
      fontWeight: FontWeight.w500,
      color: const Color(0xFFF9F8F6), 
      height: 1.55, // POLISHED: Generous editorial line-height ratio
      letterSpacing: 0.15,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 13, 
      fontWeight: FontWeight.w400,
      color: const Color(0xFF7A93B4), // Vibrant high-contrast secondary slate
      height: 1.45,
      letterSpacing: 0.1,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF050B12),
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF101B2B),
    elevation: 4,
    shadowColor: const Color(0xFF050B12).withOpacity(0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
        topRight: Radius.circular(10),
        bottomLeft: Radius.circular(10),
      ),
      side: BorderSide(color: Color(0xFFCBA358), width: 1.2),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF182A42),
    labelStyle: GoogleFonts.inter(color: const Color(0xFF7A93B4)),
    hintStyle: GoogleFonts.inter(color: const Color(0xFF7A93B4).withOpacity(0.6)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: const Color(0xFFCBA358).withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFCBA358), width: 1.5),
    ),
  ),
);

// ---------------------------------------------------------------------------
// ThemeProvider: holds which theme is currently active and notifies the
// whole app to rebuild when it changes.
// ---------------------------------------------------------------------------
class ThemeProvider extends ChangeNotifier {
  AppThemeOption _current = AppThemeOption.emerald; // default theme

  AppThemeOption get current => _current;

  ThemeData get themeData =>
      _current == AppThemeOption.emerald ? emeraldTheme : midnightTheme;

  void setTheme(AppThemeOption option) {
    _current = option;
    notifyListeners();
  }

  void toggleTheme() {
    _current = _current == AppThemeOption.emerald
        ? AppThemeOption.midnight
        : AppThemeOption.emerald;
    notifyListeners();
  }
}
