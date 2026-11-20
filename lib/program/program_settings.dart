/// Plan settings a therapist can adjust. Pure Dart.
library;

class ProgramSettings {
  const ProgramSettings({
    this.levelOverride,
    this.startingGoal = 100,
    this.maxGoal = 300,
    this.setSize = 10,
    this.restSeconds = 60,
    this.autoProgress = true,
    this.painRiseLimit = 2,
    this.painHighLimit = 7,
  });

  static const defaults = ProgramSettings();

  /// Null = use the level from the hand measurement.
  final int? levelOverride;

  /// Daily rep goal on the first day, and after a reset.
  final int startingGoal;

  /// Goal ceiling. About 300 reps per session is the working target in the
  /// research (Birkenmeier, Prager & Lang).
  final int maxGoal;

  /// Reps per set (holds and rounds use half).
  final int setSize;

  /// Rest between sets.
  final int restSeconds;

  /// Raise the goal when the last day's goal was met without fatigue or
  /// more pain.
  final bool autoProgress;

  /// Pain rising by this much from before to after a session is a warning.
  final int painRiseLimit;

  /// Pain at or above this before starting: advise rest.
  final int painHighLimit;

  static const goalRange = (min: 20, max: 400);
  static const setRange = (min: 5, max: 30);
  static const restRange = (min: 15, max: 180);

  ProgramSettings copyWith({
    int? Function()? levelOverride,
    int? startingGoal,
    int? maxGoal,
    int? setSize,
    int? restSeconds,
    bool? autoProgress,
    int? painRiseLimit,
    int? painHighLimit,
  }) =>
      ProgramSettings(
        levelOverride:
            levelOverride == null ? this.levelOverride : levelOverride(),
        startingGoal: startingGoal ?? this.startingGoal,
        maxGoal: maxGoal ?? this.maxGoal,
        setSize: setSize ?? this.setSize,
        restSeconds: restSeconds ?? this.restSeconds,
        autoProgress: autoProgress ?? this.autoProgress,
        painRiseLimit: painRiseLimit ?? this.painRiseLimit,
        painHighLimit: painHighLimit ?? this.painHighLimit,
      );

  Map<String, Object?> toJson() => {
        'levelOverride': levelOverride,
        'startingGoal': startingGoal,
        'maxGoal': maxGoal,
        'setSize': setSize,
        'restSeconds': restSeconds,
        'autoProgress': autoProgress,
        'painRiseLimit': painRiseLimit,
        'painHighLimit': painHighLimit,
      };

  static ProgramSettings fromJson(Map<String, Object?> j) {
    int i(String k, int d) => j[k] is int ? j[k] as int : d;
    const d = defaults;
    return ProgramSettings(
      levelOverride: j['levelOverride'] is int ? j['levelOverride'] as int : null,
      startingGoal: i('startingGoal', d.startingGoal),
      maxGoal: i('maxGoal', d.maxGoal),
      setSize: i('setSize', d.setSize),
      restSeconds: i('restSeconds', d.restSeconds),
      autoProgress: j['autoProgress'] is bool ? j['autoProgress'] as bool : d.autoProgress,
      painRiseLimit: i('painRiseLimit', d.painRiseLimit),
      painHighLimit: i('painHighLimit', d.painHighLimit),
    );
  }
}
