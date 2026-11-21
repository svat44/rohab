import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mediapipe_vision/mediapipe_vision.dart';

import '../exercises/hand_metrics.dart';
import 'hand_tracker.dart';

/// Front camera + Google's MediaPipe Hand Landmarker (package
/// mediapipe_vision), in live-stream mode.
///
/// Frame dropping: MediaPipe's live-stream mode runs one frame at a time
/// and keeps only the newest waiting frame, so a slow phone drops frames
/// instead of queueing them. Frames are converted only if they run
/// ([VisionImage.deferred]). Nothing is written to disk.
class MediaPipeHandTracker implements HandTracker {
  MediaPipeHandTracker();

  final _frames = StreamController<HandFrame>.broadcast();
  final _clock = Stopwatch();
  CameraController? _camera;
  HandLandmarker? _landmarker;
  StreamSubscription<HandLandmarkerResult>? _results;
  int _lastTimestamp = -1;
  int _rotation = 0;
  double _aspect = 1;

  // Stats: results per second, measured over 1 s windows.
  int _windowStart = 0;
  int _windowCount = 0;
  double _fps = 0;

  @override
  Stream<HandFrame> get frames => _frames.stream;

  @override
  TrackerStats get stats => TrackerStats(
        framesPerSecond: _fps,
        droppedFrames: _landmarker?.droppedFrames ?? 0,
      );

  @override
  Future<void> start() async {
    if (_camera != null) return;
    final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } on CameraException {
      throw const HandTrackerException('The camera could not start.');
    }
    final front = cameras
        .where((c) => c.lensDirection == CameraLensDirection.front)
        .firstOrNull;
    if (front == null) {
      throw const HandTrackerException('This phone has no front camera.');
    }

    try {
      _landmarker = await HandLandmarker.create(
        HandLandmarkerOptions(
          model: VisionModels.handLandmarker,
          runningMode: RunningMode.liveStream,
          numHands: 1,
        ),
      );
    } on MediaPipeException {
      throw const HandTrackerException('Hand tracking could not start.');
    }
    _results = _landmarker!.results.listen(_onResult, onError: (_) {});

    // Low resolution is plenty for one hand and keeps conversion cheap.
    final camera = CameraController(
      front,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup:
          Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
    );
    try {
      await camera.initialize();
    } on CameraException {
      await camera.dispose();
      await _disposeLandmarker();
      throw const HandTrackerException(
          'The camera could not start. Close other apps that use it and try again.');
    }
    _camera = camera;
    // Portrait app: rotate sensor frames upright.
    // TODO(device): confirm on a real iPhone and Android phone that
    // fingertips come out above the wrist with this rotation.
    _rotation = front.sensorOrientation;
    _clock
      ..reset()
      ..start();
    await camera.startImageStream(_onImage);
  }

  void _onImage(CameraImage image) {
    final landmarker = _landmarker;
    if (landmarker == null) return;
    final now = _clock.elapsedMilliseconds;
    _lastTimestamp = now > _lastTimestamp ? now : _lastTimestamp + 1;
    final rotated = _rotation % 180 != 0;
    _aspect = rotated ? image.height / image.width : image.width / image.height;
    try {
      landmarker.detectAsync(
        VisionImage.deferred(() => _toVisionImage(image)),
        timestampMilliseconds: _lastTimestamp,
        rotationDegrees: _rotation,
      );
    } on Object {
      // A frame MediaPipe rejects is skipped; the next one is tried.
    }
  }

  static VisionImage _toVisionImage(CameraImage image) {
    final plane = image.planes.first;
    if (image.format.group == ImageFormatGroup.bgra8888) {
      return VisionImage.fromPixels(
        pixels: plane.bytes,
        width: image.width,
        height: image.height,
        format: VisionPixelFormat.bgra,
        bytesPerRow: plane.bytesPerRow,
      );
    }
    return VisionImage.fromPixels(
      pixels: nv21ToRgb(plane.bytes, image.width, image.height),
      width: image.width,
      height: image.height,
      format: VisionPixelFormat.rgb,
    );
  }

  void _onResult(HandLandmarkerResult result) {
    final now = _clock.elapsedMilliseconds;
    _windowCount++;
    if (now - _windowStart >= 1000) {
      _fps = _windowCount * 1000 / (now - _windowStart);
      _windowStart = now;
      _windowCount = 0;
    }
    if (result.handLandmarks.isEmpty) return;
    final hand = result.handLandmarks.first;
    final world = result.handWorldLandmarks.isEmpty
        ? null
        : result.handWorldLandmarks.first;
    final category =
        result.handedness.isEmpty ? null : result.handedness.first.firstOrNull;
    _frames.add(HandFrame(
      landmarks: [for (final p in hand) Point3(p.x, p.y, p.z)],
      handedness: _userHand(category?.categoryName),
      confidence: category?.score ?? 0,
      timestamp: Duration(milliseconds: result.timestampMilliseconds ?? now),
      aspectRatio: _aspect,
      worldLandmarks:
          world == null ? null : [for (final p in world) Point3(p.x, p.y, p.z)],
    ));
  }

  /// MediaPipe Tasks labels the subject's own hand when the image is not
  /// mirrored, which camera frames are not (only the preview is). Checked
  /// on MediaPipe's sample photos with tools/camera-test: with these labels
  /// both hands read a fist as positive flexion.
  static Handedness _userHand(String? label) => switch (label) {
        'Left' => Handedness.left,
        'Right' => Handedness.right,
        _ => Handedness.unknown,
      };

  @override
  double? get previewAspect {
    final size = _camera?.value.previewSize;
    if (size == null || size.height == 0) return null;
    // previewSize is landscape; the app is portrait.
    return size.height / size.width;
  }

  @override
  Widget buildPreview(BuildContext context) {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) {
      return const SizedBox.expand();
    }
    return CameraPreview(camera);
  }

  @override
  Future<void> stop() async {
    final camera = _camera;
    _camera = null;
    if (camera != null) {
      if (camera.value.isStreamingImages) await camera.stopImageStream();
      await camera.dispose();
    }
    await _disposeLandmarker();
    _clock.stop();
  }

  Future<void> _disposeLandmarker() async {
    final landmarker = _landmarker;
    _landmarker = null;
    await landmarker?.dispose();
    await _results?.cancel();
    _results = null;
  }
}

/// NV21 (Y plane, then interleaved V/U at half resolution) to packed RGB.
/// Integer BT.601 conversion; about 77k pixels at the low preset.
Uint8List nv21ToRgb(Uint8List nv21, int width, int height) {
  final out = Uint8List(width * height * 3);
  final uvStart = width * height;
  var o = 0;
  for (var y = 0; y < height; y++) {
    final uvRow = uvStart + (y >> 1) * width;
    final yRow = y * width;
    for (var x = 0; x < width; x++) {
      final yy = nv21[yRow + x] - 16;
      final uv = uvRow + (x & ~1);
      final v = nv21[uv] - 128;
      final u = nv21[uv + 1] - 128;
      final c = 298 * (yy < 0 ? 0 : yy);
      out[o++] = _clamp((c + 409 * v + 128) >> 8);
      out[o++] = _clamp((c - 100 * u - 208 * v + 128) >> 8);
      out[o++] = _clamp((c + 516 * u + 128) >> 8);
    }
  }
  return out;
}

int _clamp(int v) => v < 0 ? 0 : (v > 255 ? 255 : v);
