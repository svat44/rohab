import '../glove/glove_service.dart';
import '../glove/mock_glove_service.dart';

/// The one place the app chooses a glove implementation.
///
/// To switch to real Bluetooth, change this function to return the BLE
/// implementation (e.g. `BleGloveService()`). Nothing else in lib/ui changes.
GloveService createGloveService() => MockGloveService();
