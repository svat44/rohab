# Glove BLE protocol (v0.2, draft)

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
| EMG             | `7a1e0004-5c3d-4f2b-9b8e-0d3c2a1f6e00` | Notify                        | Glove -> app  |

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
| `0x05` | Set EMG threshold | `u16` level, 0-1023               | Trigger for assisted grip. See below.           |

Example: set target to 40.0 kPa -> `02 90 01`. Set EMG threshold to 188 ->
`05 BC 00`.

**EMG threshold.** The app sends it after a calibration is saved and each
time it connects, if the saved calibration is less than 24 hours old. The
firmware keeps the last value in RAM. In assist mode during a session, the
glove starts a grip cycle when the 150 ms moving average of the EMG (the
last 8 samples) rises to or above the threshold, and does not start another
until the average has dropped below it again. Until a threshold is received,
the firmware does not trigger from EMG at all.

### Emergency vent (write)

Any write, any length, any value. The firmware opens the vent valve, stops the
pump, ends the session, and ignores Start until a new Start is written after
the glove reports `idle`. Write without response is allowed so the command is
not delayed by a pending acknowledgement; the app writes it twice (once
without response, once with) to be sure it lands.

### Telemetry (notify)

Sent at 20 Hz while connected. 7 bytes. EMG is not in this packet; it has
its own faster stream (below).

| Offset | Type  | Field         | Range / meaning                                         |
|--------|-------|---------------|---------------------------------------------------------|
| 0      | `u16` | Pressure      | 0.1 kPa units                                           |
| 2      | `u8`  | Glove state   | `0` idle, `1` inflating, `2` holding, `3` venting       |
| 3      | `u16` | Rep count     | Completed grip cycles since power-on                    |
| 5      | `u8`  | Fault flags   | bit 0 overpressure, bit 1 inflate timeout, others reserved (0) |
| 6      | `u8`  | Sequence      | Increments every packet, wraps at 255                   |

A rep is counted when a cycle completes holding and finishes venting. A cycle
cut short by Stop or Emergency vent is not counted.

### EMG (notify)

The ESP32 streams the MyoWare envelope (ENV output) scaled to 0-1023 at
50 Hz on this characteristic. Samples are batched: one notification every
100 ms carries 5 samples, oldest first. 11 bytes.

| Offset | Type     | Field     | Meaning                                    |
|--------|----------|-----------|--------------------------------------------|
| 0      | `u8`     | Sequence  | Increments every notification, wraps at 255 |
| 1      | `u16` x5 | Samples   | Envelope, 0-1023, 20 ms apart              |

Scaling: the ESP32 ADC is 12-bit (0-4095), so send `raw >> 2`. Sample on a
hardware timer, not in the BLE callback, so spacing stays at 20 ms. Do not
smooth further on the glove: the MyoWare envelope is already rectified and
smoothed, and the app's calibration statistics assume that signal.

The app uses the sequence number to detect dropped notifications.
Calibration counts samples, not time, so a lost packet makes a step a little
longer instead of corrupting it.

**Values the app expects from a correctly placed sensor** (these are what
the mock simulator produces):

| Condition         | Mean | SD  | Notes                                   |
|-------------------|------|-----|-----------------------------------------|
| Hand at rest      | 60   | 10  |                                         |
| Strong grip       | 380  | 40  | Ramps from rest in about 300 ms          |
| Weak grip         | 140  | 25  | Must still calibrate successfully       |
| Sensor off muscle | 65   | 10  | Must fail calibration                   |

Calibration accepts a result only if the grip level is at least rest + 3 SD
and at least 1.5 x rest. With rest at 60 and SD 10, the grip level must be at
least 90.

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
