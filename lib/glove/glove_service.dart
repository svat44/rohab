import 'package:flutter/foundation.dart';

import 'glove_models.dart';

export 'glove_models.dart';

/// The only way the UI talks to the glove.
///
/// Implementations: [MockGloveService] today, a BLE implementation later.
/// The UI never imports an implementation directly; it gets one from
/// lib/app/glove_service_factory.dart.
abstract class GloveService {
  /// Current glove state. Updates whenever telemetry arrives.
  ValueListenable<GloveSnapshot> get snapshot;

  Future<void> connect();

  Future<void> disconnect();

  Future<void> setMode(GloveMode mode);

  Future<void> setTargetPressure(double kPa);

  /// Begin repeating grip cycles in the current mode.
  Future<void> start();

  /// Finish the current cycle's vent normally and stay idle.
  Future<void> stop();

  /// Vent immediately. Must be safe to call in any state, any number of
  /// times, including while disconnected or connecting. Never throws.
  Future<void> emergencyVent();

  void dispose();
}
