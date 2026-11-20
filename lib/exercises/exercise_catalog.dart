/// The camera exercises. Pure Dart.
library;

/// What the exercise measures and how reps are counted.
enum ExerciseKind {
  /// Openness %, hysteresis reps.
  openClose,

  /// Thumb-to-fingertip rounds. Range shows openness %.
  fingerTouches,

  /// Spread %, hysteresis reps.
  spread,
}

class CameraExercise {
  const CameraExercise({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.targetReps,
    required this.repUnit,
    required this.steps,
  });

  /// Stable id stored with each session. Never rename.
  final String id;
  final ExerciseKind kind;
  final String title;
  final String description;
  final int targetReps;

  /// "reps" or "rounds".
  final String repUnit;

  /// Numbered instructions, at most 4 (checked in tests).
  final List<String> steps;

  /// True when the range is measured on spread instead of openness.
  bool get usesSpread => kind == ExerciseKind.spread;
}

class ExerciseCatalog {
  ExerciseCatalog._();

  static const openClose = CameraExercise(
    id: 'open_close',
    kind: ExerciseKind.openClose,
    title: 'Open and close',
    description: 'Open your hand fully, then make a fist.',
    targetReps: 10,
    repUnit: 'reps',
    steps: [
      'Rest your forearm on the table, palm facing the phone.',
      'Open your hand fully and straighten your fingers.',
      'Close your hand into a fist.',
      'Repeat slowly. The phone counts each open and close.',
    ],
  );

  static const fingerTouches = CameraExercise(
    id: 'finger_touches',
    kind: ExerciseKind.fingerTouches,
    title: 'Finger touches',
    description: 'Touch your thumb to each fingertip, one at a time.',
    targetReps: 8,
    repUnit: 'rounds',
    steps: [
      'Rest your forearm on the table, palm facing the phone.',
      'Touch your thumb to the tip of your index finger.',
      'Then your middle, ring and little finger, in that order.',
      'That is one round. Start again at the index finger.',
    ],
  );

  static const spread = CameraExercise(
    id: 'spread_fingers',
    kind: ExerciseKind.spread,
    title: 'Spread fingers',
    description: 'Spread your fingers apart, then bring them together.',
    targetReps: 10,
    repUnit: 'reps',
    steps: [
      'Rest your forearm on the table, palm facing the phone.',
      'Keep your fingers straight and spread them apart.',
      'Bring them back together.',
      'Repeat slowly.',
    ],
  );

  static const all = [openClose, fingerTouches, spread];

  static CameraExercise? byId(String id) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// The exercise after [id], or null if it's the last.
  static CameraExercise? after(String id) {
    final i = all.indexWhere((e) => e.id == id);
    return i < 0 || i + 1 >= all.length ? null : all[i + 1];
  }
}
