/// Builds plausible 21-landmark hands from a few pose parameters. Pure Dart.
///
/// Used by MockHandTracker and tests. Not anatomically exact; it only needs
/// PIP angles, fingertip spacing and thumb position to behave like a hand.
library;

import 'dart:math' as math;

import 'hand_metrics.dart';

class SyntheticHand {
  SyntheticHand._();

  static const _segment = 0.055; // finger bone length, in image units
  static const _wrist = Point3(0.5, 0.82, 0);

  // MCP positions, index to pinky. Palm width (index MCP to pinky MCP) 0.18.
  static const _mcps = [
    Point3(0.42, 0.62, 0),
    Point3(0.48, 0.60, 0),
    Point3(0.54, 0.61, 0),
    Point3(0.60, 0.64, 0),
  ];

  /// [curl]: 0 = fingers straight, 1 = fist (PIP bent 110 degrees).
  /// [spread]: 0 = fingers together, 1 = spread wide.
  /// [thumbOn]: fingertip index (8, 12, 16, 20) the thumb touches, or null.
  /// [scale] and [offsetX] move the whole hand (distance from camera).
  /// [fingerCurls]: per-finger curl (index to little), overriding [curl].
  /// [hook]: knuckles (MCP) straight while the finger joints bend.
  /// [wristPitch]: tilts the whole hand at the wrist, in degrees (a stand-in
  /// for wrist flexion with the forearm still).
  static List<Point3> pose({
    double curl = 0,
    double spread = 0.3,
    int? thumbOn,
    double scale = 1,
    double offsetX = 0,
    List<double>? fingerCurls,
    bool hook = false,
    double wristPitch = 0,
  }) {
    final pts = List<Point3>.filled(21, _wrist);
    pts[0] = _wrist;

    for (var f = 0; f < 4; f++) {
      final c = fingerCurls?[f] ?? curl;
      final pipBend = 110 * c * math.pi / 180;
      final mcpBend = hook ? 0.0 : 80 * c * math.pi / 180;
      final dipBend = 0.7 * pipBend;
      final fan = (f - 1.5) * (4 + 14 * spread) * math.pi / 180;
      final mcp = _mcps[f];
      // Direction in the image plane (fan), bending toward the camera (-z).
      Point3 dir(double bend) => Point3(
            math.sin(fan) * math.cos(bend),
            -math.cos(fan) * math.cos(bend),
            -math.sin(bend),
          );
      final pip = _add(mcp, dir(mcpBend), _segment);
      final dip = _add(pip, dir(mcpBend + pipBend), _segment * 0.8);
      final tip = _add(dip, dir(mcpBend + pipBend + dipBend), _segment * 0.7);
      final base = 5 + f * 4;
      pts[base] = mcp;
      pts[base + 1] = pip;
      pts[base + 2] = dip;
      pts[base + 3] = tip;
    }

    // Thumb: CMC, MCP, IP, tip. Rests to the side unless touching a finger.
    const cmc = Point3(0.40, 0.76, 0);
    const tmcp = Point3(0.34, 0.70, 0);
    final rest = const Point3(0.30, 0.62, -0.01);
    final tip = thumbOn == null
        ? rest
        : Point3(pts[thumbOn].x - 0.01, pts[thumbOn].y + 0.01, pts[thumbOn].z);
    pts[1] = cmc;
    pts[2] = tmcp;
    pts[3] = Point3((tmcp.x + tip.x) / 2, (tmcp.y + tip.y) / 2, tip.z / 2);
    pts[4] = tip;

    // Wrist tilt: rotate everything about the wrist, in the y-z plane.
    final a = wristPitch * math.pi / 180;
    final tilted = [
      for (final p in pts)
        Point3(
          p.x,
          _wrist.y + (p.y - _wrist.y) * math.cos(a) - p.z * math.sin(a),
          (p.y - _wrist.y) * math.sin(a) + p.z * math.cos(a),
        ),
    ];

    return [
      for (final p in tilted)
        Point3(
          _wrist.x + (p.x - _wrist.x) * scale + offsetX,
          _wrist.y + (p.y - _wrist.y) * scale,
          p.z * scale,
        ),
    ];
  }

  /// World landmarks in meters, like MediaPipe's handWorldLandmarks:
  /// origin near the middle of the hand, palm about 8 cm wide.
  ///
  /// The image-space pose above is a left hand with its palm toward the
  /// camera; [rightHand] mirrors it. Bend angles: MCP 80 x [curl], PIP
  /// 110 x [curl], DIP 77 x [curl] degrees.
  static List<Point3> world({
    double curl = 0,
    double spread = 0.3,
    int? thumbOn,
    bool rightHand = false,
    List<double>? fingerCurls,
    bool hook = false,
    double wristPitch = 0,
  }) {
    const metersPerUnit = 0.45; // palm 0.18 units -> about 8 cm
    final img = pose(
      curl: curl,
      spread: spread,
      thumbOn: thumbOn,
      fingerCurls: fingerCurls,
      hook: hook,
      wristPitch: wristPitch,
    );
    final c = img[9]; // middle MCP
    return [
      for (final p in img)
        Point3(
          (rightHand ? -1 : 1) * (p.x - c.x) * metersPerUnit,
          (p.y - c.y) * metersPerUnit,
          p.z * metersPerUnit,
        ),
    ];
  }

  static Point3 _add(Point3 p, Point3 d, double len) =>
      Point3(p.x + d.x * len, p.y + d.y * len, p.z + d.z * len);
}
