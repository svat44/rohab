import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/exercises/movement_quality.dart';

Duration ms(num v) => Duration(microseconds: (v * 1000).round());

void main() {
  group('OneEuroFilter', () {
    test('smooths jitter while the hand is still', () {
      final f = OneEuroFilter();
      final r = math.Random(1);
      final out = <double>[];
      for (var i = 0; i < 300; i++) {
        out.add(f.filter(100 + (r.nextDouble() - 0.5) * 20, ms(i * 33.3)));
      }
      final tail = out.skip(100).toList();
      final mean = tail.reduce((a, b) => a + b) / tail.length;
      final sd = math.sqrt(
          tail.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
              tail.length);
      // Input SD is 20 / sqrt(12) = 5.8.
      expect(sd, lessThan(5.8 * 0.4));
      expect(mean, closeTo(100, 1.5));
    });

    test('follows a fast movement with little lag', () {
      final f = OneEuroFilter();
      double y = 0;
      for (var i = 0; i < 60; i++) {
        y = f.filter(i < 10 ? 0 : 200, ms(i * 33.3));
      }
      expect(y, closeTo(200, 5));
    });

    test('first value passes through', () {
      expect(OneEuroFilter().filter(42, Duration.zero), 42);
    });
  });

  group('SPARC smoothness', () {
    List<double> bell(int n) =>
        [for (var i = 0; i < n; i++) math.pow(math.sin(math.pi * i / (n - 1)), 2).toDouble()];

    test('a single smooth movement scores about -1.4 to -1.6', () {
      expect(sparc(bell(60), sampleRateHz: 30), inInclusiveRange(-1.8, -1.3));
    });

    test('a jerky movement scores lower than a smooth one', () {
      final smooth = bell(60);
      final jerky = [
        for (var i = 0; i < 60; i++)
          smooth[i] * (0.6 + 0.4 * math.cos(2 * math.pi * 6 * i / 60).abs()),
      ];
      expect(sparc(jerky, sampleRateHz: 30),
          lessThan(sparc(smooth, sampleRateHz: 30)));
    });

    test('does not depend on movement size', () {
      final a = sparc(bell(60), sampleRateHz: 30);
      final b = sparc([for (final v in bell(60)) v * 50], sampleRateHz: 30);
      expect(a, closeTo(b, 1e-9));
    });
  });

  group('RepRecorder', () {
    test('measures amplitude, duration and peak speed of a rep', () {
      final r = RepRecorder();
      for (var i = 0; i <= 30; i++) {
        // 0 -> 120 -> 0 degrees over 1 s.
        r.add(120 * math.sin(math.pi * i / 30), ms(i * 1000 / 30));
      }
      final s = r.close()!;
      expect(s.amplitude, closeTo(120, 0.5));
      expect(s.duration, ms(1000));
      expect(s.peakSpeed, closeTo(120 * math.pi, 15)); // derivative peak
      expect(s.smoothness, lessThan(0));
    });
  });

  group('FatigueMonitor', () {
    test('flags when recent reps are much smaller', () {
      final f = FatigueMonitor();
      for (final a in <double>[100, 98, 102, 99, 101, 100, 85, 70, 65, 60, 55, 50]) {
        f.add(a);
      }
      expect(f.isFatigued, isTrue);
    });

    test('steady reps are not fatigue', () {
      final f = FatigueMonitor();
      for (var i = 0; i < 20; i++) {
        f.add(100.0 + (i.isEven ? 5 : -5));
      }
      expect(f.isFatigued, isFalse);
    });

    test('needs enough reps before judging', () {
      final f = FatigueMonitor()..add(100)..add(10);
      expect(f.isFatigued, isFalse);
    });
  });

  group('ExcursionTracker', () {
    test('reports each swing between turning points', () {
      final x = ExcursionTracker(deadband: 10);
      final out = <double>[];
      for (final v in <double>[0, 50, 100, 60, 0, 40, 80, 75, 30]) {
        final e = x.update(v);
        if (e != null) out.add(e);
      }
      expect(out, [100, 100, 80]);
    });

    test('ignores wiggles inside the deadband', () {
      final x = ExcursionTracker(deadband: 10);
      final out = [
        for (final v in <double>[50, 55, 48, 56, 51, 54]) x.update(v),
      ].whereType<double>();
      expect(out, isEmpty);
    });
  });
}
