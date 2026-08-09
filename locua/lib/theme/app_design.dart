// app_design.dart
// Single source of truth for Locua's visual design tokens: colors,
// gradients, spacing/radii, and the app logo widget. Change a palette hex,
// a gradient stop, or swap the logo asset HERE ONLY — every screen and
// widget below pulls from this file instead of hardcoding values, so a
// rebrand or theme tweak touches one file, not ten.

import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

/// One resolved set of colors for whichever AppThemeOption is active.
/// Mirrors the hex values in theme_provider.dart's emeraldTheme/
/// midnightTheme, kept here as raw Color values because some widgets need
/// more granular tokens (surfaceAlt, text2, goldBright) than Flutter's
/// ColorScheme exposes by name. If you ever add a THIRD theme, add one
/// more static const block here and one more branch in `of()`.
class AppPalette {
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color gold;
  final Color goldBright;
  final Color text;
  final Color text2;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.gold,
    required this.goldBright,
    required this.text,
    required this.text2,
  });

  static const emerald = AppPalette(
    bg: Color(0xFF0B2B22),
    surface: Color(0xFF163C2E),
    surfaceAlt: Color(0xFF1F4A38),
    gold: Color(0xFFC9A227),
    goldBright: Color(0xFFE4C158),
    text: Color(0xFFF5EFD9),
    text2: Color(0xFFA8C3B5),
  );

  static const midnight = AppPalette(
    bg: Color(0xFF0D1B2A),
    surface: Color(0xFF142238),
    surfaceAlt: Color(0xFF1C3050),
    gold: Color(0xFFC6A15B),
    goldBright: Color(0xFFDEB975),
    text: Color(0xFFF2EFEA),
    text2: Color(0xFF8FA3BF),
  );

  static AppPalette of(AppThemeOption option) =>
      option == AppThemeOption.emerald ? emerald : midnight;
}

/// Colors that carry meaning (accuracy = success, etc.) rather than brand
/// identity, so they stay constant across both themes. Tweak here to
/// change the "mood" of stat rings app-wide.
class AppSemanticColors {
  static const info = Color(0xFF7FB8E0);
  static const success = Color(0xFF8FD6A3);
  static const warning = Color(0xFFE69A9A);
}

/// Spacing/radius scale used across the home-screen widgets. Tightening or
/// loosening the whole layout later is a one-line change per token instead
/// of hunting through every widget file.
class AppMetrics {
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusPill = 999;
  static const double gapSm = 6;
  static const double gapMd = 12;
  static const double gapLg = 18;
}

/// Reusable gradients/decorations, matching the finalized HTML mockup's
/// glass-hero and rail-card backgrounds. Each takes an AppPalette so it
/// automatically adapts when the user switches Emerald <-> Midnight.
class AppGradients {
  static BoxDecoration glassHero(AppPalette p) => BoxDecoration(
        color: p.surfaceAlt.withOpacity(0.42),
        borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
        border: Border.all(color: p.gold.withOpacity(0.22)),
      );

  static LinearGradient railCard(AppPalette p, {Color? c1, Color? c2}) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c1 ?? p.surfaceAlt, c2 ?? p.surface],
      );

  /// Decorative accent pairs cycled across theme-rail cards for visual
  /// variety (purely cosmetic — add/remove/reorder pairs freely).
  static const List<List<Color>> railAccentPairs = [
    [Color(0xFF2A5A44), Color(0xFF163C2E)],
    [Color(0xFF1F4A38), Color(0xFF0F2B21)],
    [Color(0xFF3A4A2A), Color(0xFF1C2415)],
    [Color(0xFF4A2A2A), Color(0xFF241515)],
  ];
}

/// The app's logo mark. Every screen should use THIS widget instead of
/// inlining an Image.asset directly, so replacing the logo file (or
/// changing its size) is a single edit here instead of hunting through
/// every screen that shows it. Currently points at the same asset used
/// in main_shell.dart's AppBar.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/icon_512.png',
      width: size,
      height: size,
    );
  }
}