import 'package:material_ui/material_ui.dart';

import '../glove/mock_glove_service.dart';
import '../theme/app_theme.dart';

/// Debug builds only: pick the simulated patient's grip strength.
///
/// Non-modal on purpose: a modal barrier would block the STOP button.
void showDebugPresets(BuildContext context, MockGloveService glove) {
  late final PersistentBottomSheetController controller;
  controller = Scaffold.of(context).showBottomSheet(
    (context) => _PresetSheet(glove: glove, onClose: () => controller.close()),
  );
}

class _PresetSheet extends StatefulWidget {
  const _PresetSheet({required this.glove, required this.onClose});

  final MockGloveService glove;
  final VoidCallback onClose;

  @override
  State<_PresetSheet> createState() => _PresetSheetState();
}

class _PresetSheetState extends State<_PresetSheet> {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(RohabSpace.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Simulated grip (debug)', style: t.labelLarge),
            const SizedBox(height: RohabSpace.s8),
            for (final preset in MockEmgPreset.values)
              InkWell(
                key: Key('preset-${preset.name}'),
                borderRadius: BorderRadius.circular(RohabShape.radius),
                onTap: () => setState(() => widget.glove.preset = preset),
                child: SizedBox(
                  height: RohabSize.touchTarget,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${preset.label}, grip ${preset.gripMean.round()}',
                          style: t.bodyLarge,
                        ),
                      ),
                      if (widget.glove.preset == preset)
                        Icon(
                          Icons.check,
                          color: c.accent,
                          size: RohabSize.icon,
                        ),
                    ],
                  ),
                ),
              ),
            TextButton(onPressed: widget.onClose, child: const Text('Close')),
          ],
        ),
      ),
    );
  }
}
