# Rohab: guidance for Claude and plugins

Flutter app (Android and iOS) companion to a soft robotic stroke-rehab glove.
Patients are stroke survivors with limited hand function, often older, often
using one hand, and sometimes with low vision. Therapists set the plan.
Test device: Redmi 7A (low-end, Android). See README.md for structure.

## Design rules (for /impeccable and any UI work)

- Calm, clinical, trustworthy. Flat blue palette, square corners (radius 0 in `lib/theme/tokens.dart`, on purpose, buttons included), MIUI
  structure (grouped rows, centred title bar), no shadows, floating nav or heavy transitions. Do not undo the "flatten the UI"
  direction.
- Accessibility comes first: touch targets of at least 56dp, body text at
  least 18sp, contrast at least 4.5:1, and the layout must survive 200% text
  scale. Never rely on color alone.
- One clear action per screen. Plain words ("Squeeze and hold"), no jargon.
- Motion is minimal and purposeful. Respect reduced motion. Nothing looping
  that distracts from the exercise.
- Keep the STOP control and the safety banner always visible and unchanged.
- Tailor changes to a low-end phone: no heavy animation, no big assets.

## Safety (do not change without asking)

- Pressure target 35 kPa, hard cap 50 kPa (`lib/config/pressure_limits.dart`).
- STOP must work at all times. Never weaken or hide it.
- Video is never saved. Store only rep counts and ranges.
- Exercise content follows `docs/rehab-science.md` and the standard therapist
  hand-exercise list. A therapist should review any new exercise before
  patients use it.

## Plugin notes

- **impeccable**: run from this folder. Run `init` first so PRODUCT.md exists.
  Target `lib/screens/` or `lib/widgets/`. Use `critique` then `audit` before
  `polish`.
- **gsap, lenis, react-bits plugins**: web only. They do not apply to this
  Flutter app. Use Flutter animation APIs here, and use those plugins only for
  a separate project website.

## Working rules

- Build and device: `export PATH=$HOME/flutter/bin:$PATH`, then
  `flutter build apk --debug`, then
  `adb -s c731ecfb0106 install -r build/app/outputs/flutter-apk/app-debug.apk`.
  After any pull or rebuild, always install and launch on the phone.
- Run `flutter test` and `flutter analyze` before saying a change is done.
- After changing drift tables run `dart run build_runner build`.
- Commit and push only when asked. Keep exercise counters pure Dart with tests.
- Report plainly what was checked on the device and what was not.
