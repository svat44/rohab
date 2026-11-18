import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// A labelled vertical line on the [EffortBar].
class EffortMarker {
  const EffortMarker(this.value, this.label, {this.above = false});

  /// EMG level, 0-1023.
  final num value;
  final String label;

  /// Label above the bar (the trigger) or below it (rest, grip).
  final bool above;
}

/// Live muscle effort: a horizontal bar whose fill length follows the EMG
/// envelope. Only the length changes; the color never animates.
///
/// Smoothing: 150 ms moving average (8 samples at 50 Hz). Redraws at 20 Hz.
class EffortBar extends StatefulWidget {
  const EffortBar({
    super.key,
    required this.samples,
    this.markers = const [],
    this.scaleMax = defaultScaleMax,
  });

  /// Fixed scale chosen so weak grips are still visible (see session notes).
  static const defaultScaleMax = 512;
  static const barHeight = 32.0;
  static const averageWindow = 8; // ~150 ms at 50 Hz
  static const redrawInterval = Duration(milliseconds: 50); // 20 Hz
  static const markerWidth = 2.0;

  final Stream<int> samples;
  final List<EffortMarker> markers;
  final int scaleMax;

  @override
  State<EffortBar> createState() => _EffortBarState();
}

class _EffortBarState extends State<EffortBar> {
  final List<int> _window = [];
  StreamSubscription<int>? _sub;
  Timer? _redraw;
  double _average = 0;
  double _shown = 0;

  @override
  void initState() {
    super.initState();
    _subscribe();
    _redraw = Timer.periodic(EffortBar.redrawInterval, (_) {
      if (_average != _shown && mounted) setState(() => _shown = _average);
    });
  }

  @override
  void didUpdateWidget(EffortBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.samples != widget.samples) {
      _sub?.cancel();
      _subscribe();
    }
  }

  void _subscribe() {
    _sub = widget.samples.listen((v) {
      _window.add(v);
      if (_window.length > EffortBar.averageWindow) _window.removeAt(0);
      _average = _window.reduce((a, b) => a + b) / _window.length;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _redraw?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = Theme.of(context).textTheme.labelMedium!;
    final markerLabel = label.copyWith(color: c.text);
    final hasAbove = widget.markers.any((m) => m.above);
    final hasBelow = widget.markers.any((m) => !m.above);
    const labelBand = RohabType.label * 1.25 + RohabSpace.s8;
    const tick = RohabSpace.s8 / 2;

    double fraction(num v) => (v / widget.scaleMax).clamp(0.0, 1.0).toDouble();

    final trigger = widget.markers.where((m) => m.above).firstOrNull;
    return Semantics(
      label: 'Muscle effort',
      value: '${_shown.round()}'
          '${trigger == null ? '' : ', trigger at ${trigger.value.round()}'}',
      excludeSemantics: true,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final top = hasAbove ? labelBand : 0.0;
        final height =
            top + EffortBar.barHeight + (hasBelow ? labelBand : 0.0);

        final children = <Widget>[
          Positioned(
            left: 0,
            right: 0,
            top: top,
            height: EffortBar.barHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(RohabShape.radius),
              child: ColoredBox(
                color: c.divider,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: fraction(_shown),
                    heightFactor: 1,
                    child: ColoredBox(color: c.accent),
                  ),
                ),
              ),
            ),
          ),
        ];

        // Marker lines.
        for (final m in widget.markers) {
          final x = fraction(m.value) * width;
          final lineLeft = (x - EffortBar.markerWidth / 2)
              .clamp(0.0, width - EffortBar.markerWidth);
          children.add(Positioned(
            left: lineLeft,
            width: EffortBar.markerWidth,
            top: top - (m.above ? tick : 0),
            height: EffortBar.barHeight + tick,
            child: ColoredBox(color: c.text),
          ));
        }

        // Labels, centred on their line, kept inside the bar and never
        // overlapping another label on the same side.
        final scaler = MediaQuery.textScalerOf(context);
        for (final above in [true, false]) {
          final group = [
            for (final m in widget.markers)
              if (m.above == above) m
          ]..sort((a, b) => a.value.compareTo(b.value));
          final widths = [
            for (final m in group) _textWidth(m.label, markerLabel, scaler)
          ];
          final lefts = [
            for (var i = 0; i < group.length; i++)
              fraction(group[i].value) * width - widths[i] / 2
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
            children.add(Positioned(
              left: lefts[i],
              top: above ? 0 : top + EffortBar.barHeight + tick,
              child: Text(group[i].label, style: markerLabel),
            ));
          }
        }

        return SizedBox(
          height: height,
          width: width,
          child: Stack(clipBehavior: Clip.none, children: children),
        );
      }),
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
