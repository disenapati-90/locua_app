// practice_screen.dart
// Real Word Detective screen: pulls only words that are DUE for review
// today (per SRS scheduling in ProgressProvider), shows a riddle built
// from synonyms/antonyms, and lets the user answer via multiple choice.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../services/word_service.dart';
import '../providers/progress_provider.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  List<Word> _dueWords = [];
  List<Word> _allWords = [];
  int _currentIndex = 0;
  List<String> _choices = [];
  String? _selectedChoice;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final all = await WordService.loadWords();
    final progressProvider = context.read<ProgressProvider>();
    final due = progressProvider.getDueWords(all);
    setState(() {
      _allWords = all;
      _dueWords = due;
      if (_dueWords.isNotEmpty) _generateChoices();
    });
  }

  // Builds 3 answer options: the correct word + 2 random distractors
  // from the rest of the word bank.
  void _generateChoices() {
    final correct = _dueWords[_currentIndex].word;
    final others = _allWords
        .map((w) => w.word)
        .where((w) => w != correct)
        .toList()
      ..shuffle();
    final distractors = others.take(2).toList();
    _choices = [correct, ...distractors]..shuffle(Random());
    _selectedChoice = null;
    _answered = false;
  }

  void _submitAnswer(String choice) {
    final correctWord = _dueWords[_currentIndex].word;
    final isCorrect = choice == correctWord;
    final progressProvider = context.read<ProgressProvider>();

    if (isCorrect) {
      progressProvider.markCorrect(correctWord);
    } else {
      progressProvider.markIncorrect(correctWord);
    }

    setState(() {
      _selectedChoice = choice;
      _answered = true;
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentIndex++;
      if (_currentIndex < _dueWords.length) {
        _generateChoices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dueWords.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "No words due for review right now. Come back later, or learn new words in the Learn tab!",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_currentIndex >= _dueWords.length) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "Nice work! You've reviewed all ${_dueWords.length} due words for now.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
    }

    final currentWord = _dueWords[_currentIndex];
    final riddle = WordService.generateRiddle(currentWord);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${_currentIndex + 1} of ${_dueWords.length}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(riddle, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
          const SizedBox(height: 16),
          // Answer choices
          ..._choices.map((choice) {
            final isSelected = _selectedChoice == choice;
            final isCorrectChoice = choice == currentWord.word;

            // Color logic: after answering, show green for correct,
            // red for a wrong pick — otherwise neutral.
            Color? tileColor;
            if (_answered) {
              if (isCorrectChoice) {
                tileColor = Colors.green.withValues(alpha: 0.3);
              } else if (isSelected) {
                tileColor = Colors.red.withValues(alpha: 0.3);
              }
            }

            return Card(
              color: tileColor,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(choice),
                onTap: _answered ? null : () => _submitAnswer(choice),
              ),
            );
          }),
          const Spacer(),
          if (_answered)
            ElevatedButton(
              onPressed: _nextQuestion,
              child: const Text('Next'),
            ),
        ],
      ),
    );
  }
}