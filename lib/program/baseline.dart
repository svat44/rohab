/// Baseline hand measurement and level placement. Pure Dart.
library;

import '../camera/handedness.dart';

/// Active range of one hand: finger bend (mean MCP + PIP + DIP, degrees)
/// when opened as far as possible and when closed as far as possible.
class HandRange {
  const HandRange({required this.open, required this.closed});

  /// Bend at the most open. 0 = fully straight; larger = can't open fully.
  final double open;

  /// Bend at the most closed.
  final double closed;

  /// Range of motion in degrees.
  double get range => (closed - open).clamp(0, 400).toDouble();
}

class BaselineResult {
  const BaselineResult({
    required this.affectedHand,
    required this.affected,
    required this.other,
    required this.level,
    required this.cameraLimited,
    required this.takenAt,
  });

  final Handedness affectedHand;
  final HandRange affected;

  /// The other hand, as the person's own reference. Null if not measured.
  final HandRange? other;

  /// 1, 2 or 3.
  final int level;

  /// Movement is smaller than the camera measures reliably.
  final bool cameraLimited;
  final DateTime takenAt;

  /// Affected range as a share of the other hand's, 0-1, if known.
  double? get rangeRatio {
    final o = other;
    if (o == null || o.range <= 0) return null;
    return (affected.range / o.range).clamp(0, 1).toDouble();
  }

  static const recheckAfter = Duration(days: 7);

  bool isDueAt(DateTime now) => now.difference(takenAt) >= recheckAfter;
}

class LevelPlacement {
  LevelPlacement._();

  /// Below this range the camera can't count reliably (about 10 degrees of
  /// error per joint). Matches RangeCalibration.minClosureSpan.
  static const minCameraRange = 30.0;

  /// Can't straighten the fingers past this bend: an extension deficit
  /// that puts the person at level 1 whatever the range.
  static const severeOpenBend = 120.0;

  /// Placement rules (docs/rehab-science.md sections 1 and 9):
  /// - level 1: range below what the camera can count, less than half of
  ///   the other hand, or fingers can't straighten past 120 degrees of bend;
  /// - level 2: less than 85 % of the other hand;
  /// - level 3: otherwise.
  /// Without the other hand, 150 and 220 degrees stand in for 50 % and
  /// 85 % of a typical hand (about 260 degrees).
  static int place(HandRange affected, HandRange? other) {
    if (affected.range < minCameraRange) return 1;
    if (affected.open > severeOpenBend) return 1;
    final ratio = other == null || other.range <= 0
        ? affected.range / 260
        : affected.range / other.range;
    if (ratio < 0.5) return 1;
    if (ratio < 0.85) return 2;
    return 3;
  }

  static BaselineResult result({
    required Handedness affectedHand,
    required HandRange affected,
    HandRange? other,
    required DateTime takenAt,
  }) =>
      BaselineResult(
        affectedHand: affectedHand,
        affected: affected,
        other: other,
        level: place(affected, other),
        cameraLimited: affected.range < minCameraRange,
        takenAt: takenAt,
      );
}
