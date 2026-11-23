/// Rep counting for every exercise kind, behind one interface. Pure Dart.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show protected;

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
    this.image,
  });

  /// Landmarks used for distances (world landmarks when available).
  final List<Point3> points;

  /// Image-space landmarks with x and y on the same scale: where the hand
  /// is in the picture. Needed by exercises that move the whole hand (hand
  /// slide). World landmarks have no position.
  final List<Point3>? image;
  final HandAngles angles;

  /// Opening (or spread) as 0-100 % of the user's calibrated range.
  final double percent;
}

/// Maps [v] from the range [from]..[to] onto 0-1 (clamped). [from] may be
/// above [to].
double _lin(double v, double from, double to) =>
    ((v - from) / (to - from)).clamp(0.0, 1.0).toDouble();

/// Thumb tip to index tip, in hand sizes: the smaller of the 3D gap and the
/// on-screen gap (see [FingerTouchCounter]).
double _pinchGap(HandSample s) {
  final world = HandMetrics.touchGap(s.points, HandIndex.indexTip);
  final img = s.image;
  return img == null
      ? world
      : math.min(world, HandMetrics.touchGap(img, HandIndex.indexTip));
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

  /// How far along the current move is, 0-1: the bar on screen fills as the
  /// person gets to the goal, so they can see what is missing. Null: show
  /// the opening of the hand.
  double? get meter => null;

  /// Where the goal line sits on the bar, 0-1.
  double get marker => 1.0;

  /// Builds the right counter for [kind].
  ///
  /// [high] and [low] set the bands of the open/close style exercises (see
  /// [CameraExercise.repHigh]); without them each kind uses its default.
  static ExerciseCounter forKind(ExerciseKind kind,
          {double? high, double? low}) =>
      switch (kind) {
        ExerciseKind.openCloseGentle => _Hysteresis(
            HysteresisRepCounter(high: high ?? 70, low: low ?? 30),
            openText: 'Open your hand as far as you can.',
            closeText: 'Now close it gently.'),
        ExerciseKind.openClose => _Hysteresis(
            HysteresisRepCounter(high: high ?? 80, low: low ?? 20),
            openText: 'Open your hand wide.',
            closeText: 'Now make a fist.'),
        ExerciseKind.spread => _Hysteresis(
            HysteresisRepCounter(high: high ?? 80, low: low ?? 20),
            openText: 'Spread your fingers wide.',
            closeText: 'Now bring them together.'),
        ExerciseKind.holdOpen => PostureCycleCounter(
            inTarget: (s) => s.percent >= 70,
            closeness: (s) => _lin(s.percent, 0, 70),
            released: (s) => s.percent <= 40,
            hold: const Duration(seconds: 3),
            startHint: 'Open your hand as wide as you can.',
            holdHint: 'Hold it open.',
            releaseHint: 'Now relax your hand.',
          ),
        ExerciseKind.cylinder => PostureCycleCounter(
            // Closed around an object: partly, not fully, closed.
            inTarget: (s) => s.percent >= 15 && s.percent <= 65,
            closeness: (s) => s.percent > 65
                ? _lin(s.percent, 100, 65)
                : _lin(s.percent, 0, 15),
            released: (s) => s.percent >= 75,
            hold: const Duration(seconds: 2),
            startHint: 'Close your hand around the cup.',
            holdHint: 'Hold the grip.',
            releaseHint: 'Let go and open your hand.',
          ),
        ExerciseKind.hook => PostureCycleCounter(
            inTarget: isHook,
            closeness: (s) {
              final f = s.angles.fingers;
              final pip = f.map((x) => x.pip).reduce((a, b) => a + b) / f.length;
              return _lin(pip, 0, 60);
            },
            released: (s) => s.percent >= 75,
            hold: const Duration(seconds: 1),
            startHint: 'Bend your fingers like holding a bag handle.',
            holdHint: 'Hold the hook.',
            releaseHint: 'Open your hand fully.',
          ),
        ExerciseKind.pinch => PostureCycleCounter(
            inTarget: (s) => _pinchGap(s) < 0.35,
            closeness: (s) => _lin(_pinchGap(s), 1.2, 0.35),
            released: (s) => _pinchGap(s) > 0.6,
            hold: const Duration(milliseconds: 300),
            startHint: 'Touch your thumb to your index fingertip.',
            holdHint: 'Hold the pinch.',
            releaseHint: 'Move them apart.',
          ),
        ExerciseKind.fingerTouches => _Touches(FingerTouchCounter()),
        ExerciseKind.fingerLifts => FingerLiftCounter(),
        ExerciseKind.squeeze => PostureCycleCounter(
            inTarget: (s) => s.percent <= 30,
            closeness: (s) => _lin(s.percent, 100, 30),
            released: (s) => s.percent >= 55,
            hold: const Duration(seconds: 5),
            startHint: 'Make a fist and squeeze.',
            holdHint: 'Keep squeezing.',
            releaseHint: 'Relax and open your hand.',
          ),
        ExerciseKind.assistedExtension => PostureCycleCounter(
            inTarget: (s) => s.percent >= 60,
            closeness: (s) => _lin(s.percent, 0, 60),
            released: (s) => s.percent <= 40,
            hold: const Duration(seconds: 5),
            startHint: 'Lift your fingers straight with your other hand.',
            holdHint: 'Hold the stretch.',
            releaseHint: 'Let go and relax your hand.',
          ),
        ExerciseKind.thumbExtension => PostureCycleCounter(
            inTarget: (s) => s.angles.thumbAbduction >= 35,
            closeness: (s) => _lin(s.angles.thumbAbduction, 10, 35),
            released: (s) => s.angles.thumbAbduction <= 22,
            hold: const Duration(seconds: 5),
            startHint: 'Move your thumb away from your fingers.',
            holdHint: 'Hold your thumb out.',
            releaseHint: 'Relax your thumb.',
          ),
        ExerciseKind.wristStretch => WristBendCounter(),
        ExerciseKind.wristRotation => PalmRotationCounter(),
        ExerciseKind.handSlide => SlideCounter(),
        ExerciseKind.flatFingerLifts => FlatFingerLiftCounter(),
        ExerciseKind.fingerWalking =>
          FlatFingerLiftCounter(order: FlatFingerLiftCounter.walkingOrder),
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
  _Hysteresis(this._c, {required this.openText, required this.closeText});
  final HysteresisRepCounter _c;
  final String openText;
  final String closeText;
  double _percent = 0;

  @override
  int get count => _c.reps;

  @override
  bool update(HandSample s, Duration t) {
    _percent = s.percent;
    return _c.update(s.percent, t);
  }

  @override
  void resetCycle() => _c.resetCycle();

  @override
  String get hint => _c.expectingOpen ? openText : closeText;

  /// The bar is the opening itself, with the goal line where the next
  /// target is: reach the line, then the other line.
  @override
  double get meter => _percent / 100;

  @override
  double get marker => (_c.expectingOpen ? _c.high : _c.low) / 100;
}

class _Touches extends ExerciseCounter {
  _Touches(this._c);
  final FingerTouchCounter _c;

  static const names = ['index', 'middle', 'ring', 'little'];

  @override
  int get count => _c.rounds;

  @override
  bool update(HandSample s, Duration t) =>
      _c.update(s.points, t, image: s.image);

  @override
  void resetCycle() => _c.resetCycle();

  @override
  String get hint => 'Touch your thumb to your ${names[_c.expectedFinger]} '
      'fingertip (${_c.expectedFinger + 1} of 4).';

  @override
  double get meter => _c.meter;
}

/// A rep = reach the target posture, hold it for [hold], then release.
class PostureCycleCounter extends ExerciseCounter {
  PostureCycleCounter({
    required this.inTarget,
    required this.closeness,
    required this.released,
    required this.hold,
    this.startHint,
    this.holdHint,
    this.releaseHint,
  });

  final bool Function(HandSample) inTarget;

  /// 0-1: how near the hand is to the target posture.
  final double Function(HandSample) closeness;
  final bool Function(HandSample) released;
  final Duration hold;
  final String? startHint;
  final String? holdHint;
  final String? releaseHint;

  int _count = 0;
  Duration? _since;
  bool _waitingRelease = false;
  String? _hint;
  double _meter = 0;

  @override
  int get count => _count;

  @override
  String? get hint => _hint ?? startHint;

  /// First 40 % of the bar: getting into the posture. The rest: the hold,
  /// filling as the seconds pass. Full means the rep counts.
  @override
  double get meter => _meter;

  @override
  bool update(HandSample s, Duration t) {
    if (_waitingRelease) {
      _meter = 0;
      if (released(s)) {
        _waitingRelease = false;
        _hint = null;
      }
      return false;
    }
    if (!inTarget(s)) {
      _since = null;
      _hint = null;
      _meter = 0.4 * closeness(s);
      return false;
    }
    _since ??= t;
    final held = t - _since!;
    final left = hold - held;
    _meter = 0.4 + 0.6 * (held.inMilliseconds / hold.inMilliseconds).clamp(0.0, 1.0);
    _hint = hold.inSeconds >= 2 && left > Duration.zero
        ? '${holdHint ?? 'Hold.'} ${(left.inMilliseconds / 1000).ceil()} s'
        : holdHint;
    if (held >= hold) {
      _count++;
      _since = null;
      _waitingRelease = true;
      _hint = releaseHint;
      _meter = 1;
      return true;
    }
    return false;
  }

  @override
  void resetCycle() {
    _since = null;
    _hint = null;
    _meter = 0;
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
    this.order = const [0, 1, 2, 3],
  });

  final double margin;
  final Duration hold;

  /// Fingers in the order they must be lifted (0 index ... 3 little). A
  /// round is one pass through the whole list.
  final List<int> order;

  int _rounds = 0;
  int _next = 0;
  int? _candidate;
  Duration? _since;
  int? _registered;

  static const names = ['index', 'middle', 'ring', 'little'];

  @override
  int get count => _rounds;

  @override
  String get hint => 'Lift your ${names[order[_next]]} finger '
      '(${_next + 1} of ${order.length}).';

  /// How far each finger (index to little) stands out from the other three,
  /// in the units of [threshold]. Here: degrees less bent than the others.
  @protected
  List<double> gaps(HandSample s) {
    final totals = [for (final f in s.angles.fingers) f.total];
    return [
      for (var i = 0; i < 4; i++)
        [for (var j = 0; j < 4; j++) if (j != i) totals[j]]
                    .reduce((a, b) => a + b) /
                3 -
            totals[i],
    ];
  }

  /// A finger counts as lifted when its gap reaches this.
  @protected
  double get threshold => margin;

  double _meter = 0;

  /// How close the finger that is due next is to being lifted.
  @override
  double get meter => _meter;

  /// Which finger (0 index ... 3 little) is lifted right now, if any.
  @protected
  int? liftedFinger(HandSample s) {
    final g = gaps(s);
    _meter = (g[order[_next]] / threshold).clamp(0.0, 1.0).toDouble();
    int? best;
    var bestGap = threshold;
    for (var i = 0; i < 4; i++) {
      if (g[i] >= bestGap) {
        bestGap = g[i];
        best = i;
      }
    }
    return best;
  }

  @override
  bool update(HandSample s, Duration t) {
    final lifted = liftedFinger(s);
    if (lifted == null) _registered = null; // all down again: re-arm
    if (lifted != _candidate) {
      _candidate = lifted;
      _since = lifted == null ? null : t;
      return false;
    }
    if (lifted == null || lifted == _registered || t - _since! < hold) {
      return false;
    }
    _registered = lifted;
    if (lifted == order[_next]) {
      _next++;
      if (_next == order.length) {
        _next = 0;
        _rounds++;
        return true;
      }
    } else {
      _next = lifted == order[0] ? 1 : 0;
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

/// Tabletop finger lift and finger walking: the hand rests flat and one
/// finger at a time rises off the surface. A finger counts as lifted when
/// its tip is at least [margin] palm widths further from the palm's plane
/// than the average of the other three tips. Works from any camera angle,
/// since it measures against the hand itself.
class FlatFingerLiftCounter extends FingerLiftCounter {
  FlatFingerLiftCounter({
    this.liftMargin = 0.35,
    super.hold = const Duration(milliseconds: 300),
    super.order,
  }) : super(margin: 0);

  /// Index, middle, ring, little, then back: ring, middle, index.
  static const walkingOrder = [0, 1, 2, 3, 2, 1, 0];

  final double liftMargin;

  @override
  double get threshold => liftMargin;

  @override
  List<double> gaps(HandSample s) {
    final h = HandMetrics.palmHeights(s.points);
    return [
      for (var i = 0; i < 4; i++)
        (h[i] -
                [for (var j = 0; j < 4; j++) if (j != i) h[j]]
                        .reduce((a, b) => a + b) /
                    3)
            .abs(),
    ];
  }
}

/// Wrist stretch: the hand tilts at the wrist [out] degrees or more from
/// where it started, then comes back within [back] degrees. One rep each
/// time, whichever direction it bent.
class WristBendCounter extends ExerciseCounter {
  WristBendCounter({this.out = 20, this.back = 10});

  final double out;
  final double back;

  final WristMonitor _monitor = WristMonitor(limitDegrees: 1000);
  int _count = 0;
  bool _bent = false;
  double _meter = 0;
  String? _hint = 'Hold your wrist straight to start.';

  @override
  int get count => _count;

  @override
  String? get hint => _hint;

  /// Out: how far the wrist has bent. Back: how near it is to straight.
  @override
  double get meter => _meter;

  @override
  bool update(HandSample s, Duration t) {
    _monitor.update(s.points);
    if (!_monitor.hasReference) return false;
    final d = _monitor.deviation;
    _meter = _bent ? _lin(d, out, back) : _lin(d, 0, out);
    if (!_bent) {
      _hint = 'Gently bend your wrist.';
      if (d >= out) {
        _bent = true;
        _hint = 'Now bring it back to straight.';
      }
      return false;
    }
    if (d <= back) {
      _bent = false;
      _count++;
      _hint = 'Gently bend your wrist.';
      return true;
    }
    return false;
  }

  @override
  void resetCycle() {
    _bent = false;
    _monitor.reset();
    _hint = 'Hold your wrist straight to start.';
  }
}

/// Wrist rotation: the palm turns to face the other way (more than
/// [turned] of the way round) and then back. The starting side is whatever
/// the palm faces when the set starts, so it works palm down or palm up.
class PalmRotationCounter extends ExerciseCounter {
  PalmRotationCounter({this.start = 0.6, this.turned = 0.5});

  final double start;
  final double turned;

  int _count = 0;
  double? _side; // +1 or -1: which way the palm faced at the start
  bool _over = false;
  double _meter = 0;
  String? _hint = 'Hold your hand out, palm facing one way.';

  @override
  int get count => _count;

  @override
  String? get hint => _hint;

  /// Turning over: how far round. Turning back: how near the start.
  @override
  double get meter => _meter;

  @override
  bool update(HandSample s, Duration t) {
    final f = HandMetrics.palmFacing(s.points);
    final side = _side;
    if (side == null) {
      if (f.abs() >= start) {
        _side = f.sign;
        _hint = 'Slowly turn your palm over.';
      }
      return false;
    }
    final rel = f * side;
    _meter = _over ? _lin(rel, -turned, 1) : _lin(rel, 1, -turned);
    if (!_over) {
      if (rel <= -turned) {
        _over = true;
        _hint = 'Now turn it back.';
      }
      return false;
    }
    if (rel >= turned) {
      _over = false;
      _count++;
      _hint = 'Slowly turn your palm over.';
      return true;
    }
    return false;
  }

  @override
  void resetCycle() {
    _over = false;
    _side = null;
    _hint = 'Hold your hand out, palm facing one way.';
  }
}

/// Hand slide: the wrist moves [out] palm widths away from where it
/// started, then back within [back] of it. Distances are in palm widths, so
/// they do not depend on how far the phone is.
class SlideCounter extends ExerciseCounter {
  SlideCounter({this.out = 0.8, this.back = 0.3});

  final double out;
  final double back;

  int _count = 0;
  Point3? _home;
  bool _away = false;
  double _meter = 0;
  String? _hint = 'Rest your hand flat to start.';

  @override
  int get count => _count;

  @override
  String? get hint => _hint;

  /// Sliding out: how far from where it started. Sliding back: how near.
  @override
  double get meter => _meter;

  @override
  bool update(HandSample s, Duration t) {
    final pts = s.image ?? s.points;
    final palm = HandMetrics.palmWidth(pts);
    if (palm <= 0) return false;
    final wrist = pts[HandIndex.wrist];
    final home = _home ??= wrist;
    final d = wrist.distanceTo(home) / palm;
    _meter = _away ? _lin(d, out, back) : _lin(d, 0, out);
    if (!_away) {
      _hint = 'Slide your hand forward.';
      if (d >= out) {
        _away = true;
        _hint = 'Now slide it back.';
      }
      return false;
    }
    if (d <= back) {
      _away = false;
      _count++;
      _hint = 'Slide your hand forward.';
      return true;
    }
    return false;
  }

  @override
  void resetCycle() {
    _away = false;
    _home = null;
    _hint = 'Rest your hand flat to start.';
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

  /// The starting direction has been recorded.
  bool get hasReference => _reference != null;

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
