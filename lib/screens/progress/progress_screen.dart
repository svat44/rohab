import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../data/database.dart';
import '../../exercises/exercise_catalog.dart';
import '../../theme/app_theme.dart';
import 'overview.dart';
import 'progress_data.dart';
import 'range_chart.dart';
import 'reps_chart.dart';

/// Saved sessions for one exercise: a plain summary, two small charts,
/// and the list of sessions, which is the primary data.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  static Key segmentKey(String id) => Key('progress-segment-$id');
  static const emptyKey = Key('progress-empty');
  static const goToExercisesKey = Key('progress-go-exercises');
  static const summaryKey = Key('progress-summary');
  static const repsChartKey = Key('progress-reps-chart');
  static const rangeChartKey = Key('progress-range-chart');
  static Key rowKey(int i) => Key('progress-row-$i');

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String _id = progressExerciseIds.first;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final data = ref.watch(progressDataProvider(_id));
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          RohabSpace.s24, 0, RohabSpace.s24, RohabSpace.s24),
      children: [
        _Selector(
          selected: _id,
          onSelected: (id) => setState(() => _id = id),
        ),
        const SizedBox(height: RohabSpace.s16),
        ref.watch(progressOverviewProvider).when(
              data: (o) => WeekOverview(overview: o),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
        const SizedBox(height: RohabSpace.s24),
        ...data.when(
          loading: () => [Text('Loading.', style: t.bodyLarge)],
          error: (e, _) =>
              [Text('Progress could not load.', style: t.bodyLarge)],
          data: (d) => _content(context, d),
        ),
      ],
    );
  }

  List<Widget> _content(BuildContext context, ProgressData d) {
    final t = Theme.of(context).textTheme;
    final exercise = ExerciseCatalog.byId(_id)!;
    final week = d.week;
    final summary = 'This week: ${week.sessions} '
        '${week.sessions == 1 ? 'session' : 'sessions'}, ${week.reps} '
        '${week.reps == 1 ? 'rep' : 'reps'}.';

    if (d.sessions.isEmpty) {
      return [
        Text(summary, key: ProgressScreen.summaryKey, style: t.bodyLarge),
        const SizedBox(height: RohabSpace.s24),
        Text('No sessions yet. Start one from Exercises.',
            key: ProgressScreen.emptyKey, style: t.bodyLarge),
        const SizedBox(height: RohabSpace.s24),
        SizedBox(
          height: RohabSize.touchTarget,
          child: OutlinedButton(
            key: ProgressScreen.goToExercisesKey,
            onPressed: () => context.go(Routes.exercises),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.accent,
              side: BorderSide(color: context.colors.divider),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RohabShape.radius)),
              textStyle: t.labelLarge,
            ),
            child: const Text('Go to Exercises'),
          ),
        ),
      ];
    }

    final chrono = d.chronological;
    // Charts use sessions measured in the newest session's unit.
    final unit = d.sessions.first.metricUnit;
    final ranged = [for (final r in chrono) if (r.metricUnit == unit) r];
    return [
      Text(summary, key: ProgressScreen.summaryKey, style: t.bodyLarge),
      const SizedBox(height: RohabSpace.s24),
      if (_improvement(chrono, unit) case final card?) ...[
        card,
        const SizedBox(height: RohabSpace.s24),
      ],
      Text(
          chrono.length == 1
              ? 'Reps, last session'
              : 'Reps, last ${chrono.length} sessions',
          style: t.labelLarge),
      const SizedBox(height: RohabSpace.s8),
      KeyedSubtree(
        key: ProgressScreen.repsChartKey,
        child: RepsChart(sessions: chrono, unit: exercise.repUnit),
      ),
      const SizedBox(height: RohabSpace.s24),
      Text(
        unit == 'deg'
            ? 'Range of finger bend, 0° to 270°'
            : 'Range, 0% to 100%',
        style: t.labelLarge,
      ),
      const SizedBox(height: RohabSpace.s8),
      KeyedSubtree(
        key: ProgressScreen.rangeChartKey,
        child: RangeChart(sessions: ranged, unit: unit),
      ),
      const SizedBox(height: RohabSpace.s24),
      Text('Recent sessions', style: t.labelLarge),
      const SizedBox(height: RohabSpace.s8),
      const Divider(),
      for (var i = 0; i < d.sessions.length; i++) ...[
        _SessionRow(
            key: ProgressScreen.rowKey(i),
            row: d.sessions[i],
            unit: exercise.repUnit),
        const Divider(),
      ],
    ];
  }
}

/// First and latest range of movement, once there are two measured
/// sessions to compare.
Widget? _improvement(List<ExerciseSessionRow> chrono, String unit) {
  final measured = [
    for (final r in chrono)
      if (r.metricUnit == unit && r.rangeMin != null && r.rangeMax != null) r
  ];
  if (measured.length < 2) return null;
  double span(ExerciseSessionRow r) => r.rangeMax! - r.rangeMin!;
  return ImprovementCard(
    first: span(measured.first),
    latest: span(measured.last),
    unit: unit == 'deg' ? '°' : '%',
    since: shortDate(measured.first.startedAt),
  );
}

/// Three options, each at least 64 dp tall.
class _Selector extends StatelessWidget {
  const _Selector({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(RohabShape.radius);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final id in progressExerciseIds) ...[
            if (id != progressExerciseIds.first)
              const SizedBox(width: RohabSpace.s8),
            Expanded(
              child: Semantics(
                button: true,
                selected: id == selected,
                child: Material(
                  color: id == selected ? c.accent : c.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: radius,
                    side: BorderSide(
                        color: id == selected ? c.accent : c.divider,
                        width: RohabShape.border),
                  ),
                  child: InkWell(
                    key: ProgressScreen.segmentKey(id),
                    borderRadius: radius,
                    onTap: () => onSelected(id),
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(minHeight: RohabSize.touchTarget),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: RohabSpace.s8, vertical: RohabSpace.s8),
                        child: Center(
                          child: Text(
                            progressExerciseLabels[id]!,
                            textAlign: TextAlign.center,
                            style: t.labelMedium?.copyWith(
                              color: id == selected ? c.onAccent : c.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({super.key, required this.row, required this.unit});

  final ExerciseSessionRow row;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final range = rangeText(row);
    final text = '${dateTime(row.startedAt)}. ${repsText(row, unit)}.'
        '${range == null ? '' : ' $range.'}';
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: RohabSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateTime(row.startedAt), style: t.labelMedium),
            const SizedBox(height: RohabSpace.s8 / 2),
            Text(repsText(row, unit), style: t.bodyLarge),
            if (range != null) Text(range, style: t.bodyLarge),
          ],
        ),
      ),
    );
  }
}
