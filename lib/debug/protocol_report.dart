/// Results of the three-pose tracking test, and how they are judged and
/// printed. Pure Dart. Numbers only.
library;

class PoseSpec {
  const PoseSpec(this.id, this.title, this.instruction);

  final String id;
  final String title;
  final String instruction;

  static const all = [
    PoseSpec(
      'full',
      'A. Full open and close',
      'Open your hand fully, then make a fist. Repeat slowly for the whole '
          'run.',
    ),
    PoseSpec(
      'limited',
      'B. Limited range',
      'Move your fingers only through the middle half of your normal range: '
          'never fully open, never a fist. When asked to open wide or make a '
          'fist, go only as far as this pose allows.',
    ),
    PoseSpec(
      'claw',
      'C. Curled (claw) hand',
      'Keep your fingers partly bent, thumb tucked into your palm. Open a '
          'little and close a little. When asked to open wide or make a '
          'fist, go only as far as this pose allows.',
    ),
  ];
}

class PoseResult {
  const PoseResult({
    required this.pose,
    required this.seconds,
    required this.avgFps,
    required this.detectionPercent,
    required this.dropouts,
    required this.reps,
    this.note,
  });

  final PoseSpec pose;

  /// Length of the counting run.
  final double seconds;
  final double avgFps;
  final double detectionPercent;

  /// Gaps longer than 0.5 s with no confident frame.
  final int dropouts;
  final int reps;

  /// Why the run did not happen (camera error, calibration failed).
  final String? note;

  /// Reps per 60 s at this pace. A real figure when the run lasted 60 s or
  /// more, otherwise a projection.
  double get repsPer60 => seconds > 0 ? reps * 60 / seconds : 0;

  bool get projected => seconds < 60;

  bool get tenRepsIn60 => repsPer60 >= 10;

  /// Reliable only if all four hold; the limits are printed with the table.
  bool get reliable =>
      note == null &&
      avgFps >= ProtocolLimits.minFps &&
      detectionPercent >= ProtocolLimits.minDetectionPercent &&
      dropouts <= ProtocolLimits.maxDropouts &&
      tenRepsIn60;
}

/// Judging limits. These are this project's choices, not clinical values.
class ProtocolLimits {
  ProtocolLimits._();
  static const minFps = 15.0;
  static const minDetectionPercent = 90.0;
  static const maxDropouts = 2;
}

/// A fixed-width table for the console and for pasting into a report.
String formatProtocolTable(List<PoseResult> results) {
  String pad(String s, int w) => s.length >= w ? s : s + ' ' * (w - s.length);
  final rows = <List<String>>[
    [
      'Pose',
      'Avg FPS',
      'Detect %',
      'Dropouts >0.5 s',
      'Reps',
      '10 reps/60 s',
      'Verdict',
    ],
    for (final r in results)
      [
        r.pose.title,
        r.note != null ? '-' : r.avgFps.toStringAsFixed(1),
        r.note != null ? '-' : r.detectionPercent.toStringAsFixed(0),
        r.note != null ? '-' : '${r.dropouts}',
        r.note != null ? '-' : '${r.reps} in ${r.seconds.round()} s',
        r.note != null
            ? '-'
            : '${r.tenRepsIn60 ? 'yes' : 'no'}${r.projected ? ' (projected)' : ''}',
        r.note != null
            ? 'NOT RUN: ${r.note}'
            : (r.reliable ? 'OK' : 'UNRELIABLE'),
      ],
  ];
  final widths = [
    for (var c = 0; c < rows.first.length; c++)
      rows.map((r) => r[c].length).reduce((a, b) => a > b ? a : b),
  ];
  final lines = [
    for (final r in rows)
      [for (var c = 0; c < r.length; c++) pad(r[c], widths[c])]
          .join(' | ')
          .trimRight(),
  ];
  lines.insert(1, [for (final w in widths) '-' * w].join('-|-'));
  return '${lines.join('\n')}\n'
      'OK needs: FPS >= ${ProtocolLimits.minFps.round()}, detection >= '
      '${ProtocolLimits.minDetectionPercent.round()} %, dropouts <= '
      '${ProtocolLimits.maxDropouts}, and 10 reps within 60 s.';
}
