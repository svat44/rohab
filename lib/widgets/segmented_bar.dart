import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// A progress bar of [total] square segments: done = accent, the rest =
/// hairline. Reads "x of y" to screen readers.
class SegmentedBar extends StatelessWidget {
  const SegmentedBar({
    super.key,
    required this.done,
    required this.total,
    this.height = 12,
  });

  final int done;
  final int total;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: '$done of $total done',
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                child: ColoredBox(
                  color: i < done ? c.accent : c.divider,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
