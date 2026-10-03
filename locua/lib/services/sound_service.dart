// sound_service.dart
// Plays short UI feedback for the word-check flow and Quick Quiz.
//
// CHANGED this session: all 3 tap-sound packs rebuilt. The old packs were
// single-frequency sine tones with a straight linear fade — inherently
// harsh/artificial-sounding, per user feedback. Rebuilt with layered
// harmonics (2-3 overtones per sound) and natural exponential decay
// instead of a linear fade, which is much closer to how real short sounds
// actually decay. New packs: Keypad Tap (soft mechanical click), Water
// Drop (pitch glide + overtone, bubble-like), Soft Bell (3-harmonic chime
// with a slow natural decay).
//
// NOTE: AppMeta.soundPack stores the pack as a plain string ('chime',
// 'pop', 'deep' previously). Renaming the enum values means any existing
// install with an old saved pack name will safely fall back to the new
// default (keypadTap) via packFromName's orElse — not a crash, just a
// silent reset to default for anyone who'd previously picked a non-default
// pack. Acceptable since this is a cosmetic preference, not data loss.
//
// Correct/incorrect feedback still uses real SPEECH via a dedicated
// FlutterTts instance (unchanged from before) — only the tap-sound
// synthesis changed in this pass.

import 'dart:typed_data';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'storage_service.dart';

enum SoundPack { keypadTap, waterDrop, softBell }

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static final FlutterTts _feedbackTts = FlutterTts();
  static bool _feedbackTtsConfigured = false;

  static SoundPack packFromName(String name) {
    return SoundPack.values.firstWhere(
      (p) => p.name == name,
      orElse: () => SoundPack.keypadTap,
    );
  }

  /// Plays the tap sound — now a layered, naturally-decaying tone rather
  /// than a flat sine blip. Still respects the user's chosen pack.
  static Future<void> playTap() async {
    final meta = StorageService.getOrCreateAppMeta();
    if (!meta.soundEnabled) return;

    final pack = packFromName(meta.soundPack);
    final spec = _specFor(pack);
    final bytes = _generateTone(spec);

    try {
      await _player.play(BytesSource(bytes));
    } catch (_) {
      // Non-critical — never let a playback hiccup interrupt the flow.
    }
  }

  static Future<void> playCorrect() => _speakFeedback('Correct!');
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

  // CHANGED: each pack is now a short list of harmonic partials (frequency
  // + relative volume) rather than a single frequency, plus an optional
  // downward pitch glide for Water Drop.
  static _ToneSpec _specFor(SoundPack pack) {
    switch (pack) {
      case SoundPack.keypadTap:
        // Soft mechanical click: a quiet low thump + a faint high tick,
        // both very short.
        return const _ToneSpec(
          frequencies: [160, 2200],
          amplitudes: [0.38, 0.10],
          durationMs: 45,
        );
      case SoundPack.waterDrop:
        // Bubble-like: fundamental glides down in pitch, plus a quiet
        // overtone at double the (moving) fundamental.
        return const _ToneSpec(
          frequencies: [900, 1800],
          amplitudes: [0.45, 0.12],
          durationMs: 140,
          glideToFrequency: 300,
        );
      case SoundPack.softBell:
        // Small chime: fundamental + 2 quieter overtones, slow decay.
        return const _ToneSpec(
          frequencies: [600, 1200, 1800],
          amplitudes: [0.42, 0.18, 0.08],
          durationMs: 260,
        );
    }
  }

  /// Generates a mono 16-bit PCM WAV in memory from a set of harmonic
  /// partials, a short attack, and a natural EXPONENTIAL decay (rather
  /// than the old straight-line fade) — this alone makes a huge
  /// difference in how "real" a short synthesized sound feels. If
  /// [glideToFrequency] is set on the spec, the FIRST partial's frequency
  /// (and any others, scaled proportionally) slides linearly from its
  /// starting value to that target over the sound's duration.
  static Uint8List _generateTone(_ToneSpec spec) {
    const sampleRate = 44100;
    final totalSamples = (sampleRate * spec.durationMs / 1000).round();
    final attackSamples = (sampleRate * 0.003).round(); // 3ms soft attack
    // Decay constant tuned so the envelope falls to ~5% by the end.
    final decayRate = 3.0 / (spec.durationMs / 1000);

    final samples = Int16List(totalSamples);
    final baseFreq = spec.frequencies.first;

    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = i / totalSamples;

      // Attack: quick linear ramp up. Decay: exponential, natural-sounding.
      double envelope = math.exp(-decayRate * t);
      if (i < attackSamples) {
        envelope *= i / attackSamples;
      }

      // Instantaneous fundamental frequency — glides linearly toward
      // glideToFrequency if the spec asks for it.
      final instantFund = spec.glideToFrequency != null
          ? baseFreq + (spec.glideToFrequency! - baseFreq) * progress
          : baseFreq;

      double sample = 0;
      for (var p = 0; p < spec.frequencies.length; p++) {
        // Each partial keeps its original ratio to the fundamental, so
        // overtones glide along with the fundamental too.
        final ratio = spec.frequencies[p] / baseFreq;
        final freq = instantFund * ratio;
        sample += spec.amplitudes[p] * math.sin(2 * math.pi * freq * t);
      }
      sample *= envelope;

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
  final List<double> frequencies;
  final List<double> amplitudes;
  final int durationMs;
  final double? glideToFrequency;
  const _ToneSpec({
    required this.frequencies,
    required this.amplitudes,
    required this.durationMs,
    this.glideToFrequency,
  });
}