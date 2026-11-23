import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Soft pale-blue circles behind a hero number, as in MIUI's Battery and
/// Security screens. Painted once and never animated, so it costs nothing on
/// a low-end phone. Drawn well below the text contrast limits: the circles are
/// at most 18% accent on the page grey, and they never carry information.
class HeroBackdrop extends StatelessWidget {
  const HeroBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // The circles bleed past the page padding to the screen edge, like
    // MIUI's, and stay in the top band where the number is, never behind
    // a chart or a button.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -RohabSpace.s24,
          right: -RohabSpace.s24,
          top: 0,
          height: _band,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: _CirclesPainter(c.accent)),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  static const _band = 270.0;
}

class _CirclesPainter extends CustomPainter {
  const _CirclesPainter(this.accent);

  final Color accent;

  void _circle(Canvas canvas, Offset center, double radius, double alpha) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: alpha * 0.55),
            accent.withValues(alpha: alpha),
          ],
        ).createShader(rect),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    _circle(canvas, const Offset(20, 115), 100, 0.18);
    _circle(canvas, const Offset(14, 232), 30, 0.14);
    _circle(canvas, Offset(w, 92), 64, 0.14);
  }

  @override
  bool shouldRepaint(_CirclesPainter old) => old.accent != accent;
}

/// One large thin number with a short line under it. The screen's single most
/// important figure, set straight on the page.
class HeroNumber extends StatelessWidget {
  const HeroNumber({
    super.key,
    required this.value,
    required this.caption,
    required this.semanticsLabel,
    this.valueKey,
  });

  final String value;
  final String caption;
  final String semanticsLabel;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              key: valueKey,
              style: t.displayLarge?.copyWith(
                fontSize: RohabType.hero,
                fontWeight: FontWeight.w300,
                color: c.text,
              ),
            ),
          ),
          const SizedBox(height: RohabSpace.s8),
          Text(caption, textAlign: TextAlign.center, style: t.bodyLarge),
        ],
      ),
    );
  }
}
