import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'rohab_icon.dart';

/// Top bar: white, title on the left, a 48 dp outlined gear on the
/// right. Sub-screens pass [onBack] and get a back arrow instead of the gear.
/// Grows with the text size; the title wraps instead of clipping.
class RohabAppBar extends StatelessWidget {
  const RohabAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.onSettings,
    this.eyebrow,
    this.titleKey,
    this.settingsKey,
    this.backButtonKey,
  });

  final String title;

  /// Small line above the title ("Rohab" on Today).
  final String? eyebrow;
  final VoidCallback? onBack;
  final VoidCallback? onSettings;
  final Key? titleKey;

  /// Keys for the gear and the back arrow (tests, automation).
  final Key? settingsKey;
  final Key? backButtonKey;

  static const backKey = Key('app-bar-back');

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final back = onBack != null;
    final action = back ? onBack : onSettings;
    // The title is already 28sp; past 1.5x it stops growing so the bar
    // cannot eat the screen at 200% text.
    final capped = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: capped),
      child: ColoredBox(
        color: c.surface,
        child: SafeArea(
          bottom: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: RohabSize.appBarHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: RohabSpace.gutter,
                top: 4,
                bottom: 4,
              ),
              child: Row(
                children: [
                  if (back)
                    _BarButton(
                      key: backButtonKey ?? backKey,
                      icon: RohabIconData.back,
                      label: 'Back',
                      onTap: action!,
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: back ? RohabSpace.s8 : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (eyebrow != null)
                            Text(
                              eyebrow!,
                              style: RohabType.wordmark.copyWith(
                                color: c.accent,
                              ),
                            ),
                          Semantics(
                            header: true,
                            child: Text(
                              title,
                              key: titleKey,
                              style: RohabType.title,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!back && action != null)
                    _BarButton(
                      key: settingsKey,
                      icon: RohabIconData.gear,
                      label: 'Open settings',
                      onTap: action,
                    ),
                  if (back || action == null)
                    const SizedBox(width: RohabSpace.s8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final RohabIconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: InkResponse(
      onTap: onTap,
      radius: 28,
      child: SizedBox(
        width: RohabSize.touchTarget + 8,
        height: RohabSize.touchTarget,
        child: Center(child: RohabIcon(icon)),
      ),
    ),
  );
}
