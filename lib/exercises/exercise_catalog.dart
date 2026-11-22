/// The camera exercises, in three levels. Pure Dart.
///
/// These are the standard no-equipment hand exercises that therapists give
/// stroke patients (finger tapping, wrist stretch, open and close, thumb
/// opposition, wrist rotation, tabletop finger lift, finger extension, hand
/// squeeze, thumb extension, finger walking, hand slide), plus the graded
/// grasps from docs/rehab-science.md.
///
/// Levels: finger extension is the main deficit after stroke, so level 1 is
/// gentle opening, squeezing and stretching with any measurable movement;
/// level 2 is the functional grasps scored in the Fugl-Meyer hand items
/// (cylinder, hook, pinch) plus forearm and wrist control; level 3 is
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

  /// Make a fist, squeeze and hold 5 s, then relax (hand squeezes).
  squeeze,

  /// Move the thumb away from the fingers, hold 5 s, relax.
  thumbExtension,

  /// Bend the wrist away from straight and back (wrist stretch).
  wristStretch,

  /// Hand held open by the other hand's help for 5 s (finger extension
  /// stretch). The camera only checks the fingers end up straight.
  assistedExtension,

  /// Turn the palm over and back (forearm rotation).
  wristRotation,

  /// Slide the hand away across the table and back.
  handSlide,

  /// Hand flat: lift each finger in turn and lower it (tabletop finger lift).
  flatFingerLifts,

  /// Hand flat: finger walking, index to little and back again.
  fingerWalking,
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
    this.target,
    this.assistWithOtherHand = false,
  });

  /// The other hand helps (finger extension): shown on the instructions.
  final bool assistWithOtherHand;

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

  /// The wrist is meant to move (wrist stretch, wrist rotation, hand slide),
  /// so the "wrist moved, rep did not count" rule is off.
  bool get movesWrist =>
      kind == ExerciseKind.wristStretch ||
      kind == ExerciseKind.wristRotation ||
      kind == ExerciseKind.handSlide;

  /// Whether the finger-bend range (degrees) says anything about this
  /// exercise. It does not when the wrist or the whole hand is the thing
  /// that moves, or when single fingers are lifted.
  bool get reportsRange =>
      kind != ExerciseKind.wristStretch &&
      kind != ExerciseKind.wristRotation &&
      kind != ExerciseKind.handSlide &&
      kind != ExerciseKind.thumbExtension &&
      kind != ExerciseKind.flatFingerLifts &&
      kind != ExerciseKind.fingerWalking;

  /// Plain text for the "how long" line on the instructions: reps, or a
  /// hold time, so the person knows what a repetition is.
  final String? target;

  /// Whether counting depends on the person's open/closed range. Finger
  /// touches, finger lifts and the pinch use fingertip distances and
  /// relative finger angles instead, so they skip the open/fist step.
  bool get needsRange =>
      kind != ExerciseKind.fingerTouches &&
      kind != ExerciseKind.fingerLifts &&
      kind != ExerciseKind.pinch &&
      kind != ExerciseKind.thumbExtension &&
      kind != ExerciseKind.wristStretch &&
      kind != ExerciseKind.wristRotation &&
      kind != ExerciseKind.handSlide &&
      kind != ExerciseKind.flatFingerLifts &&
      kind != ExerciseKind.fingerWalking;

  int setSizeFor(int baseSetSize) =>
      (baseSetSize * setSizeFactor).round().clamp(1, 1000);
}

class ExerciseCatalog {
  ExerciseCatalog._();

  static const _rest =
      'Rest your forearm on the table, side of the hand facing the phone.';
  static const _flat =
      'Rest your hand flat on the table, side of the hand facing the phone.';

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
    target: '10 times',
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
    title: 'Open wide and hold',
    description: 'Open your hand as wide as you can and hold it.',
    repUnit: 'holds',
    setSizeFactor: 0.5,
    target: '10 times, hold 3 seconds',
    steps: [
      'Start with your hand in a loose fist, resting on the table.',
      'Slowly open your hand as wide as you can and hold it for 3 seconds.',
      'Relax and close it again.',
      'Keep your wrist still.',
    ],
  );

  static const handSqueeze = CameraExercise(
    id: 'hand_squeeze',
    level: 1,
    kind: ExerciseKind.squeeze,
    title: 'Hand squeezes',
    description: 'Make a gentle fist, squeeze, then relax.',
    repUnit: 'squeezes',
    setSizeFactor: 0.5,
    target: '10 times, hold 5 seconds',
    steps: [
      _rest,
      'Make a fist and squeeze gently.',
      'Hold for 5 seconds.',
      'Relax and open your hand.',
    ],
  );

  static const thumbExtension = CameraExercise(
    id: 'thumb_extension',
    level: 1,
    kind: ExerciseKind.thumbExtension,
    title: 'Thumb extension',
    description: 'Move your thumb away from your fingers and hold.',
    repUnit: 'holds',
    setSizeFactor: 0.5,
    target: '10 times, hold 5 seconds',
    steps: [
      'Rest your hand flat on the table, palm down, facing the phone.',
      'Move your thumb out and away from your fingers.',
      'Hold for 5 seconds.',
      'Relax your thumb back beside your hand.',
    ],
  );

  static const wristStretch = CameraExercise(
    id: 'wrist_stretch',
    level: 1,
    kind: ExerciseKind.wristStretch,
    title: 'Wrist stretch',
    description: 'Gently bend your wrist up and down.',
    repUnit: 'reps',
    target: '10 times',
    steps: [
      'Rest your forearm on the table with your hand hanging over the edge, '
          'side of the hand facing the phone.',
      'If it helps, hold your forearm with your other hand.',
      'Gently bend your wrist up, then back to straight.',
      'Go slowly. Stop if it hurts.',
    ],
  );

  static const assistedExtension = CameraExercise(
    id: 'finger_extension_assisted',
    level: 1,
    kind: ExerciseKind.assistedExtension,
    title: 'Finger stretch',
    description: 'Use your other hand to lift your fingers straight.',
    repUnit: 'holds',
    setSizeFactor: 0.5,
    target: '5 to 10 times, hold 5 seconds',
    assistWithOtherHand: true,
    steps: [
      _flat,
      'Use your other hand to gently lift your fingers up and straighten them.',
      'Hold for 5 seconds, then let go.',
      'Keep your other hand out of the way of the camera.',
    ],
  );

  // ---- Level 2: functional grasps, forearm and wrist ---------------------

  static const openClose = CameraExercise(
    id: 'open_close',
    level: 2,
    kind: ExerciseKind.openClose,
    title: 'Open and close',
    description: 'Open your hand fully, then make a fist.',
    repUnit: 'reps',
    target: '10 times',
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
    target: '10 times, hold 2 seconds',
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
    target: '10 times, hold 1 second',
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
    target: '10 times',
    steps: [
      _rest,
      'Touch the tip of your thumb to the tip of your index finger.',
      'Hold briefly, then move them apart.',
      'Keep your other fingers relaxed.',
    ],
  );

  static const wristRotation = CameraExercise(
    id: 'wrist_rotation',
    level: 2,
    kind: ExerciseKind.wristRotation,
    title: 'Wrist rotation',
    description: 'Turn your palm up, then back down.',
    repUnit: 'reps',
    target: '10 times',
    steps: [
      'Hold your hand out in front of the phone, palm down, elbow resting '
          'on the table.',
      'Slowly turn your hand so your palm faces up.',
      'Then turn it back, palm down.',
      'Keep your elbow still and go slowly.',
    ],
  );

  static const handSlide = CameraExercise(
    id: 'hand_slide',
    level: 2,
    kind: ExerciseKind.handSlide,
    title: 'Hand slide',
    description: 'Slide your hand forward on the table, then back.',
    repUnit: 'reps',
    target: '10 to 15 times',
    steps: [
      'Rest your hand flat on the table, fingers facing the phone.',
      'Slide your hand and forearm forward, as far as is comfortable.',
      'Slide it back. A smooth cloth under your hand helps. Your other '
          'hand may help you.',
      'Stay within a comfortable range.',
    ],
  );

  // ---- Level 3: single-finger control ----------------------------------

  static const fingerTouches = CameraExercise(
    id: 'finger_touches',
    level: 3,
    kind: ExerciseKind.fingerTouches,
    title: 'Finger tapping',
    description: 'Touch your thumb to each fingertip, one at a time.',
    repUnit: 'rounds',
    setSizeFactor: 0.5,
    target: '10 rounds',
    steps: [
      'Hold your hand up, palm facing the phone.',
      'Touch your thumb to the tip of your index finger. Try to make a '
          'round circle.',
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
    target: '5 to 10 rounds',
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
    target: '10 times',
    steps: [
      'Hold your hand up, palm facing the phone.',
      'Keep your fingers straight and spread them apart.',
      'Bring them back together.',
      'Repeat slowly.',
    ],
  );

  static const flatFingerLifts = CameraExercise(
    id: 'tabletop_finger_lift',
    level: 3,
    kind: ExerciseKind.flatFingerLifts,
    title: 'Tabletop finger lift',
    description: 'Lift each finger off the table, one at a time.',
    repUnit: 'rounds',
    setSizeFactor: 0.5,
    target: '10 rounds',
    steps: [
      _flat,
      'Lift your index finger off the table, then lower it.',
      'Then your middle, ring and little finger, in that order.',
      'That is one round. Keep the other fingers on the table.',
    ],
  );

  static const fingerWalking = CameraExercise(
    id: 'finger_walking',
    level: 3,
    kind: ExerciseKind.fingerWalking,
    title: 'Finger walking',
    description: 'Walk your fingers forward, then back.',
    repUnit: 'rounds',
    setSizeFactor: 0.5,
    target: '10 rounds',
    steps: [
      'Rest your hand on the table, fingers slightly apart, side of the '
          'hand facing the phone.',
      'Walk your fingers one by one: index, middle, ring, little.',
      'Then walk back: ring, middle, index.',
      'That is one round.',
    ],
  );

  static const all = [
    openCloseGentle,
    holdOpen,
    handSqueeze,
    thumbExtension,
    wristStretch,
    assistedExtension,
    openClose,
    cylinder,
    hook,
    pinch,
    wristRotation,
    handSlide,
    fingerTouches,
    fingerLifts,
    spread,
    flatFingerLifts,
    fingerWalking,
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
