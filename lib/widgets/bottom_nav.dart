import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'skeuo.dart';

class NavDestination {
  const NavDestination(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Tab bar on brushed steel: icon and text label on every tab, the current
/// tab pressed in and lit. [selectedIndex] may be null when a screen
/// outside the tabs is open.
class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NavDestination> destinations;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = Theme.of(context).textTheme.labelMedium!;

    // Brushed steel bar. The selected tab is pressed in and lit.
    return DecoratedBox(
      decoration: steelDecoration(c).copyWith(
        border: const Border(
          top: BorderSide(color: Color(0x66FFFFFF), width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: RohabSize.touchTarget + RohabSpace.s16,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.all(RohabSpace.s8 / 2),
                child: Row(
                  children: [
                    for (var i = 0; i < destinations.length; i++)
                      Expanded(
                        child: _Tab(
                          destination: destinations[i],
                          selected: i == selectedIndex,
                          style: label,
                          onTap: () => onSelected(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.destination,
    required this.selected,
    required this.style,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const lit = Color(0xFF7FD3FA);
    final fg = selected ? lit : c.onSteel;
    const radius = BorderRadius.all(Radius.circular(RohabShape.radius));
    return Semantics(
      selected: selected,
      button: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashColor: const Color(0x33FFFFFF),
            highlightColor: const Color(0x22FFFFFF),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                // Pressed-in slot for the current tab.
                color: selected ? const Color(0x59000000) : null,
                border: selected
                    ? Border.all(color: const Color(0x66000000), width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    destination.icon,
                    size: RohabSize.icon,
                    color: fg,
                    shadows: const [
                      Shadow(color: Color(0x99000000), offset: Offset(0, -1)),
                    ],
                  ),
                  const SizedBox(height: RohabSpace.s8 / 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      softWrap: false,
                      style: style.copyWith(
                        color: selected ? Colors.white : fg,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        shadows: const [
                          Shadow(
                            color: Color(0x99000000),
                            offset: Offset(0, -1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
