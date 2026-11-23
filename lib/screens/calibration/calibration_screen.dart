import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../calibration/calibration_controller.dart';
import '../../calibration/emg_calibrator.dart';
import '../../glove/glove_service.dart';
import '../../theme/app_theme.dart';
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
    final t = Theme.of(context).textTheme;
    final state = ref.watch(calibrationControllerProvider);
    final saved = ref.watch(savedCalibrationProvider);
    final needed = ref.watch(calibrationNeededProvider);
    final now = ref.watch(clockProvider)();
    final glove = ref.watch(gloveServiceProvider);

    return ValueListenableBuilder<GloveSnapshot>(
      valueListenable: glove.snapshot,
      builder: (context, s, _) {
        final blocked = CalibrationController.blockReason(s);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: RohabSpace.s24),
                children: [
                  if (state.notice != null) ...[
                    Text(state.notice!, style: t.labelLarge),
                    const SizedBox(height: RohabSpace.s24),
                  ],
                  Text(
                    'Teach the glove your resting and gripping muscle '
                    'signal. It takes about 1 minute.',
                    style: t.bodyLarge,
                  ),
                  const SizedBox(height: RohabSpace.s24),
                  const Divider(),
                  _Row(
                    label: 'Last calibrated',
                    value: saved == null
                        ? 'Not yet'
                        : formatWhen(saved.timestamp, now),
                  ),
                  const Divider(),
                  _Row(
                    label: 'Trigger level',
                    value: saved == null ? '–' : '${saved.threshold}',
                  ),
                  const Divider(),
                  if (needed) ...[
                    _Row(label: 'Status', value: 'Calibration needed'),
                    const Divider(),
                  ],
                  const SizedBox(height: RohabSpace.s16),
                  Text(
                    'A calibration lasts ${Calibration.validFor.inHours} hours.',
                    style: t.labelMedium,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(RohabSpace.s24,
                  RohabSpace.s16, RohabSpace.s24, RohabSpace.s16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: RohabSize.primaryButtonHeight,
                    child: FilledButton(
                      key: CalibrationScreen.startKey,
                      onPressed: blocked == null
                          ? ref
                              .read(calibrationControllerProvider.notifier)
                              .begin
                          : null,
                      child: const Text('Start calibration'),
                    ),
                  ),
                  // Why the button is off, right under it.
                  if (blocked != null) ...[
                    const SizedBox(height: RohabSpace.s8),
                    Text(
                      blocked,
                      textAlign: TextAlign.center,
                      style: t.labelMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: RohabSize.touchTarget),
      child: Row(
        children: [
          Expanded(child: Text(label, style: t.bodyLarge)),
          const SizedBox(width: RohabSpace.s16),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.5),
            child: Text(value, textAlign: TextAlign.end, style: t.labelLarge),
          ),
        ],
      ),
    );
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Today at 14:05", "Yesterday at 09:30", "3 Nov at 18:00".
String formatWhen(DateTime time, DateTime now) {
  final t = time.toLocal();
  final hm = '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
  final day = DateTime(t.year, t.month, t.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = today.difference(day).inDays;
  if (days == 0) return 'Today at $hm';
  if (days == 1) return 'Yesterday at $hm';
  return '${t.day} ${_months[t.month - 1]} at $hm';
}
