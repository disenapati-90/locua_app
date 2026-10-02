// quick_quiz_screen.dart
// A 10-question quick self-assessment, launched from Home.
//
// CHANGED: removed the explicit SoundService.playTap() call in
// _selectChoice — the global TapFeedbackWrapper (see main.dart) now
// handles tap sound/haptic app-wide, so calling it here too would
// double-fire on every answer choice.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/word.dart';
import '../services/word_service.dart';
import '../services/sound_service.dart';

class QuickQuizScreen extends StatefulWidget {
  const QuickQuizScreen({super.key});

  @override
  State<QuickQuizScreen> createState() => _QuickQuizScreenState();
}

class _QuizQuestion {
  final Word word;
  final List<String> choices;
  const _QuizQuestion(this.word, this.choices);
}

class _QuickQuizScreenState extends State<QuickQuizScreen> {
  static const int _questionCount = 10;

  List<_QuizQuestion>? _questions;
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedChoice;
  bool _answered = false;
  bool _finished = false;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 1400));
    _loadQuestions();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final allWords = await WordService.loadWords();
    if (allWords.length < 3) {
      setState(() => _questions = []);
      return;
    }

    final shuffled = List<Word>.from(allWords)..shuffle();
    final picked = shuffled.take(math.min(_questionCount, allWords.length)).toList();

    final questions = picked.map((w) {
      final distractors = allWords
          .where((x) => x.word != w.word)
          .map((x) => x.definition)
          .toList()
        ..shuffle();
      final choices = [w.definition, ...distractors.take(2)]..shuffle();
      return _QuizQuestion(w, choices);
    }).toList();

    setState(() => _questions = questions);
  }

  void _selectChoice(String choice) {
    if (_answered) return;
    // CHANGED: removed SoundService.playTap() here — the global
    // TapFeedbackWrapper now handles the tap sound for every tap.
    final correct = choice == _questions![_currentIndex].word.definition;
    setState(() {
      _selectedChoice = choice;
      _answered = true;
      if (correct) _score++;
    });
    if (correct) {
      SoundService.playCorrect();
    } else {
      SoundService.playIncorrect();
    }
  }

  void _next() {
    if (_currentIndex + 1 >= _questions!.length) {
      setState(() => _finished = true);
      if (_score >= 8) {
        SoundService.playCorrect();
        _confettiController.play();
      }
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedChoice = null;
      _answered = false;
    });
  }

  String get _levelLabel {
    if (_score >= 8) return 'Expert';
    if (_score >= 5) return 'Pro';
    return 'Beginner';
  }

  String get _levelBlurb {
    if (_score >= 8) return "Impressive range — you're operating at an expert vocabulary level.";
    if (_score >= 5) return "Solid grasp — you're comfortably at a pro level.";
    return "Good start — plenty of room to grow, keep at it in Learn and Practice.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Vocab Check')),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          _buildBody(context),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 40,
            maxBlastForce: 18,
            minBlastForce: 8,
            gravity: 0.2,
            colors: const [
              Colors.amber,
              Colors.greenAccent,
              Colors.tealAccent,
              Colors.white,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_questions == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_questions!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Not enough words available for a quiz right now.'),
        ),
      );
    }
    if (_finished) {
      return _buildResults(context);
    }
    return _buildQuestion(context);
  }

  Widget _buildQuestion(BuildContext context) {
    final q = _questions![_currentIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions!.length,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text('Question ${_currentIndex + 1} of ${_questions!.length}',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Text('What does this mean?',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(q.word.word.toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          ...q.choices.map((choice) {
            final isCorrectChoice = choice == q.word.definition;
            Color? tileColor;
            if (_answered) {
              if (isCorrectChoice) {
                tileColor = Colors.green.withValues(alpha: 0.18);
              } else if (choice == _selectedChoice) {
                tileColor = Colors.redAccent.withValues(alpha: 0.18);
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _answered ? null : () => _selectChoice(choice),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: tileColor,
                    padding: const EdgeInsets.all(14),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(choice, textAlign: TextAlign.left),
                ),
              ),
            );
          }),
          if (_answered) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                child: Text(_currentIndex + 1 >= _questions!.length
                    ? 'See my result'
                    : 'Next question'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_score / ${_questions!.length}',
                style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(_levelLabel,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.secondary)),
            const SizedBox(height: 12),
            Text(_levelBlurb,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}