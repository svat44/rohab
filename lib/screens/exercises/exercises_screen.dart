import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../exercises/exercise_catalog.dart';
import '../../glove/glove_service.dart';
import '../../theme/app_theme.dart';

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
            RohabSpace.s24, 0, RohabSpace.s24, RohabSpace.s24),
        children: [
          _PathRow(
            key: cameraKey,
            title: 'Camera',
            description: "Practice with your phone's camera. No glove needed.",
            onTap: () => context.go(Routes.cameraExercises),
          ),
          const SizedBox(height: RohabSpace.s16),
          _PathRow(
            key: gloveKey,
            title: 'With glove',
            // Glove exercises are not built yet, so this stays disabled
            // even when a glove is connected.
            description: s.isConnected
                ? 'Not available yet.'
                : 'Available when your glove is connected.',
          ),
        ],
      ),
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow({
    super.key,
    required this.title,
    required this.description,
    this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final enabled = onTap != null;
    final radius = BorderRadius.circular(RohabShape.radius);
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: c.divider, width: RohabShape.border),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(minHeight: RohabSize.touchTarget * 1.5),
            child: Padding(
              padding: const EdgeInsets.all(RohabSpace.s24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: t.labelLarge?.copyWith(
                              color: enabled ? c.text : c.secondary),
                        ),
                        const SizedBox(height: RohabSpace.s8),
                        Text(
                          description,
                          style: t.labelMedium?.copyWith(
                              color: enabled ? c.text : c.secondary),
                        ),
                      ],
                    ),
                  ),
                  if (enabled)
                    Icon(Icons.chevron_right,
                        size: RohabSize.icon, color: c.secondary),
                ],
              ),
            ),
          ),
        ),
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
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          RohabSpace.s8, 0, RohabSpace.s24, RohabSpace.s24),
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
              Text('Practise any exercise', style: t.labelLarge),
              const SizedBox(height: RohabSpace.s8),
              Text("Sets of exercises in today's plan count toward it.",
                  style: t.labelMedium),
              const SizedBox(height: RohabSpace.s16),
              const Divider(),
              for (final e in ExerciseCatalog.all) ...[
                InkWell(
                  key: rowKey(e.id),
                  onTap: () => context.go(Routes.cameraExercise(e.id)),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                        minHeight: RohabSize.touchTarget * 1.5),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: RohabSpace.s16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.title, style: t.labelLarge),
                                const SizedBox(height: RohabSpace.s8),
                                Text(e.description,
                                    style: t.labelMedium
                                        ?.copyWith(color: c.text)),
                              ],
                            ),
                          ),
                          const SizedBox(width: RohabSpace.s16),
                          Text('Level ${e.level}', style: t.bodyLarge),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
