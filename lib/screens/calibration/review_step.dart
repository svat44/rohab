import 'package:material_ui/material_ui.dart';

import '../../calibration/emg_calibrator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/effort_bar.dart';
import 'step_layout.dart';

/// Step 4: show the levels and save, or redo.
class ReviewStep extends StatelessWidget {
  const ReviewStep({
    super.key,
    required this.result,
    required this.samples,
    required this.onSave,
    required this.onRedo,
    required this.onCancel,
  });

  static const validInstruction = 'Check your levels.';
  static const redoKey = Key('calibration-redo');

  final CalibrationResult result;
  final Stream<int> samples;
  final VoidCallback onSave;
  final VoidCallback onRedo;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final valid = result.isValid;
    return StepLayout(
      step: 4,
      name: 'Review',
      instruction: valid ? validInstruction : EmgCalibrator.invalidMessage,
      secondary: valid
          ? Row(
              children: [
                Expanded(child: CancelButton(onPressed: onCancel)),
                const SizedBox(width: RohabSpace.s8),
                Expanded(
                  child: TextButton(
                    key: redoKey,
                    onPressed: onRedo,
                    child: const Text('Redo'),
                  ),
                ),
              ],
            )
          : CancelButton(onPressed: onCancel),
      primary: valid
          ? StepPrimaryButton(label: 'Save', onPressed: onSave)
          : StepPrimaryButton(label: 'Redo', onPressed: onRedo),
      children: [
        EffortBar(
          samples: samples,
          markers: [
            EffortMarker(result.restMean, 'Rest ${result.restMean.round()}'),
            EffortMarker(result.gripLevel, 'Grip ${result.gripLevel.round()}'),
            if (valid)
              EffortMarker(
                result.threshold,
                'Trigger ${result.threshold}',
                above: true,
              ),
          ],
        ),
        const SizedBox(height: RohabSpace.s24),
        const Divider(),
        if (valid) ...[
          _Level(label: 'Trigger level', value: result.threshold, strong: true),
          const Divider(),
        ],
        _Level(label: 'Rest level', value: result.restMean.round()),
        const Divider(),
        _Level(label: 'Grip level', value: result.gripLevel.round()),
        const Divider(),
      ],
    );
  }
}

class _Level extends StatelessWidget {
  const _Level({required this.label, required this.value, this.strong = false});

  final String label;
  final int value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: RohabSize.touchTarget),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: strong ? t.labelLarge : t.bodyLarge),
          ),
          Text(
            '$value',
            style: t.labelLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
