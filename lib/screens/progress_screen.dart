import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/database.dart';
import '../exercises/exercise_catalog.dart';
import '../exercises/exercise_providers.dart';
import '../theme/app_theme.dart';

/// Recent sets, newest first. Charts and trends come later.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  static const emptyKey = Key('progress-empty');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    // Rebuilt after every saved set (the plan provider refreshes then).
    final future = ref.watch(exerciseSessionRepositoryProvider).all();
    return FutureBuilder<List<ExerciseSessionRow>>(
      future: future,
      builder: (context, snap) {
        final rows = (snap.data ?? const <ExerciseSessionRow>[]).reversed.toList();
        if (snap.connectionState != ConnectionState.done) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: RohabSpace.s24),
            children: [Text('Loading.', style: t.bodyLarge)],
          );
        }
        if (rows.isEmpty) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: RohabSpace.s24),
            children: [
              Text('No sessions yet.', key: emptyKey, style: t.labelLarge),
              const SizedBox(height: RohabSpace.s8),
              Text('Sets you finish in Exercises will appear here.',
                  style: t.bodyLarge),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: RohabSpace.s24),
          children: [
            const Divider(),
            for (final r in rows.take(30)) ...[
              _Row(row: r),
              const Divider(),
            ],
          ],
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row});

  final ExerciseSessionRow row;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final e = ExerciseCatalog.byId(row.exerciseId);
    final d = row.startedAt.toLocal();
    final when = '${d.day} ${_months[d.month - 1]}, '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: RohabSize.touchTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: RohabSpace.s8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e?.title ?? row.exerciseId, style: t.bodyLarge),
                  Text(when, style: t.labelMedium),
                ],
              ),
            ),
            Text('${row.reps} ${e?.repUnit ?? 'reps'}', style: t.labelLarge),
          ],
        ),
      ),
    );
  }
}
