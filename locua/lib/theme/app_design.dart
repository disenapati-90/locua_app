// app_design.dart
// Single source of truth for Locua's visual design tokens: colors,
// gradients, spacing/radii, and the app logo widget. Change a palette hex,
// a gradient stop, or swap the logo asset HERE ONLY — every screen and
// widget below pulls from this file instead of hardcoding values, so a
// rebrand or theme tweak touches one file, not ten.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// One resolved set of colors for whichever AppThemeOption is active.
/// Optimized with extreme deep-matte contrast to eliminate dull interfaces
/// and create luxury editorial layering.
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
    bg: Color(0xFF040E0B),
    surface: Color(0xFF0E241E),
    surfaceAlt: Color(0xFF16372D),
    gold: Color(0xFFD4AF37),
    goldBright: Color(0xFFF3E5AB),
    text: Color(0xFFFAF6E6),
    text2: Color(0xFF85AFA2),
  );

  static const midnight = AppPalette(
    bg: Color(0xFF050B12),
    surface: Color(0xFF101B2B),
    surfaceAlt: Color(0xFF182A42),
    gold: Color(0xFFCBA358),
    goldBright: Color(0xFFEEDBB2),
    text: Color(0xFFF9F8F6),
    text2: Color(0xFF7A93B4),
  );

  static AppPalette of(AppThemeOption option) =>
      option == AppThemeOption.emerald ? emerald : midnight;
}

/// Colors that carry meaning (accuracy = success, etc.) rather than brand
/// identity, so they stay constant across both themes.
class AppSemanticColors {
  static const info = Color(0xFF5CA3D4);
  static const success = Color(0xFF57C282);
  static const warning = Color(0xFFE06C6C);
}

/// Spacing/radius scale used across the home-screen widgets.
class AppMetrics {
  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusPill = 999;
  static const double gapSm = 8;
  static const double gapMd = 16;
  static const double gapLg = 24;
}

/// Reusable premium decorations matching premium mobile software specs.
class AppGradients {
  /// Ambient glass container utilizing rich light-bleeding gradients.
  // CHANGED: withOpacity -> withValues(alpha:) — avoids the precision-loss
  // deprecation warning, same visual result.
  static BoxDecoration glassHero(AppPalette p) => BoxDecoration(
        color: p.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
        border: Border.all(color: p.gold.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: p.bg.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      );

  /// Polished linear gradient creating dynamic luster on theme rail layouts.
  static LinearGradient railCard(AppPalette p, {Color? c1, Color? c2}) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          c1 ?? p.surfaceAlt,
          c2 ?? p.surface.withValues(alpha: 0.9),
        ],
        stops: const [0.1, 0.9],
      );

  static const List<List<Color>> railAccentPairs = [
    [Color(0xFF133D30), Color(0xFF071813)],
    [Color(0xFF183D4F), Color(0xFF0A1922)],
    [Color(0xFF38401B), Color(0xFF191D0C)],
    [Color(0xFF452020), Color(0xFF1D0E0E)],
  ];
}

/// The app's logo mark. Every screen should use THIS widget instead of
/// inlining an Image.asset directly, so replacing the logo file (or
/// changing its size) is a single edit here instead of hunting through
/// every screen that shows it.
///
/// CHANGED: was a plain StatelessWidget with a hardcoded Emerald-gold glow
/// regardless of active theme. Now watches ThemeProvider so the glow color
/// always matches whichever theme (Emerald or Midnight) is actually showing.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final themeOption = context.watch<ThemeProvider>().current;
    final palette = AppPalette.of(themeOption);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: palette.gold.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size),
        child: Image.asset(
          'assets/images/icon_512.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}