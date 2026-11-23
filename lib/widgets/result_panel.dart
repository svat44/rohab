import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'rohab_button.dart';

/// The pinned solid accent panel at the bottom of a setup screen (MDCalc's
/// result bar). Radius 0, 1 dp top border, white text, a white-filled Start
/// button with accent text. Put it OUTSIDE the scroll view, and give the
/// scroll view [ResultPanel.reserve] bottom padding so the last row is never
/// covered.
class ResultPanel extends StatelessWidget {
  const ResultPanel({
    super.key,
    required this.title,
    required this.lines,
    required this.actionLabel,
    required this.onAction,
    this.disabledReason,
    this.actionKey,
  });

  final String title;
  final List<String> lines;
  final String actionLabel;
  final VoidCallback? onAction;
  final String? disabledReason;
  final Key? actionKey;

  /// Rough extra space a scroll view should keep free under its content.
  static const double reserve = 24;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final white = RohabType.body.copyWith(color: c.onAccent);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.accent,
        border: Border(top: BorderSide(color: c.accentPressed)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(RohabSpace.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: RohabType.sectionLabel.copyWith(color: c.onAccent),
              ),
              const SizedBox(height: 4),
              for (var i = 0; i < lines.length; i++)
                Text(
                  lines[i],
                  style: i == 0
                      ? RohabType.metricL.copyWith(
                          color: c.onAccent,
                          fontSize: 24,
                        )
                      : white,
                ),
              const SizedBox(height: RohabSpace.s16),
              RohabButton(
                key: actionKey,
                label: actionLabel,
                onPressed: onAction,
                onAccent: true,
                disabledReason: disabledReason,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
