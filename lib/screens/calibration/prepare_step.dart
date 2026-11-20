import 'package:material_ui/material_ui.dart';

import '../../widgets/photo_slot.dart';
import 'step_layout.dart';

/// Step 1: place the sensor.
class PrepareStep extends StatelessWidget {
  const PrepareStep({super.key, required this.onReady, required this.onCancel});

  static const instruction = 'Place the sensor on your forearm, '
      'about 2 finger-widths below the elbow crease.';

  final VoidCallback onReady;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return StepLayout(
      step: 1,
      name: 'Prepare',
      instruction: instruction,
      secondary: CancelButton(onPressed: onCancel),
      primary: StepPrimaryButton(label: "I'm ready", onPressed: onReady),
      children: const [
        PhotoSlot(caption: 'Sensor on the inner forearm, right arm shown.'),
      ],
    );
  }
}
