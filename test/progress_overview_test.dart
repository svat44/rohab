import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/screens/progress/overview.dart';

({DateTime startedAt, int reps}) s(int day, int reps, {int hour = 10}) =>
    (startedAt: DateTime(2026, 11, day, hour), reps: reps);

void main() {
  final now = DateTime(2026, 11, 20, 15);

  test('seven days, oldest first, today last, sessions summed per day', () {
    final o = buildOverview([s(20, 10), s(20, 15, hour: 8), s(18, 30)], now);
    expect(o.days, hasLength(7));
    expect(o.days.first.day, DateTime(2026, 11, 14));
    expect(o.days.last.day, DateTime(2026, 11, 20));
    expect(o.days.last.reps, 25);
    expect(o.days[4].reps, 30); // Nov 18
    expect(o.totalReps, 55);
    expect(o.activeDays, 2);
  });

  test('streak counts back from today', () {
    final o = buildOverview([s(20, 5), s(19, 5), s(18, 5), s(16, 5)], now);
    expect(o.streak, 3);
  });

  test('streak survives a day not yet done today', () {
    final o = buildOverview([s(19, 5), s(18, 5)], now);
    expect(o.streak, 2);
  });

  test('a missed day breaks the streak', () {
    final o = buildOverview([s(19, 5), s(17, 5)], now);
    expect(o.streak, 1);
  });

  test('no sessions: empty week', () {
    final o = buildOverview([], now);
    expect(o.streak, 0);
    expect(o.totalReps, 0);
    expect(o.days.every((d) => d.reps == 0), isTrue);
  });

  test('sessions older than a week do not count toward the week', () {
    final o = buildOverview([s(1, 100)], now);
    expect(o.totalReps, 0);
  });
}
