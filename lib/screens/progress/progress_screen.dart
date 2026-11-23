import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../exercises/exercise_catalog.dart';
import '../../exercises/exercise_setup.dart';
import '../../program/date_range.dart';
import '../../program/program_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/hero.dart';
import '../../widgets/rohab_row.dart';
import '../../widgets/rohab_tabs.dart';
import 'progress_data.dart';

/// Progress for one exercise over 7, 30 or 90 days. The range buttons drive
/// the repository query, so every number, the chart and the labels follow.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  static Key segmentKey(String id) => Key('progress-segment-$id');
  static Key rangeKey(RangeDays r) => Key('progress-range-${r.days}');
  static const emptyKey = Key('progress-empty');
  static const goToExercisesKey = Key('progress-go-exercises');
  static const summaryKey = Key('progress-summary');
  static const heroLabelKey = Key('progress-hero-label');
  static const heroNumberKey = Key('progress-hero-number');
  static const chartKey = Key('progress-chart');
  static const compareKey = Key('progress-compare');
  static const painKey = Key('progress-pain');
  static const footerKey = Key('progress-footer');
  static Key rowKey(int i) => Key('progress-row-$i');

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String _id = progressExerciseIds.first;

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(progressRangeProvider);
    final data = ref.watch(progressDataProvider((id: _id, range: range)));
    final c = context.colors;
    final bottom = RohabSize.navHeight + MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.only(bottom: bottom),
      children: [
        UnderlineTabs(
          scrollable: true,
          labels: [
            for (final id in progressExerciseIds) progressExerciseLabel(id),
          ],
          selected: progressExerciseIds.indexOf(_id),
          onChanged: (i) => setState(() => _id = progressExerciseIds[i]),
        ),
        HeroBubbles(
          child: Padding(
            padding: const EdgeInsets.all(RohabSpace.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RangeButtons(selected: range),
                const SizedBox(height: RohabSpace.s24),
                ...data.when(
                  loading: () => [
                    const Text('Loading.', style: RohabType.body),
                  ],
                  error: (_, _) => [
                    const Text(
                      'Progress could not load.',
                      style: RohabType.body,
                    ),
                  ],
                  data: (d) => _hero(d, range),
                ),
              ],
            ),
          ),
        ),
        ...data.when(
          loading: () => const <Widget>[],
          error: (_, _) => const <Widget>[],
          data: (d) => _body(context, d, range, c),
        ),
        _rows(context),
        Padding(
          padding: const EdgeInsets.all(RohabSpace.gutter),
          child: Text(
            'Research prototype. Not a medical device.',
            key: ProgressScreen.footerKey,
            style: RohabType.rowSub,
          ),
        ),
      ],
    );
  }

  List<Widget> _hero(ProgressData d, RangeDays range) => [
    Text(
      'Reps, last ${range.label}',
      key: ProgressScreen.heroLabelKey,
      style: RohabType.sectionLabel.copyWith(color: RohabType.rowSub.color),
    ),
    const SizedBox(height: RohabSpace.s8),
    Text(
      '${d.summary.reps}',
      key: ProgressScreen.heroNumberKey,
      style: RohabType.metricXL,
    ),
    const SizedBox(height: RohabSpace.s8),
    Text(
      d.summary.sentence,
      key: ProgressScreen.summaryKey,
      style: RohabType.body,
    ),
  ];

  List<Widget> _body(
    BuildContext context,
    ProgressData d,
    RangeDays range,
    AppColors c,
  ) {
    if (d.sessions.isEmpty) {
      return [
        const SizedBox(height: RohabSpace.s16),
        EmptyState(
          key: ProgressScreen.emptyKey,
          title: 'No sessions yet.',
          message: 'Start one from Exercises.',
          actionLabel: 'Go to Exercises',
          onAction: () => context.go(Routes.exercises),
        ),
      ];
    }
    final exercise = ExerciseCatalog.byId(_id)!;
    return [
      const RohabSectionLabel('Reps per day'),
      _RepsChart(
        key: ProgressScreen.chartKey,
        data: d,
        range: range,
        unit: exercise.repUnit,
      ),
      const RohabSectionLabel('Sessions'),
      RohabGroup(
        children: [
          for (var i = 0; i < d.sessions.length && i < 20; i++)
            RohabRow(
              key: ProgressScreen.rowKey(i),
              title: repsText(d.sessions[i], exercise.repUnit),
              subtitle: rangeText(d.sessions[i]),
              value: shortDate(d.sessions[i].startedAt),
            ),
        ],
      ),
    ];
  }

  Widget _rows(BuildContext context) {
    final overview = ref.watch(programOverviewProvider).value;
    final measured = overview?.baseline != null;
    final painAfter = overview?.painAfter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RohabSectionLabel('More'),
        RohabGroup(
          children: [
            RohabRow(
              key: ProgressScreen.compareKey,
              title: 'Compare with your other hand',
              subtitle: measured
                  ? 'See how both hands moved.'
                  : 'Measure your hands first.',
              onTap: () => context.go(Routes.baseline),
            ),
            if (painAfter != null)
              RohabRow(
                key: ProgressScreen.painKey,
                title: 'Pain after exercise',
                subtitle: 'Your last score today.',
                value: '$painAfter of 10',
              ),
          ],
        ),
      ],
    );
  }
}

class _RangeButtons extends ConsumerWidget {
  const _RangeButtons({required this.selected});

  final RangeDays selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      SquareSegmented<RangeDays>(
        options: [for (final r in RangeDays.values) (r, r.label)],
        selected: selected,
        keyFor: ProgressScreen.rangeKey,
        onChanged: (r) => ref.read(progressRangeProvider.notifier).set(r),
      );
}

/// Square accent bars, a labeled y axis, weekday labels (today bold) for 7
/// days, day numbers for 30 and 90. No gradients. A text summary is the
/// screen-reader version.
class _RepsChart extends StatelessWidget {
  const _RepsChart({
    super.key,
    required this.data,
    required this.range,
    required this.unit,
  });

  final ProgressData data;
  final RangeDays range;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final days = data.daily;
    final peak = days.fold<int>(0, (a, d) => d.reps > a ? d.reps : a);
    final top = peak == 0 ? 10.0 : (peak * 1.2).ceilToDouble();
    final every = range == RangeDays.week
        ? 1
        : range == RangeDays.month
        ? 5
        : 15;
    final summary =
        'Reps per day, last ${range.label}: ${data.summary.reps} $unit in total, '
        'best day ${peak == 0 ? 'none' : '$peak'}.';
    final barWidth = range == RangeDays.week
        ? 24.0
        : range == RangeDays.month
        ? 6.0
        : 2.5;
    return Semantics(
      label: summary,
      excludeSemantics: true,
      child: Container(
        color: c.surface,
        padding: const EdgeInsets.fromLTRB(
          RohabSpace.s8,
          RohabSpace.s16,
          RohabSpace.gutter,
          RohabSpace.s8,
        ),
        height: 240,
        child: BarChart(
          BarChartData(
            maxY: top,
            minY: 0,
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(enabled: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: top / 4,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: c.divider, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: top / 4,
                  getTitlesWidget: (v, meta) => Text(
                    '${v.round()}',
                    style: RohabType.metricS.copyWith(color: c.secondary),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    if (i < 0 || i >= days.length) {
                      return const SizedBox.shrink();
                    }
                    final today = i == days.length - 1;
                    final show =
                        range == RangeDays.week ||
                        today ||
                        (days.length - 1 - i) % every == 0;
                    if (!show) return const SizedBox.shrink();
                    final label = range == RangeDays.week
                        ? weekdayShort(days[i].day)
                        : '${days[i].day.day}';
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        label,
                        style: RohabType.metricS.copyWith(
                          color: today ? c.accent : c.secondary,
                          fontWeight: today ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < days.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: days[i].reps.toDouble(),
                      color: c.accent,
                      width: barWidth,
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
