import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Bottom action area with two fixed slots: secondary above, primary below.
/// Both slots keep their height when empty, so the primary button never
/// moves between steps and a repeated tap can't land on another action.
class ActionArea extends StatelessWidget {
  const ActionArea({super.key, this.secondary, this.primary});

  final Widget? secondary;
  final Widget? primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          RohabSpace.s24, RohabSpace.s16, RohabSpace.s24, RohabSpace.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: RohabSize.touchTarget, child: secondary),
          const SizedBox(height: RohabSpace.s8),
          SizedBox(height: RohabSize.primaryButtonHeight, child: primary),
        ],
      ),
    );
  }
}
