import 'package:material_ui/material_ui.dart';

import '../exercises/exercise_catalog.dart';
import '../theme/app_theme.dart';

/// White rounded panel with a soft shadow. The basic building block of the
/// redesigned screens. [onTap] makes the whole card one large target.
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

  /// Soft accent background, for the one most important panel on a screen.
  final bool tint;
  final EdgeInsets padding;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(RohabShape.card);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(color: c.shadow, blurRadius: 24, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: tint ? c.accentSoft : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// A rounded square with an icon in it, tinted with the accent.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.size = 56, this.solid = false});

  final IconData icon;
  final double size;

  /// Near-black circle with a light icon, instead of the quiet gray one.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: solid ? c.text : c.background,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: size * 0.48, color: solid ? c.background : c.text),
      ),
    );
  }
}

/// Small rounded label: "10 times", "Level 2", "Done".
class InfoChip extends StatelessWidget {
  const InfoChip(this.label, {super.key, this.icon, this.filled = false});

  final String label;
  final IconData? icon;

  /// Accent background instead of the soft tint.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme.labelMedium!;
    final fg = filled ? c.background : c.secondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? c.text : c.background,
        borderRadius: BorderRadius.circular(RohabShape.card),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: RohabSpace.s8 + 4, vertical: RohabSpace.s8 / 2 + 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: RohabType.label, color: fg),
              const SizedBox(width: RohabSpace.s8 / 2),
            ],
            Flexible(
              child: Text(label,
                  style: t.copyWith(color: fg, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
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
            top: RohabSpace.s16, bottom: RohabSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.labelLarge),
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
      ExerciseKind.openClose =>
        Icons.back_hand_outlined,
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
      ExerciseKind.fingerWalking => Icons.directions_walk,
    };
