import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/exercises/hand_metrics.dart';
import 'package:rohab/exercises/rep_counter.dart';
import 'package:rohab/exercises/synthetic_hand.dart';

const frame = Duration(milliseconds: 33); // ~30 fps

/// Feeds [values] one frame apart starting at [start]; returns the end time.
Duration feed(HysteresisRepCounter c, Iterable<double> values,
    [Duration start = Duration.zero]) {
  var t = start;
  for (final v in values) {
    c.update(v, t);
    t += frame;
  }
  return t;
}

/// One open-close-open cycle of [frames] frames, as a cosine 100 -> 0 -> 100.
List<double> cycle(int frames) => [
      for (var i = 0; i < frames; i++) 50 + 50 * math.cos(2 * math.pi * i / frames),
    ];

void main() {
  group('HysteresisRepCounter', () {
    test('10 clean cycles count as 10', () {
      final c = HysteresisRepCounter();
      final values = [for (var i = 0; i < 10; i++) ...cycle(60), 100.0];
      feed(c, values);
      expect(c.reps, 10);
    });

    test('jitter around 50% never counts', () {
      final c = HysteresisRepCounter();
      feed(c, [100, 100]); // armed
      feed(c, [for (var i = 0; i < 300; i++) i.isEven ? 35.0 : 65.0],
          frame * 2);
      expect(c.reps, 0);
    });

    test('noise just inside the thresholds never counts', () {
      final c = HysteresisRepCounter();
      feed(c, [for (var i = 0; i < 300; i++) i.isEven ? 21.0 : 79.0]);
      expect(c.reps, 0);
    });

    test('reps shorter than 0.8 s are ignored', () {
      final c = HysteresisRepCounter();
      // 20 frames x 33 ms = 0.66 s per cycle.
      feed(c, [for (var i = 0; i < 5; i++) ...cycle(20), 100.0]);
      expect(c.reps, 0);
      // 30 frames = 0.99 s: counts.
      final d = HysteresisRepCounter();
      feed(d, [for (var i = 0; i < 5; i++) ...cycle(30), 100.0]);
      expect(d.reps, 5);
    });

    test('a too-fast rep does not swallow the next normal one', () {
      final c = HysteresisRepCounter();
      var t = feed(c, [100, 0, 100]); // 66 ms rep: ignored
      expect(c.reps, 0);
      t = feed(c, [for (var i = 0; i < 30; i++) 0.0, 100], t);
      expect(c.reps, 1);
    });

    test('pauses during dropout: a half rep before the gap does not count',
        () {
      final c = HysteresisRepCounter();
      var t = feed(c, [...cycle(60), 100.0]);
      expect(c.reps, 1);
      // Open, then close... hand lost for 3 s ... no frames fed.
      t = feed(c, [100, 60, 10], t);
      t += const Duration(seconds: 3);
      c.resetCycle();
      // Hand returns open: this alone must not complete the rep.
      t = feed(c, [100, 100], t);
      expect(c.reps, 1);
      // A full new rep counts.
      feed(c, [...cycle(60), 100.0], t);
      expect(c.reps, 2);
    });
  });

  group('FingerTouchCounter', () {
    /// Holds the thumb on [tip] for [ms], then releases for [ms].
    Duration touch(FingerTouchCounter c, int? tip, Duration t,
        {int ms = 300}) {
      for (var e = 0; e < ms; e += 33) {
        c.update(SyntheticHand.pose(thumbOn: tip), t);
        t += frame;
      }
      for (var e = 0; e < ms; e += 33) {
        c.update(SyntheticHand.pose(), t);
        t += frame;
      }
      return t;
    }

    test('index, middle, ring, pinky in order counts one round', () {
      final c = FingerTouchCounter();
      var t = Duration.zero;
      for (final tip in HandIndex.fingertips) {
        t = touch(c, tip, t);
      }
      expect(c.rounds, 1);
    });

    test('wrong order does not count', () {
      final c = FingerTouchCounter();
      var t = Duration.zero;
      for (final tip in [HandIndex.indexTip, HandIndex.ringTip,
          HandIndex.middleTip, HandIndex.pinkyTip]) {
        t = touch(c, tip, t);
      }
      expect(c.rounds, 0);
    });

    test('a wrong finger restarts; touching the index starts a new round',
        () {
      final c = FingerTouchCounter();
      var t = Duration.zero;
      for (final tip in [HandIndex.indexTip, HandIndex.middleTip,
          HandIndex.pinkyTip, // wrong: restart
          HandIndex.indexTip, HandIndex.middleTip, HandIndex.ringTip,
          HandIndex.pinkyTip]) {
        t = touch(c, tip, t);
      }
      expect(c.rounds, 1);
    });

    test('a touch shorter than 200 ms is ignored', () {
      final c = FingerTouchCounter();
      var t = Duration.zero;
      for (final tip in HandIndex.fingertips) {
        t = touch(c, tip, t, ms: 120);
      }
      expect(c.rounds, 0);
    });

    test('holding one finger counts it once', () {
      final c = FingerTouchCounter();
      var t = Duration.zero;
      for (var i = 0; i < 60; i++) {
        c.update(SyntheticHand.pose(thumbOn: HandIndex.indexTip), t);
        t += frame;
      }
      expect(c.expectedFinger, 1);
    });

    test('eight rounds count as eight', () {
      final c = FingerTouchCounter();
      var t = Duration.zero;
      for (var r = 0; r < 8; r++) {
        for (final tip in HandIndex.fingertips) {
          t = touch(c, tip, t);
        }
      }
      expect(c.rounds, 8);
    });
  });
}
