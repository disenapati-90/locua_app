// tts_service.dart
// Wraps flutter_tts so any screen can request pronunciation without
// dealing with the plugin's setup directly. Shared by Origins, Learn,
// and Home.
//
// Session 7 Phase 3: now reads/writes user-configurable voice settings
// (sound on/off, accent locale, speech rate), persisted via AppMeta in
// Hive so they survive app restarts. Settings are lazy-loaded on first
// use (ensureInit()) rather than requiring an explicit call from
// main.dart — this keeps the change contained to this file.
//
// Accent locale ONLY applies when the caller doesn't pass an explicit
// locale. Origins word pronunciation always passes its own
// pronunciationLocale (the word's actual origin language), which
// correctly overrides the accent setting — you wouldn't want a Swahili
// word spoken with a forced "British" accent override, for example.

import 'package:flutter_tts/flutter_tts.dart';
import 'storage_service.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();

  static bool _enabled = true;
  static String _accentLocale = 'en-US';
  static double _rate = 0.45;
  static bool _initialized = false;

  static bool get enabled => _enabled;
  static String get accentLocale => _accentLocale;
  static double get rate => _rate;

  // Display labels for the accent picker in Settings.
  static const Map<String, String> accentOptions = {
    'en-US': 'American',
    'en-GB': 'British',
    'en-IN': 'Indian',
  };

  /// Loads persisted settings from Hive into memory. Safe to call
  /// multiple times — only does real work once. Called automatically by
  /// speak(), and should also be called from Settings screen's initState
  /// so the UI reflects the saved values immediately.
  static void ensureInit() {
    if (_initialized) return;
    final meta = StorageService.getOrCreateAppMeta();
    _enabled = meta.ttsEnabled;
    _accentLocale = meta.ttsAccentLocale;
    _rate = meta.ttsRate;
    _initialized = true;
  }

  static Future<void> setEnabled(bool value) async {
    ensureInit();
    _enabled = value;
    final meta = StorageService.getOrCreateAppMeta();
    meta.ttsEnabled = value;
    await meta.save();
  }

  static Future<void> setAccentLocale(String locale) async {
    ensureInit();
    _accentLocale = locale;
    final meta = StorageService.getOrCreateAppMeta();
    meta.ttsAccentLocale = locale;
    await meta.save();
  }

  static Future<void> setRate(double value) async {
    ensureInit();
    _rate = value;
    final meta = StorageService.getOrCreateAppMeta();
    meta.ttsRate = value;
    await meta.save();
  }

  /// Speaks [text]. If [locale] is given (e.g. an Origins word's own
  /// pronunciation locale), that locale is used as-is instead of the
  /// accent setting. Respects the global sound on/off toggle and
  /// speech-rate setting.
  static Future<void> speak(String text, {String? locale}) async {
    ensureInit();
    if (!_enabled) return;
    await _tts.setLanguage(locale ?? _accentLocale);
    await _tts.setSpeechRate(_rate);
    await _tts.speak(text);
  }
}