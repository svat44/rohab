/// Data types shared by every [GloveService] implementation.
/// Matches docs/ble-protocol.md.
library;

enum GloveConnection { disconnected, connecting, connected }

enum GloveMode { assist, passive, mirror }

enum GloveState { idle, inflating, holding, venting }

enum GloveFault { overpressure, timeout }

extension GloveModeLabel on GloveMode {
  String get label => switch (this) {
        GloveMode.assist => 'Assisted grip',
        GloveMode.passive => 'Passive range of motion',
        GloveMode.mirror => 'Mirror',
      };
}

extension GloveStateLabel on GloveState {
  String get label => switch (this) {
        GloveState.idle => 'Idle',
        GloveState.inflating => 'Inflating',
        GloveState.holding => 'Holding',
        GloveState.venting => 'Venting',
      };
}

extension GloveFaultLabel on GloveFault {
  String get label => switch (this) {
        GloveFault.overpressure => 'Pressure too high',
        GloveFault.timeout => 'Target pressure not reached',
      };
}

/// Everything the app knows about the glove at one moment.
class GloveSnapshot {
  const GloveSnapshot({
    required this.connection,
    required this.state,
    required this.mode,
    required this.pressureKpa,
    required this.targetKpa,
    required this.emg,
    required this.reps,
    required this.faults,
    required this.sessionActive,
  });

  static const initial = GloveSnapshot(
    connection: GloveConnection.disconnected,
    state: GloveState.idle,
    mode: GloveMode.assist,
    pressureKpa: 0,
    // Placeholder from the literature; see docs/rehab-science.md section 8.
    targetKpa: 200,
    emg: 0,
    reps: 0,
    faults: {},
    sessionActive: false,
  );

  final GloveConnection connection;
  final GloveState state;
  final GloveMode mode;

  /// Live gauge pressure in kPa.
  final double pressureKpa;

  /// Target pressure for a grip, in kPa.
  final double targetKpa;

  /// EMG envelope, 0-1023.
  final int emg;

  /// Completed grip cycles since the glove powered on.
  final int reps;

  final Set<GloveFault> faults;

  /// True between Start and Stop / Emergency vent.
  final bool sessionActive;

  bool get isConnected => connection == GloveConnection.connected;

  GloveSnapshot copyWith({
    GloveConnection? connection,
    GloveState? state,
    GloveMode? mode,
    double? pressureKpa,
    double? targetKpa,
    int? emg,
    int? reps,
    Set<GloveFault>? faults,
    bool? sessionActive,
  }) {
    return GloveSnapshot(
      connection: connection ?? this.connection,
      state: state ?? this.state,
      mode: mode ?? this.mode,
      pressureKpa: pressureKpa ?? this.pressureKpa,
      targetKpa: targetKpa ?? this.targetKpa,
      emg: emg ?? this.emg,
      reps: reps ?? this.reps,
      faults: faults ?? this.faults,
      sessionActive: sessionActive ?? this.sessionActive,
    );
  }
}
