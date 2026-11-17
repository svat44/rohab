import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'glove_service.dart';

/// Simulated glove for development and tests. No Bluetooth.
///
/// One cycle: inflate to target -> hold -> vent to zero -> rest -> repeat.
/// A rep is counted when a full cycle finishes venting.
class MockGloveService implements GloveService {
  MockGloveService({Random? random}) : _random = random ?? Random();

  static const tick = Duration(milliseconds: 50);
  static const connectDelay = Duration(milliseconds: 600);
  static const inflateRateKpaPerSec = 20.0;
  static const ventRateKpaPerSec = 40.0;
  static const emergencyVentRateKpaPerSec = 200.0;
  static const holdTime = Duration(seconds: 2);
  static const restTime = Duration(seconds: 1);
  static const inflateTimeout = Duration(seconds: 8);
  static const hardLimitKpa = 80.0;

  final Random _random;
  final ValueNotifier<GloveSnapshot> _snapshot =
      ValueNotifier(GloveSnapshot.initial);

  Timer? _ticker;
  Timer? _connectTimer;
  Duration _phaseTime = Duration.zero;
  bool _cycleCompleted = false;
  bool _emergency = false;
  bool _disposed = false;

  @override
  ValueListenable<GloveSnapshot> get snapshot => _snapshot;

  GloveSnapshot get _s => _snapshot.value;
  set _s(GloveSnapshot value) {
    if (!_disposed) _snapshot.value = value;
  }

  @override
  Future<void> connect() async {
    if (_s.connection != GloveConnection.disconnected) return;
    _s = _s.copyWith(connection: GloveConnection.connecting);
    final done = Completer<void>();
    _connectTimer = Timer(connectDelay, () {
      _s = _s.copyWith(connection: GloveConnection.connected);
      _ticker = Timer.periodic(tick, (_) => _onTick());
      done.complete();
    });
    return done.future;
  }

  @override
  Future<void> disconnect() async {
    _connectTimer?.cancel();
    _ticker?.cancel();
    _ticker = null;
    // A real glove vents on link loss (firmware rule), so pressure goes to 0.
    _s = GloveSnapshot.initial
        .copyWith(mode: _s.mode, targetKpa: _s.targetKpa, reps: _s.reps);
  }

  @override
  Future<void> setMode(GloveMode mode) async {
    if (_s.state == GloveState.inflating || _s.state == GloveState.holding) {
      return;
    }
    _s = _s.copyWith(mode: mode);
  }

  @override
  Future<void> setTargetPressure(double kPa) async {
    _s = _s.copyWith(targetKpa: kPa.clamp(0, hardLimitKpa).toDouble());
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
        final rate =
            _emergency ? emergencyVentRateKpaPerSec : ventRateKpaPerSec;
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

    _s = s.copyWith(emg: _nextEmg(s));
  }

  /// Noisy EMG envelope: higher while the hand is working.
  int _nextEmg(GloveSnapshot s) {
    final base = switch (s.state) {
      GloveState.inflating || GloveState.holding => 420.0,
      GloveState.venting => 200.0,
      GloveState.idle => 70.0,
    };
    final noise = (_random.nextDouble() - 0.5) * 120;
    final smoothed = s.emg * 0.6 + (base + noise) * 0.4;
    return smoothed.round().clamp(0, 1023);
  }

  @override
  void dispose() {
    _disposed = true;
    _connectTimer?.cancel();
    _ticker?.cancel();
    _snapshot.dispose();
  }
}
