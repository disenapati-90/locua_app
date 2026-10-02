// origins_screen.dart
// 2-level flow: L1 language-family tile grid -> L2 word-card list.
//
// CHANGED this session: now actually consumes NavProvider's
// pendingLanguageGroup/languageGroupRequestId (same mechanism/bug as
// Learn — this was also never wired). Grouping/flag logic moved to
// utils/origin_grouping.dart so home_screen.dart can share it.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:circle_flags/circle_flags.dart';
import '../models/origin_word.dart';
import '../services/origin_service.dart';
import '../providers/nav_provider.dart';
import '../widgets/back_handler_registry.dart';
import '../widgets/word_check_sheet.dart';
import '../utils/origin_grouping.dart';

class OriginsScreen extends StatefulWidget {
  const OriginsScreen({super.key});
  @override
  State<OriginsScreen> createState() => _OriginsScreenState();
}

class _LanguageGroup {
  final String displayName;
  final List<OriginWord> words;
  _LanguageGroup({required this.displayName, required this.words});
}

enum _OriginsNav { languages, words }

class _OriginsScreenState extends State<OriginsScreen> {
  static const int _tabIndex = 3;

  final Set<String> _learnedWords = {};
  _OriginsNav _nav = _OriginsNav.languages;
  _LanguageGroup? _activeGroup;
  List<OriginWord> _allWordsCache = [];

  // ADDED: cached future (was recreated every build before).
  late Future<List<OriginWord>> _wordsFuture;

  // ADDED: tracks the last-handled language-group deep-link request.
  int _lastHandledLanguageRequestId = -1;

  @override
  void initState() {
    super.initState();
    BackHandlerRegistry.register(_tabIndex, _stepBack);
    _wordsFuture = OriginService.loadOriginWords();
  }

  @override
  void dispose() {
    BackHandlerRegistry.unregister(_tabIndex);
    super.dispose();
  }

  List<_LanguageGroup> _buildGroups(List<OriginWord> allWords) {
    final byGroup = <String, List<OriginWord>>{};
    for (final w in allWords) {
      final group = displayGroupFor(w.originLanguage);
      byGroup.putIfAbsent(group, () => []).add(w);
    }
    final groups = byGroup.entries.map((e) => _LanguageGroup(displayName: e.key, words: e.value)).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return groups;
  }

  void _openGroup(_LanguageGroup g) {
    setState(() {
      _activeGroup = g;
      _nav = _OriginsNav.words;
    });
  }

  bool _stepBack() {
    if (_nav == _OriginsNav.words) {
      setState(() {
        _nav = _OriginsNav.languages;
        _activeGroup = null;
      });
      return true;
    }
    return false;
  }

  List<String> _pickDistractors(OriginWord current) {
    final others = _allWordsCache.where((w) => w.word != current.word).map((w) => w.meaning).toList()..shuffle();
    return others.take(2).toList();
  }

  void _onCheckMeaning(OriginWord w) {
    final data = WordCheckData(
      word: w.word,
      correctMeaning: w.meaning,
      distractorMeanings: _pickDistractors(w),
      funFact: w.funFact,
      pronunciationText: w.originSpelling,
      pronunciationLocale: w.pronunciationLocale,
    );
    showWordCheckSheet(context: context, data: data);
  }

  @override
  Widget build(BuildContext context) {
    // ADDED: watch NavProvider for incoming language-group deep-links.
    final navProvider = context.watch<NavProvider>();

    return FutureBuilder<List<OriginWord>>(
      future: _wordsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        _allWordsCache = snapshot.data!;
        final groups = _buildGroups(snapshot.data!);

        // ADDED: consume Home's pending language-group deep-link, same
        // pattern as Learn's pendingTheme consumption.
        if (navProvider.pendingLanguageGroup != null &&
            navProvider.languageGroupRequestId != _lastHandledLanguageRequestId) {
          _lastHandledLanguageRequestId = navProvider.languageGroupRequestId;
          final targetName = navProvider.pendingLanguageGroup;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final match = groups.where((g) => g.displayName == targetName);
            if (match.isNotEmpty) _openGroup(match.first);
            navProvider.clearPendingLanguageGroup();
          });
        }

        return Column(
          children: [
            _buildHeader(context),
            Expanded(child: _nav == _OriginsNav.languages ? _buildLanguageGrid(context, groups) : _buildWordList(context)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final title = _nav == _OriginsNav.languages ? 'Origins' : (_activeGroup?.displayName ?? '');
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          if (_nav != _OriginsNav.languages)
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _stepBack())
          else
            const SizedBox(width: 48),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        ],
      ),
    );
  }

  Widget _buildLanguageGrid(BuildContext context, List<_LanguageGroup> groups) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.95),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final g = groups[i];
        final learned = g.words.where((w) => _learnedWords.contains(w.word)).length;
        return _LanguageTile(
          group: g,
          learnedCount: learned,
          accentColor: originTileAccentColors[i % originTileAccentColors.length],
          onTap: () => _openGroup(g),
        );
      },
    );
  }

  Widget _buildWordList(BuildContext context) {
    final words = _activeGroup!.words;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final w = words[index];
        final isLearned = _learnedWords.contains(w.word);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${w.originLanguage} · ${w.originSpelling}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: Text(w.word, style: Theme.of(context).textTheme.titleLarge)),
                  _DifficultyBadge(level: w.level),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  OutlinedButton.icon(onPressed: () => _onCheckMeaning(w), icon: const Icon(Icons.help_outline, size: 18), label: const Text('Check meaning')),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(isLearned ? 'Learned ✓' : 'Mark as learned'),
                    selected: isLearned,
                    onSelected: (_) {
                      setState(() {
                        if (isLearned) {
                          _learnedWords.remove(w.word);
                        } else {
                          _learnedWords.add(w.word);
                        }
                      });
                    },
                  ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final _LanguageGroup group;
  final int learnedCount;
  final Color accentColor;
  final VoidCallback onTap;
  const _LanguageTile({required this.group, required this.learnedCount, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final total = group.words.length;
    final percent = total == 0 ? 0.0 : learnedCount / total;
    final flagCode = flagCodeFor(group.displayName);
    final percentLabel = '${(percent * 100).round()}%';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44, padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accentColor, width: 2.5)),
                child: ClipOval(
                  child: flagCode != null
                      ? CircleFlag(flagCode)
                      : Container(color: Theme.of(context).colorScheme.secondaryContainer, child: const Icon(Icons.public, size: 18)),
                ),
              ),
              const SizedBox(height: 10),
              Text(group.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('$learnedCount/$total ${total == 1 ? "word" : "words"} · $percentLabel', style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(value: percent.clamp(0.0, 1.0), minHeight: 5, valueColor: AlwaysStoppedAnimation(accentColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String level;
  const _DifficultyBadge({required this.level});

  Color _colorFor(BuildContext context) {
    switch (level) {
      case 'hard':
        return Colors.redAccent;
      case 'medium':
        return Colors.amber;
      default:
        return Colors.greenAccent.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(context);
    final label = level.isEmpty ? '' : level[0].toUpperCase() + level.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}