import 'package:material_ui/material_ui.dart';

import '../exercises/hand_metrics.dart';
import 'handedness.dart';

export 'handedness.dart';

/// One processed camera frame with a hand in it.
class HandFrame {
  const HandFrame({
    required this.landmarks,
    required this.handedness,
    required this.confidence,
    required this.timestamp,
    this.aspectRatio = 1,
    this.worldLandmarks,
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

  /// 21 landmarks in meters, origin near the middle of the hand (MediaPipe
  /// world landmarks). Joint angles come from these: unlike image
  /// coordinates, they don't foreshorten when a finger bends toward the
  /// camera. Null if the tracker doesn't provide them.
  final List<Point3>? worldLandmarks;

  bool get isUsable => confidence >= minConfidence;

  /// The best landmarks for angle math: world if available, else image
  /// points with matching axis scales.
  List<Point3> get measurePoints => worldLandmarks ?? points;

  /// Landmarks with x scaled so x and y share units, for angle and
  /// distance math.
  List<Point3> get points => [
        for (final p in landmarks) Point3(p.x * aspectRatio, p.y, p.z * aspectRatio),
      ];
}

class TrackerStats {
  const TrackerStats({
    this.framesPerSecond = 0,
    this.droppedFrames = 0,
    this.resultsTotal = 0,
  });

  /// Every result the tracker produced since it started, with a hand in it
  /// or not. Diagnostics divides confident frames by this.
  final int resultsTotal;

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

  /// Width / height of the camera image as shown (portrait, so below 1).
  /// Null until the camera is running.
  double? get previewAspect;

  /// Live camera image, or a plain stand-in. Fills the box it is given; the
  /// caller sizes that box to [previewAspect] so the whole image shows (no
  /// cropping) and the hand overlay lines up with it.
  Widget buildPreview(BuildContext context);
}

class HandTrackerException implements Exception {
  const HandTrackerException(this.message);

  /// Plain text for the user.
  final String message;

  @override
  String toString() => 'HandTrackerException: $message';
}
