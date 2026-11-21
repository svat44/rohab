/// Today's plan and goal progression. Pure Dart.
library;

import '../exercises/exercise_catalog.dart';
import 'program_settings.dart';

/// One exercise in today's plan.
class PlanItem {
  const PlanItem({
    required this.exercise,
    required this.sets,
    required this.setSize,
    required this.done,
  });

  final CameraExercise exercise;
  final int sets;

  /// Reps (or holds, or rounds) per set.
  final int setSize;

  /// Done today.
  final int done;

  int get target => sets * setSize;
  int get setsDone => (done / setSize).floor().clamp(0, sets);
  bool get complete => done >= target;

  /// How much one rep of this exercise counts toward the daily goal. A
  /// 3-second hold or a 4-touch round is about two plain reps of work, so
  /// those count double (their sets are half size).
  double get weight => 1 / exercise.setSizeFactor;
}

class DailyPlan {
  const DailyPlan({
    required this.level,
    required this.goal,
    required this.items,
    required this.repsToday,
  });

  final int level;

  /// Today's rep goal (holds and rounds count as reps toward it).
  final int goal;
  final List<PlanItem> items;
  final int repsToday;

  bool get complete => items.every((i) => i.complete);

  /// Sets planned and done today, for display: plain counts, with no
  /// weighting.
  int get setsTotal => items.fold(0, (a, i) => a + i.sets);
  int get setsDoneTotal => items.fold(0, (a, i) => a + i.setsDone);

  /// Reps planned today, with holds and rounds counted double; about
  /// [goal], rounded up to whole sets.
  int get plannedTotal =>
      items.fold(0, (a, i) => a + (i.target * i.weight).round());

  /// Done toward the plan, weighted the same way and capped per exercise.
  int get doneTotal => items.fold(
      0,
      (a, i) =>
          a + ((i.done > i.target ? i.target : i.done) * i.weight).round());

  /// The next exercise to do, or null when everything is done.
  PlanItem? get next {
    for (final i in items) {
      if (!i.complete) return i;
    }
    return null;
  }

  /// Builds today's plan. Exercises rotate by [dayNumber] for variety
  /// (variable practice); every level gets 2-3 exercises.
  /// [doneById]: reps done today per exercise id.
  static DailyPlan build({
    required int level,
    required int goal,
    required ProgramSettings settings,
    required int dayNumber,
    required Map<String, int> doneById,
  }) {
    final pool = ExerciseCatalog.forLevel(level);
    final count = pool.length <= 2 ? pool.length : 3;
    final start = pool.length <= count ? 0 : dayNumber % pool.length;
    final chosen = [
      for (var k = 0; k < count; k++) pool[(start + k) % pool.length],
    ];
    final perExercise = (goal / chosen.length).ceil();
    final items = [
      for (final e in chosen)
        () {
          final setSize = e.setSizeFor(settings.setSize);
          // Each set of holds/rounds counts its setSize toward the goal at
          // the same rate as reps, so sets = share / plain set size.
          final sets = (perExercise / settings.setSize).ceil().clamp(1, 100);
          return PlanItem(
            exercise: e,
            sets: sets,
            setSize: setSize,
            done: doneById[e.id] ?? 0,
          );
        }(),
    ];
    final repsToday = doneById.values.fold(0, (a, b) => a + b);
    return DailyPlan(level: level, goal: goal, items: items, repsToday: repsToday);
  }
}

/// How yesterday (the last day practiced) went.
class DayOutcome {
  const DayOutcome({
    required this.goal,
    required this.reps,
    required this.fatigued,
    required this.painRose,
  });

  final int goal;
  final int reps;
  final bool fatigued;
  final bool painRose;
}

class GoalProgression {
  GoalProgression._();

  /// Next day's goal:
  /// - pain rose: 10 % lower (never below the minimum);
  /// - goal met without fatigue: 10 % higher, rounded up to 10, capped;
  /// - otherwise: unchanged.
  static int next(int current, DayOutcome? last, ProgramSettings s) {
    final min = ProgramSettings.goalRange.min;
    if (!s.autoProgress || last == null) return current;
    // Integer arithmetic: 100 * 1.1 is 110.00000000000001 in floating
    // point, which would round up to 120.
    if (last.painRose) {
      final lowered = current * 9 ~/ 100 * 10;
      return lowered < min ? min : lowered;
    }
    if (last.reps >= last.goal && !last.fatigued) {
      final raised = (current * 11 + 99) ~/ 100 * 10;
      return raised.clamp(min, s.maxGoal);
    }
    return current;
  }
}
