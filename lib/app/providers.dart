import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../calibration/calibration_repository.dart';
import '../calibration/emg_calibrator.dart';
import '../glove/glove_service.dart';
import 'glove_service_factory.dart';

/// The glove. Tests override this with their own instance.
final gloveServiceProvider = Provider<GloveService>((ref) {
  final glove = createGloveService();
  ref.onDispose(glove.dispose);
  return glove;
});

/// Simulated gloves accept on-screen cues; real hardware returns null.
final patientCueProvider = Provider<PatientCueSink?>((ref) {
  final glove = ref.watch(gloveServiceProvider);
  return glove is PatientCueSink ? glove as PatientCueSink : null;
});

/// Overridden in main() once SharedPreferences has loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider'),
);

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final calibrationRepositoryProvider = Provider<CalibrationRepository>(
  (ref) => CalibrationRepository(
    ref.watch(sharedPreferencesProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// The saved calibration (may be expired), kept in sync with storage.
final savedCalibrationProvider =
    NotifierProvider<SavedCalibration, Calibration?>(SavedCalibration.new);

class SavedCalibration extends Notifier<Calibration?> {
  @override
  Calibration? build() => ref.watch(calibrationRepositoryProvider).load();

  Future<void> save(Calibration calibration) async {
    await ref.read(calibrationRepositoryProvider).save(calibration);
    state = calibration;
  }
}

/// True when there is no calibration or it is older than 24 hours.
final calibrationNeededProvider = Provider<bool>((ref) {
  final c = ref.watch(savedCalibrationProvider);
  return c == null || c.isExpiredAt(ref.watch(clockProvider)());
});

/// Sends the saved threshold to the glove each time it connects.
final thresholdSyncProvider = Provider<void>((ref) {
  final glove = ref.watch(gloveServiceProvider);
  var wasConnected = glove.snapshot.value.isConnected;
  void onChange() {
    final connected = glove.snapshot.value.isConnected;
    if (connected && !wasConnected) {
      final c = ref.read(savedCalibrationProvider);
      if (c != null && !c.isExpiredAt(ref.read(clockProvider)())) {
        glove.setEmgThreshold(c.threshold);
      }
    }
    wasConnected = connected;
  }

  glove.snapshot.addListener(onChange);
  ref.onDispose(() => glove.snapshot.removeListener(onChange));
});
