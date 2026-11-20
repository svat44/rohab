import 'package:material_ui/material_ui.dart';

import '../exercises/hand_metrics.dart';

enum Handedness { left, right, unknown }

/// One processed camera frame with a hand in it.
class HandFrame {
  const HandFrame({
    required this.landmarks,
    required this.handedness,
    required this.confidence,
    required this.timestamp,
    this.aspectRatio = 1,
  });

  /// Frames below this confidence are ignored.
  static const minConfidence = 0.6;

  /// 21 landmarks. x and y normalized to the image (0-1), z MediaPipe's
  /// relative depth.
  final List<Point3> landmarks;

  /// The user's actual hand (already corrected for the unmirrored front
  /// camera).
  final Handedness handedness;

  /// 0-1. MediaPipe's handedness score.
  final double confidence;

  /// Monotonic time of the camera frame.
  final Duration timestamp;

  /// Image width / height after rotation. Needed because x and y are
  /// normalized separately.
  final double aspectRatio;

  bool get isUsable => confidence >= minConfidence;

  /// Landmarks with x scaled so x and y share units, for angle and
  /// distance math.
  List<Point3> get points => [
        for (final p in landmarks) Point3(p.x * aspectRatio, p.y, p.z * aspectRatio),
      ];
}

class TrackerStats {
  const TrackerStats({this.framesPerSecond = 0, this.droppedFrames = 0});

  /// Frames processed per second over the last second.
  final double framesPerSecond;

  /// Frames skipped because the tracker was still busy (never queued).
  final int droppedFrames;
}

/// Something that watches the camera and reports hands.
///
/// Implementations: [MediaPipeHandTracker] (front camera + MediaPipe) and
/// [MockHandTracker] (tests and the web preview).
abstract class HandTracker {
  /// Frames that contain a hand. Frames with no hand are simply not sent;
  /// the caller times the gap.
  Stream<HandFrame> get frames;

  TrackerStats get stats;

  /// Opens the camera and starts tracking. Throws [HandTrackerException].
  Future<void> start();

  /// Stops tracking and releases the camera.
  Future<void> stop();

  /// Live camera image, or a plain stand-in.
  Widget buildPreview(BuildContext context);
}

class HandTrackerException implements Exception {
  const HandTrackerException(this.message);

  /// Plain text for the user.
  final String message;

  @override
  String toString() => 'HandTrackerException: $message';
}
