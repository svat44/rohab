import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/camera/frame_geometry.dart';

void main() {
  group('iOS (plugin delivers upright, mirrored frames)', () {
    test('a portrait buffer is not rotated and needs no x flip', () {
      final g = FrameGeometry.forFrame(
          isIOS: true, sensorOrientation: 90, width: 480, height: 640);
      expect(g.rotationDegrees, 0);
      expect(g.alreadyMirrored, isTrue);
      expect(g.aspect, closeTo(0.75, 1e-9));
      expect(g.previewX(0.2), 0.2);
    });

    test('a landscape buffer falls back to the sensor rotation', () {
      final g = FrameGeometry.forFrame(
          isIOS: true, sensorOrientation: 90, width: 640, height: 480);
      expect(g.rotationDegrees, 90);
      expect(g.aspect, closeTo(0.75, 1e-9));
    });
  });

  group('Android (raw sensor buffer)', () {
    test('front camera, 270 degrees: rotated, mirrored on the overlay', () {
      final g = FrameGeometry.forFrame(
          isIOS: false, sensorOrientation: 270, width: 320, height: 240);
      expect(g.rotationDegrees, 270);
      expect(g.alreadyMirrored, isFalse);
      expect(g.aspect, closeTo(0.75, 1e-9));
      expect(g.previewX(0.2), closeTo(0.8, 1e-9));
    });

    test('a sensor mounted at 90 degrees gives the same upright aspect', () {
      final g = FrameGeometry.forFrame(
          isIOS: false, sensorOrientation: 90, width: 640, height: 480);
      expect(g.rotationDegrees, 90);
      expect(g.aspect, closeTo(0.75, 1e-9));
    });
  });

  group('turning landmarks upright', () {
    // A landscape frame turned 270 degrees clockwise (Android front camera):
    // the delivered top-left corner ends up bottom-left, top-right ends up
    // top-left, bottom-left ends up bottom-right.
    test('270 degrees', () {
      final g = FrameGeometry.forFrame(
          isIOS: false, sensorOrientation: 270, width: 320, height: 240);
      expect(g.toUpright(0, 0), (0.0, 1.0));
      expect(g.toUpright(1, 0), (0.0, 0.0));
      expect(g.toUpright(0, 1), (1.0, 1.0));
      expect(g.toUpright(0.25, 0.5), (0.5, 0.75));
    });

    test('90 degrees is the opposite turn', () {
      final g = FrameGeometry.forFrame(
          isIOS: false, sensorOrientation: 90, width: 320, height: 240);
      expect(g.toUpright(0, 0), (1.0, 0.0));
      expect(g.toUpright(1, 0), (1.0, 1.0));
    });

    test('180 degrees and no turn', () {
      const turned = FrameGeometry(
          rotationDegrees: 180, alreadyMirrored: false, aspect: 1.333);
      expect(turned.toUpright(0.2, 0.3), (0.8, 0.7));
      const upright =
          FrameGeometry(rotationDegrees: 0, alreadyMirrored: true, aspect: 0.75);
      expect(upright.toUpright(0.2, 0.3), (0.2, 0.3));
    });

    test('a turn then the reverse turn lands back where it started', () {
      for (final deg in [90, 180, 270]) {
        final g = FrameGeometry(
            rotationDegrees: deg, alreadyMirrored: false, aspect: 1);
        final back = FrameGeometry(
            rotationDegrees: 360 - deg, alreadyMirrored: false, aspect: 1);
        final (x, y) = g.toUpright(0.3, 0.8);
        final (bx, by) = back.toUpright(x, y);
        expect(bx, closeTo(0.3, 1e-9));
        expect(by, closeTo(0.8, 1e-9));
      }
    });
  });
}
