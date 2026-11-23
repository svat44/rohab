import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Bottom action area: optional secondary button above, primary below. The
/// primary button is anchored to the bottom, so it does not move when the
/// secondary button appears or goes.
///
/// There is no box around the buttons. The scrolling content above slowly
/// fades into the page colour just before the buttons, so it looks like it
/// runs on underneath them and can be scrolled up as needed.
class ActionArea extends StatelessWidget {
  const ActionArea({super.key, this.secondary, this.primary});

  /// Height of the fade over the content above.
  static const fadeHeight = 64.0;

  final Widget? secondary;
  final Widget? primary;

  @override
  Widget build(BuildContext context) {
    final bg = context.colors.background;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The fade paints over the bottom of the content above it and lets
        // touches through to it. Eased stops make the fade gradual.
        Positioned(
          left: 0,
          right: 0,
          top: -fadeHeight,
          height: fadeHeight,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bg.withValues(alpha: 0),
                    bg.withValues(alpha: 0.10),
                    bg.withValues(alpha: 0.35),
                    bg.withValues(alpha: 0.70),
                    bg.withValues(alpha: 0.92),
                    bg,
                  ],
                  stops: const [0, 0.2, 0.4, 0.6, 0.8, 1],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            RohabSpace.s24,
            0,
            RohabSpace.s24,
            RohabSpace.s16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // No empty slot: with nothing to show, the fade meets the
              // primary button directly, so there is no gap or box.
              if (secondary != null) ...[
                SizedBox(height: RohabSize.touchTarget, child: secondary),
                const SizedBox(height: RohabSpace.s8),
              ],
              SizedBox(height: RohabSize.primaryButtonHeight, child: primary),
            ],
          ),
        ),
      ],
    );
  }
}
