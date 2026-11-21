import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../data/database.dart';
import '../../theme/app_theme.dart';
import 'progress_data.dart';

/// Reps in each of the last sessions, oldest to newest: plain bars in one
/// color, a hairline at the target, dates under some of the bars.
class RepsChart extends StatelessWidget {
  const RepsChart({super.key, required this.sessions, required this.unit});

  /// Oldest first.
  final List<ExerciseSessionRow> sessions;

  /// "reps", "rounds" or "holds".
  final String unit;

  static const barAreaHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = Theme.of(context).textTheme.labelMedium!;
    final scaler = MediaQuery.textScalerOf(context);
    final labelHeight = scaler.scale(style.fontSize! * 1.3) + RohabSpace.s8;
    return Semantics(
      label: 'Reps per session, oldest to newest. '
          '${[for (final r in sessions) '${shortDate(r.startedAt)}: ${repsText(r, unit)}'].join('. ')}.',
      excludeSemantics: true,
      child: SizedBox(
        height: barAreaHeight + labelHeight,
        width: double.infinity,
        child: CustomPaint(
          painter: _RepsPainter(
            sessions: sessions,
            bar: c.accent,
            track: c.divider,
            hairline: c.secondary,
            labelStyle: style.copyWith(color: c.text),
            scaler: scaler,
            labelHeight: labelHeight,
          ),
        ),
      ),
    );
  }
}

class _RepsPainter extends CustomPainter {
  _RepsPainter({
    required this.sessions,
    required this.bar,
    required this.track,
    required this.hairline,
    required this.labelStyle,
    required this.scaler,
    required this.labelHeight,
  });

  final List<ExerciseSessionRow> sessions;
  final Color bar;
  final Color track;
  final Color hairline;
  final TextStyle labelStyle;
  final TextScaler scaler;
  final double labelHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (sessions.isEmpty) return;
    final h = size.height - labelHeight;
    final n = sessions.length;
    final slot = size.width / n;
    final barW = math.min(slot * 0.6, 28.0);

    // The newest session's target is the reference line.
    final target = sessions.last.targetReps.toDouble();
    final top = math.max(
        target, sessions.map((r) => r.reps).reduce(math.max).toDouble());
    double y(double v) => h - (v / top) * h;
    double cx(int i) => slot * i + slot / 2;

    // Baseline.
    canvas.drawLine(Offset(0, h), Offset(size.width, h),
        Paint()..color = track..strokeWidth = 1);

    for (var i = 0; i < n; i++) {
      final v = sessions[i].reps.toDouble();
      final r = RRect.fromRectAndCorners(
        Rect.fromLTRB(cx(i) - barW / 2, y(v), cx(i) + barW / 2, h),
        topLeft: const Radius.circular(RohabShape.radius / 3),
        topRight: const Radius.circular(RohabShape.radius / 3),
      );
      canvas.drawRRect(r, Paint()..color = bar);
    }

    // Target: a 1 dp hairline across the chart.
    canvas.drawLine(Offset(0, y(target)), Offset(size.width, y(target)),
        Paint()..color = hairline..strokeWidth = 1);

    // Dates under as many bars as fit, first and last always.
    final labels = [
      for (final r in sessions)
        TextPainter(
          text: TextSpan(text: shortDate(r.startedAt), style: labelStyle),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout()
    ];
    final widest = labels.map((l) => l.width).reduce(math.max);
    final fit = math.max(1, (size.width / (widest + RohabSpace.s8)).floor());
    final shown = <int>{};
    if (n <= fit) {
      shown.addAll(List.generate(n, (i) => i));
    } else if (fit == 1) {
      shown.add(n - 1);
    } else {
      for (var k = 0; k < fit; k++) {
        shown.add((k * (n - 1) / (fit - 1)).round());
      }
    }
    for (final i in shown) {
      final l = labels[i];
      final x = (cx(i) - l.width / 2).clamp(0.0, size.width - l.width);
      l.paint(canvas, Offset(x, h + RohabSpace.s8 / 2 + 2));
    }
    for (final l in labels) {
      l.dispose();
    }
  }

  @override
  bool shouldRepaint(_RepsPainter old) =>
      old.sessions != sessions || old.bar != bar || old.scaler != scaler;
}
