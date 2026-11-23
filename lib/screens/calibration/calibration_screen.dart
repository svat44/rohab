import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../calibration/calibration_controller.dart';
import '../../glove/glove_service.dart';
import '../../theme/app_theme.dart';
import '../../calibration/calibration_status.dart';
import '../../widgets/rohab_button.dart';
import '../../widgets/rohab_row.dart';
import '../glove/glove_session.dart';
import 'grip_step.dart';
import 'prepare_step.dart';
import 'rest_step.dart';
import 'review_step.dart';

/// Hosts the calibration start screen and the 4-step flow.
class CalibrationScreen extends ConsumerWidget {
  const CalibrationScreen({super.key});

  static const startKey = Key('calibration-start');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calibrationControllerProvider);
    final controller = ref.read(calibrationControllerProvider.notifier);
    final glove = ref.watch(gloveServiceProvider);
    final samples = glove.emgSamples;

    return switch (state.step) {
      CalibrationStep.start => const _StartView(),
      CalibrationStep.prepare => PrepareStep(
        onReady: controller.ready,
        onCancel: controller.cancel,
      ),
      CalibrationStep.rest => RestStep(
        secondsLeft: state.secondsLeft,
        samples: samples,
        onCancel: controller.cancel,
      ),
      CalibrationStep.grip => GripStep(
        phase: state.gripPhase,
        trial: state.trial,
        secondsLeft: state.secondsLeft,
        samples: samples,
        onCancel: controller.cancel,
      ),
      CalibrationStep.review => ReviewStep(
        result: state.result!,
        samples: samples,
        onSave: controller.save,
        onRedo: controller.redo,
        onCancel: controller.cancel,
      ),
    };
  }
}

class _StartView extends ConsumerWidget {
  const _StartView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calibrationControllerProvider);
    final saved = ref.watch(savedCalibrationProvider);
    final now = ref.watch(clockProvider)();
    final glove = ref.watch(gloveServiceProvider);
    final c = context.colors;

    return ValueListenableBuilder<GloveSnapshot>(
      valueListenable: glove.snapshot,
      builder: (context, s, _) {
        final blocked = CalibrationController.blockReason(s);
        final status = s.isConnected
            ? 'Connected'
            : s.connection == GloveConnection.connecting
            ? 'Connecting'
            : 'Not connected. Glove exercises are off.';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                  top: RohabSpace.s16,
                  bottom: RohabSpace.s24,
                ),
                children: [
                  if (state.notice != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        RohabSpace.gutter,
                        0,
                        RohabSpace.gutter,
                        RohabSpace.s16,
                      ),
                      child: Text(state.notice!, style: RohabType.rowTitle),
                    ),
                  RohabGroup(
                    children: [
                      RohabRow(
                        title: 'Status',
                        subtitle: status,
                        // A disconnected glove must be unmistakable.
                        titleStyle: RohabType.rowTitle.copyWith(
                          color: s.isConnected ? c.success : c.danger,
                        ),
                        key: GloveSession.statusKey,
                      ),
                    ],
                  ),
                  const SizedBox(height: RohabSpace.s16),
                  const GloveSession(),
                  const SizedBox(height: RohabSpace.s16),
                  RohabGroup(
                    children: [
                      RohabRow(
                        title: 'Last calibrated',
                        value: saved == null
                            ? 'Not yet'
                            : formatWhen(
                                saved.timestamp,
                                now,
                                use24h: MediaQuery.alwaysUse24HourFormatOf(
                                  context,
                                ),
                              ),
                      ),
                      RohabRow(
                        title: 'Calibration is good for',
                        value: calibrationGoodFor(saved, now),
                      ),
                      RohabRow(
                        title: 'Grip sensitivity',
                        subtitle: 'The glove moves when your muscle signal passes this number.',
                        value: saved == null
                            ? 'Not set'
                            : '${saved.threshold} of 1023',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.divider)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(RohabSpace.gutter),
                child: RohabButton(
                  key: CalibrationScreen.startKey,
                  label: 'Start calibration',
                  onPressed: ref
                      .read(calibrationControllerProvider.notifier)
                      .begin,
                  disabledReason: blocked,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// "Today at 2:05 PM" or "Today at 14:05", following the device's 12/24-hour
/// setting; "Yesterday at ..."; "3 Nov at ...".
String formatWhen(DateTime time, DateTime now, {required bool use24h}) {
  final t = time.toLocal();
  final hm = use24h
      ? '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'
      : '${t.hour % 12 == 0 ? 12 : t.hour % 12}:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
  final day = DateTime(t.year, t.month, t.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = today.difference(day).inDays;
  if (days == 0) return 'Today at $hm';
  if (days == 1) return 'Yesterday at $hm';
  return '${t.day} ${_months[t.month - 1]} at $hm';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
