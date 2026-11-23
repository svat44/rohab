/// Date ranges and the definitions behind every Progress number. Pure Dart.
///
/// DEFINITIONS (used everywhere, tested in test/date_range_test.dart):
///  * session      = one completed run of an exercise that counted at least
///                   one rep. That is exactly one saved row.
///  * practice day = a distinct LOCAL calendar date with at least one session.
library;

/// The three ranges Progress offers.
enum RangeDays {
  week(7, '7 days'),
  month(30, '30 days'),
  quarter(90, '90 days');

  const RangeDays(this.days, this.label);
  final int days;
  final String label;
}

/// N whole local days ending today: [start] is local midnight of the first
/// day, [end] is local midnight after today (exclusive).
class DateRange {
  const DateRange(this.start, this.end);

  factory DateRange.lastDays(int days, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return DateRange(
      DateTime(today.year, today.month, today.day - (days - 1)),
      DateTime(today.year, today.month, today.day + 1),
    );
  }

  final DateTime start;
  final DateTime end;

  bool contains(DateTime t) {
    final l = t.toLocal();
    return !l.isBefore(start) && l.isBefore(end);
  }

  int get days =>
      DateTime(end.year, end.month, end.day).difference(start).inDays;
}

class RangeSummary {
  const RangeSummary({
    required this.sessions,
    required this.reps,
    required this.practiceDays,
  });

  final int sessions;
  final int reps;
  final int practiceDays;

  /// "13 sessions on 1 practice day".
  String get sentence =>
      '$sessions ${sessions == 1 ? 'session' : 'sessions'} on '
      '$practiceDays ${practiceDays == 1 ? 'practice day' : 'practice days'}';
}

/// Totals for the sessions in [range]. [rows] may be in any order and may
/// include sessions outside the range; those are ignored.
RangeSummary summarize(
  Iterable<({DateTime startedAt, int reps})> rows,
  DateRange range,
) {
  var sessions = 0, reps = 0;
  final days = <DateTime>{};
  for (final r in rows) {
    if (!range.contains(r.startedAt)) continue;
    final l = r.startedAt.toLocal();
    sessions++;
    reps += r.reps;
    days.add(DateTime(l.year, l.month, l.day));
  }
  return RangeSummary(
    sessions: sessions,
    reps: reps,
    practiceDays: days.length,
  );
}

/// Reps per local day, oldest first, one entry per day of [range].
List<({DateTime day, int reps})> dailyReps(
  Iterable<({DateTime startedAt, int reps})> rows,
  DateRange range,
) {
  final byDay = <DateTime, int>{};
  for (final r in rows) {
    if (!range.contains(r.startedAt)) continue;
    final l = r.startedAt.toLocal();
    final d = DateTime(l.year, l.month, l.day);
    byDay[d] = (byDay[d] ?? 0) + r.reps;
  }
  return [
    for (var i = 0; i < range.days; i++)
      (
        day: DateTime(range.start.year, range.start.month, range.start.day + i),
        reps:
            byDay[DateTime(
              range.start.year,
              range.start.month,
              range.start.day + i,
            )] ??
            0,
      ),
  ];
}
