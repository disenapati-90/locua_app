// sound_service.dart
// Plays short UI feedback for the word-check flow and Quick Quiz.
//
// CHANGED this session: added 2 more tap-sound packs, ported from
// KiddoSpark's Web Audio API "ASMR" sound themes (asmr1/asmr2), which the
// user specifically liked on that app:
//   - Soft Tones: a single pure sine tone, no harmonics — the purest/
//     softest option, distinct from the 3 existing harmonic-layered packs.
//   - Water Chimes: a staggered 3-note ascending arpeggio (ported from
//     KiddoSpark's asmr2 "candy_drop" sound: 3 sine notes ~60ms apart,
//     rising in pitch) — this is the one that actually reads as a water
//     chime rather than a single blip.
// These needed a new rendering path (_generateSequence) since the
// existing _generateTone only supports simultaneous harmonic partials
// sharing one envelope, not notes that start at different times within
// the same clip.
//
// Previous packs (unchanged): all 3 tap-sound packs below were rebuilt
// last session with layered harmonics (2-3 overtones per sound) and
// natural exponential decay instead of a linear fade — much closer to
// how real short sounds actually decay. Packs: Keypad Tap (soft
// mechanical click), Water Drop (pitch glide + overtone, bubble-like),
// Soft Bell (3-harmonic chime with a slow natural decay).
//
// NOTE: AppMeta.soundPack stores the pack as a plain string. Any
// existing install with an old/unknown saved pack name falls back to the
// default (keypadTap) via packFromName's orElse — not a crash, just a
// silent reset to default for that one preference.
//
// Correct/incorrect feedback still uses real SPEECH via a dedicated
// FlutterTts instance (unchanged) — only tap-sound synthesis is covered
// here.

import 'dart:typed_data';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'storage_service.dart';

enum SoundPack { keypadTap, waterDrop, softBell, softTones, waterChimes }

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

  /// Plays the tap sound — layered/naturally-decaying tone, or (for the
  /// 2 new ASMR-derived packs) a single pure tone or a staggered
  /// multi-note sequence. Still respects the user's chosen pack.
  static Future<void> playTap() async {
    final meta = StorageService.getOrCreateAppMeta();
    if (!meta.soundEnabled) return;

    final pack = packFromName(meta.soundPack);

    Uint8List bytes;
    if (pack == SoundPack.waterChimes) {
      bytes = _generateSequence(_sequenceFor(pack));
    } else {
      bytes = _generateTone(_specFor(pack));
    }

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

  // Each pack (except waterChimes, handled separately below) is a short
  // list of harmonic partials (frequency + relative volume) rather than
  // a single frequency, plus an optional downward pitch glide.
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
      case SoundPack.softTones:
        // ADDED: ported from KiddoSpark's asmr1 "Soft Tones" theme — a
        // single pure sine, no harmonics at all. Deliberately the
        // plainest/softest-sounding option of the 5.
        return const _ToneSpec(
          frequencies: [660],
          amplitudes: [0.34],
          durationMs: 130,
        );
      case SoundPack.waterChimes:
        // Handled by _generateSequence instead — see playTap(). This
        // branch is unreachable but kept exhaustive for the switch.
        return const _ToneSpec(
          frequencies: [784],
          amplitudes: [0.3],
          durationMs: 90,
        );
    }
  }

  /// ADDED: the staggered-note sequence for Water Chimes, ported from
  /// KiddoSpark's asmr2 "Chimes" theme (its candy_drop sound): 3 sine
  /// notes rising in pitch, each starting ~60ms after the last.
  static List<_NoteSpec> _sequenceFor(SoundPack pack) {
    return const [
      _NoteSpec(frequency: 784, amplitude: 0.30, startMs: 0, durationMs: 90),
      _NoteSpec(frequency: 988, amplitude: 0.26, startMs: 60, durationMs: 90),
      _NoteSpec(frequency: 1175, amplitude: 0.22, startMs: 120, durationMs: 100),
    ];
  }

  /// Generates a mono 16-bit PCM WAV in memory from a set of harmonic
  /// partials, a short attack, and a natural EXPONENTIAL decay (rather
  /// than a straight-line fade). If [glideToFrequency] is set, the FIRST
  /// partial's frequency (and others, scaled proportionally) slides
  /// linearly from its starting value to that target over the sound's
  /// duration.
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

      double envelope = math.exp(-decayRate * t);
      if (i < attackSamples) {
        envelope *= i / attackSamples;
      }

      final instantFund = spec.glideToFrequency != null
          ? baseFreq + (spec.glideToFrequency! - baseFreq) * progress
          : baseFreq;

      double sample = 0;
      for (var p = 0; p < spec.frequencies.length; p++) {
        final ratio = spec.frequencies[p] / baseFreq;
        final freq = instantFund * ratio;
        sample += spec.amplitudes[p] * math.sin(2 * math.pi * freq * t);
      }
      sample *= envelope;

      samples[i] = (sample * 32767).round().clamp(-32768, 32767);
    }

    return _wavBytes(samples, sampleRate);
  }

  /// ADDED: renders several notes that start at different times within
  /// one clip (e.g. an ascending arpeggio), each with its own short
  /// attack + exponential decay, summed together into a single buffer.
  static Uint8List _generateSequence(List<_NoteSpec> notes) {
    const sampleRate = 44100;
    final totalDurationMs = notes
        .map((n) => n.startMs + n.durationMs)
        .reduce((a, b) => a > b ? a : b) + 40; // small tail so the last note doesn't click off
    final totalSamples = (sampleRate * totalDurationMs / 1000).round();
    final samples = Int16List(totalSamples);
    final buffer = List<double>.filled(totalSamples, 0);

    for (final note in notes) {
      final startSample = (sampleRate * note.startMs / 1000).round();
      final noteSamples = (sampleRate * note.durationMs / 1000).round();
      final attackSamples = (sampleRate * 0.004).round(); // 4ms soft attack
      final decayRate = 3.0 / (note.durationMs / 1000);

      for (var i = 0; i < noteSamples; i++) {
        final globalIndex = startSample + i;
        if (globalIndex >= totalSamples) break;
        final t = i / sampleRate;

        double envelope = math.exp(-decayRate * t);
        if (i < attackSamples) {
          envelope *= i / attackSamples;
        }

        final sample = note.amplitude * math.sin(2 * math.pi * note.frequency * t) * envelope;
        buffer[globalIndex] += sample;
      }
    }

    for (var i = 0; i < totalSamples; i++) {
      samples[i] = (buffer[i] * 32767).round().clamp(-32768, 32767);
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

/// ADDED: one note within a staggered multi-note sequence (see
/// _generateSequence / Water Chimes).
class _NoteSpec {
  final double frequency;
  final double amplitude;
  final int startMs;
  final int durationMs;
  const _NoteSpec({
    required this.frequency,
    required this.amplitude,
    required this.startMs,
    required this.durationMs,
  });
}