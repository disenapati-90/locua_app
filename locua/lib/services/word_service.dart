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
}