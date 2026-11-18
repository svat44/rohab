/// BLE identifiers from docs/ble-protocol.md.
///
/// PLACEHOLDERS: these UUIDs must be replaced with the values compiled into
/// the ESP32 firmware. The app and the firmware must match exactly.
library;

class GloveBle {
  GloveBle._();

  static const advertisedNamePrefix = 'ROHAB-GLOVE-';

  static const serviceUuid = '7a1e0000-5c3d-4f2b-9b8e-0d3c2a1f6e00';
  static const controlUuid = '7a1e0001-5c3d-4f2b-9b8e-0d3c2a1f6e00';
  static const emergencyVentUuid = '7a1e0002-5c3d-4f2b-9b8e-0d3c2a1f6e00';
  static const telemetryUuid = '7a1e0003-5c3d-4f2b-9b8e-0d3c2a1f6e00';
  static const emgUuid = '7a1e0004-5c3d-4f2b-9b8e-0d3c2a1f6e00';

  // EMG stream: 50 Hz sampling, 5 samples (u16 LE) per notification.
  static const emgSampleRateHz = 50;
  static const emgSamplesPerPacket = 5;
  static const emgMax = 1023;

  // Control opcodes.
  static const opSetMode = 0x01;
  static const opSetTarget = 0x02;
  static const opStart = 0x03;
  static const opStop = 0x04;
  static const opSetEmgThreshold = 0x05;

  // Telemetry fault bits.
  static const faultOverpressure = 1 << 0;
  static const faultTimeout = 1 << 1;
}
