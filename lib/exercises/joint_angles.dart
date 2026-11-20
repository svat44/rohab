/// Finger joint angles in degrees from MediaPipe world landmarks. Pure Dart.
///
/// Convention (clinical goniometry): 0 degrees = straight, positive = flexed
/// (bent toward the palm), negative = hyperextended. Angles come from the
/// 3D world landmarks (metres), so they don't shrink when a finger bends
/// toward the camera, unlike angles from flat image coordinates.
///
/// Accuracy: studies of MediaPipe against goniometers and motion capture
/// report errors from about 4 to over 20 degrees depending on view and
/// joint (worst at the PIP). Use these numbers for practice and trends,
/// not diagnosis. See docs/rehab-science.md section 6.
library;

import 'dart:math' as math;

import '../camera/handedness.dart';
import 'hand_metrics.dart';

export '../camera/handedness.dart';

/// Flexion of one finger's three joints, in degrees.
class FingerAngles {
  const FingerAngles({required this.mcp, required this.pip, required this.dip});

  final double mcp;
  final double pip;
  final double dip;

  /// MCP + PIP + DIP. About 250-300 for a full fist, about 0 when straight.
  double get total => mcp + pip + dip;
}

class HandAngles {
  const HandAngles({
    required this.fingers,
    required this.thumbMcp,
    required this.thumbIp,
    required this.thumbAbduction,
  });

  /// Index, middle, ring, little.
  final List<FingerAngles> fingers;

  final double thumbMcp;
  final double thumbIp;

  /// Angle between the thumb and index metacarpals. Larger = thumb further
  /// from the hand.
  final double thumbAbduction;

  /// How closed the hand is: mean of the four fingers' total flexion.
  /// 0 = fully straight, about 250+ = fist.
  double get closure =>
      fingers.map((f) => f.total).reduce((a, b) => a + b) / fingers.length;

  static const fingerNames = ['index', 'middle', 'ring', 'little'];
}

class JointAngles {
  JointAngles._();

  /// Computes all angles from 21 world landmarks.
  ///
  /// [hand] is the person's real hand. The sign of flexion depends on it,
  /// because a left hand is a mirror image of a right hand. With
  /// [Handedness.unknown] the sign that makes the fingers more flexed on
  /// average is used, which can misread a hyperextended hand.
  static HandAngles compute(List<Point3> world, Handedness hand) {
    if (world.length != HandMetrics.landmarkCount) {
      throw ArgumentError.value(world.length, 'world', 'expected 21');
    }
    // Axis across the palm, index MCP toward little-finger MCP. Flexion is
    // rotation about this axis.
    final across = _normalize(world[HandIndex.pinkyMcp] - world[HandIndex.indexMcp]);

    List<double> rawFinger(int mcp) {
      final wrist = world[HandIndex.wrist];
      final m = world[mcp], p = world[mcp + 1], d = world[mcp + 2], t = world[mcp + 3];
      return [
        signedAngle(m - wrist, p - m, across),
        signedAngle(p - m, d - p, across),
        signedAngle(d - p, t - d, across),
      ];
    }

    final raw = [for (final mcp in HandIndex.fingerMcps) rawFinger(mcp)];

    // A real right hand flexes in the negative direction about this axis
    // in camera coordinates; a left hand in the positive.
    var sign = switch (hand) {
      Handedness.right => -1.0,
      Handedness.left => 1.0,
      Handedness.unknown => 0.0,
    };
    final sum = raw.expand((f) => f).reduce((a, b) => a + b);
    // A real hand can't average more than about 40 degrees past straight
    // (sum of three joints, four fingers). Beyond that the hand label is
    // wrong (the other hand is in view, or the model mislabelled it), so
    // the sign is flipped.
    const impossible = -40.0 * 4;
    if (sign == 0 || sign * sum < impossible) {
      sign = sum >= 0 ? 1.0 : -1.0;
    }

    // Thumb: unsigned (its axis of motion isn't the palm's).
    final w = world;
    final thumbMcp = flexion(w[1], w[2], w[3]);
    final thumbIp = flexion(w[2], w[3], w[4]);
    final thumbAbduction =
        _angleBetween(w[2] - w[1], w[HandIndex.indexMcp] - w[HandIndex.wrist]);

    return HandAngles(
      fingers: [
        for (final f in raw)
          FingerAngles(mcp: sign * f[0], pip: sign * f[1], dip: sign * f[2]),
      ],
      thumbMcp: thumbMcp,
      thumbIp: thumbIp,
      thumbAbduction: thumbAbduction,
    );
  }

  /// Rotation from segment [a] to segment [b] about [axis], in degrees,
  /// signed by the right-hand rule. Out-of-plane components are ignored.
  static double signedAngle(Point3 a, Point3 b, Point3 axis) {
    final c = _cross(a, b);
    final y = c.dot(axis);
    final x = a.dot(b);
    if (x == 0 && y == 0) return 0;
    return math.atan2(y, x) * 180 / math.pi;
  }

  /// Unsigned flexion at [joint]: 0 when [a], [joint], [b] are in a line.
  static double flexion(Point3 a, Point3 joint, Point3 b) =>
      _angleBetween(joint - a, b - joint);

  static double _angleBetween(Point3 u, Point3 v) {
    final d = u.length * v.length;
    if (d == 0) return 0;
    return math.acos((u.dot(v) / d).clamp(-1.0, 1.0)) * 180 / math.pi;
  }

  static Point3 _cross(Point3 a, Point3 b) => Point3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x,
      );

  static Point3 _normalize(Point3 v) {
    final l = v.length;
    return l == 0 ? v : Point3(v.x / l, v.y / l, v.z / l);
  }
}
