/// Rep counting for camera (and later glove) exercises. Pure Dart.
library;

import 'hand_metrics.dart';

/// Counts open-close style reps from a 0-100 % signal with hysteresis:
/// one rep = reaching [high], then [low], then [high] again. Jitter between
/// the two thresholds never counts. A rep faster than [minRepDuration] is
/// ignored (likely tracking noise), and its closing high starts the next rep.
///
/// Signal-agnostic: openness %, spread %, or (later) glove pressure %.
class HysteresisRepCounter {
  HysteresisRepCounter({
    this.high = 80,
    this.low = 20,
    this.minRepDuration = const Duration(milliseconds: 800),
  }) : assert(low < high);

  final double high;
  final double low;
  final Duration minRepDuration;

  int _reps = 0;
  _Phase _phase = _Phase.waitingForHigh;
  Duration? _cycleStart;

  int get reps => _reps;

  /// Feed one value at time [t] (any monotonic clock). Returns true when a
  /// rep is counted on this value.
  bool update(double percent, Duration t) {
    switch (_phase) {
      case _Phase.waitingForHigh:
        if (percent >= high) {
          _phase = _Phase.waitingForLow;
          _cycleStart = t;
        }
      case _Phase.waitingForLow:
        if (percent <= low) _phase = _Phase.waitingForSecondHigh;
      case _Phase.waitingForSecondHigh:
        if (percent >= high) {
          final counted = t - _cycleStart! >= minRepDuration;
          if (counted) _reps++;
          // This high also opens the next rep.
          _phase = _Phase.waitingForLow;
          _cycleStart = t;
          return counted;
        }
    }
    return false;
  }

  /// Drop any half-finished rep, e.g. after the hand was lost for a while.
  /// Counted reps are kept.
  void resetCycle() {
    _phase = _Phase.waitingForHigh;
    _cycleStart = null;
  }
}

enum _Phase { waitingForHigh, waitingForLow, waitingForSecondHigh }

/// Counts finger-touch rounds: thumb tip to index, middle, ring, pinky tip,
/// in that order. A touch is the thumb within [touchDistance] palm widths
/// of a fingertip for at least [holdTime]. A wrong finger restarts the round.
class FingerTouchCounter {
  FingerTouchCounter({
    this.touchDistance = 0.25,
    this.releaseDistance = 0.35,
    this.holdTime = const Duration(milliseconds: 200),
  }) : assert(releaseDistance >= touchDistance);

  final double touchDistance;

  /// The thumb must move this far away before the same finger counts again.
  final double releaseDistance;
  final Duration holdTime;

  static const order = HandIndex.fingertips;

  int _rounds = 0;
  int _next = 0; // index into [order] of the finger expected next
  int? _candidate; // fingertip currently within touch distance
  Duration? _candidateSince;
  int? _registered; // fingertip already counted for the current contact

  int get rounds => _rounds;

  /// Which finger (0 index ... 3 pinky) the round expects next.
  int get expectedFinger => _next;

  /// Returns true when a round completes on this frame.
  bool update(List<Point3> landmarks, Duration t) {
    final d = [for (final tip in order) HandMetrics.thumbTo(landmarks, tip)];

    // Release: the registered finger counts again only after the thumb
    // moves clearly away from it.
    if (_registered != null) {
      final i = order.indexOf(_registered!);
      if (d[i] > releaseDistance) _registered = null;
    }

    // Closest fingertip within touch distance, if any.
    int? touching;
    var best = double.infinity;
    for (var i = 0; i < d.length; i++) {
      if (d[i] < touchDistance && d[i] < best) {
        best = d[i];
        touching = order[i];
      }
    }

    if (touching != _candidate) {
      _candidate = touching;
      _candidateSince = touching == null ? null : t;
      return false;
    }
    if (touching == null ||
        touching == _registered ||
        t - _candidateSince! < holdTime) {
      return false;
    }

    _registered = touching;
    return _register(order.indexOf(touching));
  }

  bool _register(int finger) {
    if (finger == _next) {
      _next++;
      if (_next == order.length) {
        _next = 0;
        _rounds++;
        return true;
      }
    } else {
      // Wrong finger: restart. Touching the index starts a new round.
      _next = finger == 0 ? 1 : 0;
    }
    return false;
  }

  /// Drop a half-finished round, e.g. after the hand was lost.
  void resetCycle() {
    _next = 0;
    _candidate = null;
    _candidateSince = null;
    _registered = null;
  }
}
