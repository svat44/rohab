import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../program/daily_plan.dart';
import '../../program/program_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/action_area.dart';
import '../../widgets/level_bar.dart';

/// Today's camera practice: level, rep goal, the planned exercises in sets,
/// and the next step.
class ProgramScreen extends ConsumerWidget {
  const ProgramScreen({super.key});

  static const primaryKey = Key('program-primary');
  static const measureKey = Key('program-measure');
  static const freePracticeKey = Key('program-free');

  static const levelNames = {
    1: 'Opening the hand',
    2: 'Everyday grips',
    3: 'Single fingers',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final overview = ref.watch(programOverviewProvider);
    final back = TextButton.icon(
      onPressed: () => context.go(Routes.exercises),
      icon: const Icon(Icons.arrow_back, size: RohabSize.icon),
      label: const Text('All exercises'),
    );

    return overview.when(
      loading: () => _Frame(
        top: back,
        children: [Text('Loading your plan.', style: t.bodyLarge)],
      ),
      error: (e, _) => _Frame(
        top: back,
        children: [Text('Your plan could not load. ${e.toString()}', style: t.bodyLarge)],
      ),
      data: (o) {
        if (o.plan == null) {
          return _Frame(
            top: back,
            primary: FilledButton(
              key: primaryKey,
              onPressed: () => context.go(Routes.baseline),
              child: const Text('Measure my hands'),
            ),
            children: [
              Text('First, measure your hands', style: t.headlineMedium),
              const SizedBox(height: RohabSpace.s16),
              Text(
                'Rohab measures how far each hand opens and closes. This '
                'sets a starting level that fits your hand. It takes about '
                '2 minutes.',
                style: t.bodyLarge,
              ),
              const SizedBox(height: RohabSpace.s16),
              _InlineAction(
                key: ProgramScreen.freePracticeKey,
                text: 'Or practice any exercise without a plan.',
                action: 'Open',
                onPressed: () => context.go(Routes.allCameraExercises),
              ),
            ],
          );
        }
        return _Today(overview: o, back: back);
      },
    );
  }
}

class _Today extends StatelessWidget {
  const _Today({required this.overview, required this.back});

  final ProgramOverview overview;
  final Widget back;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final o = overview;
    final plan = o.plan!;
    final next = plan.next;
    final painHigh =
        o.painBefore != null && o.painBefore! >= o.settings.painHighLimit;

    final Widget primary;
    if (next != null) {
      primary = FilledButton(
        key: ProgramScreen.primaryKey,
        // Pain is asked once a day, before the first set.
        onPressed: () => context.go(o.painBefore == null
            ? Routes.painCheck('before', next: next.exercise.id)
            : Routes.cameraExercise(next.exercise.id)),
        child: Text(plan.doneTotal == 0 ? 'Start' : 'Continue'),
      );
    } else if (o.painAfter == null && o.painBefore != null) {
      primary = FilledButton(
        key: ProgramScreen.primaryKey,
        onPressed: () => context.go(Routes.painCheck('after')),
        child: const Text('Finish for today'),
      );
    } else {
      primary = const FilledButton(
        key: ProgramScreen.primaryKey,
        onPressed: null,
        child: Text('Done for today'),
      );
    }

    return _Frame(
      top: back,
      primary: primary,
      children: [
        Text('Level ${plan.level} · ${ProgramScreen.levelNames[plan.level]}',
            style: t.labelMedium),
        const SizedBox(height: RohabSpace.s8),
        Semantics(
          label: '${plan.doneTotal} of ${plan.plannedTotal} done today',
          excludeSemantics: true,
          child: Text('${plan.doneTotal} of ${plan.plannedTotal} today',
              style: t.headlineMedium),
        ),
        const SizedBox(height: RohabSpace.s16),
        LevelBar(
          value: plan.plannedTotal == 0 ? 0 : plan.doneTotal / plan.plannedTotal,
          semanticsLabel: 'Today',
          semanticsValue: '${plan.doneTotal} of ${plan.plannedTotal}',
        ),
        if (painHigh) ...[
          const SizedBox(height: RohabSpace.s16),
          Text(
            'You reported high pain today. Rest your hand, and tell your '
            'therapist if it stays high.',
            style: t.bodyLarge,
          ),
        ],
        if (o.baseline!.cameraLimited) ...[
          const SizedBox(height: RohabSpace.s16),
          Text(
            'Your movement is smaller than the camera can count reliably. '
            'Practice with your therapist or the glove as well.',
            style: t.bodyLarge,
          ),
        ],
        const SizedBox(height: RohabSpace.s24),
        const Divider(),
        for (final item in plan.items) ...[
          _PlanRow(item: item, isNext: identical(item, next)),
          const Divider(),
        ],
        const SizedBox(height: RohabSpace.s8),
        if (o.recheckDue)
          _InlineAction(
            key: ProgramScreen.measureKey,
            text: "It's been a week. Measure your hands again.",
            action: 'Measure',
            onPressed: () => context.go(Routes.baseline),
          ),
        _InlineAction(
          key: ProgramScreen.freePracticeKey,
          text: 'Practice any exercise, outside the plan.',
          action: 'Open',
          onPressed: () => context.go(Routes.allCameraExercises),
        ),
        if (!o.recheckDue)
          _InlineAction(
            text: 'Measure your hands again.',
            action: 'Measure',
            onPressed: () => context.go(Routes.baseline),
          ),
        const SizedBox(height: RohabSpace.s8),
        Text(
          'Level set by ${o.settings.levelOverride == null ? 'your hand measurement' : 'your therapist'}. '
          'Daily goal: ${plan.goal}.',
          style: t.labelMedium?.copyWith(color: c.secondary),
        ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.item, required this.isNext});

  final PlanItem item;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final status = item.complete
        ? 'Done'
        : '${item.setsDone} of ${item.sets} sets · ${item.setSize} ${item.exercise.repUnit} each';
    return Semantics(
      label: '${item.exercise.title}. $status.${isNext ? ' Next.' : ''}',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: RohabSize.touchTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: RohabSpace.s8),
          child: Row(
            children: [
              SizedBox(
                width: RohabSpace.s32,
                child: item.complete
                    ? Icon(Icons.check, color: c.accent, size: RohabSize.icon)
                    : null,
              ),
              const SizedBox(width: RohabSpace.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.exercise.title,
                        style: isNext
                            ? t.labelLarge
                            : t.bodyLarge?.copyWith(
                                color: item.complete ? c.secondary : c.text)),
                    const SizedBox(height: RohabSpace.s8 / 2),
                    Text(status, style: t.labelMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    super.key,
    required this.text,
    required this.action,
    required this.onPressed,
  });

  final String text;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    // The whole row is the target, not just the word on the right.
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(RohabShape.radius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: RohabSize.touchTarget),
        child: Row(
          children: [
            Expanded(
              child: Text(text,
                  style: t.labelMedium?.copyWith(color: context.colors.text)),
            ),
            TextButton(onPressed: onPressed, child: Text(action)),
          ],
        ),
      ),
    );
  }
}

/// Back link on top, scrolling content, fixed action area.
class _Frame extends StatelessWidget {
  const _Frame({required this.top, required this.children, this.primary});

  final Widget top;
  final List<Widget> children;
  final Widget? primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                RohabSpace.s8, 0, RohabSpace.s24, RohabSpace.s16),
            children: [
              Align(alignment: Alignment.centerLeft, child: top),
              Padding(
                padding: const EdgeInsets.only(left: RohabSpace.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ],
          ),
        ),
        ActionArea(primary: primary),
      ],
    );
  }
}
