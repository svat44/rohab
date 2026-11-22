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
}
