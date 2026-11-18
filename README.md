# Rohab

Companion app for a soft robotic stroke-rehab glove (ESP32 over Bluetooth LE).
Flutter, iOS and Android. Home and Calibration are functional; the glove is
simulated by `MockGloveService`.

## Run

```
flutter pub get
flutter test
flutter run
```

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
  calibration/
    emg_calibrator.dart           Pure Dart math: rest, grip, threshold, validity
    calibration_controller.dart   Step state and recording
    calibration_repository.dart   Save, load, 24 h expiry (shared_preferences)
  screens/
    home_screen.dart              Connect, live pressure, start/end session
    calibration/                  Start screen and the 4 steps
    exercises_screen.dart, progress_screen.dart, settings_screen.dart   Placeholders
  widgets/
    app_shell.dart                STOP banner + wordmark + title + page + bottom nav
    safety_banner.dart            Connection status and STOP
    effort_bar.dart               Live EMG bar with markers (reused later on Exercises)
    countdown_number.dart         Large plain countdown
test/
  emg_calibrator_test.dart        Calibration math
  calibration_flow_test.dart      Full flow, Cancel/Redo, presets, expiry, controller with mocktail
  safety_stop_test.dart           STOP from every screen and state
  mock_glove_service_test.dart    Simulated pressure and EMG
```

## Switching to real Bluetooth

1. Add `lib/glove/ble_glove_service.dart` implementing `GloveService`, using
   the UUIDs in `lib/glove/ble_protocol.dart` (replace them with the
   firmware's). Unpack 5 EMG samples per notification into `emgSamples`.
2. In `lib/app/glove_service_factory.dart`, return `BleGloveService()` instead
   of `MockGloveService()`.

No screen or widget changes. Add the Bluetooth permissions (Info.plist,
AndroidManifest) at the same time.
