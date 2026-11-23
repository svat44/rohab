import 'dart:async';

import 'package:flutter/foundation.dart';

import '../camera/camera_permission.dart';
import '../camera/hand_tracker.dart';
import '../debug/diagnostics.dart';
import '../data/exercise_session_repository.dart';
import 'exercise_catalog.dart';
import 'exercise_counters.dart';
import 'hand_distance.dart';
import 'hand_metrics.dart';
import 'joint_angles.dart';
import 'movement_quality.dart';

enum FlowStep {
  instructions,
  permission, // explain, then ask
  permissionDenied, // must go to Settings
  starting,
  cameraError,
  handCheck,
  calibrate,
  calibrationFailed,
  exercise,
  done,
}

enum CalibratePhase { high, low }

class DoneSummary {
  const DoneSummary({
    required this.reps,
    required this.target,
    required this.completed,
    required this.rangeMin,
    required this.rangeMax,
    required this.unit,
    this.avgAmplitude,
    this.avgPeakSpeed,
    this.avgSmoothness,
    this.fatigued = false,
    this.compensatedReps = 0,
  });

  final int reps;
  final int target;

  /// Reached the target (vs ended early).
  final bool completed;

  /// Smallest and largest value reached: finger bend in degrees (unit
  /// "deg"), or spread % (unit "%").
  final double? rangeMin;
  final double? rangeMax;
  final String unit;

  /// Per-rep averages: movement size (unit above), peak speed (unit per
  /// second), SPARC smoothness (closer to 0 is smoother).
  final double? avgAmplitude;
  final double? avgPeakSpeed;
  final double? avgSmoothness;

  /// Later reps were clearly smaller than the first ones.
  final bool fatigued;

  /// Reps not counted because the wrist moved instead of the fingers.
  final int compensatedReps;

  bool get inDegrees => unit == 'deg';
}

/// Runs one camera exercise: instructions -> camera permission -> hand
/// check -> range calibration (once per session) -> exercise -> done.
///
/// Time comes from a 50 ms ticker for presence and phase timing, and from
/// frame timestamps for rep timing.
class CameraExerciseController extends ChangeNotifier {
  CameraExerciseController({
    required this.exercise,
    required this._trackerFactory,
    required this._permission,
    required this._repository,
    required this._loadRange,
    required this._saveRange,
    required this.setSize,
    this.diagnostics,
    this.level,
    DateTime Function()? wallClock,
    this.onRepCounted,
  }) : _wallClock = wallClock ?? DateTime.now {
    diagnostics?.extra = _diagnosticsText;
  }

  /// Debug builds only: counts and timings, never landmarks or video.
  final DiagnosticsCollector? diagnostics;

  /// Tick-clock time since the camera opened. For diagnostics and tests.
  Duration get now => _now;

  String _diagnosticsText() =>
      'open=${percent.round()}% reps=$reps/$setSize step=${step.name}'
      '${hint == null ? '' : ' "$hint"'}';

  /// Reps (or holds, or rounds) in this set.
  final int setSize;

  /// Program level, saved with the session. Null for free practice.
  final int? level;

  static const tick = Duration(milliseconds: 50);
  static const handCheckTime = Duration(seconds: 1);
  static const presenceGap = Duration(milliseconds: 300);
  static const lostAfter = Duration(seconds: 2);

  /// No hand this long on the hand check: show tips instead of waiting.
  static const handCheckHelpAfter = Duration(seconds: 6);
  static const calibratePhaseTime = Duration(seconds: 3);
  static const calibrateSettle = Duration(milliseconds: 500);

  final CameraExercise exercise;
  final HandTracker Function() _trackerFactory;
  final CameraPermission _permission;
  final ExerciseSessionRepository _repository;
  final RangeCalibration? Function() _loadRange;
  final void Function(RangeCalibration) _saveRange;
  final DateTime Function() _wallClock;

  /// Called with the new count after each rep or round.
  // TODO(audio): speak the count here (TTS) once audio cues are added.
  final void Function(int reps)? onRepCounted;

  FlowStep step = FlowStep.instructions;
  CalibratePhase calibratePhase = CalibratePhase.high;
  int secondsLeft = 0;
  int reps = 0;

  /// Filtered opening (or spread), 0-100 % of the user's own range.
  double percent = 0;

  /// Current finger bend in degrees (mean MCP + PIP + DIP), if measured.
  double? closureDegrees;

  /// Recent reps are clearly smaller than the first: suggest a rest.
  bool suggestRest = false;

  /// The last rep was made by moving the wrist and did not count.
  bool wristCue = false;
  int compensatedReps = 0;

  /// Exercise-specific guidance ("Hold it open.", "Next: ring finger").
  String? hint;

  /// How far the hand is from the camera, smoothed. Too far or too close
  /// makes tracking worse, so the screen says so and the hand check waits.
  HandDistance distance = HandDistance.good;
  double? _palm;
  static const distanceGiveUp = Duration(seconds: 8);

  /// Live progress toward the current move, 0-1, lightly smoothed so the bar
  /// does not flicker with tracking noise. [meterMarker] is the goal line.
  double meter = 0;
  double meterMarker = 1;

  /// No count for [stuckAfter] while the hand is in view: the screen offers
  /// tips instead of leaving the person guessing.
  bool stuck = false;
  Duration _lastCountAt = Duration.zero;
  static const stuckAfter = Duration(seconds: 15);

  /// The hand has been out of view for over 2 s; counting is paused.
  bool handLost = false;

  /// On the hand check: still no hand after [handCheckHelpAfter], so the
  /// screen explains what to try (distance, light, whole hand in view).
  bool needsHandHelp = false;
  Duration _handCheckStart = Duration.zero;
  String? errorMessage;
  DoneSummary? summary;

  final Completer<void> _saved = Completer<void>();

  /// Completes once the finished set has been saved (or nothing needed
  /// saving).
  Future<void> get saved => _saved.future;

  /// The hand as last seen (null when out of view), for the overlay.
  final ValueNotifier<HandFrame?> frame = ValueNotifier(null);

  HandTracker? _tracker;
  StreamSubscription<HandFrame>? _sub;
  Timer? _ticker;
  Duration _now = Duration.zero;
  Duration? _lastSeen;
  Duration? _presentSince;
  Duration _phaseStart = Duration.zero;
  final List<double> _high = [];
  final List<double> _low = [];
  RangeCalibration? _range;
  final OneEuroFilter _filter = OneEuroFilter();
  final RepRecorder _recorder = RepRecorder();
  final FatigueMonitor _fatigue = FatigueMonitor();

  /// Swings smaller than this are noise: 10 degrees of bend, or 10 % of
  /// the spread range.
  final ExcursionTracker _swings = ExcursionTracker(deadband: 10);
  final List<RepStats> _repStats = [];
  ExerciseCounter? _counter;
  final WristMonitor _wrist = WristMonitor();
  double? _rangeMin;
  double? _rangeMax;
  Duration? _exerciseStart;
  DateTime? _startedAt;
  bool _disposed = false;

  HandTracker? get tracker => _tracker;
  TrackerStats get stats => _tracker?.stats ?? const TrackerStats();


  // ---- Steps ---------------------------------------------------------------

  /// "Start" on the instructions.
  Future<void> start() async {
    switch (await _permission.status()) {
      case CameraAccess.granted:
        await _openCamera();
      case CameraAccess.notAsked:
        _go(FlowStep.permission);
      case CameraAccess.denied:
        _go(FlowStep.permissionDenied);
    }
  }

  /// "Allow camera" on the explanation screen.
  Future<void> allowCamera() async {
    final access = await _permission.request();
    if (access == CameraAccess.granted) {
      await _openCamera();
    } else {
      _go(FlowStep.permissionDenied);
    }
  }

  Future<void> openSettings() => _permission.openSettings();

  /// Called when the app returns to the foreground (e.g. from Settings).
  Future<void> recheckPermission() async {
    if (step != FlowStep.permissionDenied && step != FlowStep.permission) {
      return;
    }
    if (await _permission.status() == CameraAccess.granted) {
      await _openCamera();
    }
  }

  /// "Try again" after a camera error.
  Future<void> retryCamera() => _openCamera();

  /// "Try again" after calibration failed.
  void retryCalibration() => _beginCalibration();

  /// "End exercise".
  Future<void> endExercise() => _finish(completed: false);

  Future<void> _openCamera() async {
    _go(FlowStep.starting);
    final tracker = _tracker ?? _trackerFactory();
    _tracker = tracker;
    try {
      await tracker.start();
    } on HandTrackerException catch (e) {
      errorMessage = e.message;
      _go(FlowStep.cameraError);
      return;
    }
    if (_disposed) {
      await tracker.stop();
      return;
    }
    _sub ??= tracker.frames.listen(_onFrame);
    _ticker ??= Timer.periodic(tick, (_) => _onTick());
    _lastSeen = null;
    _presentSince = null;
    needsHandHelp = false;
    distance = HandDistance.good;
    _palm = null;
    _handCheckStart = _now;
    _go(FlowStep.handCheck);
  }

  void _beginCalibration() {
    _high.clear();
    _low.clear();
    calibratePhase = CalibratePhase.high;
    _phaseStart = _now;
    secondsLeft = calibratePhaseTime.inSeconds;
    _go(FlowStep.calibrate);
  }

  void _beginExercise() {
    _filter.reset();
    _recorder.reset();
    _fatigue.reset();
    _swings.reset();
    _repStats.clear();
    suggestRest = false;
    closureDegrees = null;
    reps = 0;
    percent = 0;
    handLost = false;
    _rangeMin = null;
    _rangeMax = null;
    _counter = ExerciseCounter.forKind(exercise.kind,
        high: exercise.repHigh, low: exercise.repLow);
    _wrist.reset();
    wristCue = false;
    compensatedReps = 0;
    hint = _counter!.hint;
    meter = 0;
    meterMarker = _counter!.marker;
    stuck = false;
    _lastCountAt = _now;
    _exerciseStart = _now;
    _startedAt = _wallClock();
    _go(FlowStep.exercise);
  }

  Future<void> _finish({required bool completed}) async {
    if (step != FlowStep.exercise) return;
    final duration = _now - (_exerciseStart ?? _now);
    double? avg(double Function(RepStats) f) {
      final xs = _repStats.map(f).where((v) => v.isFinite).toList();
      return xs.isEmpty ? null : xs.reduce((a, b) => a + b) / xs.length;
    }

    final unit = exercise.usesSpread ? '%' : 'deg';
    // Finger-bend range means nothing when the wrist or the whole hand is
    // what moves: report no range at all.
    final reportRange = exercise.reportsRange && reps > 0;
    summary = DoneSummary(
      reps: reps,
      target: setSize,
      completed: completed,
      rangeMin: reportRange ? _rangeMin : null,
      rangeMax: reportRange ? _rangeMax : null,
      unit: unit,
      avgAmplitude: avg((r) => r.amplitude),
      avgPeakSpeed: avg((r) => r.peakSpeed),
      avgSmoothness: avg((r) => r.smoothness),
      fatigued: _fatigue.isFatigued,
      compensatedReps: compensatedReps,
    );
    final s = summary!;
    _go(FlowStep.done);
    await _stopCamera();
    if (reps > 0) {
      await _repository.save(ExerciseSessionRecord(
        exerciseId: exercise.id,
        mode: 'camera',
        reps: reps,
        targetReps: setSize,
        rangeMin: s.rangeMin,
        rangeMax: s.rangeMax,
        metricUnit: s.unit,
        avgAmplitude: s.avgAmplitude,
        avgPeakSpeed: s.avgPeakSpeed,
        avgSmoothness: s.avgSmoothness,
        fatigued: s.fatigued,
        compensatedReps: s.compensatedReps,
        level: level,
        durationSec: duration.inSeconds,
        startedAt: _startedAt ?? _wallClock(),
      ));
    }
    if (!_saved.isCompleted) _saved.complete();
  }

  // ---- Frames and time -----------------------------------------------------

  void _onFrame(HandFrame frame) {
    if (_disposed) return;
    this.frame.value = frame.isUsable ? frame : null;
    diagnostics?.onFrame(frame, _now);
    if (!frame.isUsable) return;
    _lastSeen = _now;
    final lm = frame.measurePoints;
    final palm = HandDistanceCheck.palmLength(frame.points);
    _palm = _palm == null ? palm : _palm! + (palm - _palm!) * 0.2;
    final d = HandDistanceCheck.of(_palm!);
    if (d != distance) {
      distance = d;
      notifyListeners();
    }

    switch (step) {
      case FlowStep.calibrate:
        if (_now - _phaseStart < calibrateSettle) return; // moving into pose
        final raw = _raw(frame);
        (calibratePhase == CalibratePhase.high ? _high : _low).add(raw);
      case FlowStep.exercise:
        if (handLost) {
          handLost = false;
          _lastCountAt = _now;
          _filter.reset();
          _recorder.reset();
          _wrist.reset();
        }
        final range = _range!;
        final angles = JointAngles.compute(lm, frame.handedness);
        final raw = exercise.usesSpread ? HandMetrics.rawSpread(lm) : -angles.closure;
        final filtered = _filter.filter(raw, frame.timestamp);
        final p = range.percent(filtered);
        percent = p;
        // Shown and stored: finger bend in degrees, or spread %.
        final shown = exercise.usesSpread ? p : -filtered;
        closureDegrees = exercise.usesSpread ? null : -filtered;
        _rangeMin = _rangeMin == null || shown < _rangeMin! ? shown : _rangeMin;
        _rangeMax = _rangeMax == null || shown > _rangeMax! ? shown : _rangeMax;
        _recorder.add(shown, frame.timestamp);
        final swing = _swings.update(shown);
        if (swing != null) {
          _fatigue.add(swing);
          suggestRest = _fatigue.isFatigued;
        }
        _wrist.update(lm);
        final counted = _counter!.update(
            HandSample(
                points: lm, angles: angles, percent: p, image: frame.points),
            frame.timestamp);
        hint = _counter!.hint;
        final target = _counter!.meter ?? p / 100;
        meter += (target - meter) * 0.5;
        meterMarker = _counter!.marker;
        if (counted && _wrist.moved && !exercise.movesWrist) {
          // Made by bending the wrist (tenodesis), not the fingers.
          _recorder.close();
          compensatedReps++;
          wristCue = true;
        } else if (counted) {
          wristCue = false;
          _lastCountAt = _now;
          stuck = false;
          final stats = _recorder.close();
          if (stats != null) _repStats.add(stats);
          reps++;
          onRepCounted?.call(reps);
          if (reps >= setSize) {
            _finish(completed: true);
            return;
          }
        }
        notifyListeners();
      default:
        break;
    }
  }

  /// The value calibrated and counted on; larger = more open.
  /// Open/close and finger touches: minus the finger bend in degrees,
  /// from 3D joint angles. Spread: fingertip spacing in palm widths.
  double _raw(HandFrame frame) {
    final lm = frame.measurePoints;
    if (exercise.usesSpread) return HandMetrics.rawSpread(lm);
    return -JointAngles.compute(lm, frame.handedness).closure;
  }

  void _onTick() {
    _now += tick;
    final seen = _lastSeen != null && _now - _lastSeen! <= presenceGap;
    if (!seen && frame.value != null) frame.value = null;
    diagnostics?.tick(_now, _tracker?.stats.resultsTotal ?? 0);

    switch (step) {
      case FlowStep.handCheck:
        final help = !seen && _now - _handCheckStart >= handCheckHelpAfter;
        if (help != needsHandHelp) {
          needsHandHelp = help;
          notifyListeners();
        }
        // Seen at a good distance (after 8 s the distance no longer blocks:
        // some setups cannot do better, and waiting forever is worse).
        final okDistance = distance == HandDistance.good ||
            _now - _handCheckStart >= distanceGiveUp;
        if (!seen || !okDistance) {
          _presentSince = null;
        } else {
          _presentSince ??= _now;
          if (_now - _presentSince! >= handCheckTime) {
            // Exercises that don't count on the open/closed range skip it.
            _range = exercise.needsRange
                ? _loadRange()
                : const RangeCalibration(min: -300, max: 0);
            if (_range == null) {
              _beginCalibration();
            } else {
              _beginExercise();
            }
          }
        }
      case FlowStep.calibrate:
        final elapsed = _now - _phaseStart;
        final left = (calibratePhaseTime - elapsed).inMilliseconds;
        final secs = (left / 1000).ceil().clamp(0, 3);
        if (secs != secondsLeft) {
          secondsLeft = secs;
          notifyListeners();
        }
        if (elapsed >= calibratePhaseTime) {
          if (calibratePhase == CalibratePhase.high) {
            calibratePhase = CalibratePhase.low;
            _phaseStart = _now;
            secondsLeft = calibratePhaseTime.inSeconds;
            notifyListeners();
          } else {
            final range = RangeCalibration.fromSamples(
              high: _high,
              low: _low,
              minSpan: exercise.usesSpread
                  ? RangeCalibration.minSpreadSpan
                  : RangeCalibration.minClosureSpan,
            );
            if (range == null) {
              _go(FlowStep.calibrationFailed);
            } else {
              _range = range;
              _saveRange(range);
              _beginExercise();
            }
          }
        }
      case FlowStep.exercise:
        final isStuck = !handLost && _now - _lastCountAt >= stuckAfter;
        if (isStuck != stuck) {
          stuck = isStuck;
          notifyListeners();
        }
        final lost = _lastSeen == null || _now - _lastSeen! > lostAfter;
        if (lost && !handLost) {
          handLost = true;
          _counter?.resetCycle();
          _recorder.reset();
          _swings.reset();
          notifyListeners();
        }
      default:
        break;
    }
  }

  void _go(FlowStep next) {
    step = next;
    if (!_disposed) notifyListeners();
  }

  /// Releases the camera first, then the listeners.
  Future<void> _stopCamera() async {
    _ticker?.cancel();
    _ticker = null;
    final sub = _sub;
    _sub = null;
    await _tracker?.stop();
    await sub?.cancel();
  }

  @override
  void dispose() {
    _disposed = true;
    frame.dispose();
    _stopCamera();
    super.dispose();
  }
}
