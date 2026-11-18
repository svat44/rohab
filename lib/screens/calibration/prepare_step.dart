import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';
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
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return StepLayout(
      step: 1,
      name: 'Prepare',
      instruction: instruction,
      secondary: CancelButton(onPressed: onCancel),
      primary: StepPrimaryButton(label: "I'm ready", onPressed: onReady),
      children: [
        // Photo slot: 400 x 240 dp, narrower on small phones, same shape.
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: AspectRatio(
              aspectRatio: 400 / 240,
              child: Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  border:
                      Border.all(color: c.divider, width: RohabShape.border),
                  borderRadius: BorderRadius.circular(RohabShape.radius),
                ),
                alignment: Alignment.center,
                child: Text('Photo to come', style: t.labelMedium),
              ),
            ),
          ),
        ),
        const SizedBox(height: RohabSpace.s8),
        Text('Sensor on the inner forearm, right arm shown.',
            style: t.labelMedium),
      ],
    );
  }
}
