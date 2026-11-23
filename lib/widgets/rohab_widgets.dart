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
                          size: RohabSize.icon + 8,
                          color: c.accent,
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

/// A flat square icon tile. [solid] is the blue one (done, or next);
/// otherwise light blue with a blue edge.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.size = 56, this.solid = false});

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
        edge: solid ? null : c.accent,
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

/// Section title above a group of cards.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(
          top: RohabSpace.s16,
          bottom: RohabSpace.s8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.headlineSmall),
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
