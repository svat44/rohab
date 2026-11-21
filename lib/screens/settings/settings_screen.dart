import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../config/pressure_limits.dart';
import '../../glove/glove_service.dart';
import '../../theme/app_theme.dart';

/// Settings: the glove connection and the therapist plan.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const therapistKey = Key('settings-therapist');
  static const disconnectKey = Key('settings-disconnect');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final glove = ref.watch(gloveServiceProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          RohabSpace.s24, 0, RohabSpace.s24, RohabSpace.s24),
      children: [
        const Divider(),
        ValueListenableBuilder<GloveSnapshot>(
          valueListenable: glove.snapshot,
          builder: (context, s, _) {
            final canDisconnect = s.isConnected && !s.sessionActive;
            final detail = switch (s.connection) {
              GloveConnection.disconnected => 'Not connected. Connect on Home.',
              GloveConnection.connecting => 'Connecting.',
              GloveConnection.connected when s.sessionActive =>
                'Connected. End the session on Home before disconnecting.',
              GloveConnection.connected => 'Connected.',
            };
            return ConstrainedBox(
              constraints:
                  const BoxConstraints(minHeight: RohabSize.touchTarget * 1.25),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Glove', style: t.labelLarge),
                        const SizedBox(height: RohabSpace.s8 / 2),
                        Text(detail, style: t.labelMedium),
                      ],
                    ),
                  ),
                  if (canDisconnect)
                    TextButton(
                      key: disconnectKey,
                      onPressed: glove.disconnect,
                      child: const Text('Disconnect'),
                    ),
                ],
              ),
            );
          },
        ),
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
        Text(
          'Grip pressure is ${kTargetPressureKpa.round()} kPa, never above '
          '${kHardLimitKpa.round()} kPa.',
          style: t.bodyLarge,
        ),
      ],
    );
  }
}
