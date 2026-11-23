import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../config/app_info.dart';
import '../../exercises/exercise_providers.dart';
import '../../glove/glove_service.dart';
import '../../program/program_providers.dart';
import '../../camera/handedness.dart';
import '../../settings/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rohab_button.dart';
import '../../widgets/rohab_row.dart';
import '../../widgets/rohab_tabs.dart';
import '../progress/progress_data.dart';

/// Settings: text size, affected hand, the glove, the therapist plan,
/// deleting saved sessions, and About.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const therapistKey = Key('settings-therapist');
  static const disconnectKey = Key('settings-disconnect');
  static const gloveKey = Key('settings-glove');
  static const handKey = Key('settings-hand');
  static Key textSizeKey(TextSize s) => Key('settings-text-${s.name}');
  static const clearKey = Key('settings-clear');
  static const confirmDeleteKey = Key('settings-confirm-delete');
  static const cancelDeleteKey = Key('settings-cancel-delete');
  static const clearedKey = Key('settings-cleared');
  static const aboutKey = Key('settings-about');
  static const fontsKey = Key('settings-fonts');

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _confirming = false;
  bool _cleared = false;

  Future<void> _delete() async {
    await ref.read(exerciseSessionRepositoryProvider).deleteAll();
    ref.invalidate(progressDataProvider);
    ref.invalidate(progressOverviewProvider);
    if (mounted) {
      setState(() {
        _confirming = false;
        _cleared = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final glove = ref.watch(gloveServiceProvider);
    final size = ref.watch(textSizeProvider);
    final hand = ref
        .watch(programOverviewProvider)
        .value
        ?.baseline
        ?.affectedHand;
    final bottom = RohabSize.navHeight + MediaQuery.paddingOf(context).bottom;

    return ListView(
      scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
      padding: EdgeInsets.only(bottom: bottom + RohabSpace.s16),
      children: [
        const RohabSectionLabel('Display'),
        RohabGroup(
          children: [
            Container(
              color: c.surface,
              padding: const EdgeInsets.all(RohabSpace.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Text size', style: RohabType.rowTitle),
                  const Padding(
                    padding: EdgeInsets.only(top: 2, bottom: RohabSpace.s8),
                    child: Text(
                      'Makes all text bigger.',
                      style: RohabType.rowSub,
                    ),
                  ),
                  SquareSegmented<TextSize>(
                    options: [for (final s in TextSize.values) (s, s.label)],
                    selected: size,
                    keyFor: SettingsScreen.textSizeKey,
                    onChanged: (s) =>
                        ref.read(textSizeProvider.notifier).set(s),
                  ),
                ],
              ),
            ),
          ],
        ),
        const RohabSectionLabel('You'),
        RohabGroup(
          children: [
            RohabRow(
              key: SettingsScreen.handKey,
              title: 'Affected hand',
              subtitle: 'Set when you measure your hands.',
              value: switch (hand) {
                Handedness.left => 'Left',
                Handedness.right => 'Right',
                _ => 'Not set',
              },
              onTap: () => context.go(Routes.baseline),
            ),
            RohabRow(
              key: SettingsScreen.therapistKey,
              title: 'Therapist plan',
              subtitle: 'Level, daily goal, sets and pain limits. Needs the therapist PIN.',
              onTap: () => context.go(Routes.therapist),
            ),
          ],
        ),
        const RohabSectionLabel('Glove'),
        ValueListenableBuilder<GloveSnapshot>(
          valueListenable: glove.snapshot,
          builder: (context, s, _) {
            final canDisconnect = s.isConnected && !s.sessionActive;
            return RohabGroup(
              children: [
                RohabRow(
                  key: SettingsScreen.gloveKey,
                  title: 'Glove',
                  subtitle: switch (s.connection) {
                    GloveConnection.disconnected => 'Not connected.',
                    GloveConnection.connecting => 'Connecting.',
                    GloveConnection.connected when s.sessionActive =>
                      'Connected. End the glove session before disconnecting.',
                    GloveConnection.connected => 'Connected.',
                  },
                  onTap: () => context.go(Routes.calibration),
                ),
                if (canDisconnect)
                  Container(
                    color: c.surface,
                    padding: const EdgeInsets.all(RohabSpace.gutter),
                    child: RohabButton(
                      key: SettingsScreen.disconnectKey,
                      label: 'Disconnect',
                      kind: RohabButtonKind.secondary,
                      onPressed: glove.disconnect,
                    ),
                  ),
              ],
            );
          },
        ),
        const RohabSectionLabel('Your data'),
        if (_confirming)
          Semantics(
            liveRegion: true,
            child: Container(
              color: c.surface,
              padding: const EdgeInsets.all(RohabSpace.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Delete all saved sessions? This cannot be undone.',
                    style: RohabType.body,
                  ),
                  const SizedBox(height: RohabSpace.s16),
                  RohabButton(
                    key: SettingsScreen.confirmDeleteKey,
                    label: 'Delete',
                    kind: RohabButtonKind.danger,
                    onPressed: _delete,
                  ),
                  const SizedBox(height: RohabSpace.s8),
                  RohabButton(
                    key: SettingsScreen.cancelDeleteKey,
                    label: 'Cancel',
                    kind: RohabButtonKind.secondary,
                    onPressed: () => setState(() => _confirming = false),
                  ),
                ],
              ),
            ),
          )
        else ...[
          RohabGroup(
            children: [
              RohabRow(
                key: SettingsScreen.clearKey,
                title: 'Clear all data',
                titleStyle: RohabType.rowTitle.copyWith(color: c.danger),
                onTap: () => setState(() {
                  _confirming = true;
                  _cleared = false;
                }),
              ),
            ],
          ),
          if (_cleared)
            Padding(
              padding: const EdgeInsets.all(RohabSpace.gutter),
              child: Semantics(
                liveRegion: true,
                child: const Text(
                  'All saved sessions were deleted.',
                  key: SettingsScreen.clearedKey,
                  style: RohabType.rowSub,
                ),
              ),
            ),
        ],
        const RohabSectionLabel('About'),
        RohabGroup(
          children: [
            Container(
              color: c.surface,
              padding: const EdgeInsets.all(RohabSpace.gutter),
              width: double.infinity,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rohab version $kAppVersion',
                    key: SettingsScreen.aboutKey,
                    style: RohabType.rowTitle,
                  ),
                  SizedBox(height: RohabSpace.s8),
                  Text(
                    'Research prototype. Not a medical device. Ask your therapist before changing your exercises.',
                    style: RohabType.rowSub,
                  ),
                ],
              ),
            ),
            Container(
              color: c.surface,
              padding: const EdgeInsets.all(RohabSpace.gutter),
              width: double.infinity,
              child: const Column(
                key: SettingsScreen.fontsKey,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Font licenses', style: RohabType.rowTitle),
                  SizedBox(height: RohabSpace.s8),
                  Text(
                    'Atkinson Hyperlegible Next and Source Sans 3 are '
                    'used under the SIL Open Font License 1.1. The full texts '
                    'ship with the app.',
                    style: RohabType.rowSub,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
