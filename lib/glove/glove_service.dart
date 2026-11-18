import 'package:flutter/foundation.dart';

import 'glove_models.dart';

export 'glove_models.dart';

/// The only way the UI talks to the glove.
///
/// Implementations: [MockGloveService] today, a BLE implementation later.
/// The UI never constructs an implementation; it gets one from
/// lib/app/glove_service_factory.dart through gloveServiceProvider.
abstract class GloveService {
  /// Current glove state. Updates whenever telemetry arrives (about 20 Hz).
  ValueListenable<GloveSnapshot> get snapshot;

  /// EMG envelope samples, 0-1023, one event per sample at 50 Hz.
  /// The BLE implementation unpacks 5 samples per notification.
  Stream<int> get emgSamples;

  Future<void> connect();

  Future<void> disconnect();

  Future<void> setMode(GloveMode mode);

  Future<void> setTargetPressure(double kPa);

  /// EMG level (0-1023) at which the glove starts an assisted grip.
  Future<void> setEmgThreshold(int threshold);

  /// Begin repeating grip cycles in the current mode.
  Future<void> start();

  /// Finish the current cycle's vent normally and stay idle.
  Future<void> stop();

  /// Vent immediately. Must be safe to call in any state, any number of
  /// times, including while disconnected or connecting. Never throws.
  Future<void> emergencyVent();

  void dispose();
}

/// What the screen is asking the patient to do.
enum PatientCue { rest, grip }

/// Implemented only by simulated gloves, so a fake patient can follow the
/// on-screen cue. Real hardware has a real patient and does not implement it.
abstract class PatientCueSink {
  void setPatientCue(PatientCue cue);
}
