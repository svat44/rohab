import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../glove/glove_service.dart';
import 'emg_calibrator.dart';

enum CalibrationStep { start, prepare, rest, grip, review }

enum GripPhase { grip, relax }

class CalibrationFlowState {
  const CalibrationFlowState({
    this.step = CalibrationStep.start,
    this.gripPhase = GripPhase.grip,
    this.trial = 1,
    this.secondsLeft = 0,
    this.result,
    this.notice,
  });

  final CalibrationStep step;
  final GripPhase gripPhase;

  /// 1-based trial number during the grip step.
  final int trial;

  /// Whole seconds left in the current recording phase.
  final int secondsLeft;

  /// Set on the review step.
  final CalibrationResult? result;

  /// One plain sentence for the start screen, e.g. after saving.
  final String? notice;

  /// 1-4 for the steps of the flow, 0 on the start screen.
  int get stepNumber => step.index;

  bool get isRecording =>
      step == CalibrationStep.rest || step == CalibrationStep.grip;
}

final calibrationControllerProvider =
    NotifierProvider<CalibrationController, CalibrationFlowState>(
      CalibrationController.new,
    );

/// Runs the 4-step calibration. Timing comes from the sample count, so a
/// 5 s rest is exactly 250 samples at 50 Hz.
///
/// Never calls start() on the glove: calibration never inflates it.
class CalibrationController extends Notifier<CalibrationFlowState> {
  StreamSubscription<int>? _samples;
  GloveService? _glove;
  PatientCueSink? _cueSink;
  final List<int> _rest = [];
  final List<int> _trial = [];
  final List<List<int>> _trials = [];
  int _phaseCount = 0;

  @override
  CalibrationFlowState build() {
    final glove = ref.watch(gloveServiceProvider);
    _glove = glove;
    _cueSink = ref.watch(patientCueProvider);
    glove.snapshot.addListener(_onSnapshot);
    ref.onDispose(() {
      _stopRecording();
      glove.snapshot.removeListener(_onSnapshot);
    });
    return const CalibrationFlowState();
  }

  GloveService get _g => _glove!;

  /// Why calibration can't start right now, or null if it can.
  static String? blockReason(GloveSnapshot s) {
    if (!s.isConnected) return 'Connect your glove first.';
    if (s.sessionActive || s.state != GloveState.idle) {
      return 'End the glove session first.';
    }
    return null;
  }

  void begin() {
    if (blockReason(_g.snapshot.value) != null) return;
    state = const CalibrationFlowState(step: CalibrationStep.prepare);
  }

  /// "I'm ready" on Step 1.
  void ready() {
    if (state.step != CalibrationStep.prepare) return;
    _startRest();
  }

  /// Back to the start screen. Saves nothing.
  void cancel({String? notice}) {
    _stopRecording();
    state = CalibrationFlowState(notice: notice);
  }

  /// Repeat from Step 2: the sensor is already in place.
  void redo() {
    if (state.step != CalibrationStep.review) return;
    _startRest();
  }

  Future<void> save() async {
    final result = state.result;
    if (state.step != CalibrationStep.review ||
        result == null ||
        !result.isValid) {
      return;
    }
    final calibration = Calibration.fromResult(
      result,
      ref.read(clockProvider)(),
    );
    await ref.read(savedCalibrationProvider.notifier).save(calibration);
    await _g.setEmgThreshold(calibration.threshold);
    state = CalibrationFlowState(
      notice: 'Calibration saved. Trigger level ${calibration.threshold}.',
    );
  }

  void _startRest() {
    _stopRecording();
    _rest.clear();
    _trials.clear();
    _trial.clear();
    _phaseCount = 0;
    _cue(PatientCue.rest);
    state = const CalibrationFlowState(
      step: CalibrationStep.rest,
      secondsLeft: EmgCalibrator.restSeconds,
    );
    _samples = _g.emgSamples.listen(_onSample);
  }

  void _onSample(int value) {
    _phaseCount++;
    switch (state.step) {
      case CalibrationStep.rest:
        _rest.add(value);
        if (_phaseCount >= EmgCalibrator.restSampleCount) {
          _beginTrial(1);
        } else {
          _updateSeconds(EmgCalibrator.restSampleCount);
        }
      case CalibrationStep.grip when state.gripPhase == GripPhase.grip:
        _trial.add(value);
        if (_phaseCount >= EmgCalibrator.trialSampleCount) {
          _trials.add(EmgCalibrator.trimTrial(_trial));
          _trial.clear();
          if (state.trial >= EmgCalibrator.trialCount) {
            _finish();
          } else {
            _beginRelax();
          }
        } else {
          _updateSeconds(EmgCalibrator.trialSampleCount);
        }
      case CalibrationStep.grip:
        if (_phaseCount >= EmgCalibrator.betweenTrialsSampleCount) {
          _beginTrial(state.trial + 1);
        } else {
          _updateSeconds(EmgCalibrator.betweenTrialsSampleCount);
        }
      default:
        break;
    }
  }

  void _beginTrial(int trial) {
    _phaseCount = 0;
    _cue(PatientCue.grip);
    state = CalibrationFlowState(
      step: CalibrationStep.grip,
      gripPhase: GripPhase.grip,
      trial: trial,
      secondsLeft: EmgCalibrator.trialSeconds,
    );
  }

  void _beginRelax() {
    _phaseCount = 0;
    _cue(PatientCue.rest);
    state = CalibrationFlowState(
      step: CalibrationStep.grip,
      gripPhase: GripPhase.relax,
      trial: state.trial,
      secondsLeft: EmgCalibrator.betweenTrialsSeconds,
    );
  }

  void _finish() {
    _stopRecording();
    final result = EmgCalibrator.compute(rest: _rest, trials: _trials);
    state = CalibrationFlowState(step: CalibrationStep.review, result: result);
  }

  void _updateSeconds(int phaseSamples) {
    final left = ((phaseSamples - _phaseCount) / EmgCalibrator.sampleRateHz)
        .ceil();
    if (left != state.secondsLeft) {
      state = CalibrationFlowState(
        step: state.step,
        gripPhase: state.gripPhase,
        trial: state.trial,
        secondsLeft: left,
      );
    }
  }

  void _onSnapshot() {
    if (state.step == CalibrationStep.start) return;
    final s = _g.snapshot.value;
    if (!s.isConnected) {
      cancel(notice: 'The glove disconnected. Nothing was saved.');
    } else if (s.sessionActive) {
      cancel(
        notice:
            'A session started, so calibration stopped. '
            'Nothing was saved.',
      );
    }
  }

  void _cue(PatientCue cue) => _cueSink?.setPatientCue(cue);

  void _stopRecording() {
    _samples?.cancel();
    _samples = null;
    _cue(PatientCue.rest);
  }
}
