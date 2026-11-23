import 'package:material_ui/material_ui.dart';

import '../exercises/exercise_catalog.dart';
import '../theme/app_theme.dart';
import 'surfaces.dart';

/// A flat white panel with a visible edge, the basic building block of the
/// screens. [onTap] makes the whole panel one large target; it shows a chevron
/// so it reads as a link, and darkens while pressed.
class RohabCard extends StatelessWidget {
  const RohabCard({
    super.key,
    required this.child,
    this.onTap,
    this.tint = false,
    this.padding = const EdgeInsets.all(RohabSpace.s16),
    this.minHeight = 0,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Light blue panel, for the one most important panel on a screen.
  final bool tint;
  final EdgeInsets padding;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(RohabShape.card);
    final body = Padding(padding: padding, child: child);
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: panelDecoration(c, tint: tint),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashFactory: NoSplash.splashFactory,
          highlightColor: c.accent.withValues(alpha: 0.16),
          focusColor: c.focus.withValues(alpha: 0.5),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: onTap == null
                ? body
                : Row(
                    children: [
                      Expanded(child: body),
                      Padding(
                        padding: const EdgeInsets.only(right: RohabSpace.s16),
                        child: Icon(
                          Icons.chevron_right,
                          size: RohabSize.icon,
                          color: c.secondary,
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

/// A flat rounded-square icon tile, MIUI style: a solid fill with a white
/// glyph. [solid] is the blue one (done, or next); otherwise light blue with
/// a blue glyph. No outline.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.size = 48, this.solid = true});

  final IconData icon;
  final double size;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: IconTile(
        size: size,
        color: solid ? c.accent : c.accentSoft,
        child: Icon(
          icon,
          size: size * 0.55,
          color: solid ? c.onAccent : c.accent,
        ),
      ),
    );
  }
}

/// Small label: "10 times", "Level 2", "Done".
class InfoChip extends StatelessWidget {
  const InfoChip(this.label, {super.key, this.icon, this.filled = false});

  final String label;
  final IconData? icon;

  /// Bold, in the main text colour, for the one label that matters most.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme.labelMedium!;
    final fg = filled ? c.text : c.secondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: RohabType.label + 2, color: fg),
          const SizedBox(width: RohabSpace.s8 / 2 + 2),
        ],
        Flexible(
          child: Text(
            label,
            style: t.copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Label above a group of rows, MIUI style: small, gray, set in from the
/// group edge. More space above than below, so it belongs to the group under
/// it.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          RohabSpace.s8,
          RohabSpace.s24,
          RohabSpace.s8,
          RohabSpace.s8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: t.labelMedium?.copyWith(
                color: c.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: RohabSpace.s8 / 2),
              Text(subtitle!, style: t.labelMedium),
            ],
          ],
        ),
      ),
    );
  }
}

/// One white block holding several rows, split by hairlines, like a MIUI
/// settings group. Replaces one card per row. Hairlines start after the
/// leading tile so the text edge lines up.
class RohabGroup extends StatelessWidget {
  const RohabGroup({super.key, required this.children, this.dividerInset = 0});

  final List<Widget> children;

  /// Left inset of the hairlines, so they start at the text, not the tile.
  final double dividerInset;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: panelDecoration(c),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RohabShape.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: EdgeInsets.only(left: dividerInset),
                  child: Divider(color: c.divider),
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// A row of a [RohabGroup]: optional tile, a title, an optional gray line
/// under it, an optional gray value, and a small gray chevron when it opens
/// something. At least 64 dp tall; the whole row is the touch target.
class RohabRow extends StatelessWidget {
  const RohabRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.icon,
    this.onTap,
    this.enabled = true,
    this.titleColor,
  });

  final String title;
  final String? subtitle;

  /// Gray text before the chevron ("On", "Level 2").
  final String? value;
  final IconData? icon;

  /// Null makes it a plain, non-tappable row (no chevron).
  final VoidCallback? onTap;
  final bool enabled;
  final Color? titleColor;

  /// Left edge of the text when there is a tile: 16 + 48 + 16.
  static const textInset = 80.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final dim = !enabled;
    return Semantics(
      button: onTap != null,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        splashFactory: NoSplash.splashFactory,
        highlightColor: c.accent.withValues(alpha: 0.12),
        focusColor: c.focus.withValues(alpha: 0.5),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: RohabSize.touchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: RohabSpace.s16,
              vertical: RohabSpace.s8 + 4,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Opacity(
                    opacity: dim ? 0.4 : 1,
                    child: IconBadge(icon!, size: 48),
                  ),
                  const SizedBox(width: RohabSpace.s16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: t.bodyLarge?.copyWith(
                          color: dim ? c.secondary : titleColor ?? c.text,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: RohabSpace.s8 / 2),
                        Text(subtitle!, style: t.labelMedium),
                      ],
                    ],
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: RohabSpace.s8),
                  Flexible(
                    child: Text(
                      value!,
                      textAlign: TextAlign.end,
                      style: t.labelMedium,
                    ),
                  ),
                ],
                if (onTap != null && enabled) ...[
                  const SizedBox(width: RohabSpace.s8),
                  Icon(
                    Icons.chevron_right,
                    size: RohabSize.icon,
                    color: c.secondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A picture for each kind of exercise, so the list can be scanned by
/// icon as well as by title.
IconData exerciseIcon(ExerciseKind kind) => switch (kind) {
  ExerciseKind.openCloseGentle ||
  ExerciseKind.openClose => Icons.back_hand_outlined,
  ExerciseKind.holdOpen => Icons.timer_outlined,
  ExerciseKind.squeeze => Icons.sports_mma_outlined,
  ExerciseKind.thumbExtension => Icons.thumb_up_alt_outlined,
  ExerciseKind.wristStretch => Icons.swap_vert,
  ExerciseKind.assistedExtension => Icons.front_hand_outlined,
  ExerciseKind.cylinder => Icons.local_cafe_outlined,
  ExerciseKind.hook => Icons.shopping_bag_outlined,
  ExerciseKind.pinch => Icons.pinch_outlined,
  ExerciseKind.wristRotation => Icons.autorenew,
  ExerciseKind.handSlide => Icons.swap_horiz,
  ExerciseKind.fingerTouches => Icons.touch_app_outlined,
  ExerciseKind.fingerLifts => Icons.looks_one_outlined,
  ExerciseKind.spread => Icons.open_in_full,
  ExerciseKind.flatFingerLifts => Icons.keyboard_double_arrow_up,
  ExerciseKind.fingerWalking => Icons.arrow_forward,
};
