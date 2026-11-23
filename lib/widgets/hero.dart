import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../theme/palette_values.dart';

/// HeroBubbles: the one decorative element. Exactly three soft circles
/// (about 240, 140 and 80 dp), cropped at the screen edges, accent at 8%
/// (6% for the two smaller ones), STATIC. Painted once inside a
/// RepaintBoundary, ignoring touches, hidden from screen readers. White
/// surfaces cover them; never put it behind the nav or a pinned panel.
class HeroBubbles extends StatelessWidget {
  const HeroBubbles({super.key, required this.child, this.height = 280});

  /// The hero content drawn over the bubbles.
  final Widget child;

  /// Height of the band the bubbles live in.
  final double height;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accent;
    return Stack(
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: ClipRect(
                  child: CustomPaint(painter: BubblePainter(accent)),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Paints the three circles. Positions are fractions of the band, so they
/// stay cropped by the screen edge at any width.
class BubblePainter extends CustomPainter {
  const BubblePainter(this.accent);

  final Color accent;

  static const largeDiameter = 240.0;
  static const mediumDiameter = 140.0;
  static const smallDiameter = 80.0;

  @override
  void paint(Canvas canvas, Size size) {
    void circle(Offset c, double d, double alpha) => canvas.drawCircle(
      c,
      d / 2,
      Paint()..color = accent.withValues(alpha: alpha),
    );
    circle(Offset(size.width - 40, 70), largeDiameter, kBubbleAlphaLarge);
    circle(Offset(20, size.height - 50), mediumDiameter, kBubbleAlphaSmall);
    circle(
      Offset(size.width - 10, size.height - 20),
      smallDiameter,
      kBubbleAlphaSmall,
    );
  }

  @override
  bool shouldRepaint(BubblePainter old) => old.accent != accent;
}
