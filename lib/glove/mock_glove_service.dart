import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/pressure_limits.dart';
import 'glove_service.dart';

/// Simulated grip strength for the fake patient. Debug builds can switch
/// presets with a long-press on the "Rohab" wordmark.
enum MockEmgPreset {
  strong('Strong', gripMean: 380, gripSd: 40),
  weak('Weak', gripMean: 140, gripSd: 25),
  noSignal('No signal', gripMean: 65, gripSd: 10);

  const MockEmgPreset(
    this.label, {
    required this.gripMean,
    required this.gripSd,
  });

  final String label;
  final double gripMean;
  final double gripSd;

  static const restMean = 60.0;
  static const restSd = 10.0;
}

/// Simulated glove for development and tests. No Bluetooth.
///
/// Pressure: inflate to target -> hold -> vent to zero -> rest -> repeat.
/// A rep is counted when a full cycle finishes venting.
///
/// EMG: a fake patient at rest Normal(60, 10) or gripping Normal(preset),
/// with a 300 ms linear ramp between them, sampled at 50 Hz. The patient
/// grips when the screen cues it ([setPatientCue]) or while the glove is
/// inflating or holding during a session.
class MockGloveService implements GloveService, PatientCueSink {
  MockGloveService({Random? random, this.preset = MockEmgPreset.strong})
    : _random = random ?? Random();

  static const tick = Duration(milliseconds: 50);
  static const emgTick = Duration(milliseconds: 20); // 50 Hz
  static const connectDelay = Duration(milliseconds: 600);
  // Rates for small pumps (Adafruit ZR370) into Ecoflex PneuNet actuators:
  // about 2.3 s to reach the 35 kPa target. Emergency vent reaches 0 from
  // the target in about 0.2 s. Limits come from lib/config/pressure_limits.dart.
  static const inflateRateKpaPerSec = 15.0;
  static const ventRateKpaPerSec = 35.0;
  static const emergencyVentRateKpaPerSec = 175.0;
  static const holdTime = Duration(seconds: 2);
  static const restTime = Duration(seconds: 1);
  static const inflateTimeout = Duration(seconds: 8);
  static const effortRamp = Duration(milliseconds: 300);

  final Random _random;
  final ValueNotifier<GloveSnapshot> _snapshot = ValueNotifier(
    GloveSnapshot.initial,
  );
  final StreamController<int> _emg = StreamController<int>.broadcast();

  MockEmgPreset preset;

  /// Last threshold the app sent. Null until one is sent.
  int? emgThreshold;

  Timer? _ticker;
  Timer? _emgTicker;
  Timer? _connectTimer;
  Duration _phaseTime = Duration.zero;
  bool _cycleCompleted = false;
  bool _emergency = false;
  bool _disposed = false;
  PatientCue _cue = PatientCue.rest;
  double _effort = 0; // 0 = at rest, 1 = full grip
  int _lastEmg = 0;

  @override
  ValueListenable<GloveSnapshot> get snapshot => _snapshot;

  @override
  Stream<int> get emgSamples => _emg.stream;

  GloveSnapshot get _s => _snapshot.value;
  set _s(GloveSnapshot value) {
    if (!_disposed) _snapshot.value = value;
  }

  @override
  void setPatientCue(PatientCue cue) => _cue = cue;

  @override
  Future<void> connect() async {
    if (_s.connection != GloveConnection.disconnected) return;
    _s = _s.copyWith(connection: GloveConnection.connecting);
    final done = Completer<void>();
    _connectTimer = Timer(connectDelay, () {
      _s = _s.copyWith(connection: GloveConnection.connected);
      _ticker = Timer.periodic(tick, (_) => _onTick());
      _emgTicker = Timer.periodic(emgTick, (_) => _onEmgTick());
      done.complete();
    });
    return done.future;
  }

  @override
  Future<void> disconnect() async {
    _connectTimer?.cancel();
    _ticker?.cancel();
    _emgTicker?.cancel();
    _ticker = null;
    _emgTicker = null;
    // A real glove vents on link loss (firmware rule), so pressure goes to 0.
    _s = GloveSnapshot.initial.copyWith(
      mode: _s.mode,
      targetKpa: _s.targetKpa,
      reps: _s.reps,
    );
  }

  @override
  Future<void> setMode(GloveMode mode) async {
    if (_s.state == GloveState.inflating || _s.state == GloveState.holding) {
      return;
    }
    _s = _s.copyWith(mode: mode);
  }

  @override
  /// Targets above [kHardLimitKpa] are clamped to it and raise the
  /// overpressure fault (which vents, as the firmware would).
  @override
  Future<void> setTargetPressure(double kPa) async {
    if (kPa > kHardLimitKpa) {
      _s = _s.copyWith(targetKpa: kHardLimitKpa);
      simulateFault(GloveFault.overpressure);
      return;
    }
    _s = _s.copyWith(targetKpa: kPa < 0 ? 0 : kPa);
  }

  @override
  Future<void> setEmgThreshold(int threshold) async {
    emgThreshold = threshold.clamp(0, 1023);
  }

  @override
  Future<void> start() async {
    if (!_s.isConnected || _s.sessionActive) return;
    _emergency = false;
    _phaseTime = restTime; // begin the first inflate on the next tick
    _s = _s.copyWith(sessionActive: true, faults: const {});
  }

  @override
  Future<void> stop() async {
    _s = _s.copyWith(sessionActive: false);
    if (_s.state == GloveState.inflating || _s.state == GloveState.holding) {
      _beginVent(emergency: false);
    }
  }

  @override
  Future<void> emergencyVent() async {
    if (_disposed) return;
    _s = _s.copyWith(sessionActive: false);
    if (_s.pressureKpa > 0 || _s.state != GloveState.idle) {
      _beginVent(emergency: true);
    }
  }

  /// Test / demo hook: make the glove report a fault. It vents immediately,
  /// as the firmware would.
  void simulateFault(GloveFault fault) {
    _s = _s.copyWith(faults: {..._s.faults, fault}, sessionActive: false);
    _beginVent(emergency: true);
  }

  void _beginVent({required bool emergency}) {
    _emergency = _emergency || emergency;
    _cycleCompleted = _cycleCompleted && !emergency;
    _phaseTime = Duration.zero;
    if (_s.pressureKpa <= 0) {
      _emergency = false;
      _s = _s.copyWith(pressureKpa: 0, state: GloveState.idle);
    } else {
      _s = _s.copyWith(state: GloveState.venting);
    }
  }

  void _onTick() {
    if (_disposed) return;
    final dt = tick.inMicroseconds / Duration.microsecondsPerSecond;
    _phaseTime += tick;
    var s = _s;

    switch (s.state) {
      case GloveState.idle:
        if (s.sessionActive && _phaseTime >= restTime) {
          _phaseTime = Duration.zero;
          _cycleCompleted = false;
          s = s.copyWith(state: GloveState.inflating);
        }
      case GloveState.inflating:
        final p = s.pressureKpa + inflateRateKpaPerSec * dt;
        if (p >= s.targetKpa) {
          _phaseTime = Duration.zero;
          s = s.copyWith(pressureKpa: s.targetKpa, state: GloveState.holding);
        } else if (_phaseTime >= inflateTimeout) {
          _s = s.copyWith(pressureKpa: p);
          simulateFault(GloveFault.timeout);
          return;
        } else {
          s = s.copyWith(pressureKpa: p);
        }
      case GloveState.holding:
        // Small sensor wobble around target.
        final p = s.targetKpa + (_random.nextDouble() - 0.5) * 0.4;
        if (_phaseTime >= holdTime) {
          _cycleCompleted = true;
          _phaseTime = Duration.zero;
          s = s.copyWith(pressureKpa: p, state: GloveState.venting);
        } else {
          s = s.copyWith(pressureKpa: p);
        }
      case GloveState.venting:
        final rate = _emergency
            ? emergencyVentRateKpaPerSec
            : ventRateKpaPerSec;
        final p = s.pressureKpa - rate * dt;
        if (p <= 0) {
          _phaseTime = Duration.zero;
          s = s.copyWith(
            pressureKpa: 0,
            state: GloveState.idle,
            reps: _cycleCompleted ? s.reps + 1 : s.reps,
          );
          _cycleCompleted = false;
          _emergency = false;
        } else {
          s = s.copyWith(pressureKpa: p);
        }
    }

    // Hard cap: the reported pressure never exceeds the limit.
    if (s.pressureKpa > kHardLimitKpa) {
      s = s.copyWith(pressureKpa: kHardLimitKpa);
    }
    _s = s.copyWith(emg: _lastEmg);
  }

  void _onEmgTick() {
    if (_disposed) return;
    final working =
        _s.sessionActive &&
        (_s.state == GloveState.inflating || _s.state == GloveState.holding);
    final target = (_cue == PatientCue.grip || working) ? 1.0 : 0.0;
    final step = emgTick.inMicroseconds / effortRamp.inMicroseconds;
    _effort = target > _effort
        ? min(target, _effort + step)
        : max(target, _effort - step);

    final mean =
        MockEmgPreset.restMean +
        _effort * (preset.gripMean - MockEmgPreset.restMean);
    final sd =
        MockEmgPreset.restSd + _effort * (preset.gripSd - MockEmgPreset.restSd);
    _lastEmg = (mean + sd * _gaussian()).round().clamp(0, 1023);
    _emg.add(_lastEmg);
  }

  /// Standard normal sample (Box-Muller).
  double _gaussian() {
    final u1 = 1.0 - _random.nextDouble(); // (0, 1]
    final u2 = _random.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  @override
  void dispose() {
    _disposed = true;
    _connectTimer?.cancel();
    _ticker?.cancel();
    _emgTicker?.cancel();
    _emg.close();
    _snapshot.dispose();
  }
}
