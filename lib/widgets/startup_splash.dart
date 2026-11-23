import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Opening screen: a hand slowly opens, finger by finger, in the three blues
/// of the Rohab logo, then the name appears. It is the exercise itself in
/// miniature (open the hand), and it plays once per launch for about two
/// seconds. A tap skips it, and it is skipped when the phone asks for
/// reduced motion.
class StartupSplash extends StatefulWidget {
  const StartupSplash({super.key, required this.onDone});

  final VoidCallback onDone;

  static const duration = Duration(milliseconds: 2600);

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: StartupSplash.duration)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _finish();
        });
  bool _finished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else if (!_c.isAnimating && !_finished) {
      _c.forward();
    }
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: Semantics(
        label: 'Rohab is starting. Tap to skip.',
        child: ColoredBox(
          color: c.background,
          child: Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final name = Curves.easeOut.transform(
                  ((_c.value - 0.62) / 0.28).clamp(0.0, 1.0),
                );
                final out = ((_c.value - 0.94) / 0.06).clamp(0.0, 1.0);
                return Opacity(
                  opacity: 1 - out,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CustomPaint(
                          painter: _HandPainter(
                            progress: _c.value,
                            colors: [
                              c.accent,
                              const Color(0xFF29B6F6),
                              const Color(0xFF54C5F8),
                            ],
                            baseColor: c.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: RohabSpace.s24),
                      Opacity(
                        opacity: name,
                        child: Text(
                          RohabTokens.name,
                          style: t.headlineMedium?.copyWith(
                            fontSize: 44,
                            shadows: c.letterpress,
                          ),
                        ),
                      ),
                      const SizedBox(height: RohabSpace.s8),
                      Opacity(
                        opacity: name,
                        child: Text(
                          'Hand exercises, every day',
                          style: t.labelMedium,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Four fingers and a thumb rise from a palm bar one after another, like a
/// hand opening. Each finger is a rounded bar cut on a slant, the shape used
/// in the logo's strokes.
class _HandPainter extends CustomPainter {
  const _HandPainter({
    required this.progress,
    required this.colors,
    required this.baseColor,
  });

  final double progress;
  final List<Color> colors;
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    const maxLen = [0.62, 0.78, 0.84, 0.70]; // index, middle, ring, little
    final w = size.width;
    final baseY = size.height * 0.92;
    final barW = w * 0.15;
    final gap = w * 0.045;
    final total = 4 * barW + 3 * gap;
    final left = (w - total) / 2 + w * 0.06;

    // Palm: a solid bar the fingers stand on.
    final palm = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        left - w * 0.02,
        baseY - barW * 0.5,
        total + w * 0.04,
        barW * 0.9,
      ),
      Radius.circular(barW * 0.35),
    );
    canvas.drawRRect(palm, Paint()..color = baseColor);

    for (var i = 0; i < 4; i++) {
      final start = 0.05 + i * 0.12;
      final p = Curves.easeOutCubic.transform(
        ((progress - start) / 0.38).clamp(0.0, 1.0),
      );
      final h = size.height * 0.84 * maxLen[i] * p;
      if (h < 1) continue;
      final x = left + i * (barW + gap);
      final r = Rect.fromLTWH(x, baseY - barW * 0.5 - h, barW, h + barW * 0.2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(barW / 2)),
        Paint()..color = colors[i % colors.length],
      );
    }

    // Thumb: rises last, leaning out to the side.
    final tp = Curves.easeOutCubic.transform(
      ((progress - 0.55) / 0.32).clamp(0.0, 1.0),
    );
    if (tp > 0) {
      canvas.save();
      canvas.translate(left - w * 0.01, baseY - barW * 0.2);
      canvas.rotate(-0.95 * tp);
      final len = size.height * 0.42 * tp;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-barW, -len, barW, len + barW * 0.4),
          Radius.circular(barW / 2),
        ),
        Paint()..color = colors[2],
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_HandPainter old) => old.progress != progress;
}
