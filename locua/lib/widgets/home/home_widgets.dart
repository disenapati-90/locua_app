// home_widgets.dart
// Reusable widgets for the redesigned Home screen (glass hero, mini stat
// rings, theme rail cards, quick-access tiles, word-of-the-day card).
// All colors/spacing come from AppPalette/AppMetrics in app_design.dart —
// no hardcoded hex values in here, so a theme or spacing tweak never
// requires touching this file.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_design.dart';

/// "Continue" card at the top of Home — current theme, progress, Resume.
class GlassHeroCard extends StatelessWidget {
  final AppPalette palette;
  final String contextLabel;
  final String themeTitle;
  final String subtitle;
  final double progress; // 0..1
  final VoidCallback onResume;

  const GlassHeroCard({
    super.key,
    required this.palette,
    required this.contextLabel,
    required this.themeTitle,
    required this.subtitle,
    required this.progress,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppGradients.glassHero(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contextLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: palette.goldBright,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      themeTitle,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(fontSize: 11.5, color: palette.text2)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.gold,
                  foregroundColor: palette.bg,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppMetrics.radiusSm),
                  ),
                  elevation: 0,
                ),
                child: const Text('Resume',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppMetrics.radiusPill),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation(palette.goldBright),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small circular stat (This Week / Accuracy / Streak style ring).
class MiniRingStat extends StatelessWidget {
  final AppPalette palette;
  final double percent; // 0..1
  final String centerText;
  final String label;
  final Color ringColor;

  const MiniRingStat({
    super.key,
    required this.palette,
    required this.percent,
    required this.centerText,
    required this.label,
    required this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 58,
          height: 58,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                strokeWidth: 5,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation(ringColor),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: palette.bg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  centerText,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: palette.text),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppMetrics.gapSm),
        Text(
          label.toUpperCase(),
          style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
              color: palette.text2),
        ),
      ],
    );
  }
}

/// One card in the horizontally-scrolling "Themes" rail.
class ThemeRailCard extends StatelessWidget {
  final AppPalette palette;
  final String themeName;
  final double percent; // 0..1
  final String level; // "easy" | "medium" | "hard"
  final int learned;
  final int total;
  final Color accent1;
  final Color accent2;
  final VoidCallback onTap;

  const ThemeRailCard({
    super.key,
    required this.palette,
    required this.themeName,
    required this.percent,
    required this.level,
    required this.learned,
    required this.total,
    required this.accent1,
    required this.accent2,
    required this.onTap,
  });

  Color get _levelColor {
    switch (level) {
      case 'hard':
        return AppSemanticColors.warning;
      case 'medium':
        return palette.goldBright;
      default:
        return AppSemanticColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        height: 128,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: AppGradients.railCard(palette, c1: accent1, c2: accent2),
          borderRadius: BorderRadius.circular(AppMetrics.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  value: percent.clamp(0.0, 1.0),
                  strokeWidth: 3,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(palette.goldBright),
                ),
              ),
            ),
            Text(
              themeName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: palette.text),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _levelColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                level.isEmpty ? '' : level[0].toUpperCase() + level.substring(1),
                style: TextStyle(
                    fontSize: 9.5, fontWeight: FontWeight.w700, color: _levelColor),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppMetrics.radiusPill),
                  child: LinearProgressIndicator(
                    value: percent.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(palette.goldBright),
                  ),
                ),
                const SizedBox(height: 2),
                Text('$learned/$total',
                    style: TextStyle(fontSize: 9.5, color: palette.text2)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps a horizontal rail with a right-edge fade so it's visually obvious
/// there's more content to scroll (desktop testers won't miss it — see
/// the Origins-screen backlog note about this same issue).
class FadeEdgeRail extends StatelessWidget {
  final AppPalette palette;
  final double height;
  final Widget child;

  const FadeEdgeRail({
    super.key,
    required this.palette,
    required this.child,
    this.height = 128,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(height: height, child: child),
        Positioned(
          right: 0,
          top: 0,
          bottom: 8,
          width: 28,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [palette.bg.withOpacity(0), palette.bg],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One tile in the "Quick Access" row (Detective / Origins / Vault).
class QuickAccessTile extends StatelessWidget {
  final AppPalette palette;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickAccessTile({
    super.key,
    required this.palette,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: palette.surfaceAlt,
            borderRadius: BorderRadius.circular(AppMetrics.radiusMd),
          ),
          child: Column(
            children: [
              Icon(icon, color: palette.goldBright, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600, color: palette.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact "Word of the Day" card at the bottom of Home.
class WordOfDayCard extends StatelessWidget {
  final AppPalette palette;
  final String word;
  final String definition;
  final VoidCallback onPlayPronunciation;

  const WordOfDayCard({
    super.key,
    required this.palette,
    required this.word,
    required this.definition,
    required this.onPlayPronunciation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppMetrics.radiusMd),
        border: Border(top: BorderSide(color: palette.gold.withOpacity(0.25))),
      ),
      child: Column(
        children: [
          Text(
            'WORD OF THE DAY',
            style: TextStyle(
                fontSize: 9.5,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
                color: palette.gold),
          ),
          const SizedBox(height: 5),
          Text(
            word,
            style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                color: palette.text,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Text(
            definition,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: palette.text2, height: 1.4),
          ),
          const SizedBox(height: 9),
          OutlinedButton(
            onPressed: onPlayPronunciation,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: palette.gold),
              foregroundColor: palette.goldBright,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppMetrics.radiusPill)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            ),
            child: const Text('▶  Hear it', style: TextStyle(fontSize: 10.5)),
          ),
        ],
      ),
    );
  }
}