import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/exercises/hand_metrics.dart';
import 'package:rohab/exercises/synthetic_hand.dart';

void main() {
  group('jointAngle (PIP angle math)', () {
    test('straight finger is 180 degrees', () {
      expect(
        HandMetrics.jointAngle(const Point3(0, 0, 0), const Point3(0, 1, 0),
            const Point3(0, 2, 0)),
        closeTo(180, 1e-9),
      );
    });

    test('right angle is 90 degrees', () {
      expect(
        HandMetrics.jointAngle(const Point3(0, 0, 0), const Point3(0, 1, 0),
            const Point3(1, 1, 0)),
        closeTo(90, 1e-9),
      );
    });

    test('uses depth (z) too', () {
      expect(
        HandMetrics.jointAngle(const Point3(0, 0, 0), const Point3(0, 1, 0),
            const Point3(0, 1, -1)),
        closeTo(90, 1e-9),
      );
    });

    test('degenerate points do not produce NaN', () {
      const p = Point3(1, 1, 1);
      expect(HandMetrics.jointAngle(p, p, p), 180);
    });
  });

  group('synthetic hand', () {
    test('open hand has PIP angles near 180', () {
      for (final a in HandMetrics.pipAngles(SyntheticHand.pose(curl: 0))) {
        expect(a, closeTo(180, 0.5));
      }
    });

    test('fist has PIP angles near 70', () {
      for (final a in HandMetrics.pipAngles(SyntheticHand.pose(curl: 1))) {
        expect(a, closeTo(70, 0.5));
      }
    });

    test('rawOpenness is the mean of the four PIP angles', () {
      final lm = SyntheticHand.pose(curl: 0.5);
      final a = HandMetrics.pipAngles(lm);
      expect(HandMetrics.rawOpenness(lm), closeTo(a.reduce((x, y) => x + y) / 4, 1e-9));
    });
  });

  group('normalization by palm width', () {
    test('palm width is landmark 5 to 17', () {
      final lm = SyntheticHand.pose();
      final dx = lm[17].x - lm[5].x, dy = lm[17].y - lm[5].y;
      expect(HandMetrics.palmWidth(lm), closeTo(math.sqrt(dx * dx + dy * dy), 1e-12));
    });

    test('distances do not change with hand size or position', () {
      final near = SyntheticHand.pose(spread: 0.8, scale: 1.6, offsetX: 0.1);
      final far = SyntheticHand.pose(spread: 0.8, scale: 0.6);
      expect(HandMetrics.rawSpread(near), closeTo(HandMetrics.rawSpread(far), 1e-6));
      expect(HandMetrics.rawOpenness(near), closeTo(HandMetrics.rawOpenness(far), 1e-6));
      expect(
          HandMetrics.normalizedDistance(near, 0, 12),
          closeTo(HandMetrics.normalizedDistance(far, 0, 12), 1e-6));
    });

    test('spread grows when fingers spread', () {
      expect(HandMetrics.rawSpread(SyntheticHand.pose(spread: 1)),
          greaterThan(HandMetrics.rawSpread(SyntheticHand.pose(spread: 0))));
    });

    test('rejects the wrong number of landmarks', () {
      expect(() => HandMetrics.palmWidth(const [Point3(0, 0, 0)]),
          throwsArgumentError);
    });
  });

  group('percentOfRange (clamping)', () {
    test('maps the calibrated range to 0-100', () {
      expect(HandMetrics.percentOfRange(70, 70, 170), 0);
      expect(HandMetrics.percentOfRange(120, 70, 170), 50);
      expect(HandMetrics.percentOfRange(170, 70, 170), 100);
    });

    test('clamps below 0 and above 100', () {
      expect(HandMetrics.percentOfRange(10, 70, 170), 0);
      expect(HandMetrics.percentOfRange(250, 70, 170), 100);
    });

    test('an empty range gives 0 instead of dividing by zero', () {
      expect(HandMetrics.percentOfRange(100, 100, 100), 0);
    });
  });

  group('MovingAverage', () {
    test('averages the last 5 values', () {
      final m = MovingAverage(5);
      for (final v in <double>[10, 20, 30, 40, 50, 60]) {
        m.add(v);
      }
      expect(m.value, 40); // 20..60
    });
  });

  group('RangeCalibration', () {
    test('uses percentiles so one outlier does not stretch the range', () {
      final high = [for (var i = 0; i < 50; i++) 170.0, 260.0];
      final low = [for (var i = 0; i < 50; i++) 70.0, -40.0];
      final c = RangeCalibration.fromSamples(
          high: high, low: low, minSpan: RangeCalibration.minOpennessSpan)!;
      expect(c.max, 170);
      expect(c.min, 70);
    });

    test('too small a range fails', () {
      expect(
        RangeCalibration.fromSamples(
            high: [120, 121], low: [110, 111],
            minSpan: RangeCalibration.minOpennessSpan),
        isNull,
      );
    });
  });
}
