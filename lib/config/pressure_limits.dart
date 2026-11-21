/// Glove pressure limits. The single source for every pressure value in
/// the app, the mock glove and the BLE spec.
///
/// Hardware: Ecoflex 00-30 PneuNet actuators reach full bend near 55 kPa,
/// and the Adafruit ZR370 pumps stall near 55 kPa. Targets stay well below
/// that.
///
/// Any pressure control (e.g. a future Settings max-pressure slider) must
/// not allow values above [kHardLimitKpa]. The firmware enforces the same
/// cap on its own (docs/ble-protocol.md).
library;

// TODO: replace both with bench-test values from the first cast actuator.

/// Default grip target, kPa (gauge).
const double kTargetPressureKpa = 35;

/// Never exceeded. Above this the mock glove raises an overpressure fault
/// and vents; the firmware does the same.
const double kHardLimitKpa = 50;
