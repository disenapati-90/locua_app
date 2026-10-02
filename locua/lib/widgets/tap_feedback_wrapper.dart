// tap_feedback_wrapper.dart
// Wraps the whole app (via MaterialApp's `builder`) to give app-wide tap
// sound + light haptic feedback on every valid tap, without needing to
// instrument every individual button/tile in every screen.
//
// HOW THIS WORKS: a Listener at the root of the widget tree receives RAW
// pointer events for every touch anywhere in the app, regardless of which
// descendant widget (button, card, chip, etc.) ultimately handles the
// gesture — pointer events route to every widget in the hit-test path
// independent of Flutter's gesture-arena resolution.
//
// TAP vs. SCROLL/DRAG: a raw pointer-down/up pair fires for scrolling and
// dragging too, not just taps — so this tracks the down position/time and
// only treats the gesture as a "tap" if the finger didn't move far and
// didn't take too long. Not perfect (a very slow deliberate tap could
// theoretically be missed) but covers the vast majority of real taps
// without firing during scrolling.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import '../services/sound_service.dart';

class TapFeedbackWrapper extends StatefulWidget {
  final Widget child;
  const TapFeedbackWrapper({super.key, required this.child});

  @override
  State<TapFeedbackWrapper> createState() => _TapFeedbackWrapperState();
}

class _TapFeedbackWrapperState extends State<TapFeedbackWrapper> {
  static const double _tapSlop = 20.0; // max movement (px) to still count as a tap
  static const int _tapMaxMs = 450; // max duration to still count as a tap

  final Map<int, Offset> _downPositions = {};
  final Map<int, DateTime> _downTimes = {};

  void _onPointerDown(PointerDownEvent event) {
    _downPositions[event.pointer] = event.position;
    _downTimes[event.pointer] = DateTime.now();
  }

  void _onPointerUp(PointerUpEvent event) {
    final downPos = _downPositions.remove(event.pointer);
    final downTime = _downTimes.remove(event.pointer);
    if (downPos == null || downTime == null) return;

    final distance = (event.position - downPos).distance;
    final durationMs = DateTime.now().difference(downTime).inMilliseconds;

    if (distance <= _tapSlop && durationMs <= _tapMaxMs) {
      HapticFeedback.lightImpact();
      SoundService.playTap();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _downPositions.remove(event.pointer);
    _downTimes.remove(event.pointer);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
}