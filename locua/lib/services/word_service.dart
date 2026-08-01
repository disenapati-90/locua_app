// word_service.dart
// Loads the static word bank (word_bank.json) from assets and converts
// it into a list of Word objects the rest of the app can use.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/word.dart';

class WordService {
  static Future<List<Word>> loadWords() async {
    final String jsonString =
        await rootBundle.loadString('assets/data/word_bank.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((item) => Word.fromJson(item)).toList();
    
  }
  // Generates a Word Detective riddle for a given word, using its own
  // synonyms/antonyms — no separate riddle content needed.
  static String generateRiddle(Word w) {
    final synText = w.synonyms.join(" and ");
    final antText = w.antonyms.join(" and ");
    return "I mean the opposite of $antText. "
        "I am close in meaning to $synText. What word am I?";
  }
}