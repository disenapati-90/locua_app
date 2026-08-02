// recorder_service.dart
// Wraps the `record` package for voice mnemonic recording/playback.
//
// IMPORTANT: file-based recording (via path_provider) only works on
// native platforms (Android/iOS), not Flutter Web — browsers don't allow
// direct filesystem access. On web, we skip the file path step so the
// UI can show a clear message instead of failing silently. This will
// work correctly once we build the real Android APK.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class RecorderService {
  static final AudioRecorder _recorder = AudioRecorder();

  static Future<String?> startRecording(String word) async {
    if (kIsWeb) {
      return null; // signals "not supported in this preview" to the UI
    }
    if (await _recorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/mnemonic_$word.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      return path;
    }
    return null;
  }

  static Future<String?> stopRecording() async {
    if (kIsWeb) return null;
    return await _recorder.stop();
  }
}