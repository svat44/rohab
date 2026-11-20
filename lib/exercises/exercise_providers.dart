import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../camera/camera_permission.dart';
import '../camera/hand_tracker.dart';
import '../camera/mediapipe_hand_tracker.dart';
import '../camera/mock_hand_tracker.dart';
import '../data/connection.dart';
import '../data/database.dart';
import '../data/exercise_session_repository.dart';
import 'hand_metrics.dart';

/// Creates a hand tracker for one exercise. Tests override this.
///
/// The web preview has no MediaPipe camera path, so it uses the simulated
/// hand.
final handTrackerFactoryProvider = Provider<HandTracker Function()>((ref) {
  if (kIsWeb) {
    return () => MockHandTracker(script: MockHandTracker.cycles());
  }
  return MediaPipeHandTracker.new;
});

final cameraPermissionProvider = Provider<CameraPermission>((ref) =>
    kIsWeb ? const GrantedCameraPermission() : const SystemCameraPermission());

final appDatabaseProvider = Provider<AppDatabase?>((ref) {
  final executor = openAppDatabase();
  if (executor == null) return null;
  final db = AppDatabase(executor);
  ref.onDispose(db.close);
  return db;
});

final exerciseSessionRepositoryProvider =
    Provider<ExerciseSessionRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db == null
      ? InMemoryExerciseSessionRepository()
      : DriftExerciseSessionRepository(db);
});

/// The range learned at the start of a camera session. Lives until the
/// user taps Finish, so "Next exercise" doesn't calibrate again.
class CameraSessionRanges {
  const CameraSessionRanges({this.openness, this.spread});

  final RangeCalibration? openness;
  final RangeCalibration? spread;

  CameraSessionRanges copyWith({
    RangeCalibration? openness,
    RangeCalibration? spread,
  }) =>
      CameraSessionRanges(
        openness: openness ?? this.openness,
        spread: spread ?? this.spread,
      );
}

final cameraSessionRangesProvider =
    NotifierProvider<CameraSessionRangesNotifier, CameraSessionRanges>(
        CameraSessionRangesNotifier.new);

class CameraSessionRangesNotifier extends Notifier<CameraSessionRanges> {
  @override
  CameraSessionRanges build() => const CameraSessionRanges();

  void setOpenness(RangeCalibration r) => state = state.copyWith(openness: r);

  void setSpread(RangeCalibration r) => state = state.copyWith(spread: r);

  /// End of the camera session.
  void clear() => state = const CameraSessionRanges();
}
