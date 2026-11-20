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
    mediapipe_hand_tracker.dart   Front camera + MediaPipe, live-stream mode
    mock_hand_tracker.dart        Scripted hand for tests and the web preview
    camera_permission.dart        Camera permission behind an interface
  exercises/
    hand_metrics.dart             Pure Dart: PIP angles, openness, spread, ranges
    rep_counter.dart              Hysteresis reps and finger-touch rounds
    exercise_catalog.dart         The three camera exercises
    camera_exercise_controller.dart  Steps, timing, counting, saving
    exercise_providers.dart       Tracker, permission, database, session ranges
  data/
    database.dart                 drift: exercise_sessions table
    exercise_session_repository.dart  Save and read sessions
  calibration/
    emg_calibrator.dart           Pure Dart math: rest, grip, threshold, validity
    calibration_controller.dart   Step state and recording
    calibration_repository.dart   Save, load, 24 h expiry (shared_preferences)
  screens/
    home_screen.dart              Connect, live pressure, start/end session
    calibration/                  Start screen and the 4 steps
    exercises/                    Path picker, camera list, camera exercise flow
    progress_screen.dart, settings_screen.dart   Placeholders
  widgets/
    app_shell.dart                STOP banner + wordmark + title + page + bottom nav
    safety_banner.dart            Connection status and STOP
    level_bar.dart                Flat 0-100 % bar with markers (openness, EMG, later glove)
    effort_bar.dart               Live EMG bar built on LevelBar
    countdown_number.dart         Large plain countdown
test/
  emg_calibrator_test.dart        Calibration math
  calibration_flow_test.dart      Full flow, Cancel/Redo, presets, expiry, controller with mocktail
  safety_stop_test.dart           STOP from every screen and state
  mock_glove_service_test.dart    Simulated pressure and EMG
  hand_metrics_test.dart          Angles, normalization, clamping, calibration
  rep_counter_test.dart           Reps, jitter, short reps, dropout, finger touches
  camera_flow_test.dart           Full camera flows with the mock hand
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

## Testing camera exercises on a phone

Hand tracking has only been tested with the simulated hand. On a real phone
(debug build, `flutter run`), the camera view shows tracking speed and
dropped frames in the top-left corner.

1. Normal room light, phone propped upright about 40 cm away.
2. Exercises > Camera > Open and close > Start. Allow the camera.
3. Check: the hand check passes within a couple of seconds; fps stays at 15
   or more; reps count once per open-close; covering the camera for 3 s shows
   "Hold your hand inside the frame." and no rep is counted.
4. Repeat with the other hand, then try Finger touches and Spread fingers.
5. Note fps, dropped frames, any missed or extra reps, and the phone model.
