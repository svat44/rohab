import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class NavDestination {
  const NavDestination(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Tab bar at the bottom of a phone: an icon and a word on every tab, the
/// current tab filled solid blue with a bold label, so it never depends on
/// colour alone. [selectedIndex] may be null when a screen outside the tabs
/// is open.
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(RohabSpace.s8 / 2),
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: NavTab(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tabs down the left side, for windows wider than a phone. Same tabs, same
/// order, same filled-when-current rule as [BottomNav].
class SideNav extends StatelessWidget {
  const SideNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const width = 128.0;

  final List<NavDestination> destinations;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(right: BorderSide(color: c.divider)),
      ),
      child: SizedBox(
        width: width,
        child: SafeArea(
          top: false,
          right: false,
          child: ListView(
            padding: const EdgeInsets.all(RohabSpace.s8),
            children: [
              for (var i = 0; i < destinations.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: RohabSpace.s8),
                  child: NavTab(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                    minHeight: 88,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavTab extends StatelessWidget {
  const NavTab({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
    this.minHeight = RohabSize.touchTarget,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = Theme.of(context).textTheme.labelMedium!;
    final fg = selected ? c.accent : c.secondary;
    final radius = BorderRadius.circular(RohabShape.card);
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashFactory: NoSplash.splashFactory,
            highlightColor: c.accent.withValues(alpha: 0.2),
            focusColor: c.focus.withValues(alpha: 0.6),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: selected ? c.accentSoft : null,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
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
                          fontWeight: FontWeight.w700,
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
