import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/exercises/exercise_catalog.dart';
import 'package:rohab/exercises/exercise_counters.dart';
import 'package:rohab/exercises/hand_metrics.dart';
import 'package:rohab/exercises/joint_angles.dart';
import 'package:rohab/exercises/synthetic_hand.dart';

HandSample sample(List<Point3> world,
    {double percent = 100, List<Point3>? image}) {
  return HandSample(
    points: world,
    angles: JointAngles.compute(world, Handedness.left),
    percent: percent,
    image: image,
  );
}

/// Turns the hand about the vertical axis through the wrist (palm over).
List<Point3> turnedAboutY(List<Point3> pts, double degrees) {
  final a = degrees * math.pi / 180;
  final w = pts[0];
  return [
    for (final p in pts)
      Point3(
        w.x + (p.x - w.x) * math.cos(a) + (p.z - w.z) * math.sin(a),
        p.y,
        w.z - (p.x - w.x) * math.sin(a) + (p.z - w.z) * math.cos(a),
      ),
  ];
}

/// Feeds [s] every 100 ms for [seconds]; returns the next time.
Duration feed(ExerciseCounter c, HandSample s, Duration from, double seconds,
    {List<bool>? counted}) {
  var t = from;
  final end = from + Duration(milliseconds: (seconds * 1000).round());
  while (t < end) {
    final r = c.update(s, t);
    counted?.add(r);
    t += const Duration(milliseconds: 100);
  }
  return t;
}

void main() {
  group('catalog', () {
    test('has the therapist exercises at the three levels', () {
      expect(ExerciseCatalog.all, hasLength(17));
      for (final id in [
        'finger_touches', // finger tapping / thumb opposition
        'wrist_stretch',
        'hold_open', // open and close, hold
        'wrist_rotation',
        'tabletop_finger_lift',
        'finger_extension_assisted',
        'hand_squeeze',
        'thumb_extension',
        'finger_walking',
        'hand_slide',
      ]) {
        expect(ExerciseCatalog.byId(id), isNotNull, reason: id);
      }
      for (final level in [1, 2, 3]) {
        expect(ExerciseCatalog.forLevel(level).length, greaterThanOrEqualTo(5));
      }
    });

    test('every exercise has a target and at most four steps', () {
      for (final e in ExerciseCatalog.all) {
        expect(e.target, isNotNull, reason: e.id);
        expect(e.steps.length, inInclusiveRange(1, 4), reason: e.id);
        // Builds a counter without throwing.
        ExerciseCounter.forKind(e.kind, high: e.repHigh, low: e.repLow);
      }
    });

    test('wrist exercises do not report finger range or flag the wrist', () {
      for (final id in ['wrist_stretch', 'wrist_rotation', 'hand_slide']) {
        final e = ExerciseCatalog.byId(id)!;
        expect(e.movesWrist, isTrue);
        expect(e.reportsRange, isFalse);
        expect(e.needsRange, isFalse);
      }
      expect(ExerciseCatalog.openClose.movesWrist, isFalse);
      expect(ExerciseCatalog.openClose.reportsRange, isTrue);
    });
  });

  group('hand squeeze and finger stretch (5 s holds)', () {
    test('a squeeze counts after 5 s and needs a release', () {
      final c = ExerciseCounter.forKind(ExerciseKind.squeeze);
      final fist = sample(SyntheticHand.world(curl: 1), percent: 5);
      final flags = <bool>[];
      var t = feed(c, fist, Duration.zero, 4.5, counted: flags);
      expect(c.count, 0);
      t = feed(c, fist, t, 1, counted: flags);
      expect(c.count, 1);
      // Still squeezing: no second count until released.
      t = feed(c, fist, t, 6);
      expect(c.count, 1);
      t = feed(c, sample(SyntheticHand.world(), percent: 90), t, 0.5);
      feed(c, fist, t, 5.5);
      expect(c.count, 2);
    });

    test('a short squeeze does not count', () {
      final c = ExerciseCounter.forKind(ExerciseKind.squeeze);
      var t = feed(c, sample(SyntheticHand.world(curl: 1), percent: 5),
          Duration.zero, 3);
      feed(c, sample(SyntheticHand.world(), percent: 90), t, 1);
      expect(c.count, 0);
    });

    test('assisted finger stretch counts a 5 s open hold', () {
      final c = ExerciseCounter.forKind(ExerciseKind.assistedExtension);
      feed(c, sample(SyntheticHand.world(), percent: 85), Duration.zero, 5.2);
      expect(c.count, 1);
    });
  });

  group('thumb extension', () {
    HandSample thumb(double abduction) {
      final w = SyntheticHand.world();
      final a = JointAngles.compute(w, Handedness.left);
      return HandSample(
        points: w,
        percent: 100,
        angles: HandAngles(
          fingers: a.fingers,
          thumbMcp: a.thumbMcp,
          thumbIp: a.thumbIp,
          thumbAbduction: abduction,
        ),
      );
    }

    test('thumb out for 5 s counts, thumb in does not', () {
      final c = ExerciseCounter.forKind(ExerciseKind.thumbExtension);
      var t = feed(c, thumb(15), Duration.zero, 6);
      expect(c.count, 0);
      t = feed(c, thumb(50), t, 5.2);
      expect(c.count, 1);
    });
  });

  group('wrist stretch', () {
    test('bending the wrist out and back counts one rep, each time', () {
      final c = WristBendCounter();
      var t = Duration.zero;
      t = feed(c, sample(SyntheticHand.world()), t, 1.5);
      expect(c.hint, contains('bend'));
      expect(c.count, 0);
      t = feed(c, sample(SyntheticHand.world(wristPitch: 30)), t, 1);
      expect(c.count, 0, reason: 'bent but not back yet');
      expect(c.hint, contains('back'));
      t = feed(c, sample(SyntheticHand.world()), t, 0.5);
      expect(c.count, 1);
      t = feed(c, sample(SyntheticHand.world(wristPitch: -30)), t, 1);
      feed(c, sample(SyntheticHand.world()), t, 0.5);
      expect(c.count, 2, reason: 'either direction counts');
    });

    test('a small wobble does not count', () {
      final c = WristBendCounter();
      var t = feed(c, sample(SyntheticHand.world()), Duration.zero, 1.5);
      t = feed(c, sample(SyntheticHand.world(wristPitch: 8)), t, 1);
      feed(c, sample(SyntheticHand.world()), t, 1);
      expect(c.count, 0);
    });
  });

  group('wrist rotation', () {
    test('palm over and back is one rep, from either starting side', () {
      for (final startAngle in [0.0, 180.0]) {
        final c = PalmRotationCounter();
        final base = SyntheticHand.world();
        HandSample at(double a) => sample(turnedAboutY(base, startAngle + a));
        var t = feed(c, at(0), Duration.zero, 0.5);
        for (final a in <double>[30, 60, 90, 120, 150, 180]) {
          t = feed(c, at(a), t, 0.2);
        }
        expect(c.count, 0, reason: 'turned over, not back yet');
        expect(c.hint, contains('back'));
        for (final a in <double>[150, 120, 90, 60, 30, 0]) {
          t = feed(c, at(a), t, 0.2);
        }
        expect(c.count, 1, reason: 'start $startAngle');
      }
    });

    test('a quarter turn is not enough', () {
      final c = PalmRotationCounter();
      final base = SyntheticHand.world();
      var t = feed(c, sample(base), Duration.zero, 0.5);
      t = feed(c, sample(turnedAboutY(base, 80)), t, 0.5);
      feed(c, sample(base), t, 0.5);
      expect(c.count, 0);
    });
  });

  group('hand slide', () {
    test('sliding out about a palm and a half and back counts', () {
      final c = SlideCounter();
      final world = SyntheticHand.world();
      HandSample at(double dx) => sample(world,
          image: SyntheticHand.pose(offsetX: dx, scale: 1));
      var t = feed(c, at(0), Duration.zero, 0.5);
      t = feed(c, at(0.08), t, 0.3);
      expect(c.count, 0);
      t = feed(c, at(0.2), t, 0.3);
      feed(c, at(0.02), t, 0.3);
      expect(c.count, 1);
    });

    test('moving the whole hand closer to the camera is not a slide', () {
      final c = SlideCounter();
      final world = SyntheticHand.world();
      var t = feed(c, sample(world, image: SyntheticHand.pose()),
          Duration.zero, 0.5);
      t = feed(c, sample(world, image: SyntheticHand.pose(scale: 1.4)), t, 0.5);
      feed(c, sample(world, image: SyntheticHand.pose()), t, 0.5);
      expect(c.count, 0);
    });
  });

  group('tabletop finger lift and finger walking', () {
    List<Point3> lifted(int? finger) {
      final w = SyntheticHand.world();
      if (finger == null) return w;
      final tip = HandIndex.fingertips[finger];
      return [
        for (var i = 0; i < w.length; i++)
          // Raise the whole finger (its three upper joints and the tip).
          (i >= tip - 2 && i <= tip)
              ? Point3(w[i].x, w[i].y, w[i].z - 0.04)
              : w[i],
      ];
    }

    Duration lift(ExerciseCounter c, int finger, Duration t) {
      t = feed(c, sample(lifted(finger)), t, 0.5);
      return feed(c, sample(lifted(null)), t, 0.3);
    }

    test('lifting index to little in order is one round', () {
      final c = FlatFingerLiftCounter();
      var t = Duration.zero;
      for (final f in [0, 1, 2, 3]) {
        t = lift(c, f, t);
      }
      expect(c.count, 1);
    });

    test('the wrong order restarts the round', () {
      final c = FlatFingerLiftCounter();
      var t = Duration.zero;
      for (final f in [0, 2, 1, 3]) {
        t = lift(c, f, t);
      }
      expect(c.count, 0);
    });

    test('walking is forward then back: seven steps', () {
      final c = FlatFingerLiftCounter(order: FlatFingerLiftCounter.walkingOrder);
      var t = Duration.zero;
      for (final f in [0, 1, 2, 3]) {
        t = lift(c, f, t);
      }
      expect(c.count, 0, reason: 'still has to walk back');
      expect(c.hint, contains('ring'));
      for (final f in [2, 1, 0]) {
        t = lift(c, f, t);
      }
      expect(c.count, 1);
    });

    test('a flat hand does not count anything', () {
      final c = FlatFingerLiftCounter();
      feed(c, sample(lifted(null)), Duration.zero, 3);
      expect(c.count, 0);
    });
  });

  group('live meter and clear guidance', () {
    test('pinch: the meter fills as the thumb nears the index fingertip', () {
      final c = ExerciseCounter.forKind(ExerciseKind.pinch);
      final apart = sample(SyntheticHand.world());
      final touching = sample(SyntheticHand.world(thumbOn: HandIndex.indexTip));
      c.update(apart, Duration.zero);
      final far = c.meter!;
      expect(c.hint, contains('thumb'));
      c.update(touching, const Duration(milliseconds: 100));
      expect(c.meter!, greaterThan(far));
      expect(c.hint, contains('Hold'));
    });

    test('pinch: thumb and index together counts one pinch, then needs a release',
        () {
      final c = ExerciseCounter.forKind(ExerciseKind.pinch);
      final touching = sample(SyntheticHand.world(thumbOn: HandIndex.indexTip));
      var t = feed(c, touching, Duration.zero, 1);
      expect(c.count, 1);
      t = feed(c, touching, t, 2);
      expect(c.count, 1, reason: 'held pinch must not count again');
      t = feed(c, sample(SyntheticHand.world()), t, 0.5);
      feed(c, touching, t, 1);
      expect(c.count, 2);
    });

    test('pinch: a slightly loose touch (0.28 palm widths) still counts', () {
      final c = ExerciseCounter.forKind(ExerciseKind.pinch);
      final w = SyntheticHand.world(thumbOn: HandIndex.indexTip);
      final palm = HandMetrics.palmWidth(w);
      final tip = w[HandIndex.indexTip];
      final loose = [
        for (var i = 0; i < w.length; i++)
          i == 4 ? Point3(tip.x - 0.28 * palm, tip.y, tip.z) : w[i],
      ];
      feed(c, sample(loose), Duration.zero, 1);
      expect(c.count, 1);
    });

    test('finger tapping tells which finger is next and fills toward it', () {
      final c = ExerciseCounter.forKind(ExerciseKind.fingerTouches);
      c.update(sample(SyntheticHand.world()), Duration.zero);
      final far = c.meter!;
      expect(c.hint, contains('index'));
      expect(c.hint, contains('1 of 4'));
      c.update(sample(SyntheticHand.world(thumbOn: HandIndex.indexTip)),
          const Duration(milliseconds: 100));
      expect(c.meter!, greaterThan(far));
      expect(c.meter!, closeTo(1, 0.01));
    });

    test('open and close: the goal line moves between the two targets', () {
      final c = ExerciseCounter.forKind(ExerciseKind.openClose);
      c.update(sample(SyntheticHand.world(), percent: 10), Duration.zero);
      expect(c.hint, contains('Open'));
      expect(c.marker, closeTo(0.8, 1e-9));
      expect(c.meter, closeTo(0.1, 1e-9));
      c.update(sample(SyntheticHand.world(), percent: 90),
          const Duration(seconds: 1));
      expect(c.hint, contains('fist'));
      expect(c.marker, closeTo(0.2, 1e-9));
    });

    test('a hold counts down in seconds and the bar fills with it', () {
      final c = ExerciseCounter.forKind(ExerciseKind.squeeze);
      final fist = sample(SyntheticHand.world(curl: 1), percent: 5);
      var t = feed(c, fist, Duration.zero, 2);
      expect(c.hint, contains('s'));
      final mid = c.meter!;
      expect(mid, inExclusiveRange(0.4, 1.0));
      t = feed(c, fist, t, 2);
      expect(c.meter!, greaterThan(mid));
    });

    test('a wrist exercise ignores finger opening (its bar is its own)', () {
      final c = ExerciseCounter.forKind(ExerciseKind.wristRotation);
      final flat = sample(SyntheticHand.world());
      // The same hand posture with wildly different "opening" gives the
      // same meter: it follows the palm turning, nothing else.
      c.update(HandSample(points: flat.points, angles: flat.angles, percent: 5),
          Duration.zero);
      final a = c.meter;
      c.update(HandSample(points: flat.points, angles: flat.angles, percent: 95),
          const Duration(milliseconds: 100));
      expect(c.meter, a);
    });
  });
}
