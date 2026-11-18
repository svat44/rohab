import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';
import '../../widgets/countdown_number.dart';
import '../../widgets/effort_bar.dart';
import 'step_layout.dart';

/// Step 2: record 5 s of resting signal.
class RestStep extends StatelessWidget {
  const RestStep({
    super.key,
    required this.secondsLeft,
    required this.samples,
    required this.onCancel,
  });

  static const instruction = 'Rest your hand on the table. Stay relaxed.';

  final int secondsLeft;
  final Stream<int> samples;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return StepLayout(
      step: 2,
      name: 'Rest',
      instruction: instruction,
      secondary: CancelButton(onPressed: onCancel),
      children: [
        CountdownNumber(seconds: secondsLeft),
        const SizedBox(height: RohabSpace.s32),
        EffortBar(samples: samples),
      ],
    );
  }
}
