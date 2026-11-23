import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/camera/landmark_smoother.dart';
import 'package:rohab/exercises/hand_metrics.dart';
import 'package:rohab/exercises/synthetic_hand.dart';

double sd(List<double> xs) {
  final m = xs.reduce((a, b) => a + b) / xs.length;
  return math.sqrt(
      xs.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / xs.length);
}

List<Point3> noisy(List<Point3> base, math.Random r, double amp) => [
      for (final p in base)
        Point3(p.x + (r.nextDouble() - 0.5) * amp,
            p.y + (r.nextDouble() - 0.5) * amp, p.z),
    ];

void main() {
  const dt = Duration(milliseconds: 66); // about 15 fps
  Duration at(int i) => dt * i;

  test('a still hand: wobble is cut by more than half', () {
    final base = SyntheticHand.pose();
    final r = math.Random(3);
    final sm = LandmarkSmoother();
    final raw = <double>[], smooth = <double>[];
    for (var i = 0; i < 120; i++) {
      final f = noisy(base, r, 0.01); // +-0.5 % of the image
      sm.beginFrame(at(i));
      final s = sm.smoothImage(f, at(i));
      if (i > 15) {
        raw.add(f[8].x);
        smooth.add(s[8].x);
      }
    }
    expect(sd(smooth), lessThan(sd(raw) * 0.5));
  });

  test('a still pinch no longer flickers across the touch limit', () {
    // Thumb tip hovers right at the limit with noise: raw crosses it often,
    // smoothed stays on one side far more.
    final base = SyntheticHand.world(thumbOn: HandIndex.indexTip);
    final r = math.Random(11);
    final sm = LandmarkSmoother();
    int flips(List<double> d, double limit) {
      var n = 0;
      for (var i = 1; i < d.length; i++) {
        if ((d[i] < limit) != (d[i - 1] < limit)) n++;
      }
      return n;
    }

    final rawD = <double>[], smD = <double>[];
    for (var i = 0; i < 150; i++) {
      final f = [
        for (final p in base)
          Point3(p.x + (r.nextDouble() - 0.5) * 0.02,
              p.y + (r.nextDouble() - 0.5) * 0.02, p.z),
      ];
      sm.beginFrame(at(i));
      final s = sm.smoothWorld(f, at(i));
      if (i > 15) {
        rawD.add(HandMetrics.thumbTo(f, HandIndex.indexTip));
        smD.add(HandMetrics.thumbTo(s, HandIndex.indexTip));
      }
    }
    final limit = (rawD.reduce((a, b) => a + b) / rawD.length);
    expect(flips(smD, limit), lessThan(flips(rawD, limit) ~/ 2));
  });

  test('a moving hand is followed with little lag', () {
    final sm = LandmarkSmoother();
    var lagSum = 0.0;
    var n = 0;
    for (var i = 0; i < 60; i++) {
      // Sweeps 0.3 of the image in 1 s.
      final shift = 0.3 * math.sin(i * dt.inMilliseconds / 1000 * math.pi);
      final f = SyntheticHand.pose(offsetX: shift);
      sm.beginFrame(at(i));
      final s = sm.smoothImage(f, at(i));
      if (i > 10) {
        lagSum += (f[0].x - s[0].x).abs();
        n++;
      }
    }
    expect(lagSum / n, lessThan(0.03));
  });

  test('a gap in tracking starts fresh instead of gliding', () {
    final sm = LandmarkSmoother();
    final a = SyntheticHand.pose();
    final b = SyntheticHand.pose(offsetX: 0.2);
    for (var i = 0; i < 20; i++) {
      sm.beginFrame(at(i));
      sm.smoothImage(a, at(i));
    }
    final t = at(20) + const Duration(seconds: 2);
    sm.beginFrame(t);
    final s = sm.smoothImage(b, t);
    expect(s[0].x, closeTo(b[0].x, 1e-9));
  });
}
