import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../app/providers.dart';
import '../app/router.dart';
import '../glove/glove_service.dart';
import '../program/program_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/hero.dart';
import '../widgets/rohab_button.dart';
import '../widgets/rohab_row.dart';
import '../widgets/segmented_bar.dart';

/// Today: how many sets are done, what is next, one Start button, then a few
/// rows (only the ones that have something to say).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const todayKey = Key('home-today');
  static const todayPrimaryKey = Key('home-today-primary');
  static const gloveRowKey = Key('home-glove');
  static const therapistRowKey = Key('home-therapist');
  static const goalRowKey = Key('home-goal');
  static const calibrationNeededKey = Key('home-calibration-needed');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glove = ref.watch(gloveServiceProvider);
    final overview = ref.watch(programOverviewProvider).value;
    final calibrationNeeded = ref.watch(calibrationNeededProvider);
    final bottom = RohabSize.navHeight + MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.only(bottom: bottom + RohabSpace.s16),
      children: [
        if (overview != null) _Hero(overview: overview),
        if (overview != null) _Rows(overview: overview),
        ValueListenableBuilder<GloveSnapshot>(
          valueListenable: glove.snapshot,
          builder: (context, s, _) => Padding(
            padding: const EdgeInsets.only(top: RohabSpace.s16),
            child: RohabGroup(
              children: [
                RohabRow(
                  key: HomeScreen.gloveRowKey,
                  title: 'Glove',
                  subtitle: s.isConnected && calibrationNeeded
                      ? 'Calibration needed.'
                      : null,
                  value: s.isConnected ? 'Connected' : 'Not connected',
                  onTap: () => context.go(Routes.calibration),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.overview});

  final ProgramOverview overview;

  @override
  Widget build(BuildContext context) {
    final plan = overview.plan;
    if (plan == null) {
      return HeroBubbles(
        key: HomeScreen.todayKey,
        child: Padding(
          padding: const EdgeInsets.all(RohabSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Start here', style: RohabType.sectionLabel),
              const SizedBox(height: RohabSpace.s8),
              const Text("Let's measure your hands", style: RohabType.rowTitle),
              const SizedBox(height: RohabSpace.s8),
              const Text(
                'This takes about 2 minutes. It picks exercises that fit you.',
                style: RohabType.body,
              ),
              const SizedBox(height: RohabSpace.s24),
              RohabButton(
                key: HomeScreen.todayPrimaryKey,
                label: 'Measure my hands',
                onPressed: () => context.go(Routes.baseline),
              ),
            ],
          ),
        ),
      );
    }
    final next = plan.next;
    final done = plan.setsDoneTotal;
    final total = plan.setsTotal;
    final String label;
    final VoidCallback? action;
    if (next != null) {
      label = done == 0 ? 'Start' : 'Continue';
      action = () => context.go(
        overview.painBefore == null
            ? Routes.painCheck('before', next: next.exercise.id)
            : Routes.cameraExercise(next.exercise.id),
      );
    } else if (overview.painAfter == null && overview.painBefore != null) {
      label = 'Finish for today';
      action = () => context.go(Routes.painCheck('after'));
    } else {
      label = 'Done for today';
      action = null;
    }
    return HeroBubbles(
      key: HomeScreen.todayKey,
      child: Padding(
        padding: const EdgeInsets.all(RohabSpace.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Sets done today', style: RohabType.sectionLabel),
            const SizedBox(height: RohabSpace.s8),
            Semantics(
              label: '$done of $total sets done today',
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$done', style: RohabType.metricXL),
                  const SizedBox(width: RohabSpace.s8),
                  Text(
                    'of $total',
                    style: RohabType.metricL.copyWith(
                      color: context.colors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RohabSpace.s16),
            SegmentedBar(done: done, total: total),
            const SizedBox(height: RohabSpace.s16),
            Text(
              next == null
                  ? 'You finished your exercises for today.'
                  : 'Next: ${next.exercise.title}',
              style: RohabType.body,
            ),
            const SizedBox(height: RohabSpace.s24),
            RohabButton(
              key: HomeScreen.todayPrimaryKey,
              label: label,
              onPressed: action,
              disabledReason: action == null
                  ? 'Nothing more to do today.'
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// "From your therapist" and "Your goal": only when there is data.
class _Rows extends StatelessWidget {
  const _Rows({required this.overview});

  final ProgramOverview overview;

  @override
  Widget build(BuildContext context) {
    final plan = overview.plan;
    final fromTherapist = overview.settings.levelOverride != null;
    if (plan == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: RohabSpace.s16),
      child: RohabGroup(
        children: [
          if (fromTherapist)
            RohabRow(
              key: HomeScreen.therapistRowKey,
              title: 'From your therapist',
              subtitle: 'Level ${plan.level} exercises.',
              onTap: () => context.go(Routes.cameraExercises),
            ),
          RohabRow(
            key: HomeScreen.goalRowKey,
            title: 'Your goal',
            subtitle: "Today's exercises and reps to aim for.",
            value: '${plan.goal}',
            onTap: () => context.go(Routes.cameraExercises),
          ),
        ],
      ),
    );
  }
}
