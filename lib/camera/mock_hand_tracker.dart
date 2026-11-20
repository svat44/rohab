import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../exercises/hand_metrics.dart';
import '../exercises/synthetic_hand.dart';
import '../theme/app_theme.dart';
import 'hand_tracker.dart';

/// What the simulated hand does at a moment, given time since start().
/// Return null for "no hand in view".
typedef HandScript = HandPose? Function(Duration t);

class HandPose {
  const HandPose({this.curl = 0, this.spread = 0.3, this.thumbOn});

  final double curl;
  final double spread;
  final int? thumbOn;

  static const open = HandPose();
  static const fist = HandPose(curl: 1);
}

/// Simulated hand for tests and the web preview. No camera.
///
/// Drive it with a [HandScript], or set [pose] directly between pumps.
/// Optional noise jitters landmarks; [lowConfidenceEvery] makes every Nth
/// frame low confidence so the caller's filter is exercised.
class MockHandTracker implements HandTracker {
  MockHandTracker({
    this.script,
    this.fps = 30,
    this.noise = 0,
    this.lowConfidenceEvery = 0,
    math.Random? random,
  }) : _random = random ?? math.Random(11);

  final HandScript? script;
  final int fps;

  /// Landmark jitter, in image units (0.003 is realistic).
  final double noise;
  final int lowConfidenceEvery;
  final math.Random _random;

  /// Used when there is no [script]. Null = no hand.
  HandPose? pose = HandPose.open;

  final _frames = StreamController<HandFrame>.broadcast();
  Timer? _timer;
  int _frameCount = 0;
  bool started = false;

  @override
  Stream<HandFrame> get frames => _frames.stream;

  @override
  TrackerStats get stats => TrackerStats(framesPerSecond: fps.toDouble());

  @override
  Future<void> start() async {
    if (_timer != null) return;
    started = true;
    _frameCount = 0;
    final period = Duration(microseconds: 1000000 ~/ fps);
    _timer = Timer.periodic(period, (_) {
      _frameCount++;
      final t = period * _frameCount;
      final p = script == null ? pose : script!(t);
      if (p == null) return;
      var lm = SyntheticHand.pose(
          curl: p.curl, spread: p.spread, thumbOn: p.thumbOn);
      if (noise > 0) {
        lm = [
          for (final q in lm)
            Point3(q.x + _jitter(), q.y + _jitter(), q.z + _jitter()),
        ];
      }
      var world = SyntheticHand.world(
          curl: p.curl, spread: p.spread, thumbOn: p.thumbOn);
      if (noise > 0) {
        // Same jitter in metres (image unit is about 0.45 m here).
        world = [
          for (final q in world)
            Point3(q.x + _jitter() * 0.45, q.y + _jitter() * 0.45,
                q.z + _jitter() * 0.45),
        ];
      }
      final low = lowConfidenceEvery > 0 && _frameCount % lowConfidenceEvery == 0;
      _frames.add(HandFrame(
        landmarks: lm,
        worldLandmarks: world,
        // The synthetic hand is a left hand, palm to the camera.
        handedness: Handedness.left,
        confidence: low ? 0.3 : 0.95,
        timestamp: t,
      ));
    });
  }

  double _jitter() => (_random.nextDouble() - 0.5) * 2 * noise;

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    started = false;
  }

  @override
  Widget buildPreview(BuildContext context) {
    final c = context.colors;
    return ColoredBox(
      color: c.surface,
      child: Center(
        child: Text('Simulated hand', style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }

  /// Open/close cycles: [period] per cycle, starting open.
  static HandScript cycles({
    Duration period = const Duration(milliseconds: 1600),
    Duration? dropoutStart,
    Duration dropoutLength = Duration.zero,
  }) {
    return (t) {
      if (dropoutStart != null &&
          t >= dropoutStart &&
          t < dropoutStart + dropoutLength) {
        return null;
      }
      final phase = (t.inMicroseconds % period.inMicroseconds) /
          period.inMicroseconds;
      return phase < 0.5 ? HandPose.open : HandPose.fist;
    };
  }
}
