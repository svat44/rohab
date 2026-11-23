import 'dart:async';

import 'package:flutter/foundation.dart';

import '../camera/camera_permission.dart';
import '../camera/hand_tracker.dart';
import '../exercises/hand_metrics.dart';
import '../exercises/joint_angles.dart';
import 'baseline.dart';

enum BaselineStep {
  chooseHand,
  permission,
  permissionDenied,
  starting,
  cameraError,
  handCheck,
  measure,
  otherHandPrompt,
  failed,
  result,
}

enum MeasurePhase { open, closed }

/// Measures active range of both hands: hand check, then open (4 s) and
/// close (4 s), twice, for the affected hand and then the other hand.
class BaselineController extends ChangeNotifier {
  BaselineController({
    required this._trackerFactory,
    required this._permission,
    required this._save,
    DateTime Function()? wallClock,
  }) : _wallClock = wallClock ?? DateTime.now;

  static const tick = Duration(milliseconds: 50);
  static const handCheckTime = Duration(seconds: 1);
  static const presenceGap = Duration(milliseconds: 300);
  static const phaseTime = Duration(seconds: 4);
  static const settle = Duration(milliseconds: 700);
  static const cycles = 2;
  static const minSamples = 10;

  final HandTracker Function() _trackerFactory;
  final CameraPermission _permission;
  final Future<void> Function(BaselineResult) _save;
  final DateTime Function() _wallClock;

  BaselineStep step = BaselineStep.chooseHand;
  Handedness? affectedHand;

  /// True while measuring the unaffected hand.
  bool measuringOther = false;
  MeasurePhase phase = MeasurePhase.open;
  int cycle = 1;
  int secondsLeft = 0;

  /// Shown when the camera seems to see the other hand.
  String? handHint;
  String? errorMessage;
  BaselineResult? result;

  /// The hand as last seen (null when out of view), for the overlay.
  final ValueNotifier<HandFrame?> frame = ValueNotifier(null);

  HandTracker? _tracker;
  StreamSubscription<HandFrame>? _sub;
  Timer? _ticker;
  Duration _now = Duration.zero;
  Duration? _lastSeen;
  Duration? _presentSince;
  Duration _phaseStart = Duration.zero;
  int _wrongHandFrames = 0;
  final List<double> _open = [];
  final List<double> _closed = [];
  HandRange? _affectedRange;
  bool _disposed = false;

  HandTracker? get tracker => _tracker;
  TrackerStats get stats => _tracker?.stats ?? const TrackerStats();

  Handedness get currentHand {
    final a = affectedHand ?? Handedness.right;
    if (!measuringOther) return a;
    return a == Handedness.left ? Handedness.right : Handedness.left;
  }

  static String handName(Handedness h) =>
      h == Handedness.left ? 'left' : 'right';

  Future<void> chooseHand(Handedness hand) async {
    affectedHand = hand;
    switch (await _permission.status()) {
      case CameraAccess.granted:
        await _openCamera();
      case CameraAccess.notAsked:
        _go(BaselineStep.permission);
      case CameraAccess.denied:
        _go(BaselineStep.permissionDenied);
    }
  }

  Future<void> allowCamera() async {
    if (await _permission.request() == CameraAccess.granted) {
      await _openCamera();
    } else {
      _go(BaselineStep.permissionDenied);
    }
  }

  Future<void> openSettings() => _permission.openSettings();

  Future<void> recheckPermission() async {
    if (step != BaselineStep.permission &&
        step != BaselineStep.permissionDenied) {
      return;
    }
    if (await _permission.status() == CameraAccess.granted) await _openCamera();
  }

  Future<void> retry() async {
    measuringOther = false;
    _affectedRange = null;
    await _openCamera();
  }

  /// "Measure other hand".
  void measureOther() {
    measuringOther = true;
    _startHandCheck();
  }

  /// "Skip": the other hand can't be measured (e.g. both affected).
  Future<void> skipOther() => _finish(null);

  Future<void> _openCamera() async {
    _go(BaselineStep.starting);
    final t = _tracker ?? _trackerFactory();
    _tracker = t;
    try {
      await t.start();
    } on HandTrackerException catch (e) {
      errorMessage = e.message;
      _go(BaselineStep.cameraError);
      return;
    }
    if (_disposed) {
      await t.stop();
      return;
    }
    _sub ??= t.frames.listen(_onFrame);
    _ticker ??= Timer.periodic(tick, (_) => _onTick());
    _startHandCheck();
  }

  void _startHandCheck() {
    _lastSeen = null;
    _presentSince = null;
    _open.clear();
    _closed.clear();
    handHint = null;
    _wrongHandFrames = 0;
    _go(BaselineStep.handCheck);
  }

  void _startMeasure() {
    phase = MeasurePhase.open;
    cycle = 1;
    _phaseStart = _now;
    secondsLeft = phaseTime.inSeconds;
    _go(BaselineStep.measure);
  }

  void _onFrame(HandFrame f) {
    if (_disposed) return;
    frame.value = f.isUsable ? f : null;
    if (!f.isUsable) return;
    _lastSeen = _now;
    // A hint only: the label can be wrong, so measuring goes on.
    final wrong =
        f.handedness != Handedness.unknown && f.handedness != currentHand;
    _wrongHandFrames = wrong ? _wrongHandFrames + 1 : 0;
    final hint = _wrongHandFrames > 20
        ? 'This looks like your ${handName(f.handedness)} hand. '
              'Use your ${handName(currentHand)} hand.'
        : null;
    if (hint != handHint) {
      handHint = hint;
      notifyListeners();
    }
    if (step != BaselineStep.measure || _now - _phaseStart < settle) return;
    // The person told us which hand this is; that sets the flexion sign
    // more reliably than the model's label.
    final bend = JointAngles.compute(f.measurePoints, currentHand).closure;
    (phase == MeasurePhase.open ? _open : _closed).add(bend);
  }

  void _onTick() {
    _now += tick;
    final seen = _lastSeen != null && _now - _lastSeen! <= presenceGap;
    if (!seen && frame.value != null) frame.value = null;
    switch (step) {
      case BaselineStep.handCheck:
        if (!seen) {
          _presentSince = null;
        } else {
          _presentSince ??= _now;
          if (_now - _presentSince! >= handCheckTime) _startMeasure();
        }
      case BaselineStep.measure:
        final elapsed = _now - _phaseStart;
        final secs = ((phaseTime - elapsed).inMilliseconds / 1000).ceil().clamp(
          0,
          4,
        );
        if (secs != secondsLeft) {
          secondsLeft = secs;
          notifyListeners();
        }
        if (elapsed < phaseTime) return;
        _phaseStart = _now;
        secondsLeft = phaseTime.inSeconds;
        if (phase == MeasurePhase.open) {
          phase = MeasurePhase.closed;
          notifyListeners();
        } else if (cycle < cycles) {
          cycle++;
          phase = MeasurePhase.open;
          notifyListeners();
        } else {
          _endHand();
        }
      default:
        break;
    }
  }

  void _endHand() {
    if (_open.length < minSamples || _closed.length < minSamples) {
      errorMessage =
          "We couldn't see your hand well enough. Try again with "
          'your whole hand in view and good light.';
      _go(BaselineStep.failed);
      return;
    }
    final range = HandRange(
      open: RangeCalibration.percentile(_open, 0.1),
      closed: RangeCalibration.percentile(_closed, 0.9),
    );
    if (!measuringOther) {
      _affectedRange = range;
      _go(BaselineStep.otherHandPrompt);
    } else {
      _finish(range);
    }
  }

  Future<void> _finish(HandRange? other) async {
    final affected = _affectedRange;
    if (affected == null) return;
    _ticker?.cancel();
    _ticker = null;
    await _tracker?.stop();
    final r = LevelPlacement.result(
      affectedHand: affectedHand ?? Handedness.right,
      affected: affected,
      other: other,
      takenAt: _wallClock(),
    );
    await _save(r);
    result = r;
    _go(BaselineStep.result);
  }

  void _go(BaselineStep s) {
    step = s;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    frame.dispose();
    _ticker?.cancel();
    final sub = _sub;
    _tracker?.stop().then((_) => sub?.cancel());
    super.dispose();
  }
}
