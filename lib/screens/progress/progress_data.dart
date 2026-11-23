import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/database.dart';
import '../../exercises/exercise_catalog.dart';
import '../../exercises/exercise_providers.dart';
import '../../program/date_range.dart';

/// The exercises Progress can show, in tab order: every catalog exercise.
final progressExerciseIds = [for (final e in ExerciseCatalog.all) e.id];

String progressExerciseLabel(String id) =>
    ExerciseCatalog.byId(id)?.title ?? id;

/// The range chosen on Progress. Everything on the screen follows it.
final progressRangeProvider =
    NotifierProvider<ProgressRangeNotifier, RangeDays>(
      ProgressRangeNotifier.new,
    );

class ProgressRangeNotifier extends Notifier<RangeDays> {
  @override
  RangeDays build() => RangeDays.week;

  void set(RangeDays r) => state = r;
}

class ProgressData {
  const ProgressData({
    required this.range,
    required this.sessions,
    required this.summary,
    required this.daily,
  });

  final DateRange range;

  /// Sessions in the range, newest first.
  final List<ExerciseSessionRow> sessions;
  final RangeSummary summary;

  /// Reps per day over the range, oldest first.
  final List<({DateTime day, int reps})> daily;

  /// Oldest first, for the range chart.
  List<ExerciseSessionRow> get chronological => sessions.reversed.toList();
}

/// Progress for one exercise over one range. Invalidate after a session is
/// saved or the data is cleared.
final progressDataProvider =
    FutureProvider.family<ProgressData, ({String id, RangeDays range})>((
      ref,
      key,
    ) async {
      final repo = ref.watch(exerciseSessionRepositoryProvider);
      final now = ref.watch(clockProvider)();
      final range = DateRange.lastDays(key.range.days, now);
      final sessions = await repo.sessionsIn(range, exerciseId: key.id);
      final pairs = [
        for (final r in sessions) (startedAt: r.startedAt, reps: r.reps),
      ];
      return ProgressData(
        range: range,
        sessions: sessions,
        summary: summarize(pairs, range),
        daily: dailyReps(pairs, range),
      );
    });

/// Every exercise, same range: the invalidation target after a save.
final progressOverviewProvider = FutureProvider<RangeSummary>((ref) async {
  final repo = ref.watch(exerciseSessionRepositoryProvider);
  final now = ref.watch(clockProvider)();
  return repo.summaryIn(
    DateRange.lastDays(ref.watch(progressRangeProvider).days, now),
  );
});

// ---- Plain-text formatting, shared by the list, chart and screen readers.

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

/// "Nov 18".
String shortDate(DateTime t) {
  final d = t.toLocal();
  return '${_months[d.month - 1]} ${d.day}';
}

/// "Range 18%–94%" or "Range 12°–245°". Null if the range was not measured.
String? rangeText(ExerciseSessionRow r) {
  final lo = r.rangeMin, hi = r.rangeMax;
  if (lo == null || hi == null) return null;
  final u = r.metricUnit == 'deg' ? '°' : '%';
  return 'Range ${lo.round()}$u–${hi.round()}$u';
}

/// "10 of 10 reps".
String repsText(ExerciseSessionRow r, String unit) =>
    '${r.reps} of ${r.targetReps} $unit';
