import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/database.dart';
import '../../data/exercise_session_repository.dart';
import '../../exercises/exercise_providers.dart';

/// The exercises Progress can show, in selector order.
const progressExerciseIds = ['open_close', 'finger_touches', 'spread_fingers'];

const progressExerciseLabels = {
  'open_close': 'Open and close',
  'finger_touches': 'Finger touches',
  'spread_fingers': 'Spread fingers',
};

class ProgressData {
  const ProgressData({required this.sessions, required this.week});

  /// Newest first, at most 10.
  final List<ExerciseSessionRow> sessions;
  final WeeklySummary week;

  /// Oldest first, for the charts.
  List<ExerciseSessionRow> get chronological => sessions.reversed.toList();
}

/// Progress for one exercise. Invalidate after a session is saved or the
/// data is cleared.
final progressDataProvider = FutureProvider.family<ProgressData, String>((
  ref,
  exerciseId,
) async {
  final repo = ref.watch(exerciseSessionRepositoryProvider);
  final now = ref.watch(clockProvider)();
  return ProgressData(
    sessions: await repo.sessionsFor(exerciseId, limit: 10),
    week: await repo.weeklySummary(now: now),
  );
});

// ---- Plain-text formatting, shared by the list, charts and screen readers.

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

/// "Nov 18, 09:12".
String dateTime(DateTime t) {
  final d = t.toLocal();
  return '${shortDate(d)}, ${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

/// Scale of the range axis for a metric unit: finger bend runs 0-270
/// degrees, spread runs 0-100 %.
double rangeAxisMax(String unit) => unit == 'deg' ? 270 : 100;

/// "Range 18%–94%" or "Range 12°–245°". Null if the range was not
/// measured.
String? rangeText(ExerciseSessionRow r) {
  final lo = r.rangeMin, hi = r.rangeMax;
  if (lo == null || hi == null) return null;
  final u = r.metricUnit == 'deg' ? '°' : '%';
  return 'Range ${lo.round()}$u–${hi.round()}$u';
}

/// "10 of 10 reps".
String repsText(ExerciseSessionRow r, String unit) =>
    '${r.reps} of ${r.targetReps} $unit';
