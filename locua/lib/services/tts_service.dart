// tts_service.dart
// Wraps flutter_tts so any screen can request pronunciation without
// dealing with the plugin's setup directly. Shared by both the Origins
// screen (foreign-origin words) and the Learn screen (core word bank).

import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();

  // Speaks the given text using the specified locale (e.g. "fa-IR").
  // Defaults to US English if no locale is given — used for core words.
  static Future<void> speak(String text, {String locale = 'en-US'}) async {
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(0.45); // slightly slower for clearer learning
    await _tts.speak(text);
  }
}