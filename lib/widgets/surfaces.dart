import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/tokens.dart';

/// The plain surfaces of a clinic form: a flat white panel with a visible
/// edge, and solid buttons with a darker bottom edge that sinks when pressed.
/// No shadows, no textures: every edge is a line a person with low vision can
/// still see.

/// A flat panel: white, with a 1.5 px edge.
BoxDecoration panelDecoration(
  AppColors c, {
  bool tint = false,
  double radius = RohabShape.card,
}) => BoxDecoration(
  color: tint ? c.accentSoft : c.surface,
  borderRadius: BorderRadius.circular(radius),
  // MIUI cards have no edge: white on the grey page.
);

/// A flat tile: the base for icon badges and other small non-button
/// controls.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.color,
    required this.child,
    this.size,
    this.radius = 14,
    this.edge,
  });

  final Color color;
  final Widget child;
  final double? size;
  final double radius;
  final Color? edge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: edge == null ? null : Border.all(color: edge!, width: 1.5),
      ),
      child: Center(child: child),
    );
  }
}

/// Look shared by the filled, outlined and text buttons: a solid face, a
/// 2 px edge, and a darker 4 px bottom edge that sinks when pressed. A press
/// also darkens the face, and a focused button gets a yellow 4 px ring.
/// Disabled: flat, no bottom edge. The colours come from the button's own
/// style.
ButtonStyle solidButton(ButtonStyle base, {required Color edge}) {
  return base.copyWith(
    elevation: const WidgetStatePropertyAll(0),
    shadowColor: const WidgetStatePropertyAll(Color(0x00000000)),
    surfaceTintColor: const WidgetStatePropertyAll(Color(0x00000000)),
    splashFactory: NoSplash.splashFactory,
    overlayColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.pressed)
          ? const Color(0x2E000000)
          : const Color(0x00000000),
    ),
    side: WidgetStateProperty.resolveWith((s) {
      if (s.contains(WidgetState.focused)) {
        return const BorderSide(
          color: Color(0xFFFFD21F),
          width: RohabShape.focusRing,
        );
      }
      return BorderSide.none;
    }),
  );
}

/// One option of a choice row (text size, exercise, pain score). The chosen
/// option is filled solid blue; the others are white with a dark edge. A
/// check mark joins the chosen label in the screens that use it, so it never
/// relies on colour alone. Put an [InkWell] inside as the [child].
class ChoiceBox extends StatelessWidget {
  const ChoiceBox({super.key, required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const radius = BorderRadius.all(Radius.circular(16));
    return Material(
      color: selected ? c.accent : c.controlFill,
      shape: const RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
