import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/camera/landmark_smoother.dart';
import 'package:rohab/exercises/hand_distance.dart';
import 'package:rohab/exercises/hand_metrics.dart';
import 'package:rohab/exercises/synthetic_hand.dart';

void main() {
  group('distance check', () {
    test('a normal hand is good, a tiny one too far, a huge one too close', () {
      HandDistance of(double scale) => HandDistanceCheck.of(
          HandDistanceCheck.palmLength(SyntheticHand.pose(scale: scale)));
      expect(of(1.0), HandDistance.good);
      expect(of(0.3), HandDistance.tooFar);
      expect(of(1.8), HandDistance.tooClose);
    });

    test('a fist reads the same distance as an open hand', () {
      final open = HandDistanceCheck.palmLength(SyntheticHand.pose());
      final fist = HandDistanceCheck.palmLength(SyntheticHand.pose(curl: 1));
      expect(fist, closeTo(open, 0.01));
    });

    test('advice says which way to move, and nothing when good', () {
      expect(HandDistanceCheck.advice(HandDistance.tooFar), contains('closer'));
      expect(HandDistanceCheck.advice(HandDistance.tooClose), contains('back'));
      expect(HandDistanceCheck.advice(HandDistance.good), isNull);
    });
  });

  group('smoothing does not depend on how far the hand is', () {
    // The same still hand with the same pixel noise, near and far.
    double wobbleShare(double scale) {
      final base = SyntheticHand.pose(scale: scale);
      final r = math.Random(5);
      final sm = LandmarkSmoother();
      final out = <double>[];
      for (var i = 0; i < 150; i++) {
        final t = const Duration(milliseconds: 66) * i;
        final f = [
          for (final p in base)
            Point3(p.x + (r.nextDouble() - 0.5) * 0.01,
                p.y + (r.nextDouble() - 0.5) * 0.01, p.z),
        ];
        sm.beginFrame(t);
        final s = sm.smoothImage(f, t);
        if (i > 20) out.add(s[8].x);
      }
      final m = out.reduce((a, b) => a + b) / out.length;
      final sd = math.sqrt(
          out.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) /
              out.length);
      // Wobble as a share of the hand's size.
      return sd / HandDistanceCheck.palmLength(base);
    }

    test('a far hand is smoothed at least as hard, relative to its size', () {
      final near = wobbleShare(1.3);
      final far = wobbleShare(0.55);
      // Far noise is a bigger share of a small hand; the filter must pull it
      // down, so the remaining share stays within a small factor of near.
      expect(far, lessThan(near * 2.2));
    });
  });
}
