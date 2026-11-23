import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

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

    // Solid bar with a 1 px top border. The current tab is a filled shape
    // with a bold label, so it never depends on colour alone.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: RohabSize.touchTarget),
          child: Center(
            heightFactor: 1,
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
    final fg = selected ? c.onAccent : c.secondary;
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
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: selected ? c.accent : null,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: RohabSize.touchTarget,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(destination.icon, size: RohabSize.icon, color: fg),
                    const SizedBox(height: RohabSpace.s8 / 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        softWrap: false,
                        style: style.copyWith(
                          color: fg,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
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
