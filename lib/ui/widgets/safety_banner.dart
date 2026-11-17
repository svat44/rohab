import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/glove_scope.dart';
import '../../glove/glove_service.dart';
import '../theme.dart';

/// Shown at the top of every screen: connection status and the STOP button.
///
/// STOP calls [GloveService.emergencyVent] directly, in every state,
/// with no confirmation step.
class SafetyBanner extends StatelessWidget {
  const SafetyBanner({super.key});

  static const stopKey = Key('safety-stop');

  @override
  Widget build(BuildContext context) {
    final glove = GloveScope.of(context);
    final c = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(
          Space.s2, Space.s1, Space.s1, Space.s1),
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder<GloveSnapshot>(
              valueListenable: glove.snapshot,
              builder: (context, s, _) {
                final (title, detail) = _statusText(s);
                final hasFault = s.faults.isNotEmpty;
                return Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      Icon(
                        s.isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        size: 28,
                        color: s.isConnected ? c.accent : c.gray,
                      ),
                      const SizedBox(width: Space.s1),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(title,
                                style: textTheme.labelLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            if (detail != null)
                              Text(
                                detail,
                                style: textTheme.labelMedium?.copyWith(
                                  color: hasFault ? c.danger : c.gray,
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
          const SizedBox(width: Space.s1),
          _StopButton(onPressed: () {
            HapticFeedback.heavyImpact();
            glove.emergencyVent();
          }),
        ],
      ),
    );
  }

  (String, String?) _statusText(GloveSnapshot s) {
    if (s.faults.isNotEmpty) {
      return ('Glove vented', 'Fault: ${s.faults.first.label}');
    }
    return switch (s.connection) {
      GloveConnection.disconnected => ('Not connected', null),
      GloveConnection.connecting => ('Connecting', null),
      GloveConnection.connected => ('Connected', s.state.label),
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
        width: 112,
        height: Sizes.stopButton,
        child: FilledButton(
          key: SafetyBanner.stopKey,
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: c.danger,
            foregroundColor: c.onDanger,
            minimumSize: const Size(112, Sizes.stopButton),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
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
