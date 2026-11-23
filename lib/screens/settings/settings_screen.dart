import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../config/app_info.dart';
import '../../exercises/exercise_providers.dart';
import '../../glove/glove_service.dart';
import '../../settings/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rohab_widgets.dart';
import '../../widgets/surfaces.dart';
import '../progress/overview.dart';
import '../progress/progress_data.dart';

/// Settings: the glove connection, the therapist plan, text size, deleting
/// saved sessions, and About.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const therapistKey = Key('settings-therapist');
  static const disconnectKey = Key('settings-disconnect');
  static Key textSizeKey(TextSize s) => Key('settings-text-${s.name}');
  static const clearKey = Key('settings-clear');
  static const confirmDeleteKey = Key('settings-confirm-delete');
  static const cancelDeleteKey = Key('settings-cancel-delete');
  static const clearedKey = Key('settings-cleared');
  static const aboutKey = Key('settings-about');

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
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final glove = ref.watch(gloveServiceProvider);
    final size = ref.watch(textSizeProvider);

    return ListView(
      scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
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
            ValueListenableBuilder<GloveSnapshot>(
              valueListenable: glove.snapshot,
              builder: (context, s, _) {
                final canDisconnect = s.isConnected && !s.sessionActive;
                final detail = switch (s.connection) {
                  GloveConnection.disconnected =>
                    'Not connected. Connect on Home.',
                  GloveConnection.connecting => 'Connecting.',
                  GloveConnection.connected when s.sessionActive =>
                    'Connected. End the session on Home before disconnecting.',
                  GloveConnection.connected => 'Connected.',
                };
                return ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: RohabSize.touchTarget,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RohabSpace.s16,
                      vertical: RohabSpace.s8 + 4,
                    ),
                    child: Row(
                      children: [
                        const IconBadge(Icons.bluetooth, size: 48),
                        const SizedBox(width: RohabSpace.s16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Glove', style: t.bodyLarge),
                              const SizedBox(height: RohabSpace.s8 / 2),
                              Text(detail, style: t.labelMedium),
                              if (canDisconnect) ...[
                                const SizedBox(height: RohabSpace.s8),
                                TextButton(
                                  key: SettingsScreen.disconnectKey,
                                  onPressed: glove.disconnect,
                                  child: const Text('Disconnect'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            RohabRow(
              key: SettingsScreen.therapistKey,
              icon: Icons.assignment,
              title: 'Therapist plan',
              subtitle:
                  'Level, daily goal, sets and pain limits. '
                  'Needs the therapist PIN.',
              onTap: () => context.go(Routes.therapist),
            ),
          ],
        ),
        const SectionTitle('Text size'),
        RohabGroup(
          children: [
            Padding(
              padding: const EdgeInsets.all(RohabSpace.s8),
              child: Row(
                children: [
                  for (final s in TextSize.values) ...[
                    if (s != TextSize.values.first)
                      const SizedBox(width: RohabSpace.s8),
                    Expanded(
                      child: _Segment(
                        key: SettingsScreen.textSizeKey(s),
                        label: s.label,
                        selected: s == size,
                        onTap: () => ref.read(textSizeProvider.notifier).set(s),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: RohabSpace.s24),
        if (_confirming)
          _ConfirmDelete(
            onDelete: _delete,
            onCancel: () => setState(() => _confirming = false),
          )
        else ...[
          RohabGroup(
            children: [
              RohabRow(
                key: SettingsScreen.clearKey,
                title: 'Clear all data',
                titleColor: c.danger,
                onTap: () => setState(() {
                  _confirming = true;
                  _cleared = false;
                }),
              ),
            ],
          ),
          if (_cleared)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                RohabSpace.s8,
                RohabSpace.s8,
                RohabSpace.s8,
                0,
              ),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  'All saved sessions were deleted.',
                  key: SettingsScreen.clearedKey,
                  style: t.labelMedium,
                ),
              ),
            ),
        ],
        const SectionTitle('About'),
        RohabGroup(
          children: [
            Padding(
              padding: const EdgeInsets.all(RohabSpace.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rohab version $kAppVersion',
                    key: SettingsScreen.aboutKey,
                    style: t.bodyLarge,
                  ),
                  const SizedBox(height: RohabSpace.s8),
                  Text(
                    'Rohab is not a medical device. Ask your therapist before '
                    'changing your exercises.',
                    style: t.labelMedium,
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

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(RohabShape.card);
    return Semantics(
      button: true,
      selected: selected,
      child: ChoiceBox(
        selected: selected,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: RohabSize.touchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: RohabSpace.s8,
              ),
              child: Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (selected)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.check,
                              size: RohabType.label + 2,
                              color: c.onAccent,
                            ),
                          ),
                        ),
                      TextSpan(text: label),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? c.onAccent : c.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Confirmation, shown in the page rather than as a pop-up window: a
/// pop-up would cover the STOP banner.
class _ConfirmDelete extends StatelessWidget {
  const _ConfirmDelete({required this.onDelete, required this.onCancel});

  final VoidCallback onDelete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: RohabSpace.s16),
        padding: const EdgeInsets.all(RohabSpace.s16),
        decoration: panelDecoration(c, radius: RohabShape.radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Delete all saved sessions? This cannot be undone.',
              style: t.bodyLarge,
            ),
            const SizedBox(height: RohabSpace.s16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: RohabSize.touchTarget,
                    child: TextButton(
                      key: SettingsScreen.confirmDeleteKey,
                      onPressed: onDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: c.onDanger,
                        backgroundColor: c.danger,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            RohabShape.radius,
                          ),
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ),
                const SizedBox(width: RohabSpace.s8),
                Expanded(
                  child: SizedBox(
                    height: RohabSize.touchTarget,
                    child: TextButton(
                      key: SettingsScreen.cancelDeleteKey,
                      onPressed: onCancel,
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
