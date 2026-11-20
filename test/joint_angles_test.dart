import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/exercises/hand_metrics.dart';
import 'package:rohab/exercises/joint_angles.dart';
import 'package:rohab/exercises/synthetic_hand.dart';

void main() {
  group('signedAngle', () {
    const x = Point3(1, 0, 0);
    test('straight segments are 0 degrees', () {
      expect(JointAngles.signedAngle(const Point3(0, -1, 0),
          const Point3(0, -1, 0), x), closeTo(0, 1e-9));
    });

    test('a 90 degree bend is +90 one way and -90 the other', () {
      expect(JointAngles.signedAngle(const Point3(0, -1, 0),
          const Point3(0, 0, -1), x), closeTo(90, 1e-9));
      expect(JointAngles.signedAngle(const Point3(0, -1, 0),
          const Point3(0, 0, 1), x), closeTo(-90, 1e-9));
    });

    test('unsigned flexion of a straight line is 0', () {
      expect(
          JointAngles.flexion(const Point3(0, 0, 0), const Point3(0, 1, 0),
              const Point3(0, 2, 0)),
          closeTo(0, 1e-9));
    });
  });

  group('world-landmark finger angles', () {
    for (final right in [false, true]) {
      final hand = right ? Handedness.right : Handedness.left;
      final name = right ? 'right' : 'left';

      test('$name hand: open hand is about 0 at every joint', () {
        final a = JointAngles.compute(SyntheticHand.world(rightHand: right), hand);
        for (final f in a.fingers) {
          expect(f.mcp, closeTo(0, 3));
          expect(f.pip, closeTo(0, 1));
          expect(f.dip, closeTo(0, 1));
        }
        expect(a.closure, closeTo(0, 5));
      });

      test('$name hand: fist reads as positive flexion of the built angles',
          () {
        final a = JointAngles.compute(
            SyntheticHand.world(curl: 1, rightHand: right), hand);
        for (final f in a.fingers) {
          expect(f.mcp, closeTo(30, 3));
          expect(f.pip, closeTo(110, 2));
          expect(f.dip, closeTo(77, 2));
        }
        expect(a.closure, closeTo(217, 6));
      });

      test('$name hand: half curl is about half', () {
        final a = JointAngles.compute(
            SyntheticHand.world(curl: 0.5, rightHand: right), hand);
        expect(a.fingers[1].pip, closeTo(55, 2));
      });
    }

    test('the wrong hand label flips the sign', () {
      final a = JointAngles.compute(
          SyntheticHand.world(curl: 1), Handedness.right);
      expect(a.fingers[0].pip, lessThan(0));
    });

    test('unknown hand picks the sign that reads a fist as flexed', () {
      for (final right in [false, true]) {
        final a = JointAngles.compute(
            SyntheticHand.world(curl: 1, rightHand: right), Handedness.unknown);
        expect(a.fingers[0].pip, closeTo(110, 2));
      }
    });

    test('angles do not depend on hand size', () {
      final small = SyntheticHand.world(curl: 0.6);
      final big = [for (final p in small) Point3(p.x * 1.4, p.y * 1.4, p.z * 1.4)];
      final a = JointAngles.compute(small, Handedness.left);
      final b = JointAngles.compute(big, Handedness.left);
      expect(b.closure, closeTo(a.closure, 1e-6));
    });

    test('thumb abduction is the angle between thumb and index metacarpals',
        () {
      // Synthetic: thumb metacarpal (-0.06, -0.06), index (-0.08, -0.20).
      final a = JointAngles.compute(SyntheticHand.world(), Handedness.left);
      expect(a.thumbAbduction, closeTo(23.2, 0.5));
    });

    test('rejects the wrong landmark count', () {
      expect(() => JointAngles.compute(const [], Handedness.left),
          throwsArgumentError);
    });
  });
}
