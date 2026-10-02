// home_screen.dart
// Reimagined Home: greeting -> continue learning -> vocab-level check ->
// origin spotlight -> stats glance -> explore origins -> word of the day
// -> explore themes.
//
// CHANGED this session: complete rebuild per user-approved wireframe.
// Removed the duplicate branding row (AppBar already shows it). "Continue
// learning" and both explore rails now deep-link correctly via
// NavProvider's pendingTheme/pendingLanguageGroup — safe now that
// learn_screen.dart and origins_screen.dart actually consume them.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:circle_flags/circle_flags.dart';
import '../models/word.dart';
import '../models/origin_word.dart';
import '../services/word_service.dart';
import '../services/origin_service.dart';
import '../services/storage_service.dart';
import '../providers/progress_provider.dart';
import '../providers/nav_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_design.dart';
import '../widgets/home/home_widgets.dart';
import '../services/tts_service.dart';
import '../utils/origin_grouping.dart';
import 'quick_quiz_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  int _dayOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    return date.difference(startOfYear).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();
    final themeOption = context.watch<ThemeProvider>().current;
    final palette = AppPalette.of(themeOption);
    final userName = StorageService.getOrCreateAppMeta().userName;

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([WordService.loadWords(), OriginService.loadOriginWords()]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allWords = snapshot.data![0] as List<Word>;
        final allOriginWords = snapshot.data![1] as List<OriginWord>;
        final totalWords = allWords.length;

        final progressByWord = {for (final p in progressProvider.allProgress) p.word: p};
        bool isLearned(String word) => progressByWord[word]?.learned ?? false;

        final learnedCount = allWords.where((w) => isLearned(w.word)).length;
        final wordBankPercent = totalWords == 0 ? 0.0 : learnedCount / totalWords;
        final accuracyPercent = progressProvider.overallAccuracy / 100;
        final currentStreak = progressProvider.currentStreak;

        // Find the theme most worth resuming: first one started but not
        // finished, falling back to the first theme overall.
        final themeMap = <String, List<Word>>{};
        for (final w in allWords) {
          themeMap.putIfAbsent(w.theme, () => []).add(w);
        }
        final themeEntries = themeMap.entries.toList();
        String continueTheme = themeEntries.isNotEmpty ? themeEntries.first.key : '';
        for (final entry in themeEntries) {
          final total = entry.value.length;
          final learned = entry.value.where((w) => isLearned(w.word)).length;
          if (learned > 0 && learned < total) {
            continueTheme = entry.key;
            break;
          }
        }

        // Word of the Day — stable for the whole calendar day.
        Word? wordOfDay;
        if (allWords.isNotEmpty) {
          wordOfDay = allWords[_dayOfYear(DateTime.now()) % allWords.length];
        }

        // Origin spotlight — same stable daily-pick pattern as Word of the Day.
        OriginWord? spotlightOrigin;
        if (allOriginWords.isNotEmpty) {
          spotlightOrigin = allOriginWords[_dayOfYear(DateTime.now()) % allOriginWords.length];
        }

        // Origin language groups for the Explore Origins rail — same
        // grouping logic Origins itself uses, imported from the shared util.
        final originGroupMap = <String, List<OriginWord>>{};
        for (final w in allOriginWords) {
          originGroupMap.putIfAbsent(displayGroupFor(w.originLanguage), () => []).add(w);
        }
        final originGroups = originGroupMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Greeting
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName.isEmpty ? 'Welcome' : 'Hello, $userName',
                          style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 19, fontWeight: FontWeight.w700, color: palette.text),
                        ),
                        const SizedBox(height: 2),
                        Text('🔥 $currentStreak day streak — keep it going',
                            style: TextStyle(fontSize: 12, color: palette.text2)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.read<NavProvider>().setIndex(5),
                      child: Icon(Icons.settings_outlined, color: palette.text2, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Continue Learning — generic progress copy, but the
                // button now correctly deep-links to the actual
                // in-progress theme, since Learn's consumption of
                // pendingTheme is fixed this session.
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppGradients.glassHero(palette),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR VOCABULARY JOURNEY',
                          style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: palette.goldBright)),
                      const SizedBox(height: 4),
                      Text('$learnedCount of $totalWords words learned', style: TextStyle(fontSize: 12, color: palette.text2)),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppMetrics.radiusPill),
                        child: LinearProgressIndicator(
                          value: wordBankPercent.clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: Colors.black.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation(palette.goldBright),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: palette.gold, foregroundColor: palette.bg),
                          onPressed: themeEntries.isEmpty
                              ? null
                              : () => context.read<NavProvider>().setIndex(1, theme: continueTheme),
                          child: const Text('Continue learning', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Check your vocab level — expanded, same visual weight
                // as Continue Learning.
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [palette.surfaceAlt, palette.surface],
                    ),
                    borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
                    border: Border.all(color: palette.text2.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: palette.goldBright.withValues(alpha: 0.15)),
                            child: Icon(Icons.psychology_outlined, color: palette.goldBright, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Check your vocab level', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.text)),
                                Text('10 questions · 2 minutes', style: TextStyle(fontSize: 11, color: palette.text2)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: palette.goldBright, foregroundColor: palette.bg),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickQuizScreen())),
                          child: const Text('Start quick check', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Origin spotlight — deep-links to that word's actual
                // language group in Origins.
                if (spotlightOrigin != null)
                  GestureDetector(
                    onTap: () => context.read<NavProvider>().setIndex(
                          3,
                          languageGroup: displayGroupFor(spotlightOrigin!.originLanguage),
                        ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppSemanticColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppMetrics.radiusMd),
                        border: Border.all(color: AppSemanticColors.info.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 30, height: 30,
                              child: flagCodeFor(displayGroupFor(spotlightOrigin.originLanguage)) != null
                                  ? CircleFlag(flagCodeFor(displayGroupFor(spotlightOrigin.originLanguage))!)
                                  : Container(color: palette.surfaceAlt, child: const Icon(Icons.public, size: 14)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ORIGINS · ${spotlightOrigin.originLanguage.toUpperCase()}',
                                    style: TextStyle(fontSize: 9, letterSpacing: 0.5, color: AppSemanticColors.info)),
                                Text(spotlightOrigin.word,
                                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, fontFamily: 'PlayfairDisplay', color: palette.text)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: palette.text2, size: 18),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 14),

                // 5. Stats glance — one condensed line, not three rings.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(AppMetrics.radiusMd)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statChip(palette, '$learnedCount', 'mastered'),
                      _statDivider(),
                      _statChip(palette, '${accuracyPercent.isNaN ? 0 : (accuracyPercent * 100).round()}%', 'accuracy'),
                      _statDivider(),
                      _statChip(palette, '$currentStreak', 'day streak'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 6. Explore Origins — deep-links each tile to its
                // specific language group.
                Text('EXPLORE ORIGINS', style: TextStyle(fontSize: 11, letterSpacing: 0.8, fontWeight: FontWeight.w600, color: palette.text2)),
                const SizedBox(height: 10),
                FadeEdgeRail(
                  palette: palette,
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: originGroups.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final entry = originGroups[i];
                      final flagCode = flagCodeFor(entry.key);
                      return GestureDetector(
                        onTap: () => context.read<NavProvider>().setIndex(3, languageGroup: entry.key),
                        child: Container(
                          width: 70,
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(color: palette.surfaceAlt, borderRadius: BorderRadius.circular(AppMetrics.radiusMd)),
                          child: Column(
                            children: [
                              ClipOval(
                                child: SizedBox(
                                  width: 26, height: 26,
                                  child: flagCode != null
                                      ? CircleFlag(flagCode)
                                      : Container(color: palette.surface, child: const Icon(Icons.public, size: 12)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(entry.key, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 9.5, color: palette.text)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // 7. Word of the Day
                if (wordOfDay != null)
                  Builder(builder: (context) {
                    final wotd = wordOfDay!;
                    return WordOfDayCard(
                      palette: palette,
                      word: wotd.word,
                      definition: wotd.definition,
                      onPlayPronunciation: () => TtsService.speak(wotd.word),
                    );
                  }),
                const SizedBox(height: 18),

                // 8. Explore Themes — deep-links each tile to its
                // specific theme in Learn.
                Text('EXPLORE THEMES', style: TextStyle(fontSize: 11, letterSpacing: 0.8, fontWeight: FontWeight.w600, color: palette.text2)),
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
                      final learned = entry.value.where((w) => isLearned(w.word)).length;
                      final accent = AppGradients.railAccentPairs[i % AppGradients.railAccentPairs.length];
                      return ThemeRailCard(
                        palette: palette,
                        themeName: entry.key,
                        percent: total == 0 ? 0.0 : learned / total,
                        level: 'medium',
                        learned: learned,
                        total: total,
                        accent1: accent[0],
                        accent2: accent[1],
                        onTap: () => context.read<NavProvider>().setIndex(1, theme: entry.key),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statChip(AppPalette palette, String value, String label) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 11.5, color: palette.text2),
        children: [
          TextSpan(text: '$value ', style: TextStyle(color: palette.text, fontWeight: FontWeight.w700)),
          TextSpan(text: label),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(width: 1, height: 12, color: Colors.white.withValues(alpha: 0.15));
}