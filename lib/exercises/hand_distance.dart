/// Is the hand a good distance from the camera? Pure Dart.
///
/// Tracking gets worse and every threshold gets noisier as the hand gets
/// small in the picture (the camera image is only 320 x 240), and a hand
/// that fills the frame gets cut off. The palm length (wrist to middle
/// knuckle) is the measure: it hardly changes when the fingers curl, so a
/// fist and an open hand read the same.
library;

import 'hand_metrics.dart';

enum HandDistance { tooFar, good, tooClose }

class HandDistanceCheck {
  HandDistanceCheck._();

  /// Palm length as a share of the picture height. About 0.15 is a hand 40
  /// cm away; the limits leave a wide comfortable band.
  static const tooFarBelow = 0.10;
  static const tooCloseAbove = 0.32;

  /// [image]: upright landmarks with x and y on the same scale.
  static double palmLength(List<Point3> image) =>
      image[HandIndex.wrist].distanceTo(image[HandIndex.middleMcp]);

  static HandDistance of(double palmLength) {
    if (palmLength < tooFarBelow) return HandDistance.tooFar;
    if (palmLength > tooCloseAbove) return HandDistance.tooClose;
    return HandDistance.good;
  }

  static String? advice(HandDistance d) => switch (d) {
    HandDistance.tooFar => 'Move your hand closer to the camera.',
    HandDistance.tooClose => 'Move your hand back a little.',
    HandDistance.good => null,
  };
}
