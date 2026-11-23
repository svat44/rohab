import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/program/date_range.dart';

({DateTime startedAt, int reps}) s(DateTime at, int reps) =>
    (startedAt: at, reps: reps);

void main() {
  final now = DateTime(2026, 11, 20, 15);

  test('lastDays covers N whole local days ending today', () {
    final r = DateRange.lastDays(7, now);
    expect(r.start, DateTime(2026, 11, 14));
    expect(r.end, DateTime(2026, 11, 21));
    expect(r.days, 7);
    expect(r.contains(DateTime(2026, 11, 14, 0, 0)), isTrue);
    expect(r.contains(DateTime(2026, 11, 13, 23, 59)), isFalse);
    expect(r.contains(DateTime(2026, 11, 20, 23, 59)), isTrue);
    expect(r.contains(DateTime(2026, 11, 21)), isFalse);
  });

  test('session = one saved run; practice day = distinct local date', () {
    final r = DateRange.lastDays(7, now);
    final sum = summarize([
      for (var i = 0; i < 13; i++) s(DateTime(2026, 11, 20, 8, i), 5),
    ], r);
    expect(sum.sessions, 13);
    expect(sum.practiceDays, 1);
    expect(sum.reps, 65);
    expect(sum.sentence, '13 sessions on 1 practice day');
  });

  test('sessions and practice days never contradict: days <= sessions', () {
    final r = DateRange.lastDays(30, now);
    final sum = summarize([
      s(DateTime(2026, 11, 20, 9), 5),
      s(DateTime(2026, 11, 20, 18), 5),
      s(DateTime(2026, 11, 10, 9), 5),
    ], r);
    expect(sum.sessions, 3);
    expect(sum.practiceDays, 2);
    expect(sum.practiceDays <= sum.sessions, isTrue);
  });

  test('7 days returns fewer reps than 90 days for the same data', () {
    final rows = [
      for (var d = 0; d < 100; d += 5)
        s(
          DateTime(
            2026,
            11,
            20 - d % 20,
            9,
          ).subtract(Duration(days: d ~/ 20 * 20)),
          10,
        ),
    ];
    final week = summarize(rows, DateRange.lastDays(7, now));
    final quarter = summarize(rows, DateRange.lastDays(90, now));
    expect(week.reps, lessThan(quarter.reps));
    expect(DateRange.lastDays(30, now).days, 30);
  });

  test('dailyReps has one entry per day, today last', () {
    final r = DateRange.lastDays(7, now);
    final d = dailyReps([
      s(DateTime(2026, 11, 20, 9), 4),
      s(DateTime(2026, 11, 20, 10), 6),
    ], r);
    expect(d, hasLength(7));
    expect(d.last.day, DateTime(2026, 11, 20));
    expect(d.last.reps, 10);
    expect(d.first.reps, 0);
  });

  test('empty data gives zeros and the singular sentence', () {
    final sum = summarize([], DateRange.lastDays(7, now));
    expect(sum.sentence, '0 sessions on 0 practice days');
    expect(
      summarize([
        s(DateTime(2026, 11, 20), 1),
      ], DateRange.lastDays(7, now)).sentence,
      '1 session on 1 practice day',
    );
  });
}
