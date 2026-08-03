// recorder_service.dart
// Wraps the `record` package for voice mnemonic recording, and the
// `audioplayers` package for voice mnemonic playback.
//
// IMPORTANT: file-based recording (via path_provider) only works on
// native platforms (Android/iOS), not Flutter Web — browsers don't allow
// direct filesystem access. On web, recording is skipped entirely, so
// there is never a file to play back either. Playback logic below is
// guarded the same way — it will only be truly testable once we build
// the real Android APK.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class RecorderService {
  static final AudioRecorder _recorder = AudioRecorder();
  static final AudioPlayer _player = AudioPlayer();

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

  // Plays back a saved voice mnemonic from its file path.
  // Returns false if playback isn't possible (e.g. web preview, or
  // the file no longer exists) so the UI can show a clear message.
  static Future<bool> playRecording(String path) async {
    if (kIsWeb) return false;
    try {
      await _player.play(DeviceFileSource(path));
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> stopPlayback() async {
    if (kIsWeb) return;
    await _player.stop();
  }

  // Lets the UI react when playback finishes naturally (e.g. to reset
  // a play/stop icon back to "play").
  static Stream<void> get onPlaybackComplete => _player.onPlayerComplete;
}