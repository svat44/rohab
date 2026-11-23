import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'level_bar.dart';

/// A labeled vertical line on the [EffortBar].
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
  static const barHeight = LevelBar.barHeight;
  static const averageWindow = 8; // ~150 ms at 50 Hz
  static const redrawInterval = Duration(milliseconds: 50); // 20 Hz

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
    final trigger = widget.markers.where((m) => m.above).firstOrNull;
    return LevelBar(
      value: _shown / widget.scaleMax,
      semanticsLabel: 'Muscle effort',
      semanticsValue:
          '${_shown.round()}'
          '${trigger == null ? '' : ', trigger at ${trigger.value.round()}'}',
      markers: [
        for (final m in widget.markers)
          LevelMarker(m.value / widget.scaleMax, m.label, above: m.above),
      ],
    );
  }
}
