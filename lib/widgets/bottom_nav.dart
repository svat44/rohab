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

    // Floating white pill; the active tab is a near-black circle, so it
    // is not told apart by colour alone (it also has a bold label).
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            RohabSpace.s16, RohabSpace.s8, RohabSpace.s16, RohabSpace.s8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                  color: c.shadow, blurRadius: 24, offset: const Offset(0, 6)),
            ],
          ),
          child: SizedBox(
            height: RohabSize.touchTarget + RohabSpace.s16,
            child: Row(
              children: [
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: Semantics(
                      selected: i == selectedIndex,
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(40),
                        onTap: () => onSelected(i),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: RohabMotion.max,
                              width: 44,
                              height: 36,
                              decoration: BoxDecoration(
                                color: i == selectedIndex
                                    ? c.text
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                destinations[i].icon,
                                size: RohabSize.icon,
                                color: i == selectedIndex
                                    ? c.background
                                    : c.secondary,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                destinations[i].label,
                                maxLines: 1,
                                softWrap: false,
                                style: label.copyWith(
                                  color: i == selectedIndex
                                      ? c.text
                                      : c.secondary,
                                  fontWeight: i == selectedIndex
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
