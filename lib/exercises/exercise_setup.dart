/// Per-exercise setup: hand, reps per set, sets, rest. Remembered between
/// visits. Pure Dart apart from the Riverpod glue at the bottom.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/providers.dart';
import '../camera/handedness.dart';
import '../program/program_providers.dart';
import 'exercise_providers.dart';

/// Rough seconds one rep takes (open, hold, close, release) at the slow pace
/// of someone relearning the movement. Used only for "About N minutes".
const int kSecondsPerRep = 10;

const kRepsRange = (min: 1, max: 20);
const kSetsRange = (min: 1, max: 6);
const kRestRange = (min: 10, max: 120);
const int kRestStep = 10;

const kDefaultReps = 5;
const kDefaultSets = 3;
const kDefaultRestSeconds = 30;

class ExerciseSetup {
  const ExerciseSetup({
    required this.hand,
    this.reps = kDefaultReps,
    this.sets = kDefaultSets,
    this.restSeconds = kDefaultRestSeconds,
  });

  /// Handedness.left or Handedness.right.
  final Handedness hand;
  final int reps;
  final int sets;
  final int restSeconds;

  int get totalReps => reps * sets;

  /// Seconds for the whole plan: every rep plus the rests between sets.
  int get totalSeconds => totalReps * kSecondsPerRep + (sets - 1) * restSeconds;

  /// Whole minutes, rounded up, at least 1.
  int get minutes => (totalSeconds / 60).ceil().clamp(1, 1000);

  String get summaryLine => '$sets sets x $reps reps = $totalReps reps';
  String get timeLine =>
      'About $minutes ${minutes == 1 ? 'minute' : 'minutes'}';

  ExerciseSetup copyWith({
    Handedness? hand,
    int? reps,
    int? sets,
    int? restSeconds,
  }) => ExerciseSetup(
    hand: hand ?? this.hand,
    reps: (reps ?? this.reps).clamp(kRepsRange.min, kRepsRange.max),
    sets: (sets ?? this.sets).clamp(kSetsRange.min, kSetsRange.max),
    restSeconds: (restSeconds ?? this.restSeconds).clamp(
      kRestRange.min,
      kRestRange.max,
    ),
  );
}

class ExerciseSetupStore {
  ExerciseSetupStore(this._prefs);
  final SharedPreferences _prefs;

  static String _k(String id, String f) => 'setup.$id.$f';

  /// Last-used values for [id], or defaults with [defaultHand].
  ExerciseSetup load(String id, Handedness defaultHand) {
    final h = _prefs.getString(_k(id, 'hand'));
    return ExerciseSetup(
      hand: h == 'left'
          ? Handedness.left
          : h == 'right'
          ? Handedness.right
          : defaultHand,
    ).copyWith(
      reps: _prefs.getInt(_k(id, 'reps')),
      sets: _prefs.getInt(_k(id, 'sets')),
      restSeconds: _prefs.getInt(_k(id, 'rest')),
    );
  }

  Future<void> save(String id, ExerciseSetup s) async {
    await _prefs.setString(
      _k(id, 'hand'),
      s.hand == Handedness.left ? 'left' : 'right',
    );
    await _prefs.setInt(_k(id, 'reps'), s.reps);
    await _prefs.setInt(_k(id, 'sets'), s.sets);
    await _prefs.setInt(_k(id, 'rest'), s.restSeconds);
  }
}

final exerciseSetupStoreProvider = Provider<ExerciseSetupStore>(
  (ref) => ExerciseSetupStore(ref.watch(sharedPreferencesProvider)),
);

/// The affected hand from the hand measurement, or right if not measured.
final defaultHandProvider = Provider<Handedness>((ref) {
  final h = ref.watch(programOverviewProvider).value?.baseline?.affectedHand;
  return h == Handedness.left ? Handedness.left : Handedness.right;
});

/// Setups changed in this run; anything else is read from storage.
class ExerciseSetups extends Notifier<Map<String, ExerciseSetup>> {
  @override
  Map<String, ExerciseSetup> build() => {};

  ExerciseSetup of(String id) =>
      state[id] ??
      ref
          .read(exerciseSetupStoreProvider)
          .load(id, ref.read(defaultHandProvider));

  Future<void> update(String id, ExerciseSetup s) async {
    state = {...state, id: s};
    await ref.read(exerciseSetupStoreProvider).save(id, s);
  }
}

final exerciseSetupsProvider =
    NotifierProvider<ExerciseSetups, Map<String, ExerciseSetup>>(
      ExerciseSetups.new,
    );

/// Day of the newest saved session per exercise id.
final lastDoneProvider = FutureProvider<Map<String, DateTime>>((ref) async {
  final rows = await ref.watch(exerciseSessionRepositoryProvider).all();
  final out = <String, DateTime>{};
  for (final r in rows) {
    final prev = out[r.exerciseId];
    if (prev == null || r.startedAt.isAfter(prev)) {
      out[r.exerciseId] = r.startedAt;
    }
  }
  return out;
});

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String weekdayShort(DateTime d) => _weekdays[d.weekday - 1];

/// "Today", a weekday within the last 6 days, a short date after that, or
/// "New" when never done.
String lastDoneLabel(DateTime? last, DateTime now) {
  if (last == null) return 'New';
  final a = DateTime(last.year, last.month, last.day);
  final b = DateTime(now.year, now.month, now.day);
  final days = b.difference(a).inDays;
  if (days <= 0) return 'Today';
  if (days < 7) return weekdayShort(last);
  return '${last.day} ${_months[last.month - 1]}';
}
