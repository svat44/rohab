import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/tokens.dart';

/// Flat panels and choice boxes. White, 1 dp hairline, radius 0. No shadows.
BoxDecoration panelDecoration(AppColors c, {bool tint = false}) =>
    BoxDecoration(
      color: tint ? c.accentSoft : c.surface,
      border: Border.all(color: c.divider, width: RohabShape.border),
    );

/// One option of a choice row (pain score, text size). Selected = accentTint
/// fill with a 2 dp accent border; otherwise white with a 1 dp border.
/// Radius 0.
class ChoiceBox extends StatelessWidget {
  const ChoiceBox({super.key, required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = AppColors(RohabPalette.light);
    return Material(
      color: selected ? c.accentSoft : c.surface,
      shape: Border.all(
        color: selected ? c.accent : c.controlEdge,
        width: selected ? RohabShape.strongBorder : RohabShape.border,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
