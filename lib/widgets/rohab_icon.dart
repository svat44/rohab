import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// The one icon family: outlined, 2 dp stroke, round caps, drawn on a 24 dp
/// grid. No filled or two-tone glyphs, no other icon set.
enum RohabIconData {
  gear,
  back,
  chevron,
  close,
  today,
  glove,
  hand,
  chart,
  check,
  add,
  remove,
}

class RohabIcon extends StatelessWidget {
  const RohabIcon(
    this.icon, {
    super.key,
    this.color,
    this.size = RohabSize.icon,
  });

  final RohabIconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.text;
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _IconPainter(icon, c)),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.icon, this.color);

  final RohabIconData icon;
  final Color color;

  static Path _gear() {
    final p = Path();
    const teeth = 8;
    const rIn = 7.2, rOut = 9.6;
    for (var i = 0; i < teeth; i++) {
      final a = i * 2 * math.pi / teeth;
      const w1 = 0.30, w2 = 0.17;
      final pts = [
        (rIn, a - w1),
        (rOut, a - w2),
        (rOut, a + w2),
        (rIn, a + w1),
      ];
      for (final (r, t) in pts) {
        final o = Offset(12 + r * math.cos(t), 12 + r * math.sin(t));
        i == 0 && r == rIn && t == a - w1
            ? p.moveTo(o.dx, o.dy)
            : p.lineTo(o.dx, o.dy);
      }
    }
    p.close();
    p.addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 3));
    return p;
  }

  static Path _build(RohabIconData icon) {
    final p = Path();
    switch (icon) {
      case RohabIconData.gear:
        return _gear();
      case RohabIconData.back:
        p
          ..moveTo(19, 12)
          ..lineTo(5, 12)
          ..moveTo(11, 6)
          ..lineTo(5, 12)
          ..lineTo(11, 18);
      case RohabIconData.chevron:
        p
          ..moveTo(9, 5)
          ..lineTo(16, 12)
          ..lineTo(9, 19);
      case RohabIconData.close:
        p
          ..moveTo(6, 6)
          ..lineTo(18, 18)
          ..moveTo(18, 6)
          ..lineTo(6, 18);
      case RohabIconData.today:
        p
          ..addRect(const Rect.fromLTRB(4, 5, 20, 20))
          ..moveTo(4, 10)
          ..lineTo(20, 10)
          ..moveTo(8, 3)
          ..lineTo(8, 7)
          ..moveTo(16, 3)
          ..lineTo(16, 7);
      case RohabIconData.glove:
        p
          ..moveTo(7, 7.5)
          ..lineTo(17, 16.5)
          ..lineTo(12, 21)
          ..lineTo(12, 3)
          ..lineTo(17, 7.5)
          ..lineTo(7, 16.5);
      case RohabIconData.hand:
        p
          ..moveTo(7.5, 12)
          ..lineTo(7.5, 7)
          ..moveTo(11, 11)
          ..lineTo(11, 3.5)
          ..moveTo(14.5, 11)
          ..lineTo(14.5, 4.5)
          ..moveTo(18, 12)
          ..lineTo(18, 8)
          ..moveTo(7.5, 13)
          ..lineTo(4.5, 10.5)
          ..moveTo(7.5, 12)
          ..cubicTo(7.5, 17, 9, 21, 12.75, 21)
          ..cubicTo(16.5, 21, 18, 17, 18, 12);
      case RohabIconData.chart:
        p
          ..moveTo(5, 20)
          ..lineTo(5, 11)
          ..moveTo(12, 20)
          ..lineTo(12, 4)
          ..moveTo(19, 20)
          ..lineTo(19, 14);
      case RohabIconData.check:
        p
          ..moveTo(5, 12.5)
          ..lineTo(10, 17.5)
          ..lineTo(19, 7);
      case RohabIconData.add:
        p
          ..moveTo(12, 5)
          ..lineTo(12, 19)
          ..moveTo(5, 12)
          ..lineTo(19, 12);
      case RohabIconData.remove:
        p
          ..moveTo(5, 12)
          ..lineTo(19, 12);
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.save();
    canvas.scale(s);
    canvas.drawPath(
      _build(icon),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = RohabShape.icon
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.icon != icon || old.color != color;
}
