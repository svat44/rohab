import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'rohab_icon.dart';

class NavDestination {
  const NavDestination(this.label, this.icon);
  final String label;
  final RohabIconData icon;
}

/// Four tabs on white with a 1 dp hairline on top. The selected tab has an
/// accent icon, a bold accent label and a 3 dp square accent bar across the
/// top edge of the tab. No pill, no indicator blob, labels always visible.
/// [selectedIndex] may be null when a screen outside the tabs is open.
class RohabNavBar extends StatelessWidget {
  const RohabNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NavDestination> destinations;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  /// Labels stop growing at this scale; below it they follow the user's text
  /// size. Four labels share the width, so past it "Exercises" cannot fit.
  static const maxLabelScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scaler = MediaQuery.textScalerOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: SafeArea(
        top: false,
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: scaler.clamp(maxScaleFactor: maxLabelScale)),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: _NavTab(
                      destination: destinations[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelected(i),
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

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: c.accentSoft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: RohabSize.navHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: RohabShape.navBar,
                child: ColoredBox(
                  color: selected ? c.accent : RohabPalette.clear,
                ),
              ),
              const SizedBox(height: RohabSpace.s8 - 2),
              Center(
                child: RohabIcon(
                  destination.icon,
                  color: selected ? c.accent : c.secondary,
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  destination.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: selected
                      ? RohabType.navLabelSelected
                      : RohabType.navLabel,
                ),
              ),
              const SizedBox(height: RohabSpace.s8 - 2),
            ],
          ),
        ),
      ),
    );
  }
}
