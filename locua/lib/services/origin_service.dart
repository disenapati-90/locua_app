// origin_service.dart
// Loads origin_words.json from assets into a list of OriginWord objects.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/origin_word.dart';

class OriginService {
  static Future<List<OriginWord>> loadOriginWords() async {
    final String jsonString =
        await rootBundle.loadString('assets/data/origin_words.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((item) => OriginWord.fromJson(item)).toList();
  }
}