import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../data/database.dart';
import '../../theme/app_theme.dart';
import 'progress_data.dart';

/// For each session, a vertical bar from the smallest to the largest value
/// reached, on a track showing the whole scale (0-100 %, or 0-270 degrees
/// of finger bend).
class RangeChart extends StatelessWidget {
  const RangeChart({super.key, required this.sessions, required this.unit});

  /// Oldest first. All must share the same metric unit.
  final List<ExerciseSessionRow> sessions;

  /// "deg" or "%".
  final String unit;

  static const height = 120.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label:
          'Range per session, oldest to newest. '
          '${[for (final r in sessions) '${shortDate(r.startedAt)}: ${rangeText(r)?.replaceFirst('Range ', '') ?? 'not measured'}'].join('. ')}.',
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _RangePainter(
            sessions: sessions,
            axisMax: rangeAxisMax(unit),
            bar: c.accent,
            track: c.divider,
          ),
        ),
      ),
    );
  }
}

class _RangePainter extends CustomPainter {
  _RangePainter({
    required this.sessions,
    required this.axisMax,
    required this.bar,
    required this.track,
  });

  final List<ExerciseSessionRow> sessions;
  final double axisMax;
  final Color bar;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    if (sessions.isEmpty) return;
    final n = sessions.length;
    final slot = size.width / n;
    final barW = math.min(slot * 0.6, 28.0);
    double y(double v) =>
        size.height - (v.clamp(0, axisMax) / axisMax) * size.height;
    const radius = Radius.circular(RohabShape.radius / 3);
    for (var i = 0; i < n; i++) {
      final cx = slot * i + slot / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(cx - barW / 2, 0, cx + barW / 2, size.height),
          radius,
        ),
        Paint()..color = track,
      );
      final lo = sessions[i].rangeMin, hi = sessions[i].rangeMax;
      if (lo == null || hi == null) continue;
      final top = y(math.max(lo, hi)), bottom = y(math.min(lo, hi));
      // At least 2 dp tall so a very small range is still visible.
      final rect = Rect.fromLTRB(
        cx - barW / 2,
        top,
        cx + barW / 2,
        math.max(bottom, top + 2),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()..color = bar,
      );
    }
  }

  @override
  bool shouldRepaint(_RangePainter old) =>
      old.sessions != sessions || old.axisMax != axisMax || old.bar != bar;
}
