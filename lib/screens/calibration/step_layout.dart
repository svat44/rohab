import 'package:material_ui/material_ui.dart';

import '../../theme/app_theme.dart';
import '../../widgets/action_area.dart';

/// Shared frame for the calibration steps: step indicator, one instruction,
/// content, and a fixed action area.
///
/// The action area always has two fixed slots (secondary above, primary
/// below), so a button never slides under a finger between steps. On the
/// recording steps the primary slot stays empty, which keeps Cancel away
/// from where "I'm ready" was.
class StepLayout extends StatelessWidget {
  const StepLayout({
    super.key,
    required this.step,
    required this.name,
    required this.instruction,
    this.children = const [],
    this.secondary,
    this.primary,
  });

  static const totalSteps = 4;
  static const cancelKey = Key('calibration-cancel');
  static const primaryKey = Key('calibration-primary');
  static const instructionKey = Key('calibration-instruction');

  final int step;
  final String name;
  final String instruction;
  final List<Widget> children;
  final Widget? secondary;
  final Widget? primary;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: RohabSpace.s24),
            children: [
              _StepIndicator(step: step),
              const SizedBox(height: RohabSpace.s8),
              Text('Step $step of $totalSteps · $name', style: t.labelMedium),
              const SizedBox(height: RohabSpace.s24),
              Semantics(
                liveRegion: true,
                child: Text(instruction,
                    key: instructionKey, style: t.titleLarge),
              ),
              const SizedBox(height: RohabSpace.s24),
              ...children,
              const SizedBox(height: RohabSpace.s24),
            ],
          ),
        ),
        ActionArea(secondary: secondary, primary: primary),
      ],
    );
  }
}

/// Four flat segments: done (accent-soft), current (accent), to do (divider).
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 1; i <= StepLayout.totalSteps; i++) ...[
            if (i > 1) const SizedBox(width: RohabSpace.s8),
            Expanded(
              child: Container(
                height: RohabSpace.s8,
                decoration: BoxDecoration(
                  color: i < step
                      ? c.accentSoft
                      : i == step
                          ? c.accent
                          : c.divider,
                  borderRadius: BorderRadius.circular(RohabSpace.s8 / 2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Cancel: back to the Calibration start, nothing saved.
class CancelButton extends StatelessWidget {
  const CancelButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
        key: StepLayout.cancelKey,
        onPressed: onPressed,
        child: const Text('Cancel'),
      );
}

/// Full-width primary button for a step.
class StepPrimaryButton extends StatelessWidget {
  const StepPrimaryButton(
      {super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
        key: StepLayout.primaryKey,
        onPressed: onPressed,
        child: Text(label),
      );
}
