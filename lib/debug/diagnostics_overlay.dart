import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'diagnostics.dart';

/// Debug builds only: whether new exercise runs show the overlay. Switched
/// from the debug menu (long-press the "Rohab" title).
final diagnosticsEnabledProvider = NotifierProvider<DiagnosticsEnabled, bool>(
  DiagnosticsEnabled.new,
);

class DiagnosticsEnabled extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

/// Live numbers over the camera: speed, detection, dropout, openness and
/// rep state. Also logged to the console about once a second.
class DiagnosticsOverlay extends StatelessWidget {
  const DiagnosticsOverlay({super.key, required this.collector});

  final DiagnosticsCollector collector;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme.labelMedium!;
    return ListenableBuilder(
      listenable: collector,
      builder: (context, _) {
        final extra = collector.extra?.call() ?? '';
        return DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(RohabShape.radius / 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(RohabSpace.s8),
            child: Text(
              'FPS ${collector.fps.toStringAsFixed(0)}\n'
              'Detected ${collector.detectionPercent.toStringAsFixed(0)}% (10 s)\n'
              'Dropout ${(collector.dropout.inMilliseconds / 1000).toStringAsFixed(1)} s\n'
              '$extra',
              style: t.copyWith(color: context.colors.text),
            ),
          ),
        );
      },
    );
  }
}
