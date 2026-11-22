# Rohab

Companion app for a soft robotic stroke-rehab glove (ESP32 over Bluetooth LE).
Flutter, iOS and Android. Home, Calibration and camera Exercises are
functional; the glove is simulated by `MockGloveService`. Camera exercises
work without a glove: the front camera and Google's MediaPipe Hand Landmarker
(package `mediapipe_vision`) track the hand on the phone. Video is never
saved; only rep counts and ranges are stored.

## Run

```
flutter pub get
flutter test
flutter run
```

The hand model (`assets/mediapipe/`) is committed. After changing the
`hooks: user_defines: mediapipe_vision` list in pubspec.yaml, run
`dart run mediapipe_core:bundle_models`. After changing the drift tables,
run `dart run build_runner build`.

Requirements from MediaPipe: Android minSdk 28, iOS 15. The iOS project uses
Swift Package Manager; `permission_handler` enables the camera permission
from `NSCameraUsageDescription`. If you switch to CocoaPods, add
`PERMISSION_CAMERA=1` to the Podfile's preprocessor definitions.

In debug builds, long-press the "Rohab" wordmark to choose the simulated
patient's grip: Strong, Weak or No signal.

## Structure

```
docs/ble-protocol.md              GATT service, characteristics, packet layouts, EMG contract
lib/
  main.dart                       Entry point (loads SharedPreferences, ProviderScope)
  app/
    glove_service_factory.dart    Picks the glove implementation (the one file to change for real BLE)
    providers.dart                Riverpod providers: glove, storage, calibration, threshold sync
    router.dart                   go_router: one branch per screen inside AppShell
    app.dart                      MaterialApp.router, light and dark theme
  theme/
    tokens.dart                   Brand tokens: color, type, spacing, radius, sizes, motion
    app_theme.dart                ThemeData built from the tokens
  glove/
    glove_service.dart            Abstract interface the UI depends on
    glove_models.dart             Snapshot, mode, state, fault types
    mock_glove_service.dart       Simulated glove, 50 Hz EMG, grip presets
    ble_protocol.dart             Placeholder UUIDs and opcodes from the spec
  camera/
    hand_tracker.dart             HandTracker interface and HandFrame
    frame_geometry.dart           Pure Dart: per-platform frame rotation, mirroring and aspect
    mediapipe_hand_tracker.dart   Front camera + MediaPipe, live-stream mode
    mock_hand_tracker.dart        Scripted hand for tests and the web preview
    camera_permission.dart        Camera permission behind an interface
  exercises/
    joint_angles.dart             Pure Dart: MCP/PIP/DIP and thumb angles from 3D world landmarks
    movement_quality.dart         One Euro filter, SPARC smoothness, per-rep stats, fatigue
    hand_metrics.dart             Pure Dart: palm-normalized distances, spread, ranges
    rep_counter.dart              Hysteresis reps and finger-touch rounds
    exercise_catalog.dart         The 17 camera exercises, in three levels
    camera_exercise_controller.dart  Steps, timing, counting, saving
    exercise_providers.dart       Tracker, permission, database, session ranges
  data/
    database.dart                 drift: exercise_sessions, assessments, pain_checks (schema 3)
    exercise_session_repository.dart  Save and read sessions
    program_repository.dart       Hand measurements and pain checks
  calibration/
    emg_calibrator.dart           Pure Dart math: rest, grip, threshold, validity
    calibration_controller.dart   Step state and recording
    calibration_repository.dart   Save, load, 24 h expiry (shared_preferences)
  screens/
    home_screen.dart              Connect, live pressure, start/end session
    calibration/                  Start screen and the 4 steps
    exercises/                    Path picker, today's plan, hand measurement, pain check, exercise flow
    settings/                     Settings and the therapist plan
    progress_screen.dart, settings_screen.dart   Placeholders
  widgets/
    app_shell.dart                STOP banner + wordmark + title + page + bottom nav
    safety_banner.dart            Connection status and STOP
    rohab_widgets.dart            RohabCard, IconBadge, InfoChip, SectionTitle, exercise icons
    level_bar.dart                Flat 0-100 % bar with markers (openness, EMG, later glove)
    effort_bar.dart               Live EMG bar built on LevelBar
    countdown_number.dart         Large plain countdown
test/
  emg_calibrator_test.dart        Calibration math
  calibration_flow_test.dart      Full flow, Cancel/Redo, presets, expiry, controller with mocktail
  safety_stop_test.dart           STOP from every screen and state
  mock_glove_service_test.dart    Simulated pressure and EMG
  joint_angles_test.dart          Joint angles for both hands, sign, size independence
  movement_quality_test.dart      Filter, SPARC, rep stats, swings, fatigue
  hand_metrics_test.dart          Angles, normalization, clamping, calibration
  rep_counter_test.dart           Reps, jitter, short reps, dropout, finger touches
  camera_flow_test.dart           Measuring, plan, sets, wrist check, pain, therapist, counting
  program_test.dart               Placement, plan, progression, pain rules, PIN
  exercise_counters_test.dart     Every exercise's counter and the wrist monitor
  exercise_session_repository_test.dart  drift table and repository
```

## Switching to real Bluetooth

1. Add `lib/glove/ble_glove_service.dart` implementing `GloveService`, using
   the UUIDs in `lib/glove/ble_protocol.dart` (replace them with the
   firmware's). Unpack 5 EMG samples per notification into `emgSamples`.
2. In `lib/app/glove_service_factory.dart`, return `BleGloveService()` instead
   of `MockGloveService()`.

No screen or widget changes. Add the Bluetooth permissions (Info.plist,
AndroidManifest) at the same time.

## Exercise program (camera)

Built from `docs/rehab-science.md`:

1. **Measure hands** (`lib/program/baseline*.dart`): open and close each
   hand twice; finger bend in degrees, affected hand against the other.
   Sets the level and is suggested again after 7 days.
2. **Levels** (`lib/exercises/exercise_catalog.dart`). The exercises are the
   standard no-equipment hand exercises therapists give after stroke, plus
   graded grasps:
   - 1, opening and stretching: open and close gently, open wide and hold
     (3 s), hand squeezes (5 s), thumb extension (5 s), wrist stretch,
     finger stretch with the other hand's help (5 s).
   - 2, everyday grips and forearm: open and close, cup grip, hook grip,
     pinch, wrist rotation (palm up and back), hand slide.
   - 3, single fingers: finger tapping / thumb opposition, one finger at a
     time, spread fingers, tabletop finger lift, finger walking.

   Each counter is pure Dart in `exercise_counters.dart` and tested in
   `test/therapist_exercises_test.dart` with a synthetic hand. The camera
   only sees the hand, so the finger stretch (the other hand does the work)
   is counted as a held, straight hand, and the wrist exercises turn off the
   "wrist moved" rule and the finger-range readout.
3. **Daily plan** (`lib/program/daily_plan.dart`): a rep goal (starts at
   100, max 300) split into sets with rest; exercises rotate by day. The
   goal rises 10 % after a full day without fatigue or more pain, and drops
   10 % when pain rose.
4. **Wrist check** (`WristMonitor` in `exercise_counters.dart`): a rep made
   by tilting the hand at the wrist more than 25 degrees does not count.
5. **Pain** 0-10 before the first set and after the last: high pain advises
   rest; a rise of 2 or more lowers the next goal.
6. **Therapist plan** (Settings, 4-digit PIN): level override, goals, set
   size, rest, pain limits, automatic progression.

## Camera orientation (why the hand was drawn off the real hand)

The `camera` plugin delivers frames differently per platform, read from its
sources (see `lib/camera/frame_geometry.dart`): on **iOS** the front-camera
frames arrive already upright and already mirrored, on **Android** they are
the raw, unmirrored sensor buffer. Rotating iOS frames by the sensor angle,
and flipping x again when drawing, made MediaPipe see a sideways hand
(tracking almost never started) and drew the skeleton mirrored. The tracker
now rotates and mirrors per platform, labels the hand accordingly, sizes the
camera view by the analysed image, and the app is locked to portrait
(`main.dart`, Info.plist, AndroidManifest). Not yet confirmed on a physical
phone; checking it is step 3 of "Testing camera exercises on a phone".

## Hand tracking test page

`tools/camera-test/index.html` runs the same MediaPipe hand model and the
same joint-angle math (ported from `lib/exercises/joint_angles.dart`) in a
desktop browser. Open the file in Chrome, press Start camera and allow the
camera. It shows the 21 hand points, MCP/PIP/DIP angles per finger, finger
bend, range of motion and tracking speed. It needs internet to load the
model; video never leaves the browser. Keep its math in step with the Dart
code.

Background research behind the measurements: `docs/rehab-science.md`.

## Testing camera exercises on a phone

Hand tracking has only been tested with the simulated hand. On a real phone
(debug build, `flutter run`), the camera view shows tracking speed and
dropped frames in the top-left corner.

1. Normal room light, phone propped upright about 40 cm away.
2. Exercises > Camera > Open and close > Start. Allow the camera.
3. Check: the hand check passes within a couple of seconds; fps stays at 15
   or more; reps count once per open-close; covering the camera for 3 s shows
   "Hold your hand inside the frame." and no rep is counted.
4. Move the hand to the left of the frame: the drawn skeleton must stay on
   the hand, on the same side (this is the mirroring check). Repeat with the
   other hand, then try Finger tapping and Spread fingers.
5. Note fps, dropped frames, any missed or extra reps, and the phone model.

## Camera test protocol (debug builds, on a phone)

Long-press the "Rohab" title to open the debug menu.

- **Diagnostics overlay**: turn it on, then start any exercise. It shows
  FPS, the share of frames with confidence of at least 0.6 over the last
  10 s, the current dropout length, openness and rep state, and logs the
  same line to the console about once a second. No landmarks, images or
  video are stored or logged.
- **Test protocol**: runs three poses (full open/close, limited range,
  curled hand) through the real exercise flow, 30 s of counting each, and
  prints a table: average FPS, detection %, dropouts over 0.5 s, reps, and
  whether 10 reps fit in 60 s (projected from the 30 s run). "OK" needs
  FPS >= 15, detection >= 90 %, at most 2 dropouts and 10 reps per 60 s.
  Those limits are this project's choice, not clinical values.

`test/pose_protocol_sim_test.dart` runs the same table with a scripted hand.
It checks the counting and calibration logic only, not camera detection.
