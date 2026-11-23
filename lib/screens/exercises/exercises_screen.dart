import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../exercises/exercise_catalog.dart';
import '../../glove/glove_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rohab_widgets.dart';
import 'program_screen.dart';

/// Choose how to exercise: with the phone's camera, or (later) the glove.
class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  static const cameraKey = Key('path-camera');
  static const gloveKey = Key('path-glove');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glove = ref.watch(gloveServiceProvider);
    return ValueListenableBuilder<GloveSnapshot>(
      valueListenable: glove.snapshot,
      builder: (context, s, _) => ListView(
        padding: const EdgeInsets.fromLTRB(
          RohabSpace.s24,
          0,
          RohabSpace.s24,
          RohabSpace.s24,
        ),
        children: [
          RohabGroup(
            dividerInset: RohabRow.textInset,
            children: [
              RohabRow(
                key: cameraKey,
                icon: Icons.photo_camera_outlined,
                title: 'Camera',
                subtitle: "Practice with your phone's camera. No glove needed.",
                onTap: () => context.go(Routes.cameraExercises),
              ),
              // Glove exercises are not built yet, so this stays disabled
              // even when a glove is connected.
              RohabRow(
                key: gloveKey,
                icon: Icons.bluetooth,
                title: 'With glove',
                subtitle: s.isConnected
                    ? 'Not available yet.'
                    : 'Available when your glove is connected.',
                enabled: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The camera exercises: title, one line, target.
class CameraExerciseListScreen extends StatelessWidget {
  const CameraExerciseListScreen({super.key});

  static Key rowKey(String id) => Key('exercise-$id');

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        RohabSpace.s8,
        0,
        RohabSpace.s24,
        RohabSpace.s24,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go(Routes.cameraExercises),
            icon: const Icon(Icons.arrow_back, size: RohabSize.icon),
            label: const Text("Today's plan"),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: RohabSpace.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: RohabSpace.s8),
              Text('Practice any exercise', style: t.headlineMedium),
              const SizedBox(height: RohabSpace.s8),
              Text(
                "Sets of exercises in today's plan count toward it.",
                style: t.labelMedium,
              ),
              for (final level in [1, 2, 3]) ...[
                SectionTitle(
                  'Level $level · ${ProgramScreen.levelNames[level]}',
                ),
                RohabGroup(
                  dividerInset: RohabRow.textInset,
                  children: [
                    for (final e in ExerciseCatalog.forLevel(level))
                      RohabRow(
                        key: rowKey(e.id),
                        icon: exerciseIcon(e.kind),
                        title: e.title,
                        subtitle: e.description,
                        value: e.target,
                        onTap: () => context.go(Routes.cameraExercise(e.id)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
