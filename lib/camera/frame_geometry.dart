/// How a camera frame must be turned and drawn. Pure Dart.
///
/// The `camera` plugin hands frames to the app differently per platform
/// (read from the plugin sources, camera_avfoundation 0.11 and
/// camera_android_camerax 0.7):
///
/// - **iOS** turns the video output to the device orientation and mirrors it
///   for the front camera (`DefaultCamera.swift`: `isVideoMirrored = true`,
///   `updateOrientation`). Frames arrive upright and already mirrored, so
///   they must NOT be rotated again, and the landmarks already match the
///   mirrored preview.
/// - **Android** (CameraX) hands over the raw sensor buffer: unrotated and
///   unmirrored. It must be rotated by the sensor orientation, and the
///   preview is mirrored by the plugin, so the overlay has to mirror x.
///
/// Rotating an upright iOS frame by 90 degrees (what a one-size-fits-all
/// `sensorOrientation` does) shows MediaPipe a sideways hand: tracking
/// almost never starts, and when it does the drawn hand is flipped.
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
