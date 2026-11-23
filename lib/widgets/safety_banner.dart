import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../app/providers.dart';
import '../calibration/calibration_controller.dart';
import '../glove/glove_service.dart';
import '../theme/app_theme.dart';
import 'rohab_button.dart';

/// The glove STOP sign, top right of every screen, shown only while the glove
/// is doing something: a session running, the hand moving or pressurised,
/// calibration in progress, or a fault. Idle, or no glove, it is not shown.
/// It sits above the screen (never inside a scroll view) and calls
/// [GloveService.emergencyVent] directly, with no confirmation step.
class SafetyBanner extends ConsumerWidget {
  const SafetyBanner({super.key});

  static const stopKey = StopButton.stopKey;

  /// True when pressure could be live or something just went wrong.
  static bool isActive(GloveSnapshot s, {required bool calibrating}) {
    if (s.faults.isNotEmpty) return true;
    if (!s.isConnected) return false;
    return s.sessionActive || s.state != GloveState.idle || calibrating;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glove = ref.watch(gloveServiceProvider);
    final step = ref.watch(calibrationControllerProvider).step;
    final calibrating = step != CalibrationStep.start;
    return ValueListenableBuilder<GloveSnapshot>(
      valueListenable: glove.snapshot,
      builder: (context, s, _) {
        if (!isActive(s, calibrating: calibrating)) {
          return const SizedBox.shrink();
        }
        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(RohabSpace.s8),
            child: StopButton(onStop: glove.emergencyVent),
          ),
        );
      },
    );
  }
}

/// A plain red line under the top bar while the glove has a fault, so the
/// reason for a vent is never hidden. Not shown otherwise.
class GloveFaultNotice extends ConsumerWidget {
  const GloveFaultNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glove = ref.watch(gloveServiceProvider);
    final c = context.colors;
    return ValueListenableBuilder<GloveSnapshot>(
      valueListenable: glove.snapshot,
      builder: (context, s, _) {
        if (s.faults.isEmpty) return const SizedBox.shrink();
        return Semantics(
          liveRegion: true,
          child: Container(
            color: c.surface,
            padding: const EdgeInsets.all(RohabSpace.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Glove vented',
                  style: RohabType.rowTitle.copyWith(color: c.danger),
                ),
                Text('Fault: ${s.faults.first.label}', style: RohabType.rowSub),
              ],
            ),
          ),
        );
      },
    );
  }
}
