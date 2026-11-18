import 'package:material_ui/material_ui.dart';

import '../../calibration/calibration_controller.dart';
import '../../calibration/emg_calibrator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/countdown_number.dart';
import '../../widgets/effort_bar.dart';
import 'step_layout.dart';

/// Step 3: three 3 s grips with 5 s rest between.
class GripStep extends StatelessWidget {
  const GripStep({
    super.key,
    required this.phase,
    required this.trial,
    required this.secondsLeft,
    required this.samples,
    required this.onCancel,
  });

  static const gripInstruction = 'Try to make a fist.';
  static const relaxInstruction = 'Relax.';

  final GripPhase phase;
  final int trial;
  final int secondsLeft;
  final Stream<int> samples;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return StepLayout(
      step: 3,
      name: 'Grip',
      instruction:
          phase == GripPhase.grip ? gripInstruction : relaxInstruction,
      secondary: CancelButton(onPressed: onCancel),
      children: [
        Text('Trial $trial of ${EmgCalibrator.trialCount}',
            style: t.labelLarge),
        const SizedBox(height: RohabSpace.s16),
        CountdownNumber(seconds: secondsLeft),
        const SizedBox(height: RohabSpace.s32),
        EffortBar(samples: samples),
      ],
    );
  }
}
