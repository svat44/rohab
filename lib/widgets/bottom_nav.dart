import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class NavDestination {
  const NavDestination(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Flat bottom navigation: outline icons, text labels, teal for the active
/// tab. [selectedIndex] may be null when a screen outside the tabs is open.
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

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: RohabSize.touchTarget + RohabSpace.s16 + 4,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == selectedIndex,
                    button: true,
                    child: InkWell(
                      onTap: () => onSelected(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Active tab sits in a soft pill, so it is not
                          // told apart by color alone.
                          AnimatedContainer(
                            duration: RohabMotion.max,
                            width: 64,
                            height: 32,
                            decoration: BoxDecoration(
                              color: i == selectedIndex
                                  ? c.accentSoft
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              destinations[i].icon,
                              size: RohabSize.icon,
                              color:
                                  i == selectedIndex ? c.accent : c.secondary,
                            ),
                          ),
                          const SizedBox(height: RohabSpace.s8 / 2),
                          // Shrinks (never below 16sp at the default size)
                          // rather than running into the next label.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              destinations[i].label,
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              softWrap: false,
                              style: label.copyWith(
                                color: i == selectedIndex
                                    ? c.accent
                                    : c.secondary,
                                fontWeight: i == selectedIndex
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
