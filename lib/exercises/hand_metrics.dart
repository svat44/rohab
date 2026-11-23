/// Hand measurements from MediaPipe's 21 hand landmarks. Pure Dart.
///
/// Landmark indices (MediaPipe Hand Landmarker):
///   0 wrist; thumb 1-4; index 5-8; middle 9-12; ring 13-16; pinky 17-20.
///   For each finger: MCP, PIP, DIP, TIP.
library;

import 'dart:math' as math;

/// One landmark. x and y are in the same units on both axes (see
/// [HandPoints]); z is MediaPipe's relative depth, on roughly x's scale.
class Point3 {
  const Point3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  Point3 operator -(Point3 o) => Point3(x - o.x, y - o.y, z - o.z);

  double dot(Point3 o) => x * o.x + y * o.y + z * o.z;

  double get length => math.sqrt(dot(this));

  double distanceTo(Point3 o) => (this - o).length;

  @override
  String toString() => 'Point3($x, $y, $z)';
}

/// MediaPipe landmark indices used here.
class HandIndex {
  HandIndex._();
  static const wrist = 0;
  static const thumbTip = 4;
  static const indexMcp = 5;
  static const middleMcp = 9;
  static const ringMcp = 13;
  static const pinkyMcp = 17;
  static const indexTip = 8;
  static const middleTip = 12;
  static const ringTip = 16;
  static const pinkyTip = 20;

  /// MCP index of each finger, index to pinky. PIP = MCP + 1, DIP = MCP + 2.
  static const fingerMcps = [indexMcp, middleMcp, ringMcp, pinkyMcp];

  /// Fingertips, index to pinky, in touch order.
  static const fingertips = [indexTip, middleTip, ringTip, pinkyTip];
}

class HandMetrics {
  HandMetrics._();

  static const landmarkCount = 21;

  /// Distance from index MCP (5) to pinky MCP (17). All distances are
  /// normalized by it, so results don't depend on how far the hand is.
  static double palmWidth(List<Point3> lm) {
    _check(lm);
    return lm[HandIndex.indexMcp].distanceTo(lm[HandIndex.pinkyMcp]);
  }

  /// Distance between two landmarks in palm widths.
  static double normalizedDistance(List<Point3> lm, int a, int b) {
    final palm = palmWidth(lm);
    if (palm <= 0) return 0;
    return lm[a].distanceTo(lm[b]) / palm;
  }

  /// Angle at [joint] between [a] and [b], in degrees. 180 = straight.
  static double jointAngle(Point3 a, Point3 joint, Point3 b) {
    final u = a - joint;
    final v = b - joint;
    final denom = u.length * v.length;
    if (denom == 0) return 180;
    final cos = (u.dot(v) / denom).clamp(-1.0, 1.0);
    return math.acos(cos) * 180 / math.pi;
  }

  /// PIP angles for index, middle, ring and pinky, from (MCP, PIP, DIP).
  static List<double> pipAngles(List<Point3> lm) {
    _check(lm);
    return [
      for (final mcp in HandIndex.fingerMcps)
        jointAngle(lm[mcp], lm[mcp + 1], lm[mcp + 2]),
    ];
  }

  /// Mean of the four PIP angles, in degrees. Higher = more open.
  static double rawOpenness(List<Point3> lm) {
    final a = pipAngles(lm);
    return a.reduce((x, y) => x + y) / a.length;
  }

  /// Mean distance between adjacent fingertips (8-12, 12-16, 16-20), in
  /// palm widths. Higher = more spread.
  static double rawSpread(List<Point3> lm) {
    final d = [
      normalizedDistance(lm, HandIndex.indexTip, HandIndex.middleTip),
      normalizedDistance(lm, HandIndex.middleTip, HandIndex.ringTip),
      normalizedDistance(lm, HandIndex.ringTip, HandIndex.pinkyTip),
    ];
    return d.reduce((x, y) => x + y) / d.length;
  }

  /// Hand size for contact tests: the palm width, but never less than 85 %
  /// of the wrist-to-middle-knuckle length. A hand turned side-on makes the
  /// palm look narrow, which would inflate every distance; the palm length
  /// does not shrink the same way.
  static double handScale(List<Point3> lm) {
    _check(lm);
    final width = palmWidth(lm);
    final length = lm[HandIndex.wrist].distanceTo(lm[HandIndex.middleMcp]);
    return width > length * 0.85 ? width : length * 0.85;
  }

  /// Thumb tip to [fingertip], in hand sizes ([handScale]).
  static double touchGap(List<Point3> lm, int fingertip) {
    final scale = handScale(lm);
    if (scale <= 0) return double.infinity;
    return lm[HandIndex.thumbTip].distanceTo(lm[fingertip]) / scale;
  }

  /// Thumb tip to [fingertip] in palm widths.
  static double thumbTo(List<Point3> lm, int fingertip) =>
      normalizedDistance(lm, HandIndex.thumbTip, fingertip);

  /// Which way the palm faces along the camera axis: about +1 or -1 when
  /// it faces the camera or away from it, 0 when edge-on. Flips sign when
  /// the hand turns over. Which sign is "palm toward camera" depends on the
  /// hand, so callers compare against where they started.
  static double palmFacing(List<Point3> lm) {
    _check(lm);
    final n = _cross(
      lm[HandIndex.indexMcp] - lm[HandIndex.wrist],
      lm[HandIndex.pinkyMcp] - lm[HandIndex.wrist],
    );
    final l = n.length;
    return l == 0 ? 0 : n.z / l;
  }

  /// Height of each fingertip (index to pinky) above the palm's plane, in
  /// palm widths, positive on the side the palm normal points to.
  static List<double> palmHeights(List<Point3> lm) {
    _check(lm);
    final wrist = lm[HandIndex.wrist];
    final n = _cross(
      lm[HandIndex.indexMcp] - wrist,
      lm[HandIndex.pinkyMcp] - wrist,
    );
    final l = n.length;
    final palm = palmWidth(lm);
    if (l == 0 || palm == 0) return const [0, 0, 0, 0];
    return [
      for (final tip in HandIndex.fingertips)
        (lm[tip] - wrist).dot(n) / l / palm,
    ];
  }

  static Point3 _cross(Point3 a, Point3 b) => Point3(
    a.y * b.z - a.z * b.y,
    a.z * b.x - a.x * b.z,
    a.x * b.y - a.y * b.x,
  );

  /// Maps [raw] into 0-100 % of the user's calibrated range.
  static double percentOfRange(double raw, double min, double max) {
    final span = max - min;
    if (span <= 0) return 0;
    return ((raw - min) / span * 100).clamp(0.0, 100.0).toDouble();
  }

  static void _check(List<Point3> lm) {
    if (lm.length != landmarkCount) {
      throw ArgumentError.value(
        lm.length,
        'landmarks',
        'expected $landmarkCount',
      );
    }
  }
}

/// Moving average over the last [window] values.
class MovingAverage {
  MovingAverage(this.window) : assert(window > 0);

  final int window;
  final List<double> _values = [];

  double add(double v) {
    _values.add(v);
    if (_values.length > window) _values.removeAt(0);
    return value;
  }

  double get value =>
      _values.isEmpty ? 0 : _values.reduce((a, b) => a + b) / _values.length;

  void reset() => _values.clear();
}

/// A per-session range, learned from the user's own most-open and
/// most-closed hand. Uses the 90th / 10th percentiles so one noisy frame
/// can't stretch the range.
class RangeCalibration {
  const RangeCalibration({required this.min, required this.max});

  final double min;
  final double max;

  /// Smallest usable range: below this the open and closed hand could not
  /// be told apart (degrees for openness, palm widths for spread).
  static const minOpennessSpan = 25.0;
  static const minSpreadSpan = 0.08;

  /// Smallest usable range of finger bend (mean MCP + PIP + DIP), degrees.
  /// Below this, movement is too close to camera tracking error (about
  /// 10 degrees per joint) to count reliably.
  static const minClosureSpan = 30.0;

  static double percentile(List<double> values, double p) {
    if (values.isEmpty) throw ArgumentError('no values');
    final s = [...values]..sort();
    final i = ((s.length - 1) * p).round();
    return s[i];
  }

  /// [high]: raw values while asked to open/spread. [low]: while asked to
  /// close/bring together. Returns null if the range is too small.
  static RangeCalibration? fromSamples({
    required List<double> high,
    required List<double> low,
    required double minSpan,
  }) {
    if (high.isEmpty || low.isEmpty) return null;
    final max = percentile(high, 0.9);
    final min = percentile(low, 0.1);
    if (max - min < minSpan) return null;
    return RangeCalibration(min: min, max: max);
  }

  double percent(double raw) => HandMetrics.percentOfRange(raw, min, max);
}
