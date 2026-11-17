# Glove BLE protocol (v0, draft)

The app talks to the glove's ESP32 over Bluetooth Low Energy using one custom
GATT service. The app is the central. The glove is the peripheral and
advertises as `ROHAB-GLOVE-xxxx` (last 4 hex digits of its MAC).

> **All UUIDs below are placeholders.** They must be replaced with the values
> compiled into the ESP32 firmware, and the two must match exactly. In the app
> they live in one place: `lib/glove/ble_protocol.dart`.

All multi-byte integers are **little-endian**. Pressure is gauge pressure in
kPa, sent as an unsigned integer in tenths of a kPa (`325` = 32.5 kPa).

## Service

| Name          | UUID (placeholder)                     |
|---------------|----------------------------------------|
| Glove service | `7a1e0000-5c3d-4f2b-9b8e-0d3c2a1f6e00` |

## Characteristics

| Name            | UUID (placeholder)                     | Properties                    | Direction     |
|-----------------|----------------------------------------|-------------------------------|---------------|
| Control         | `7a1e0001-5c3d-4f2b-9b8e-0d3c2a1f6e00` | Write (with response)         | App -> glove  |
| Emergency vent  | `7a1e0002-5c3d-4f2b-9b8e-0d3c2a1f6e00` | Write, Write without response | App -> glove  |
| Telemetry       | `7a1e0003-5c3d-4f2b-9b8e-0d3c2a1f6e00` | Notify, Read                  | Glove -> app  |

Emergency vent has its own characteristic on purpose: it must never wait
behind a queued control write, and the firmware can treat any write to it as
"vent now" without parsing.

### Control (write)

First byte is the opcode. Remaining bytes are the payload.

| Opcode | Command        | Payload                              | Notes                                           |
|--------|----------------|--------------------------------------|-------------------------------------------------|
| `0x01` | Set mode       | `u8` mode: `0` assist, `1` passive, `2` mirror | Rejected while inflating or holding.   |
| `0x02` | Set target     | `u16` target pressure, 0.1 kPa units | Firmware clamps to its own hard limit.          |
| `0x03` | Start          | none                                 | Begins repeating grip cycles in current mode.   |
| `0x04` | Stop           | none                                 | Finishes venting normally, then stays idle.     |

Example: set target to 40.0 kPa -> `02 90 01`.

### Emergency vent (write)

Any write, any length, any value. The firmware opens the vent valve, stops the
pump, ends the session, and ignores Start until a new Start is written after
the glove reports `idle`. Write without response is allowed so the command is
not delayed by a pending acknowledgement; the app writes it twice (once
without response, once with) to be sure it lands.

### Telemetry (notify)

Sent at 20 Hz while connected. One packet carries everything so values are
always in sync. 9 bytes, fits the default 20-byte ATT payload.

| Offset | Type  | Field         | Range / meaning                                         |
|--------|-------|---------------|---------------------------------------------------------|
| 0      | `u16` | Pressure      | 0.1 kPa units                                           |
| 2      | `u16` | EMG envelope  | 0-1023, rectified and smoothed on the glove             |
| 4      | `u8`  | Glove state   | `0` idle, `1` inflating, `2` holding, `3` venting       |
| 5      | `u16` | Rep count     | Completed grip cycles since power-on                    |
| 7      | `u8`  | Fault flags   | bit 0 overpressure, bit 1 inflate timeout, others reserved (0) |
| 8      | `u8`  | Sequence      | Increments every packet, wraps at 255                   |

A rep is counted when a cycle completes holding and finishes venting. A cycle
cut short by Stop or Emergency vent is not counted.

## Faults

| Flag          | Raised when                                          | Glove action        |
|---------------|------------------------------------------------------|---------------------|
| Overpressure  | Pressure exceeds the firmware hard limit             | Vent immediately    |
| Timeout       | Target not reached within 8 s of inflating           | Vent immediately    |

Flags stay set until the next Start.

## Safety requirements for the firmware

These do not depend on the app and must hold even if the app crashes:

1. **Link-loss vent.** If the BLE connection drops while inflating or
   holding, vent immediately.
2. **Hard pressure limit.** The firmware enforces its own maximum regardless
   of the target the app sends.
3. **Physical vent.** A hardware button or valve on the glove vents without
   any software. The app's STOP button is a second path, not the only one.
4. **Vent is idempotent.** Repeated emergency vent writes are safe.
