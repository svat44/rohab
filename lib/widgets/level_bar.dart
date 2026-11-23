import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// A labeled vertical line on a [LevelBar].
class LevelMarker {
  const LevelMarker(this.position, this.label, {this.above = false});

  /// 0-1 along the bar.
  final double position;
  final String label;

  /// Label above the bar or below it.
  final bool above;
}

/// A flat horizontal level bar: 32 dp track in the divider color, accent
/// fill, optional markers. Only the fill length changes; colors never
/// animate.
///
/// Shared by the EMG effort bar, the camera openness bar and (later) glove
/// exercises.
class LevelBar extends StatelessWidget {
  const LevelBar({
    super.key,
    required this.value,
    required this.semanticsLabel,
    required this.semanticsValue,
    this.markers = const [],
  });

  static const barHeight = 24.0;
  static const markerWidth = 4.0;

  /// Fill, 0-1.
  final double value;
  final List<LevelMarker> markers;
  final String semanticsLabel;
  final String semanticsValue;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = RohabType.rowSub;
    final markerLabel = label.copyWith(color: c.text);
    final hasAbove = markers.any((m) => m.above);
    final hasBelow = markers.any((m) => !m.above);
    const labelBand = 15 * 1.3 + RohabSpace.s8;
    const tick = RohabSpace.s8 / 2;

    double fraction(double v) => v.clamp(0.0, 1.0);

    return Semantics(
      label: semanticsLabel,
      value: semanticsValue,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final top = hasAbove ? labelBand : 0.0;
          final height =
              top + LevelBar.barHeight + (hasBelow ? labelBand : 0.0);

          final children = <Widget>[
            Positioned(
              left: 0,
              right: 0,
              top: top,
              height: LevelBar.barHeight,
              // Square track with a solid accent fill.
              child: ClipRect(
                child: ColoredBox(
                  color: c.divider,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: fraction(value),
                      heightFactor: 1,
                      child: ColoredBox(color: c.accent),
                    ),
                  ),
                ),
              ),
            ),
          ];

          // Marker lines.
          for (final m in markers) {
            final x = fraction(m.position) * width;
            final lineLeft = (x - LevelBar.markerWidth / 2).clamp(
              0.0,
              width - LevelBar.markerWidth,
            );
            children.add(
              Positioned(
                left: lineLeft,
                width: LevelBar.markerWidth,
                top: top - (m.above ? tick : 0),
                height: LevelBar.barHeight + tick,
                child: ColoredBox(color: c.text),
              ),
            );
          }

          // Labels, centered on their line, kept inside the bar and never
          // overlapping another label on the same side.
          final scaler = MediaQuery.textScalerOf(context);
          for (final above in [true, false]) {
            final group = [
              for (final m in markers)
                if (m.above == above) m,
            ]..sort((a, b) => a.position.compareTo(b.position));
            final widths = [
              for (final m in group) _textWidth(m.label, markerLabel, scaler),
            ];
            final lefts = [
              for (var i = 0; i < group.length; i++)
                fraction(group[i].position) * width - widths[i] / 2,
            ];
            const gap = RohabSpace.s8;
            for (var i = 0; i < lefts.length; i++) {
              if (i > 0) {
                final minLeft = lefts[i - 1] + widths[i - 1] + gap;
                if (lefts[i] < minLeft) lefts[i] = minLeft;
              }
              if (lefts[i] < 0) lefts[i] = 0;
            }
            for (var i = lefts.length - 1; i >= 0; i--) {
              final maxLeft = i == lefts.length - 1
                  ? width - widths[i]
                  : lefts[i + 1] - gap - widths[i];
              if (lefts[i] > maxLeft) lefts[i] = maxLeft;
            }
            for (var i = 0; i < group.length; i++) {
              children.add(
                Positioned(
                  left: lefts[i],
                  top: above ? 0 : top + LevelBar.barHeight + tick,
                  child: Text(group[i].label, style: markerLabel),
                ),
              );
            }
          }

          return SizedBox(
            height: height,
            width: width,
            child: Stack(clipBehavior: Clip.none, children: children),
          );
        },
      ),
    );
  }
}

double _textWidth(String text, TextStyle style, TextScaler scaler) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout();
  final w = painter.width;
  painter.dispose();
  return w;
}
