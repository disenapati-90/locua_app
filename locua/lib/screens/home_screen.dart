// home_screen.dart
// Redesigned Home screen ("Hybrid" mockup direction): glass hero for the
// current in-progress theme, three stat rings, a horizontally-scrolling
// theme rail, quick access to Detective/Origins/Vault, and a Word of the
// Day card. All visual tokens come from theme/app_design.dart — nothing
// here is a hardcoded color/gradient, so a rebrand never touches this file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../services/word_service.dart';
import '../providers/progress_provider.dart';
import '../providers/nav_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_design.dart';
import '../widgets/home/home_widgets.dart';
import '../services/tts_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Stable "word of the day" — same word all day, changes daily, no extra
  // storage needed. Based on day-of-year so it naturally cycles through
  // the whole word bank over the year.
  int _dayOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    return date.difference(startOfYear).inDays + 1;
  }

  // Most common level among a theme's words, used for the rail's level tag
  // (Word.level is per-word, themes don't have their own level field).
  String _dominantLevel(List<Word> words) {
    final counts = <String, int>{};
    for (final w in words) {
      counts[w.level] = (counts[w.level] ?? 0) + 1;
    }
    var best = words.first.level;
    var bestCount = 0;
    counts.forEach((level, count) {
      if (count > bestCount) {
        best = level;
        bestCount = count;
      }
    });
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();
    final themeOption = context.watch<ThemeProvider>().current;
    final palette = AppPalette.of(themeOption);

    return FutureBuilder<List<Word>>(
      future: WordService.loadWords(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allWords = snapshot.data!;
        final totalWords = allWords.length;

        // Read-only lookup — never calls getOrCreateProgress() here, since
        // that method WRITES a new Hive entry for every word it's given.
        // Looping that over the whole word bank just to render Home would
        // silently create hundreds of junk Progress records.
        final progressByWord = {
          for (final p in progressProvider.allProgress) p.word: p
        };
        bool isLearned(String word) => progressByWord[word]?.learned ?? false;

        final learnedCount = allWords.where((w) => isLearned(w.word)).length;
        final wordBankPercent = totalWords == 0 ? 0.0 : learnedCount / totalWords;
        final accuracyPercent = progressProvider.overallAccuracy / 100;
        final currentStreak = progressProvider.currentStreak;
        // Visual fill only (streak ring), not a literal goal — treats a
        // 7-day run as a "full" ring. Tweak the divisor to change the feel.
        final streakRingPercent = (currentStreak / 7).clamp(0.0, 1.0);

        // Group words by theme, preserving word_bank.json order.
        final themeMap = <String, List<Word>>{};
        for (final w in allWords) {
          themeMap.putIfAbsent(w.theme, () => []).add(w);
        }
        final themeEntries = themeMap.entries.toList();

        // Pick the "Continue" theme: first one that's started but not
        // finished; falls back to the very first theme if none in progress.
        String continueTheme = themeEntries.isNotEmpty ? themeEntries.first.key : '';
        int continueLearned = 0;
        int continueTotal = themeEntries.isNotEmpty ? themeEntries.first.value.length : 0;
        String continueLevel =
            themeEntries.isNotEmpty ? _dominantLevel(themeEntries.first.value) : 'easy';
        for (final entry in themeEntries) {
          final total = entry.value.length;
          final learned = entry.value.where((w) => isLearned(w.word)).length;
          if (learned > 0 && learned < total) {
            continueTheme = entry.key;
            continueLearned = learned;
            continueTotal = total;
            continueLevel = _dominantLevel(entry.value);
            break;
          }
        }
        if (continueLearned == 0 && themeEntries.isNotEmpty) {
          continueLearned =
              themeEntries.first.value.where((w) => isLearned(w.word)).length;
        }
        final continuePercent = continueTotal == 0 ? 0.0 : continueLearned / continueTotal;

        // Word of the day — stable for the whole calendar day.
        Word? wordOfDay;
        if (allWords.isNotEmpty) {
          final index = _dayOfYear(DateTime.now()) % allWords.length;
          wordOfDay = allWords[index];
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Header: logo + brand + streak chip ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const AppLogo(size: 32),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Locua',
                                style: TextStyle(
                                    fontFamily: 'PlayfairDisplay',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: palette.text)),
                            Text('WORDS GROW WORLDS',
                                style: TextStyle(
                                    fontSize: 6,
                                    letterSpacing: 1.2,
                                    color: palette.text2)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: palette.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppMetrics.radiusPill),
                        border: Border.all(color: palette.gold.withOpacity(0.35)),
                      ),
                      child: Text('🔥 $currentStreak',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: palette.goldBright)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ---- Continue (glass hero) ----
                if (themeEntries.isNotEmpty)
                  GlassHeroCard(
                    palette: palette,
                    contextLabel: 'Continue',
                    themeTitle: continueTheme,
                    subtitle:
                        '$continueLearned of $continueTotal words · ${continueLevel[0].toUpperCase()}${continueLevel.substring(1)}',
                    progress: continuePercent,
                    onResume: () => context.read<NavProvider>().setIndex(1, theme: continueTheme), // Learn tab
                  ),
                const SizedBox(height: 16),

                // ---- Stat rings ----
                Row(
                  children: [
                    Expanded(
                      child: MiniRingStat(
                        palette: palette,
                        percent: wordBankPercent,
                        centerText: '${(wordBankPercent * 100).round()}%',
                        label: 'Word Bank',
                        ringColor: AppSemanticColors.info,
                      ),
                    ),
                    Expanded(
                      child: MiniRingStat(
                        palette: palette,
                        percent: accuracyPercent,
                        centerText: '${accuracyPercent.isNaN ? 0 : (accuracyPercent * 100).round()}%',
                        label: 'Accuracy',
                        ringColor: AppSemanticColors.success,
                      ),
                    ),
                    Expanded(
                      child: MiniRingStat(
                        palette: palette,
                        percent: streakRingPercent,
                        centerText: '🔥$currentStreak',
                        label: 'Streak',
                        ringColor: palette.goldBright,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text('$learnedCount words mastered overall',
                      style: TextStyle(fontSize: 10.5, color: palette.text2)),
                ),
                const SizedBox(height: 18),

                // ---- Themes rail ----
                Text('THEMES',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                        color: palette.text2)),
                const SizedBox(height: 10),
                FadeEdgeRail(
                  palette: palette,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: themeEntries.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final entry = themeEntries[i];
                      final total = entry.value.length;
                      final learned =
                          entry.value.where((w) => isLearned(w.word)).length;
                      final accent = AppGradients
                          .railAccentPairs[i % AppGradients.railAccentPairs.length];
                      return ThemeRailCard(
                        palette: palette,
                        themeName: entry.key,
                        percent: total == 0 ? 0.0 : learned / total,
                        level: _dominantLevel(entry.value),
                        learned: learned,
                        total: total,
                        accent1: accent[0],
                        accent2: accent[1],
                        onTap: () => context.read<NavProvider>().setIndex(1, theme: entry.key), // Learn tab
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // ---- Quick Access ----
                Text('QUICK ACCESS',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                        color: palette.text2)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    QuickAccessTile(
                      palette: palette,
                      icon: Icons.search,
                      label: 'Detective',
                      onTap: () => context.read<NavProvider>().setIndex(2), // Practice tab
                    ),
                    const SizedBox(width: 9),
                    QuickAccessTile(
                      palette: palette,
                      icon: Icons.public,
                      label: 'Origins',
                      onTap: () => context.read<NavProvider>().setIndex(3), // Origins tab
                    ),
                    const SizedBox(width: 9),
                    QuickAccessTile(
                      palette: palette,
                      icon: Icons.mic_none,
                      label: 'Vault',
                      onTap: () => context.read<NavProvider>().setIndex(4), // Vault tab
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ---- Word of the Day ----
                if (wordOfDay != null)
                  Builder(builder: (context) {
                    final wotd = wordOfDay!; // fresh non-nullable binding for the closure below
                    return WordOfDayCard(
                      palette: palette,
                      word: wotd.word,
                      definition: wotd.definition,
                      onPlayPronunciation: () => TtsService.speak(wotd.word),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}