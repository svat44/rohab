import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Bottom action area: optional secondary button above, primary below. The
/// primary button is anchored to the bottom, so it does not move when the
/// secondary button appears or goes.
///
/// A solid white bar with a line along its top: the scrolling content stops
/// at the line, like the action bar of a form. Nothing fades.
class ActionArea extends StatelessWidget {
  const ActionArea({super.key, this.secondary, this.primary});

  final Widget? secondary;
  final Widget? primary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          top: BorderSide(color: c.divider, width: RohabShape.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          RohabSpace.s24,
          RohabSpace.s16,
          RohabSpace.s24,
          RohabSpace.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (secondary != null) ...[
              SizedBox(height: RohabSize.touchTarget, child: secondary),
              const SizedBox(height: RohabSpace.s16),
            ],
            SizedBox(height: RohabSize.primaryButtonHeight, child: primary),
          ],
        ),
      ),
    );
  }
}
