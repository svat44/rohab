/// The camera exercises, in three levels. Pure Dart.
///
/// Levels follow the evidence in docs/rehab-science.md: finger extension is
/// the main deficit after stroke, so level 1 trains opening the hand with
/// any measurable movement; level 2 trains the functional grasps scored in
/// the Fugl-Meyer hand items (cylinder, hook, pinch); level 3 trains
/// single-finger control and opposition.
library;

/// How an exercise is counted.
enum ExerciseKind {
  /// Open/close with a wider tolerance (70 % / 30 % of the user's range).
  openCloseGentle,

  /// Open the hand and hold it open for 3 s, then relax.
  holdOpen,

  /// Full open/close (80 % / 20 %).
  openClose,

  /// Close around an object, hold 2 s, release fully.
  cylinder,

  /// Knuckles straight, finger joints bent (carrying-a-bag grip), then open.
  hook,

  /// Thumb tip to index tip, then apart.
  pinch,

  /// Thumb to each fingertip in order; one round = four touches.
  fingerTouches,

  /// Straighten one finger at a time while the others stay bent.
  fingerLifts,

  /// Spread fingers apart, then together.
  spread,
}

class CameraExercise {
  const CameraExercise({
    required this.id,
    required this.level,
    required this.kind,
    required this.title,
    required this.description,
    required this.repUnit,
    required this.steps,
    this.object,
    this.setSizeFactor = 1,
    this.repHigh = 80,
    this.repLow = 20,
  });

  /// Stable id stored with each session. Never rename.
  final String id;

  /// 1, 2 or 3.
  final int level;
  final ExerciseKind kind;
  final String title;
  final String description;

  /// "reps", "holds" or "rounds".
  final String repUnit;

  /// Numbered instructions, at most 4 (checked in tests).
  final List<String> steps;

  /// Open/close style exercises count a rep when the movement reaches
  /// [repHigh] percent of the person's range, then [repLow], then [repHigh]
  /// again. Per exercise so a gentler exercise can use wider bands.
  /// Hold and posture exercises ignore these.
  final double repHigh;
  final double repLow;

  /// Something to hold, if needed.
  final String? object;

  /// Holds and rounds take longer than single reps, so their sets are
  /// smaller: set size x this factor.
  final double setSizeFactor;

  /// True when the range is measured on spread instead of finger bend.
  bool get usesSpread => kind == ExerciseKind.spread;

  /// Whether counting depends on the person's open/closed range. Finger
  /// touches, finger lifts and the pinch use fingertip distances and
  /// relative finger angles instead, so they skip the open/fist step.
  bool get needsRange =>
      kind != ExerciseKind.fingerTouches &&
      kind != ExerciseKind.fingerLifts &&
      kind != ExerciseKind.pinch;

  int setSizeFor(int baseSetSize) =>
      (baseSetSize * setSizeFactor).round().clamp(1, 1000);
}

class ExerciseCatalog {
  ExerciseCatalog._();

  static const _rest =
      'Rest your forearm on the table, side of the hand facing the phone.';

  // ---- Level 1: any measurable movement --------------------------------

  static const openCloseGentle = CameraExercise(
    id: 'open_close_gentle',
    level: 1,
    kind: ExerciseKind.openCloseGentle,
    title: 'Open and close, gently',
    description: 'Open your hand as far as you can, then close it.',
    repUnit: 'reps',
    repHigh: 70,
    repLow: 30,
    steps: [
      _rest,
      'Keep your wrist still.',
      'Open your hand as far as it goes. Any amount counts.',
      'Close it again. Go slowly.',
    ],
  );

  static const holdOpen = CameraExercise(
    id: 'hold_open',
    level: 1,
    kind: ExerciseKind.holdOpen,
    title: 'Hold your hand open',
    description: 'Open your hand and hold it for 3 seconds.',
    repUnit: 'holds',
    setSizeFactor: 0.5,
    steps: [
      _rest,
      'Keep your wrist still.',
      'Open your hand as far as you can and hold it for 3 seconds.',
      'Relax your hand, then start again.',
    ],
  );

  // ---- Level 2: functional grasps --------------------------------------

  static const openClose = CameraExercise(
    id: 'open_close',
    level: 2,
    kind: ExerciseKind.openClose,
    title: 'Open and close',
    description: 'Open your hand fully, then make a fist.',
    repUnit: 'reps',
    steps: [
      _rest,
      'Keep your wrist still.',
      'Open your hand fully and straighten your fingers.',
      'Close your hand into a fist.',
    ],
  );

  static const cylinder = CameraExercise(
    id: 'cylinder_grasp',
    level: 2,
    kind: ExerciseKind.cylinder,
    title: 'Grip a cup',
    description: 'Close your hand around a cup, hold, then let go.',
    repUnit: 'reps',
    object: 'An empty plastic cup or a rolled towel',
    steps: [
      'Stand the cup on the table next to your hand.',
      'Close your fingers around it and hold for 2 seconds.',
      'Let go and open your hand fully.',
      'Keep your wrist still.',
    ],
  );

  static const hook = CameraExercise(
    id: 'hook_grip',
    level: 2,
    kind: ExerciseKind.hook,
    title: 'Hook grip',
    description: 'Bend your fingers like holding a bag handle.',
    repUnit: 'reps',
    steps: [
      _rest,
      'Keep your knuckles straight and bend the rest of your fingers, '
          'like holding a bag handle.',
      'Hold for 1 second.',
      'Open your hand fully.',
    ],
  );

  static const pinch = CameraExercise(
    id: 'pinch',
    level: 2,
    kind: ExerciseKind.pinch,
    title: 'Pinch',
    description: 'Touch your thumb and index fingertip together.',
    repUnit: 'reps',
    steps: [
      _rest,
      'Touch the tip of your thumb to the tip of your index finger.',
      'Hold briefly, then move them apart.',
      'Keep your other fingers relaxed.',
    ],
  );

  // ---- Level 3: single-finger control ----------------------------------

  static const fingerTouches = CameraExercise(
    id: 'finger_touches',
    level: 3,
    kind: ExerciseKind.fingerTouches,
    title: 'Finger touches',
    description: 'Touch your thumb to each fingertip, one at a time.',
    repUnit: 'rounds',
    setSizeFactor: 0.5,
    steps: [
      'Hold your hand up, palm facing the phone.',
      'Touch your thumb to the tip of your index finger.',
      'Then your middle, ring and little finger, in that order.',
      'That is one round. Start again at the index finger.',
    ],
  );

  static const fingerLifts = CameraExercise(
    id: 'finger_lifts',
    level: 3,
    kind: ExerciseKind.fingerLifts,
    title: 'One finger at a time',
    description: 'Straighten one finger while the others stay bent.',
    repUnit: 'rounds',
    setSizeFactor: 0.5,
    steps: [
      'Make a loose fist, side of the hand facing the phone.',
      'Straighten your index finger only, then bend it again.',
      'Then your middle, ring and little finger, in that order.',
      'That is one round.',
    ],
  );

  static const spread = CameraExercise(
    id: 'spread_fingers',
    level: 3,
    kind: ExerciseKind.spread,
    title: 'Spread fingers',
    description: 'Spread your fingers apart, then bring them together.',
    repUnit: 'reps',
    steps: [
      'Hold your hand up, palm facing the phone.',
      'Keep your fingers straight and spread them apart.',
      'Bring them back together.',
      'Repeat slowly.',
    ],
  );

  static const all = [
    openCloseGentle,
    holdOpen,
    openClose,
    cylinder,
    hook,
    pinch,
    fingerTouches,
    fingerLifts,
    spread,
  ];

  static List<CameraExercise> forLevel(int level) =>
      [for (final e in all) if (e.level == level) e];

  static CameraExercise? byId(String id) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }
}
