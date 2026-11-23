import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'rohab_icon.dart';

/// Small gray bold label above a group of rows.
class RohabSectionLabel extends StatelessWidget {
  const RohabSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        RohabSpace.gutter,
        RohabSpace.s24,
        RohabSpace.gutter,
        RohabSpace.s8,
      ),
      child: Text(text, style: RohabType.sectionLabel),
    ),
  );
}

/// A full-width white row: bold title, gray one-line description, small
/// value on the right, chevron. At least 64 dp tall; grows with text size, so
/// nothing is clipped. Rows are separated by [RohabGroup]'s hairlines.
class RohabRow extends StatelessWidget {
  const RohabRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.chevron,
    bool locked = false,
    bool enabled = true,
    this.trailing,
    this.titleStyle,
    this.valueKey,
    this.valueStyle,
  }) : locked = locked || !enabled;

  final String title;
  final String? subtitle;

  /// Small value on the right ("Today", "Not connected"). Tabular when it is a
  /// number or date; pass [trailing] for anything else.
  final String? value;
  final VoidCallback? onTap;

  /// Defaults to true when [onTap] is set.
  final bool? chevron;

  /// Dimmed, not tappable, and says so to screen readers.
  final bool locked;
  final Widget? trailing;
  final TextStyle? titleStyle;

  /// Key on the value text, so tests and screen readers can find it.
  final Key? valueKey;

  /// Overrides the small value style (e.g. a bigger number).
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final showChevron = (chevron ?? onTap != null) && !locked;
    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: RohabSize.rowMin),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RohabSpace.gutter,
          vertical: RohabSpace.s8 + 4,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: locked
                        ? RohabType.rowTitle.copyWith(color: c.disabledText)
                        : (titleStyle ?? RohabType.rowTitle),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!, style: RohabType.rowSub),
                    ),
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: RohabSpace.s16),
              ConstrainedBox(
                // Never more than 45% of the row, so the title keeps room.
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                ),
                child: Text(
                  value!,
                  key: valueKey,
                  textAlign: TextAlign.end,
                  style:
                      valueStyle ??
                      RohabType.metricS.copyWith(color: c.secondary),
                ),
              ),
            ],
            ?trailing,
            if (showChevron) ...[
              const SizedBox(width: RohabSpace.s8),
              RohabIcon(RohabIconData.chevron, color: c.secondary),
            ],
          ],
        ),
      ),
    );
    return Semantics(
      button: onTap != null,
      enabled: !locked,
      child: Material(
        color: c.surface,
        child: onTap == null || locked
            ? body
            : InkWell(
                onTap: onTap,
                splashFactory: NoSplash.splashFactory,
                highlightColor: c.accentSoft,
                focusColor: c.focus.withValues(alpha: 0.5),
                child: body,
              ),
      ),
    );
  }
}

/// Rows stacked on white with 1 dp hairlines between them and above and below
/// the group. Radius 0.
class RohabGroup extends StatelessWidget {
  const RohabGroup({
    super.key,
    required this.children,
    this.dividerInset = RohabSpace.gutter,
  });

  final double dividerInset;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final line = ColoredBox(
      color: c.divider,
      child: const SizedBox(height: RohabShape.border, width: double.infinity),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        line,
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1)
            ColoredBox(
              color: c.surface,
              child: Padding(
                padding: EdgeInsets.only(left: dividerInset),
                child: line,
              ),
            ),
        ],
        line,
      ],
    );
  }
}
