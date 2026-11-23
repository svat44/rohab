import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../camera/handedness.dart';
import '../../data/database.dart';
import '../../exercises/exercise_catalog.dart';
import '../../exercises/exercise_providers.dart';
import '../../exercises/exercise_setup.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/result_panel.dart';
import '../../widgets/rohab_app_bar.dart';
import '../../widgets/rohab_row.dart';
import '../../widgets/rohab_stepper.dart';
import '../../widgets/rohab_tabs.dart';

/// The "calculator" page for one exercise: Set up | How to | History, with
/// the plan pinned at the bottom.
class ExerciseSetupScreen extends ConsumerStatefulWidget {
  const ExerciseSetupScreen({super.key, required this.exerciseId});

  final String exerciseId;

  static const startKey = Key('setup-start');
  static const handKey = Key('setup-hand');

  @override
  ConsumerState<ExerciseSetupScreen> createState() =>
      _ExerciseSetupScreenState();
}

class _ExerciseSetupScreenState extends ConsumerState<ExerciseSetupScreen> {
  int _tab = 0;

  CameraExercise get _exercise =>
      ExerciseCatalog.byId(widget.exerciseId) ?? ExerciseCatalog.openClose;

  @override
  Widget build(BuildContext context) {
    // Watch so the panel follows every change.
    ref.watch(exerciseSetupsProvider);
    final setup = ref.read(exerciseSetupsProvider.notifier).of(_exercise.id);
    void change(ExerciseSetup s) =>
        ref.read(exerciseSetupsProvider.notifier).update(_exercise.id, s);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RohabAppBar(
          title: _exercise.title,
          onBack: () => context.go(Routes.allCameraExercises),
        ),
        UnderlineTabs(
          labels: const ['Set up', 'How to', 'History'],
          selected: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        Expanded(
          child: switch (_tab) {
            0 => _SetUp(setup: setup, onChanged: change),
            1 => _HowTo(exercise: _exercise),
            _ => _History(exercise: _exercise),
          },
        ),
        ResultPanel(
          title: 'Your plan',
          lines: [setup.summaryLine, setup.timeLine],
          actionLabel: 'Start',
          actionKey: ExerciseSetupScreen.startKey,
          onAction: () => context.go(
            Routes.cameraExercise(
              _exercise.id,
              reps: setup.reps,
              sets: setup.sets,
              rest: setup.restSeconds,
              set: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _SetUp extends StatelessWidget {
  const _SetUp({required this.setup, required this.onChanged});

  final ExerciseSetup setup;
  final ValueChanged<ExerciseSetup> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      padding: EdgeInsets.only(
        top: RohabSpace.s16,
        bottom: RohabSpace.s24 + ResultPanel.reserve,
      ),
      children: [
        RohabGroup(
          children: [
            Container(
              color: c.surface,
              padding: const EdgeInsets.all(RohabSpace.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Hand', style: RohabType.rowTitle),
                  const Padding(
                    padding: EdgeInsets.only(top: 2, bottom: RohabSpace.s8),
                    child: Text(
                      'Which hand you will exercise.',
                      style: RohabType.rowSub,
                    ),
                  ),
                  SquareSegmented<Handedness>(
                    key: ExerciseSetupScreen.handKey,
                    options: const [
                      (Handedness.right, 'Right'),
                      (Handedness.left, 'Left'),
                    ],
                    selected: setup.hand,
                    onChanged: (h) => onChanged(setup.copyWith(hand: h)),
                  ),
                ],
              ),
            ),
            RohabStepper(
              label: 'Reps per set',
              hint: 'How many times in one set.',
              value: setup.reps,
              min: kRepsRange.min,
              max: kRepsRange.max,
              onChanged: (v) => onChanged(setup.copyWith(reps: v)),
            ),
            RohabStepper(
              label: 'Sets',
              hint: 'How many sets today.',
              value: setup.sets,
              min: kSetsRange.min,
              max: kSetsRange.max,
              onChanged: (v) => onChanged(setup.copyWith(sets: v)),
            ),
            RohabStepper(
              label: 'Rest between sets',
              hint: 'Time to rest your hand.',
              value: setup.restSeconds,
              min: kRestRange.min,
              max: kRestRange.max,
              step: kRestStep,
              unit: 's',
              onChanged: (v) => onChanged(setup.copyWith(restSeconds: v)),
            ),
          ],
        ),
      ],
    );
  }
}

class _HowTo extends StatelessWidget {
  const _HowTo({required this.exercise});

  final CameraExercise exercise;

  Future<bool> _hasPhoto(String path) async {
    try {
      final m = await AssetManifest.loadFromAssetBundle(rootBundle);
      return m.listAssets().contains(path);
    } on Object {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final photo = 'assets/exercises/${exercise.id}.jpg';
    return ListView(
      padding: EdgeInsets.only(
        top: RohabSpace.s16,
        bottom: RohabSpace.s24 + ResultPanel.reserve,
      ),
      children: [
        RohabGroup(
          children: [
            for (var i = 0; i < exercise.steps.length; i++)
              Container(
                color: c.surface,
                padding: const EdgeInsets.all(RohabSpace.gutter),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${i + 1}',
                        style: RohabType.metricL.copyWith(color: c.accent),
                      ),
                    ),
                    Expanded(
                      child: Text(exercise.steps[i], style: RohabType.body),
                    ),
                  ],
                ),
              ),
            if (exercise.object != null)
              Container(
                color: c.surface,
                padding: const EdgeInsets.all(RohabSpace.gutter),
                width: double.infinity,
                child: Text(
                  'You need: ${exercise.object}.',
                  style: RohabType.rowTitle,
                ),
              ),
            Container(
              color: c.surface,
              padding: const EdgeInsets.all(RohabSpace.gutter),
              width: double.infinity,
              child: const Text(
                'Take your time. Stop if anything hurts.',
                style: RohabType.rowSub,
              ),
            ),
          ],
        ),
        // A photo only if one exists. No placeholder.
        FutureBuilder<bool>(
          future: _hasPhoto(photo),
          builder: (context, snap) => snap.data == true
              ? Padding(
                  padding: const EdgeInsets.only(top: RohabSpace.s16),
                  child: Image.asset(
                    photo,
                    fit: BoxFit.cover,
                    semanticLabel: '${exercise.title} photo',
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _History extends ConsumerWidget {
  const _History({required this.exercise});

  final CameraExercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(exerciseSessionRepositoryProvider);
    return FutureBuilder<List<ExerciseSessionRow>>(
      future: repo.sessionsFor(exercise.id, limit: 50),
      builder: (context, snap) {
        final rows = snap.data;
        if (rows == null) {
          return const Padding(
            padding: EdgeInsets.only(top: RohabSpace.s16),
            child: EmptyState(title: 'Loading.'),
          );
        }
        return ListView(
          padding: EdgeInsets.only(
            top: RohabSpace.s16,
            bottom: RohabSpace.s24 + ResultPanel.reserve,
          ),
          children: [
            if (rows.isEmpty)
              const EmptyState(title: 'No sessions yet.')
            else
              RohabGroup(
                children: [
                  for (final r in rows)
                    RohabRow(
                      title:
                          '${weekdayShort(r.startedAt)} ${r.startedAt.day}/${r.startedAt.month}, ${TimeOfDay.fromDateTime(r.startedAt).format(context)}',
                      subtitle: '${r.durationSec} s',
                      value: '${r.reps} of ${r.targetReps}',
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
