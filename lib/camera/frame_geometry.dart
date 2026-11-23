/// How a camera frame must be turned and drawn. Pure Dart.
///
/// Two facts, both confirmed on a real Android phone (the first version of
/// this code got the second one wrong, and the skeleton was drawn shifted
/// and squashed) and in the reference live-camera sample of the
/// mediapipe_vision package:
///
/// 1. MediaPipe is told `rotationDegrees` so it can see an upright hand, but
///    it still reports landmarks in the coordinates of the frame as the
///    camera DELIVERED it (a landscape sensor buffer on Android). Landmarks
///    must be turned the same way before they are drawn or measured:
///    [toUpright].
/// 2. The front-camera preview is a mirror. Android streams unmirrored
///    buffers (so x is flipped when drawing); iOS streams buffers that are
///    already mirrored (so it is not).
///
/// Rotation: Android needs the sensor angle (270 for most front cameras in
/// portrait). iOS frames may arrive upright or in sensor layout depending on
/// the plugin version, so a portrait buffer is left alone and a landscape
/// buffer is turned by the sensor angle.
library;

class FrameGeometry {
  const FrameGeometry({
    required this.rotationDegrees,
    required this.alreadyMirrored,
    required this.aspect,
  });

  /// Clockwise degrees MediaPipe must rotate the buffer by to make it upright.
  final int rotationDegrees;

  /// The buffer is already a mirror image (front camera, as the preview
  /// shows it). Landmarks then need no x flip to sit on the preview.
  final bool alreadyMirrored;

  /// Width / height of the upright image.
  final double aspect;

  /// Quarter turns clockwise (0-3) that stand the delivered frame upright.
  int get quarterTurns => (rotationDegrees ~/ 90) % 4;

  /// Maps a normalized point in the delivered frame to the same point in the
  /// upright frame (still not mirrored). Clockwise turn of the picture.
  (double, double) toUpright(double x, double y) => switch (quarterTurns) {
    1 => (1 - y, x),
    2 => (1 - x, 1 - y),
    3 => (y, 1 - x),
    _ => (x, y),
  };

  /// Where a landmark's normalized x lands on a mirrored preview, 0-1.
  double previewX(double x) => alreadyMirrored ? x : 1 - x;

  static FrameGeometry forFrame({
    required bool isIOS,
    required int sensorOrientation,
    required int width,
    required int height,
  }) {
    final int rotation;
    if (isIOS) {
      // Upright (portrait) buffer: leave it alone. A landscape buffer means
      // the plugin did not rotate it; fall back to the sensor angle.
      rotation = height >= width ? 0 : sensorOrientation % 360;
    } else {
      rotation = sensorOrientation % 360;
    }
    final swapped = rotation % 180 != 0;
    return FrameGeometry(
      rotationDegrees: rotation,
      alreadyMirrored: isIOS,
      aspect: swapped ? height / width : width / height,
    );
  }
}
