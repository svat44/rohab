import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// MDCalc-style tabs: a label with a 3 dp accent underline when selected, a
/// hairline under the whole strip. Labels wrap instead of clipping. With
/// [scrollable] the strip scrolls sideways (Progress exercise tabs); otherwise
/// the tabs share the width equally.
class UnderlineTabs extends StatelessWidget {
  const UnderlineTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.scrollable = false,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget tab(int i) {
      final on = i == selected;
      return Semantics(
        button: true,
        selected: on,
        label: labels[i],
        excludeSemantics: true,
        child: InkWell(
          onTap: () => onChanged(i),
          splashFactory: NoSplash.splashFactory,
          highlightColor: c.accentSoft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: RohabSize.touchTarget,
              maxWidth: scrollable ? 168 : double.infinity,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RohabSpace.s16,
                    vertical: RohabSpace.s8 + 4,
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: RohabType.button.copyWith(
                      color: on ? c.accent : c.secondary,
                    ),
                  ),
                ),
                SizedBox(
                  height: RohabShape.tabUnderline,
                  child: ColoredBox(color: on ? c.accent : RohabPalette.clear),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final tabs = [for (var i = 0; i < labels.length; i++) tab(i)];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      child: scrollable
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: RohabSpace.s8),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: tabs,
                ),
              ),
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (final t in tabs) Expanded(child: t)],
              ),
            ),
    );
  }
}

/// A row of equal square buttons (Right | Left, 7 | 30 | 90 days). Selected =
/// 2 dp accent border, bold accent label, accentTint fill. Unselected = white
/// with a 1 dp border. Never pills; radius 0.
class SquareSegmented<T> extends StatelessWidget {
  const SquareSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.keyFor,
  });

  /// Optional key for each option's button (tests, automation).
  final Key? Function(T value)? keyFor;

  /// Value and its label, in order.
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : RohabSpace.s8),
                child: _Segment(
                  key: keyFor?.call(options[i].$1),
                  label: options[i].$2,
                  on: options[i].$1 == selected,
                  onTap: () => onChanged(options[i].$1),
                  c: c,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
    required this.c,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: on,
    label: label,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      child: Ink(
        decoration: BoxDecoration(
          color: on ? c.accentSoft : c.surface,
          border: Border.all(
            color: on ? c.accent : c.controlEdge,
            width: on ? RohabShape.strongBorder : RohabShape.border,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RohabSpace.s8,
                vertical: RohabSpace.s8,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: RohabType.button.copyWith(
                  color: on ? c.accent : c.text,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w400,
                  fontVariations: [FontVariation('wght', on ? 700 : 400)],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
