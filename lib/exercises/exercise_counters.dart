/// Rep counting for every exercise kind, behind one interface. Pure Dart.
library;

import 'dart:math' as math;

import 'exercise_catalog.dart';
import 'hand_metrics.dart';
import 'joint_angles.dart';
import 'rep_counter.dart';

/// Everything a counter may need from one frame.
class HandSample {
  const HandSample({
    required this.points,
    required this.angles,
    required this.percent,
  });

  /// Landmarks used for distances (world landmarks when available).
  final List<Point3> points;
  final HandAngles angles;

  /// Opening (or spread) as 0-100 % of the user's calibrated range.
  final double percent;
}

/// Counts reps (or holds, or rounds) of one exercise.
abstract class ExerciseCounter {
  int get count;

  /// Returns true when this frame completes a rep.
  bool update(HandSample s, Duration t);

  /// Drop a half-finished rep (e.g. the hand was out of view).
  void resetCycle();

  /// Short, plain guidance for the current moment, if any.
  String? get hint => null;

  /// Builds the right counter for [kind].
  static ExerciseCounter forKind(ExerciseKind kind) => switch (kind) {
        ExerciseKind.openCloseGentle =>
          _Hysteresis(HysteresisRepCounter(high: 70, low: 30)),
        ExerciseKind.openClose || ExerciseKind.spread =>
          _Hysteresis(HysteresisRepCounter()),
        ExerciseKind.holdOpen => PostureCycleCounter(
            inTarget: (s) => s.percent >= 70,
            released: (s) => s.percent <= 40,
            hold: const Duration(seconds: 3),
            holdHint: 'Hold it open.',
            releaseHint: 'Now relax your hand.',
          ),
        ExerciseKind.cylinder => PostureCycleCounter(
            // Closed around an object: partly, not fully, closed.
            inTarget: (s) => s.percent >= 15 && s.percent <= 65,
            released: (s) => s.percent >= 75,
            hold: const Duration(seconds: 2),
            holdHint: 'Hold the grip.',
            releaseHint: 'Let go and open your hand.',
          ),
        ExerciseKind.hook => PostureCycleCounter(
            inTarget: isHook,
            released: (s) => s.percent >= 75,
            hold: const Duration(seconds: 1),
            holdHint: 'Hold the hook.',
            releaseHint: 'Open your hand fully.',
          ),
        ExerciseKind.pinch => PostureCycleCounter(
            inTarget: (s) =>
                HandMetrics.thumbTo(s.points, HandIndex.indexTip) < 0.25,
            released: (s) =>
                HandMetrics.thumbTo(s.points, HandIndex.indexTip) > 0.45,
            hold: const Duration(milliseconds: 300),
            holdHint: 'Hold the pinch.',
            releaseHint: 'Move them apart.',
          ),
        ExerciseKind.fingerTouches => _Touches(FingerTouchCounter()),
        ExerciseKind.fingerLifts => FingerLiftCounter(),
      };

  /// Hook grip: knuckles (MCP) mostly straight, finger joints (PIP) bent.
  static bool isHook(HandSample s) {
    final f = s.angles.fingers;
    final mcp = f.map((x) => x.mcp).reduce((a, b) => a + b) / f.length;
    final pip = f.map((x) => x.pip).reduce((a, b) => a + b) / f.length;
    return mcp <= 30 && pip >= 60;
  }
}

class _Hysteresis extends ExerciseCounter {
  _Hysteresis(this._c);
  final HysteresisRepCounter _c;

  @override
  int get count => _c.reps;

  @override
  bool update(HandSample s, Duration t) => _c.update(s.percent, t);

  @override
  void resetCycle() => _c.resetCycle();
}

class _Touches extends ExerciseCounter {
  _Touches(this._c);
  final FingerTouchCounter _c;

  static const names = ['index', 'middle', 'ring', 'little'];

  @override
  int get count => _c.rounds;

  @override
  bool update(HandSample s, Duration t) => _c.update(s.points, t);

  @override
  void resetCycle() => _c.resetCycle();

  @override
  String get hint => 'Next: ${names[_c.expectedFinger]} finger';
}

/// A rep = reach the target posture, hold it for [hold], then release.
class PostureCycleCounter extends ExerciseCounter {
  PostureCycleCounter({
    required this.inTarget,
    required this.released,
    required this.hold,
    this.holdHint,
    this.releaseHint,
  });

  final bool Function(HandSample) inTarget;
  final bool Function(HandSample) released;
  final Duration hold;
  final String? holdHint;
  final String? releaseHint;

  int _count = 0;
  Duration? _since;
  bool _waitingRelease = false;
  String? _hint;

  @override
  int get count => _count;

  @override
  String? get hint => _hint;

  @override
  bool update(HandSample s, Duration t) {
    if (_waitingRelease) {
      if (released(s)) {
        _waitingRelease = false;
        _hint = null;
      }
      return false;
    }
    if (!inTarget(s)) {
      _since = null;
      _hint = null;
      return false;
    }
    _since ??= t;
    _hint = holdHint;
    if (t - _since! >= hold) {
      _count++;
      _since = null;
      _waitingRelease = true;
      _hint = releaseHint;
      return true;
    }
    return false;
  }

  @override
  void resetCycle() {
    _since = null;
    _hint = null;
    // A hold already counted still needs a release before the next one.
  }
}

/// Finger individuation: straighten index, middle, ring, little in turn
/// while the others stay bent. A finger counts as lifted when its bend is
/// at least [margin] degrees below the mean of the other three, held for
/// [hold]. One round = all four in order; a wrong finger restarts.
class FingerLiftCounter extends ExerciseCounter {
  FingerLiftCounter({
    this.margin = 60,
    this.hold = const Duration(milliseconds: 400),
  });

  final double margin;
  final Duration hold;

  int _rounds = 0;
  int _next = 0;
  int? _candidate;
  Duration? _since;
  int? _registered;

  static const names = ['index', 'middle', 'ring', 'little'];

  @override
  int get count => _rounds;

  @override
  String get hint => 'Next: ${names[_next]} finger';

  int? _lifted(HandSample s) {
    final totals = [for (final f in s.angles.fingers) f.total];
    int? best;
    var bestGap = margin;
    for (var i = 0; i < 4; i++) {
      final others = [for (var j = 0; j < 4; j++) if (j != i) totals[j]];
      final gap = others.reduce((a, b) => a + b) / 3 - totals[i];
      if (gap >= bestGap) {
        bestGap = gap;
        best = i;
      }
    }
    return best;
  }

  @override
  bool update(HandSample s, Duration t) {
    final lifted = _lifted(s);
    if (lifted == null) _registered = null; // all bent again: re-arm
    if (lifted != _candidate) {
      _candidate = lifted;
      _since = lifted == null ? null : t;
      return false;
    }
    if (lifted == null || lifted == _registered || t - _since! < hold) {
      return false;
    }
    _registered = lifted;
    if (lifted == _next) {
      _next++;
      if (_next == 4) {
        _next = 0;
        _rounds++;
        return true;
      }
    } else {
      _next = lifted == 0 ? 1 : 0;
    }
    return false;
  }

  @override
  void resetCycle() {
    _next = 0;
    _candidate = null;
    _since = null;
    _registered = null;
  }
}

/// Watches for compensation: the hand tilting at the wrist (or the forearm
/// moving) instead of the fingers doing the work. Bending the wrist
/// straightens the fingers passively (tenodesis), so a rep made that way
/// should not count.
///
/// The reference is the direction of the back of the hand (wrist to middle
/// knuckle) when the set starts; with the forearm resting still, a change
/// in that direction is wrist movement.
class WristMonitor {
  WristMonitor({this.limitDegrees = 25, this.referenceFrames = 10});

  final double limitDegrees;
  final int referenceFrames;

  final List<Point3> _samples = [];
  Point3? _reference;
  double _deviation = 0;

  /// Degrees the hand has tilted from where it started.
  double get deviation => _deviation;

  bool get moved => _deviation > limitDegrees;

  void update(List<Point3> points) {
    final v = points[HandIndex.middleMcp] - points[HandIndex.wrist];
    if (_reference == null) {
      _samples.add(v);
      if (_samples.length >= referenceFrames) {
        double avg(double Function(Point3) f) =>
            _samples.map(f).reduce((a, b) => a + b) / _samples.length;
        _reference = Point3(avg((p) => p.x), avg((p) => p.y), avg((p) => p.z));
      }
      return;
    }
    final r = _reference!;
    final d = r.length * v.length;
    _deviation =
        d == 0 ? 0 : math.acos((r.dot(v) / d).clamp(-1.0, 1.0)) * 180 / math.pi;
  }

  /// New reference, e.g. after the hand was out of view.
  void reset() {
    _samples.clear();
    _reference = null;
    _deviation = 0;
  }
}
