import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'rohab_icon.dart';

/// Underline-style stepper: label and hint above, then [-] value [+] with the
/// value sitting on a 2 dp underline. The two buttons are 56x56, radius 4.
/// The value is clamped to [min]..[max] and moves by [step]; a button at its
/// limit is disabled.
class RohabStepper extends StatelessWidget {
  const RohabStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.hint,
    this.unit,
  });

  final String label;
  final String? hint;
  final int value;
  final int min;
  final int max;
  final int step;
  final String? unit;
  final ValueChanged<int> onChanged;

  static const decreaseKey = Key('stepper-decrease');
  static const increaseKey = Key('stepper-increase');

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final v = value.clamp(min, max);
    return Material(
      color: c.surface,
      child: Padding(
        padding: const EdgeInsets.all(RohabSpace.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: RohabType.rowTitle),
            if (hint != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(hint!, style: RohabType.rowSub),
              ),
            const SizedBox(height: RohabSpace.s8),
            Row(
              children: [
                _StepButton(
                  key: decreaseKey,
                  icon: RohabIconData.remove,
                  label: 'Decrease $label',
                  onTap: v - step >= min ? () => onChanged(v - step) : null,
                ),
                Expanded(
                  child: Semantics(
                    label: '$label, $v${unit == null ? '' : ' $unit'}',
                    excludeSemantics: true,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: RohabSpace.s8,
                      ),
                      padding: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: c.accent,
                            width: RohabShape.strongBorder,
                          ),
                        ),
                      ),
                      child: Text.rich(
                        TextSpan(
                          text: '$v',
                          style: RohabType.metricL,
                          children: [
                            if (unit != null)
                              TextSpan(
                                text: ' $unit',
                                style: RohabType.metricS.copyWith(
                                  color: c.secondary,
                                ),
                              ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                _StepButton(
                  key: increaseKey,
                  icon: RohabIconData.add,
                  label: 'Increase $label',
                  onTap: v + step <= max ? () => onChanged(v + step) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final RohabIconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final off = onTap == null;
    return Semantics(
      button: true,
      enabled: !off,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: RohabSize.stepperButton,
        height: RohabSize.stepperButton,
        child: Material(
          color: off ? c.disabledFill : c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RohabShape.control),
            side: BorderSide(color: c.controlEdge),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(RohabShape.control),
            splashFactory: NoSplash.splashFactory,
            highlightColor: c.accentSoft,
            child: Center(
              child: RohabIcon(icon, color: off ? c.disabledText : c.accent),
            ),
          ),
        ),
      ),
    );
  }
}
