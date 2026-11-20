import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../theme/app_theme.dart';

/// Settings. Only the therapist plan is built so far.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const therapistKey = Key('settings-therapist');

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          RohabSpace.s24, 0, RohabSpace.s24, RohabSpace.s24),
      children: [
        const Divider(),
        InkWell(
          key: therapistKey,
          onTap: () => context.go(Routes.therapist),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(minHeight: RohabSize.touchTarget * 1.25),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Therapist plan', style: t.labelLarge),
                      const SizedBox(height: RohabSpace.s8 / 2),
                      Text('Level, daily goal, sets and pain limits. '
                          'Needs the therapist PIN.',
                          style: t.labelMedium),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: RohabSize.icon, color: c.secondary),
              ],
            ),
          ),
        ),
        const Divider(),
        const SizedBox(height: RohabSpace.s16),
        Text('Maximum pressure, session length and reminders come in a '
            'later update.', style: t.bodyLarge),
      ],
    );
  }
}
