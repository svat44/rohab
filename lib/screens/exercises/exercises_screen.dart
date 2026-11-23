import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../exercises/exercise_catalog.dart';
import '../../exercises/exercise_setup.dart';
import '../../glove/glove_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/rohab_app_bar.dart';
import '../../widgets/rohab_row.dart';
import '../../widgets/rohab_tabs.dart';

/// Every exercise: Camera | Glove | All, as rows. Tap one to set it up.
class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key, this.initialTab = 0});

  /// 0 Camera, 1 Glove, 2 All.
  final int initialTab;

  static const gloveTabLinkKey = Key('exercises-glove-link');
  static Key rowKey(String id) => Key('exercise-$id');

  @override
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  late int _tab = widget.initialTab;

  static const levelNames = {
    1: 'Opening the hand',
    2: 'Everyday grips',
    3: 'Single fingers',
  };

  @override
  Widget build(BuildContext context) {
    final glove = ref.watch(gloveServiceProvider);
    final last = ref.watch(lastDoneProvider).value ?? const {};
    final now = ref.watch(clockProvider)();
    // Everything scrolls, tabs included, so large text plus a pinned STOP bar
    // never overflows.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RohabAppBar(
          title: 'Practice any exercise',
          onBack: () => context.go(Routes.exercises),
        ),
        Expanded(
          child: ValueListenableBuilder<GloveSnapshot>(
            valueListenable: glove.snapshot,
            builder: (context, s, _) {
              final gloveTab = _tab == 1;
              final locked = gloveTab && !s.isConnected;
              return ListView(
                padding: EdgeInsets.only(
                  bottom: RohabSpace.s24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  UnderlineTabs(
                    labels: const ['Camera', 'Glove', 'All'],
                    selected: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                  if (gloveTab && !s.isConnected) ...[
                    const SizedBox(height: RohabSpace.s16),
                    RohabGroup(
                      children: [
                        RohabRow(
                          key: ExerciseListScreen.gloveTabLinkKey,
                          title: 'Glove',
                          subtitle:
                              'Connect your glove to use glove exercises.',
                          value: 'Not connected',
                          onTap: () => context.go(Routes.calibration),
                        ),
                      ],
                    ),
                  ],
                  if (gloveTab && s.isConnected)
                    const Padding(
                      padding: EdgeInsets.only(top: RohabSpace.s16),
                      child: EmptyState(
                        title: 'No glove exercises yet',
                        message: 'Your glove is connected. Glove exercises are not ready in this version.',
                      ),
                    )
                  else
                    for (final level in [1, 2, 3]) ...[
                      RohabSectionLabel(levelNames[level]!),
                      RohabGroup(
                        children: [
                          for (final e in ExerciseCatalog.forLevel(level))
                            RohabRow(
                              key: ExerciseListScreen.rowKey(e.id),
                              title: e.title,
                              subtitle: e.description,
                              value: locked
                                  ? null
                                  : lastDoneLabel(last[e.id], now),
                              locked: locked,
                              chevron: !locked,
                              onTap: locked
                                  ? null
                                  : () =>
                                        context.go(Routes.exerciseSetup(e.id)),
                            ),
                        ],
                      ),
                      if (locked)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(
                            RohabSpace.gutter,
                            RohabSpace.s8,
                            RohabSpace.gutter,
                            0,
                          ),
                          child: Text(
                            'Connect your glove to use this',
                            style: RohabType.rowSub,
                          ),
                        ),
                    ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The old "practice any exercise" route: now the All tab.
class CameraExerciseListScreen extends StatelessWidget {
  const CameraExerciseListScreen({super.key});

  static Key rowKey(String id) => ExerciseListScreen.rowKey(id);

  @override
  Widget build(BuildContext context) => const ExerciseListScreen(initialTab: 2);
}

/// The Exercises tab: choose how to exercise. Camera opens today's plan (the
/// exercises for today, in sets); the glove option waits for a connected
/// glove.
class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  static const cameraKey = Key('path-camera');
  static const gloveKey = Key('path-glove');
  static const allKey = Key('path-all');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glove = ref.watch(gloveServiceProvider);
    return ValueListenableBuilder<GloveSnapshot>(
      valueListenable: glove.snapshot,
      builder: (context, s, _) => ListView(
        padding: EdgeInsets.only(
          top: RohabSpace.s16,
          bottom:
              RohabSize.navHeight +
              MediaQuery.paddingOf(context).bottom +
              RohabSpace.s16,
        ),
        children: [
          RohabGroup(
            children: [
              RohabRow(
                key: cameraKey,
                title: 'Camera',
                subtitle: "Today's exercises with your phone's camera. No glove needed.",
                onTap: () => context.go(Routes.cameraExercises),
              ),
              RohabRow(
                key: allKey,
                title: 'Practice any exercise',
                subtitle: 'Pick one and set reps, sets and rest.',
                onTap: () => context.go(Routes.allCameraExercises),
              ),
              // Glove exercises are not built yet, so this stays locked even
              // when a glove is connected.
              RohabRow(
                key: gloveKey,
                title: 'With glove',
                subtitle: s.isConnected
                    ? 'Not available yet.'
                    : 'Connect your glove to use this.',
                locked: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
