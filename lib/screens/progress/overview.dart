import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../exercises/exercise_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rohab_widgets.dart';

/// Reps done on one calendar day.
class DayTotal {
  const DayTotal(this.day, this.reps);

  final DateTime day;
  final int reps;
}

class ProgressOverview {
  const ProgressOverview({
    required this.days,
    required this.streak,
    required this.activeDays,
    required this.totalReps,
  });

  /// The last 7 days, oldest first; the last one is today.
  final List<DayTotal> days;

  /// Days in a row with any exercise, counting back from today (or from
  /// yesterday, if today has not been done yet).
  final int streak;

  /// Days with any exercise in the last 7.
  final int activeDays;
  final int totalReps;
}

/// Pure: builds the overview from sessions (any order) and today's date.
ProgressOverview buildOverview(
    List<({DateTime startedAt, int reps})> sessions, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final byDay = <DateTime, int>{};
  for (final s in sessions) {
    final l = s.startedAt.toLocal();
    final d = DateTime(l.year, l.month, l.day);
    byDay[d] = (byDay[d] ?? 0) + s.reps;
  }
  final days = [
    for (var i = 6; i >= 0; i--)
      DayTotal(DateTime(today.year, today.month, today.day - i),
          byDay[DateTime(today.year, today.month, today.day - i)] ?? 0),
  ];
  var streak = 0;
  var cursor = today;
  if ((byDay[cursor] ?? 0) == 0) {
    cursor = DateTime(today.year, today.month, today.day - 1);
  }
  while ((byDay[cursor] ?? 0) > 0) {
    streak++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return ProgressOverview(
    days: days,
    streak: streak,
    activeDays: days.where((d) => d.reps > 0).length,
    totalReps: days.fold(0, (a, d) => a + d.reps),
  );
}

final progressOverviewProvider = FutureProvider<ProgressOverview>((ref) async {
  final repo = ref.watch(exerciseSessionRepositoryProvider);
  final now = ref.watch(clockProvider)();
  final rows = await repo.all();
  return buildOverview(
      [for (final r in rows) (startedAt: r.startedAt, reps: r.reps)], now);
});

/// "Your week": a bar for each of the last 7 days, the days in a row, and
/// plain totals. Flat bars, labelled with their numbers.
class WeekOverview extends StatelessWidget {
  const WeekOverview({super.key, required this.overview});

  final ProgressOverview overview;

  static const chartKey = Key('progress-week-chart');
  static const streakKey = Key('progress-streak');
  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final o = overview;
    final peak = o.days.fold<int>(0, (a, d) => d.reps > a ? d.reps : a);
    final streakText = o.streak == 0
        ? 'No days in a row yet'
        : o.streak == 1
            ? '1 day in a row'
            : '${o.streak} days in a row';
    return RohabCard(
      padding: const EdgeInsets.all(RohabSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your week', style: t.labelMedium),
          const SizedBox(height: RohabSpace.s8),
          Text(streakText, key: streakKey, style: t.headlineMedium),
          const SizedBox(height: RohabSpace.s8),
          Text(
            '${o.activeDays} of 7 days exercised · ${o.totalReps} '
            '${o.totalReps == 1 ? 'rep' : 'reps'}',
            style: t.bodyLarge,
          ),
          const SizedBox(height: RohabSpace.s16),
          Semantics(
            label: 'Reps per day, last 7 days: '
                '${o.days.map((d) => d.reps).join(', ')}',
            excludeSemantics: true,
            child: SizedBox(
              key: chartKey,
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < o.days.length; i++) ...[
                    if (i > 0) const SizedBox(width: RohabSpace.s8),
                    Expanded(
                      child: _Bar(
                        reps: o.days[i].reps,
                        peak: peak,
                        letter: _letters[o.days[i].day.weekday - 1],
                        today: i == o.days.length - 1,
                        color: c.accent,
                        track: c.accentSoft,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.reps,
    required this.peak,
    required this.letter,
    required this.today,
    required this.color,
    required this.track,
  });

  final int reps;
  final int peak;
  final String letter;
  final bool today;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(reps == 0 ? '' : '$reps',
              style: t.labelMedium?.copyWith(color: c.text)),
        ),
        const SizedBox(height: RohabSpace.s8 / 2),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: peak == 0
                  ? 0.04
                  : (reps / peak).clamp(0.04, 1.0).toDouble(),
              widthFactor: 1,
              child: ColoredBox(color: reps == 0 ? track : color),
            ),
          ),
        ),
        const SizedBox(height: RohabSpace.s8 / 2),
        Text(letter,
            style: t.labelMedium?.copyWith(
                color: today ? c.accent : c.secondary,
                fontWeight: today ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }
}

/// "Where you started, where you are": the first and latest range of
/// movement for one exercise, as two plain numbers and the change.
class ImprovementCard extends StatelessWidget {
  const ImprovementCard({
    super.key,
    required this.first,
    required this.latest,
    required this.unit,
    required this.since,
  });

  final double first;
  final double latest;

  /// '°' or '%'.
  final String unit;
  final String since;

  static const key0 = Key('progress-improvement');

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final change = (latest - first).round();
    final up = change > 0;
    final summary = change == 0
        ? 'About the same as when you started.'
        : up
            ? 'Up $change$unit since $since.'
            : 'Down ${-change}$unit since $since. A bad day is normal; '
                'rest and try again.';
    return RohabCard(
      key: key0,
      padding: const EdgeInsets.all(RohabSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('How far you move', style: t.labelMedium),
          const SizedBox(height: RohabSpace.s16),
          Row(
            children: [
              Expanded(child: _Figure('Start', '${first.round()}$unit')),
              Icon(Icons.arrow_forward, color: c.secondary),
              Expanded(
                  child: _Figure('Now', '${latest.round()}$unit',
                      emphasis: true)),
            ],
          ),
          const SizedBox(height: RohabSpace.s16),
          Text(summary, style: t.bodyLarge),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.value, {this.emphasis = false});

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(label, style: t.labelMedium),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: t.displayLarge?.copyWith(
                  fontSize: 44,
                  color: emphasis ? context.colors.accent : context.colors.text)),
        ),
      ],
    );
  }
}
