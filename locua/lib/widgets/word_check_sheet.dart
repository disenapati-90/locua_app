// word_check_sheet.dart
// Session 7 Phase 4: the "word check" flip-card flow shown when tapping a
// word in Learn's reader or Origins' word list.
//
// CHANGED: removed the explicit SoundService.playTap() call in
// _selectChoice — the new app-wide TapFeedbackWrapper (see main.dart)
// now handles tap sound/haptic globally, so calling it here too would
// double-fire the sound on every answer choice.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../services/tts_service.dart';
import '../services/sound_service.dart';

class WordCheckData {
  final String word;
  final String correctMeaning;
  final List<String> distractorMeanings;
  final List<String>? synonyms;
  final List<String>? antonyms;
  final String? funFact;
  final String pronunciationText;
  final String? pronunciationLocale;

  const WordCheckData({
    required this.word,
    required this.correctMeaning,
    required this.distractorMeanings,
    this.synonyms,
    this.antonyms,
    this.funFact,
    required this.pronunciationText,
    this.pronunciationLocale,
  });
}

enum _Stage { question, result, detail }

Future<void> showWordCheckSheet({
  required BuildContext context,
  required WordCheckData data,
  VoidCallback? onComplete,
  bool startAtDetail = false,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _WordCheckSheetBody(
      data: data,
      startAtDetail: startAtDetail,
    ),
  );
  onComplete?.call();
}

class _WordCheckSheetBody extends StatefulWidget {
  final WordCheckData data;
  final bool startAtDetail;
  const _WordCheckSheetBody({required this.data, required this.startAtDetail});

  @override
  State<_WordCheckSheetBody> createState() => _WordCheckSheetBodyState();
}

class _WordCheckSheetBodyState extends State<_WordCheckSheetBody> {
  late _Stage _stage;
  String? _selectedChoice;
  late final List<String> _choices;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _stage = widget.startAtDetail ? _Stage.detail : _Stage.question;
    _choices = [widget.data.correctMeaning, ...widget.data.distractorMeanings]
      ..shuffle();
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 900));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  bool get _isCorrect => _selectedChoice == widget.data.correctMeaning;

  void _selectChoice(String choice) {
    // CHANGED: removed SoundService.playTap() here — the global
    // TapFeedbackWrapper now handles the tap sound for every tap in the
    // app, including this one.
    setState(() {
      _selectedChoice = choice;
      _stage = _Stage.result;
    });
    if (choice == widget.data.correctMeaning) {
      SoundService.playCorrect();
      _confettiController.play();
    } else {
      SoundService.playIncorrect();
    }
  }

  void _showDetail() => setState(() => _stage = _Stage.detail);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        top: false,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    ...previousChildren.map(
                      (child) => Positioned.fill(child: child),
                    ),
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  child: child,
                  builder: (context, child) {
                    final angle = (1 - animation.value) * math.pi / 2;
                    final showFront = animation.value > 0.5;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: Opacity(
                        opacity: showFront ? 1.0 : 0.0,
                        child: child,
                      ),
                    );
                  },
                );
              },
              child: switch (_stage) {
                _Stage.question => _buildQuestion(context),
                _Stage.result => _buildResult(context),
                _Stage.detail => _buildDetail(context),
              },
            ),
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 24,
              maxBlastForce: 12,
              minBlastForce: 6,
              gravity: 0.25,
              colors: const [
                Colors.amber,
                Colors.greenAccent,
                Colors.tealAccent,
                Colors.white,
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      key: const ValueKey('question'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.35)),
            ),
            child: Text(
              'Self-check · not graded — head to Practice for spaced-repetition scoring',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 18),
          Text('What does this mean?',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(widget.data.word.toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          ..._choices.map((choice) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _selectChoice(choice),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(choice, textAlign: TextAlign.left),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final color = _isCorrect ? Colors.green : Colors.redAccent;
    return Padding(
      key: const ValueKey('result'),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_isCorrect ? Icons.check_circle : Icons.cancel, color: color, size: 48),
          const SizedBox(height: 12),
          Text(
            _isCorrect ? 'Correct!' : 'Not quite',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
          ),
          const SizedBox(height: 6),
          Text(widget.data.word.toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _showDetail,
            icon: const Icon(Icons.menu_book),
            label: const Text('Know more'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context) {
    final d = widget.data;
    return Padding(
      key: const ValueKey('detail'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.word.toUpperCase(), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(d.correctMeaning, style: Theme.of(context).textTheme.bodyLarge),
          if (d.synonyms != null && d.synonyms!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Synonyms: ${d.synonyms!.join(", ")}',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (d.antonyms != null && d.antonyms!.isNotEmpty)
            Text('Antonyms: ${d.antonyms!.join(", ")}',
                style: Theme.of(context).textTheme.bodyMedium),
          if (d.funFact != null) ...[
            const SizedBox(height: 10),
            Text(d.funFact!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () =>
                TtsService.speak(d.pronunciationText, locale: d.pronunciationLocale),
            icon: const Icon(Icons.volume_up, size: 18),
            label: const Text('Hear pronunciation'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}