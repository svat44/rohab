import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/exercises/exercise_catalog.dart';
import 'package:rohab/exercises/exercise_counters.dart';
import 'package:rohab/exercises/hand_metrics.dart';
import 'package:rohab/exercises/joint_angles.dart';
import 'package:rohab/exercises/synthetic_hand.dart';

const frame = Duration(milliseconds: 33);

HandSample sample({
  double curl = 0,
  double percent = 0,
  List<double>? fingerCurls,
  bool hook = false,
  int? thumbOn,
}) {
  final w = SyntheticHand.world(
      curl: curl, fingerCurls: fingerCurls, hook: hook, thumbOn: thumbOn);
  return HandSample(
    points: w,
    angles: JointAngles.compute(w, Handedness.left),
    percent: percent,
  );
}

/// Feeds [s] for [ms] milliseconds starting at [t]; returns the end time.
Duration hold(ExerciseCounter c, HandSample s, Duration t, int ms) {
  for (var e = 0; e < ms; e += 33) {
    c.update(s, t);
    t += frame;
  }
  return t;
}

void main() {
  test('hold open: counts a 3 s hold, then needs a relax', () {
    final c = ExerciseCounter.forKind(ExerciseKind.holdOpen);
    var t = hold(c, sample(percent: 90), Duration.zero, 2500);
    expect(c.count, 0, reason: 'only 2.5 s');
    t = hold(c, sample(percent: 90), t, 800);
    expect(c.count, 1);
    t = hold(c, sample(percent: 90), t, 4000);
    expect(c.count, 1, reason: 'still holding: not a new rep');
    t = hold(c, sample(percent: 20), t, 500);
    hold(c, sample(percent: 90), t, 3200);
    expect(c.count, 2);
  });

  test('gentle open/close counts at 70 % / 30 %', () {
    final c = ExerciseCounter.forKind(ExerciseKind.openCloseGentle);
    var t = Duration.zero;
    for (var i = 0; i < 4; i++) {
      t = hold(c, sample(percent: 75), t, 500);
      t = hold(c, sample(percent: 25), t, 500);
    }
    hold(c, sample(percent: 75), t, 500);
    expect(c.count, 4);
  });

  test('cylinder: partly closed and held 2 s, then released', () {
    final c = ExerciseCounter.forKind(ExerciseKind.cylinder);
    var t = hold(c, sample(percent: 5), Duration.zero, 3000);
    expect(c.count, 0, reason: 'a full fist is not a cup grip');
    t = hold(c, sample(percent: 40), t, 2100);
    expect(c.count, 1);
    t = hold(c, sample(percent: 90), t, 300);
    hold(c, sample(percent: 40), t, 2100);
    expect(c.count, 2);
  });

  test('hook: knuckles straight and finger joints bent', () {
    expect(ExerciseCounter.isHook(sample(curl: 0.8, hook: true)), isTrue);
    expect(ExerciseCounter.isHook(sample(curl: 1)), isFalse, reason: 'fist');
    expect(ExerciseCounter.isHook(sample()), isFalse, reason: 'open');
    final c = ExerciseCounter.forKind(ExerciseKind.hook);
    var t = hold(c, sample(curl: 0.8, hook: true, percent: 30), Duration.zero, 1100);
    expect(c.count, 1);
    t = hold(c, sample(percent: 90), t, 300);
    hold(c, sample(curl: 0.8, hook: true, percent: 30), t, 1100);
    expect(c.count, 2);
  });

  test('pinch: thumb to index tip, then apart', () {
    final c = ExerciseCounter.forKind(ExerciseKind.pinch);
    var t = Duration.zero;
    for (var i = 0; i < 3; i++) {
      t = hold(c, sample(thumbOn: HandIndex.indexTip), t, 400);
      t = hold(c, sample(), t, 400);
    }
    expect(c.count, 3);
    // Thumb to the middle finger is not an index pinch.
    hold(c, sample(thumbOn: HandIndex.middleTip), t, 600);
    expect(c.count, 3);
  });

  group('finger lifts', () {
    List<double> lift(int f) => [for (var i = 0; i < 4; i++) i == f ? 0.0 : 0.9];

    test('index, middle, ring, little in order is one round', () {
      final c = ExerciseCounter.forKind(ExerciseKind.fingerLifts);
      var t = Duration.zero;
      for (var f = 0; f < 4; f++) {
        t = hold(c, sample(fingerCurls: lift(f)), t, 500);
        t = hold(c, sample(curl: 0.9), t, 300);
      }
      expect(c.count, 1);
    });

    test('wrong order does not count', () {
      final c = ExerciseCounter.forKind(ExerciseKind.fingerLifts);
      var t = Duration.zero;
      for (final f in [0, 2, 1, 3]) {
        t = hold(c, sample(fingerCurls: lift(f)), t, 500);
        t = hold(c, sample(curl: 0.9), t, 300);
      }
      expect(c.count, 0);
    });

    test('lifting all fingers together is not a lift', () {
      final c = ExerciseCounter.forKind(ExerciseKind.fingerLifts);
      hold(c, sample(), Duration.zero, 1000);
      expect(c.count, 0);
    });
  });

  group('wrist monitor', () {
    test('ignores finger movement, flags wrist tilt over 25 degrees', () {
      final m = WristMonitor();
      for (var i = 0; i < 10; i++) {
        m.update(SyntheticHand.world());
      }
      m.update(SyntheticHand.world(curl: 1));
      expect(m.moved, isFalse, reason: 'closing the fingers is fine');
      m.update(SyntheticHand.world(wristPitch: 15));
      expect(m.moved, isFalse);
      m.update(SyntheticHand.world(wristPitch: 35));
      expect(m.moved, isTrue);
      expect(m.deviation, closeTo(35, 2));
    });

    test('reset takes a new reference', () {
      final m = WristMonitor();
      for (var i = 0; i < 10; i++) {
        m.update(SyntheticHand.world());
      }
      m.reset();
      for (var i = 0; i < 10; i++) {
        m.update(SyntheticHand.world(wristPitch: 40));
      }
      m.update(SyntheticHand.world(wristPitch: 40));
      expect(m.moved, isFalse);
    });
  });
}
