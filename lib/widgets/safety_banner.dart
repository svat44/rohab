import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../glove/glove_service.dart';
import '../glove/mock_glove_service.dart';
import '../theme/app_theme.dart';
import 'skeuo.dart';

/// Shown at the top of every screen: connection status and the STOP button.
///
/// STOP calls [GloveService.emergencyVent] directly, in every state,
/// with no confirmation step.
class SafetyBanner extends ConsumerWidget {
  const SafetyBanner({super.key});

  static const stopKey = Key('safety-stop');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glove = ref.watch(gloveServiceProvider);
    final c = context.colors;
    final textTheme = Theme.of(context).textTheme;

    // Without a glove there is nothing to vent, so the banner stays away
    // (camera-only use). It appears as soon as a glove connects or faults.
    return ValueListenableBuilder<GloveSnapshot>(
      valueListenable: glove.snapshot,
      builder: (context, snap, banner) =>
          snap.connection == GloveConnection.disconnected && snap.faults.isEmpty
          ? const SizedBox.shrink()
          : banner!,
      child: _banner(context, glove, c, textTheme),
    );
  }

  Widget _banner(
    BuildContext context,
    GloveService glove,
    AppColors c,
    TextTheme textTheme,
  ) {
    return Container(
      decoration: paperDecoration(c, radius: 0).copyWith(
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(
        RohabSpace.s16,
        RohabSpace.s8,
        RohabSpace.s8,
        RohabSpace.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder<GloveSnapshot>(
              valueListenable: glove.snapshot,
              builder: (context, s, _) {
                final (title, detail) = _statusText(
                  s,
                  glove is MockGloveService,
                );
                final hasFault = s.faults.isNotEmpty;
                return Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      Icon(
                        s.isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        size: RohabSize.icon,
                        color: s.isConnected ? c.accent : c.secondary,
                      ),
                      const SizedBox(width: RohabSpace.s8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Wraps instead of cutting off on narrow phones.
                            Text(
                              title,
                              style: textTheme.labelLarge,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (detail != null)
                              Text(
                                detail,
                                style: textTheme.labelMedium?.copyWith(
                                  color: hasFault ? c.danger : c.secondary,
                                  fontWeight: hasFault
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: RohabSpace.s8),
          _StopButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              glove.emergencyVent();
            },
          ),
        ],
      ),
    );
  }

  (String, String?) _statusText(GloveSnapshot s, bool simulated) {
    if (s.faults.isNotEmpty) {
      return ('Glove vented', 'Fault: ${s.faults.first.label}');
    }
    return switch (s.connection) {
      GloveConnection.disconnected => ('Glove not connected', null),
      GloveConnection.connecting => ('Connecting', null),
      GloveConnection.connected => (
        simulated ? 'Simulated glove' : 'Connected',
        s.state.patientLabel,
      ),
    };
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: 'Stop. Vents the glove now.',
      excludeSemantics: true,
      child: SizedBox(
        width: RohabSize.stopButtonWidth,
        height: RohabSize.stopButtonHeight,
        child: FilledButton(
          key: SafetyBanner.stopKey,
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: c.danger,
            foregroundColor: c.onDanger,
            minimumSize: const Size(
              RohabSize.stopButtonWidth,
              RohabSize.stopButtonHeight,
            ),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RohabShape.radius),
            ),
            textStyle: const TextStyle(
              fontFamily: RohabTokens.fontFamily,
              fontSize: RohabType.title,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          child: const Text('STOP'),
        ),
      ),
    );
  }
}
