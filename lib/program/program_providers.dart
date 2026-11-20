import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../data/program_repository.dart';
import '../exercises/exercise_providers.dart';
import 'baseline.dart';
import 'daily_plan.dart';
import 'pain.dart';
import 'program_settings.dart';
import 'program_store.dart';

final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db == null ? InMemoryProgramRepository() : DriftProgramRepository(db);
});

final programStoreProvider =
    Provider<ProgramStore>((ref) => ProgramStore(ref.watch(sharedPreferencesProvider)));

final programSettingsProvider =
    NotifierProvider<ProgramSettingsNotifier, ProgramSettings>(
        ProgramSettingsNotifier.new);

class ProgramSettingsNotifier extends Notifier<ProgramSettings> {
  @override
  ProgramSettings build() => ref.watch(programStoreProvider).loadSettings();

  Future<void> save(ProgramSettings s) async {
    await ref.read(programStoreProvider).saveSettings(s);
    state = s;
    ref.invalidate(programOverviewProvider);
  }

  /// Sets today's goal back to the starting goal.
  Future<void> resetGoal() async {
    await ref.read(programStoreProvider).saveGoal(
        state.startingGoal, ref.read(clockProvider)());
    ref.invalidate(programOverviewProvider);
  }
}

/// Everything the program screen shows.
class ProgramOverview {
  const ProgramOverview({
    required this.baseline,
    required this.settings,
    required this.plan,
    required this.painBefore,
    required this.painAfter,
    required this.recheckDue,
  });

  /// Null until the hands have been measured.
  final BaselineResult? baseline;
  final ProgramSettings settings;

  /// Null until the hands have been measured.
  final DailyPlan? plan;

  /// Today's latest pain scores, if asked.
  final int? painBefore;
  final int? painAfter;
  final bool recheckDue;

  int? get level => plan?.level;
}

final programOverviewProvider = FutureProvider<ProgramOverview>((ref) async {
  final settings = ref.watch(programSettingsProvider);
  final now = ref.watch(clockProvider)();
  final repo = ref.watch(programRepositoryProvider);
  final sessions = ref.watch(exerciseSessionRepositoryProvider);
  final store = ref.watch(programStoreProvider);

  final baseline = await repo.latestBaseline();
  final pain = await repo.painOn(now);
  int? latest(String phase) {
    final xs = [for (final p in pain) if (p.phase == phase) p.score];
    return xs.isEmpty ? null : xs.last;
  }

  if (baseline == null) {
    return ProgramOverview(
      baseline: null,
      settings: settings,
      plan: null,
      painBefore: latest('before'),
      painAfter: latest('after'),
      recheckDue: false,
    );
  }

  // Today's goal: carried forward from the last practice day, adjusted
  // once per day by the progression rules.
  final stored = store.loadGoal();
  int goal;
  if (stored == null) {
    goal = settings.startingGoal;
    await store.saveGoal(goal, now);
  } else if (stored.date != ProgramStore.dayKey(now)) {
    goal = stored.goal;
    final lastDay = await sessions.lastDayBefore(now);
    if (lastDay != null) {
      final rows = await sessions.on(lastDay);
      final dayPain = await repo.painOn(lastDay);
      final before = [for (final p in dayPain) if (p.phase == 'before') p.score];
      final after = [for (final p in dayPain) if (p.phase == 'after') p.score];
      goal = GoalProgression.next(
        stored.goal,
        DayOutcome(
          goal: stored.goal,
          reps: rows.fold(0, (a, r) => a + r.reps),
          fatigued: rows.any((r) => r.fatigued),
          painRose: before.isNotEmpty &&
              after.isNotEmpty &&
              PainRules.after(before.first, after.last, settings) ==
                  PainAdvice.painRose,
        ),
        settings,
      );
    }
    await store.saveGoal(goal, now);
  } else {
    goal = stored.goal;
  }

  final done = <String, int>{};
  for (final r in await sessions.on(now)) {
    done[r.exerciseId] = (done[r.exerciseId] ?? 0) + r.reps;
  }
  final level = settings.levelOverride ?? baseline.level;
  final dayNumber = now.difference(DateTime(2026)).inDays;
  return ProgramOverview(
    baseline: baseline,
    settings: settings,
    plan: DailyPlan.build(
      level: level,
      goal: goal,
      settings: settings,
      dayNumber: dayNumber,
      doneById: done,
    ),
    painBefore: latest('before'),
    painAfter: latest('after'),
    recheckDue: baseline.isDueAt(now),
  );
});
