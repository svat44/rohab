# Design redesign summary

## What was wrong
Roboto and thin giant numbers, centred stacks, wireframe cards, a pill nav indicator, a dead Progress filter,
two different "days" numbers, a missing reps-per-set control, a low-contrast disabled button, a duplicated Glove
block on Home, 24 h time hard-coded, and jargon ("Trigger level").

## What changed
- Foundation: bundled fonts (Atkinson Hyperlegible Next, Source Sans 3, SIL OFL texts registered), one teal palette,
  tokens, contrast script (`dart run tool/contrast.dart`) and test; all 24 pairs pass AA (`contrast.md`).
- Components: RohabTheme, RohabAppBar, RohabNavBar, RohabRow/Group/SectionLabel, UnderlineTabs, SquareSegmented,
  RohabButton, RohabStepper, ResultPanel, SegmentedBar, HeroBubbles, EmptyState, StopButton, MetricText, RohabIcon.
- Screens: Today, Glove, Exercises (menu, list, setup), camera session, Progress (real 7/30/90 range), Settings.
- STOP is now a top-right stop sign shown only while the glove is active (user request; needs safety review).

## Checks
- `flutter analyze`: 0 issues. `flutter test`: 321 passed (baseline 299).
- Pressure limits (35 / 50 kPa), BLE, EMG maths and rep thresholds: no diff (`git diff` on lib/config, lib/glove,
  emg_calibrator, counters is empty; only two calibration-start copy strings changed).
- Greps over `lib/` (excluding tokens/palette): `GoogleFonts` 0, `StadiumBorder` 0, `BoxShadow` 0, `Gradient` 0,
  `Roboto` 0, `Colors.` 0; `fontFamily:` only in the theme, the STOP/debug screens; Material `Icons.` 0 outside debug.
- Seen on the Redmi 7A (release build): Today, Glove, Exercises, Practice list, Progress.

## Could NOT be verified
- Real on-device camera fps: not measured, not improved. No figure is claimed.
- 200% text and 412x915 captures; before/after pairs; Settings, setup, camera and STOP sign on device.
- Glove behaviour with real hardware (mock glove only).
- Remaining items are listed in `issues.md` under Open items.
