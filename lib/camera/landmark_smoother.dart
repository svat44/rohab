/// Smooths the 21 hand landmarks frame to frame. Pure Dart.
///
/// MediaPipe's points wobble by a few pixels every frame even when the hand
/// is still. That shakes the drawn skeleton and, worse, pushes distances and
/// angles back and forth across the counting thresholds (a pinch flickers
/// between touching and not touching). One Euro filter on every coordinate:
/// strong smoothing when the hand is still, almost none when it moves fast,
/// so it does not feel laggy.
library;

import '../exercises/hand_metrics.dart';
import '../exercises/movement_quality.dart';

class LandmarkSmoother {
  LandmarkSmoother({
    this.minCutoff = 1.2,
    // Speeds differ by units: image points move about 0-1 per second, world
    // points (meters) about 0-0.5, so the speed coefficients differ too.
    this.imageBeta = 3.0,
    this.worldBeta = 15.0,
    this.resetAfter = const Duration(milliseconds: 400),
  });

  final double minCutoff;
  final double imageBeta;
  final double worldBeta;

  /// A longer gap between frames (hand out of view) starts fresh instead of
  /// gliding from the old position.
  final Duration resetAfter;

  late final List<OneEuroFilter> _image = _bank(imageBeta);
  late final List<OneEuroFilter> _world = _bank(worldBeta);
  Duration? _last;

  List<OneEuroFilter> _bank(double beta) => [
    for (var i = 0; i < HandMetrics.landmarkCount * 3; i++)
      OneEuroFilter(minCutoff: minCutoff, beta: beta, dCutoff: 1.0),
  ];

  /// Call once per frame, before [smoothImage] and [smoothWorld].
  void beginFrame(Duration t) {
    final last = _last;
    if (last != null && t - last > resetAfter) reset();
    _last = t;
  }

  /// Palm length (wrist to middle knuckle) the defaults were tuned for, in
  /// image units: a hand about 40 cm from the phone.
  static const referenceScale = 0.15;

  /// How big the hand is now relative to the reference. A far hand is small:
  /// its pixel noise is a bigger share of the hand and it moves fewer
  /// pixels per second, so it needs more smoothing and a lower speed
  /// threshold; a near hand the opposite. Without this the same movement
  /// behaves differently at different distances.
  double _size = 1;

  List<Point3> smoothImage(List<Point3> pts, Duration t) {
    if (pts.length == HandMetrics.landmarkCount) {
      final palm = pts[HandIndex.wrist].distanceTo(pts[HandIndex.middleMcp]);
      _size = (palm / referenceScale).clamp(0.4, 2.5).toDouble();
    }
    return _run(_image, pts, t, imageBeta);
  }

  List<Point3> smoothWorld(List<Point3> pts, Duration t) =>
      _run(_world, pts, t, worldBeta);

  List<Point3> _run(
    List<OneEuroFilter> bank,
    List<Point3> pts,
    Duration t,
    double beta,
  ) {
    if (pts.length != HandMetrics.landmarkCount) return pts;
    // Smaller hand: lower cutoff (smoother) and a larger beta per unit of
    // speed; bigger hand the reverse.
    final cutoff = minCutoff * _size.clamp(0.6, 1.5);
    final b = beta / _size;
    return [
      for (var i = 0; i < pts.length; i++)
        Point3(
          bank[i * 3].filter(pts[i].x, t, minCutoff: cutoff, beta: b),
          bank[i * 3 + 1].filter(pts[i].y, t, minCutoff: cutoff, beta: b),
          bank[i * 3 + 2].filter(pts[i].z, t, minCutoff: cutoff, beta: b),
        ),
    ];
  }

  void reset() {
    for (final f in _image) {
      f.reset();
    }
    for (final f in _world) {
      f.reset();
    }
    _last = null;
  }
}
