# Rohab

Companion app for a soft robotic stroke-rehab glove (ESP32 over Bluetooth LE).
Flutter, iOS and Android. This is the app shell: only Home is functional; the
glove is simulated by `MockGloveService`.

## Run

```
flutter pub get
flutter test
flutter run
```

## Structure

```
docs/ble-protocol.md            GATT service, characteristics, packet layout
lib/
  main.dart                     Entry point
  app/
    glove_service_factory.dart  Picks the glove implementation (the one file to change for real BLE)
    glove_scope.dart            Provides the GloveService to all screens
    app.dart                    MaterialApp, light and dark theme
  glove/
    glove_service.dart          Abstract interface the UI depends on
    glove_models.dart           Snapshot, mode, state, fault types
    mock_glove_service.dart     Simulated glove
    ble_protocol.dart           Placeholder UUIDs and opcodes from the spec
  ui/
    theme.dart                  Color, type, spacing and size tokens
    app_shell.dart              Safety banner + title + page + bottom nav
    widgets/                    SafetyBanner (STOP), BottomNav, PlaceholderBody
    screens/                    Home (functional) and four placeholders
test/
  mock_glove_service_test.dart  Simulated pressure, reps, faults, vent
  safety_stop_test.dart         STOP from every screen and state, sizes, contrast
```

## Switching to real Bluetooth

1. Add `lib/glove/ble_glove_service.dart` implementing `GloveService`, using
   the UUIDs in `lib/glove/ble_protocol.dart` (replace them with the firmware's).
2. In `lib/app/glove_service_factory.dart`, return `BleGloveService()` instead
   of `MockGloveService()`.

No screen or widget changes. Platform Bluetooth permissions (Info.plist,
AndroidManifest) are added in the same session.
