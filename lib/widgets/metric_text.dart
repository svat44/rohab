import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// A number in Atkinson with tabular figures, and an optional unit in smaller
/// Atkinson beside it. Every numeral in the app goes through this or through a
/// [RohabType] metric style.
class MetricText extends StatelessWidget {
  const MetricText(
    this.value, {
    super.key,
    this.unit,
    this.style = RohabType.metricL,
    this.color,
  });

  final String value;
  final String? unit;
  final TextStyle style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? style.color;
    return Text.rich(
      TextSpan(
        text: value,
        style: style.copyWith(color: c),
        children: [
          if (unit != null)
            TextSpan(
              text: ' $unit',
              style: RohabType.metricS.copyWith(
                color: context.colors.secondary,
              ),
            ),
        ],
      ),
    );
  }
}
