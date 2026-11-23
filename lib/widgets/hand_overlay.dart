import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:material_ui/material_ui.dart';

import '../camera/hand_tracker.dart';
import '../theme/app_theme.dart';

/// Draws the tracked hand (21 landmarks) over the camera, so the person
/// can see what Rohab sees. The front-camera preview is a mirror; see
/// [HandFrame.mirrored] for how x is mapped onto it.
class HandOverlay extends StatelessWidget {
  const HandOverlay({super.key, required this.frame});

  final ValueListenable<HandFrame?> frame;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ValueListenableBuilder<HandFrame?>(
      valueListenable: frame,
      builder: (context, f, _) => CustomPaint(
        painter: _HandPainter(f, c.accent, c.surface),
        size: Size.infinite,
      ),
    );
  }
}

const _bones = [
  [0, 1], [1, 2], [2, 3], [3, 4], // thumb
  [0, 5], [5, 6], [6, 7], [7, 8], // index
  [5, 9], [9, 10], [10, 11], [11, 12], // middle
  [9, 13], [13, 14], [14, 15], [15, 16], // ring
  [13, 17], [17, 18], [18, 19], [19, 20], // little
  [0, 17],
];

class _HandPainter extends CustomPainter {
  _HandPainter(this.frame, this.color, this.outline);

  final HandFrame? frame;
  final Color color;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame;
    if (f == null || f.landmarks.length < 21) return;
    // The preview is a mirror. Landmarks from an unmirrored frame need an x
    // flip to sit on it; landmarks from an already mirrored frame do not.
    Offset at(int i) {
      final x = f.landmarks[i].x;
      return Offset(
        (f.mirrored ? x : 1 - x) * size.width,
        f.landmarks[i].y * size.height,
      );
    }

    // A light outline under the line keeps it visible on any background.
    final under = Paint()
      ..color = outline
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final b in _bones) {
      canvas.drawLine(at(b[0]), at(b[1]), under);
    }
    for (final b in _bones) {
      canvas.drawLine(at(b[0]), at(b[1]), line);
    }
    for (var i = 0; i < 21; i++) {
      canvas.drawCircle(at(i), 6, under);
      canvas.drawCircle(
        at(i),
        i % 4 == 0 && i > 0 ? 5 : 3.5,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_HandPainter old) =>
      old.frame != frame || old.color != color;
}
