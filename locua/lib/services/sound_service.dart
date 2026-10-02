// sound_service.dart
// Plays short UI feedback for the word-check flow and Quick Quiz.
//
// CHANGED: correct/incorrect feedback now uses actual SPEECH ("Correct!"
// / "Not quite") via a dedicated FlutterTts instance, instead of a
// synthesized tone — testing showed the tones read as unclear/odd for
// pass/fail feedback specifically. The TAP sound (choosing an answer)
// still uses the original synthesized-tone approach across all 3 sound
// packs, since that one's just a tactile click and worked fine.
//
// This uses its OWN FlutterTts instance, separate from tts_service.dart's
// instance — deliberately does NOT use the user's chosen word-pronunciation
// accent/rate from Settings, since "Correct!"/"Not quite" is app feedback,
// not word pronunciation, and should sound consistent regardless of which
// accent the user picked for hearing vocabulary words.
//
// Gated by the same "Sound Effects" toggle as the tap sound (AppMeta.
// soundEnabled) — NOT the separate Voice/TTS toggle, since this is UI
// feedback rather than word-pronunciation speech.

import 'dart:typed_data';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'storage_service.dart';

enum SoundPack { chime, pop, deep }

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static final FlutterTts _feedbackTts = FlutterTts();
  static bool _feedbackTtsConfigured = false;

  static SoundPack packFromName(String name) {
    return SoundPack.values.firstWhere(
      (p) => p.name == name,
      orElse: () => SoundPack.chime,
    );
  }

  /// Plays the tap sound — a short synthesized tone, still respects the
  /// user's chosen sound pack.
  static Future<void> playTap() async {
    final meta = StorageService.getOrCreateAppMeta();
    if (!meta.soundEnabled) return;

    final pack = packFromName(meta.soundPack);
    final spec = _tapSpecFor(pack);
    final bytes = _generateTone(frequency: spec.frequency, durationMs: spec.durationMs);

    try {
      await _player.play(BytesSource(bytes));
    } catch (_) {
      // Non-critical — never let a playback hiccup interrupt the flow.
    }
  }

  /// Speaks "Correct!" aloud. Call this alongside your existing confetti
  /// trigger — this only handles the audio side.
  static Future<void> playCorrect() => _speakFeedback('Correct!');

  /// Speaks "Not quite" aloud.
  static Future<void> playIncorrect() => _speakFeedback('Not quite');

  static Future<void> _speakFeedback(String phrase) async {
    final meta = StorageService.getOrCreateAppMeta();
    if (!meta.soundEnabled) return;

    try {
      if (!_feedbackTtsConfigured) {
        await _feedbackTts.setLanguage('en-US');
        await _feedbackTts.setSpeechRate(0.5);
        await _feedbackTts.setPitch(1.0);
        _feedbackTtsConfigured = true;
      }
      await _feedbackTts.speak(phrase);
    } catch (_) {
      // Non-critical — never let a TTS hiccup interrupt the quiz flow.
    }
  }

  static _ToneSpec _tapSpecFor(SoundPack pack) {
    return switch (pack) {
      SoundPack.chime => const _ToneSpec(880, 70),
      SoundPack.pop => const _ToneSpec(660, 40),
      SoundPack.deep => const _ToneSpec(330, 90),
    };
  }

  /// Generates a mono 16-bit PCM WAV tone in memory: a pure sine wave at
  /// [frequency] Hz for [durationMs], with a short linear fade-in/out to
  /// avoid audible clicks at the start/end of playback.
  static Uint8List _generateTone({
    required double frequency,
    required int durationMs,
  }) {
    const sampleRate = 44100;
    final totalSamples = (sampleRate * durationMs / 1000).round();
    final fadeSamples = (sampleRate * 0.01).round(); // 10ms fade

    final samples = Int16List(totalSamples);
    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      var amplitude = 0.5;
      if (i < fadeSamples) {
        amplitude *= i / fadeSamples;
      } else if (i > totalSamples - fadeSamples) {
        amplitude *= (totalSamples - i) / fadeSamples;
      }
      final sample = amplitude * math.sin(2 * math.pi * frequency * t);
      samples[i] = (sample * 32767).round().clamp(-32768, 32767);
    }

    return _wavBytes(samples, sampleRate);
  }

  static Uint8List _wavBytes(Int16List samples, int sampleRate) {
    final dataLength = samples.lengthInBytes;
    final header = ByteData(44);

    void writeString(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        header.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    header.setUint32(4, 36 + dataLength, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    writeString(36, 'data');
    header.setUint32(40, dataLength, Endian.little);

    final bytes = Uint8List(44 + dataLength);
    bytes.setRange(0, 44, header.buffer.asUint8List());
    bytes.setRange(44, 44 + dataLength, samples.buffer.asUint8List());
    return bytes;
  }
}

class _ToneSpec {
  final double frequency;
  final int durationMs;
  const _ToneSpec(this.frequency, this.durationMs);
}