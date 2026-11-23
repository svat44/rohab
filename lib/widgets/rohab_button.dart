import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

enum RohabButtonKind { primary, secondary, danger }

/// The one button. Full width, 64 dp tall, rectangular with a 4 dp radius, no
/// shadow. [disabledReason] turns it off AND says why on a line underneath, so
/// a disabled button is never a mystery. Disabled looks like: gray fill, dark
/// gray label (passes AA) and a 1 dp border.
class RohabButton extends StatelessWidget {
  const RohabButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = RohabButtonKind.primary,
    this.disabledReason,
    this.onAccent = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final RohabButtonKind kind;

  /// Shown under the button while it is disabled. Required whenever
  /// [onPressed] is null for a button the user can see.
  final String? disabledReason;

  /// White-filled button with accent text, for use on the accent
  /// [ResultPanel].
  final bool onAccent;

  bool get _disabled => onPressed == null || disabledReason != null;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final VoidCallback? press = _disabled ? null : onPressed;
    final (Color fill, Color fg, Color edge) = _disabled
        ? (c.disabledFill, c.disabledText, c.controlEdge)
        : onAccent
        ? (c.surface, c.accent, c.surface)
        : switch (kind) {
            RohabButtonKind.primary => (c.accent, c.onAccent, c.accent),
            RohabButtonKind.danger => (c.danger, c.onDanger, c.danger),
            RohabButtonKind.secondary => (c.surface, c.accent, c.controlEdge),
          };
    final button = SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: press,
        style: FilledButton.styleFrom(
          backgroundColor: fill,
          foregroundColor: fg,
          disabledBackgroundColor: fill,
          disabledForegroundColor: fg,
          minimumSize: const Size.fromHeight(RohabSize.primaryButtonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: RohabSpace.s16,
            vertical: RohabSpace.s8,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RohabShape.control),
            side: BorderSide(color: edge, width: RohabShape.border),
          ),
          textStyle: RohabType.button,
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
    if (!_disabled || disabledReason == null) return button;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(height: RohabSpace.s8),
        Text(disabledReason!, style: RohabType.rowSub),
      ],
    );
  }
}

/// The shared STOP control: a red stop-sign octagon with a white "STOP",
/// 56 dp, top right of the screen. Shown only while the glove is doing
/// something (see SafetyBanner). Calls [onStop] on every press, in every
/// state, with no confirmation step.
class StopButton extends StatelessWidget {
  const StopButton({super.key, required this.onStop});

  /// Key tests and the shell use to find the one STOP control.
  static const stopKey = Key('safety-stop');

  static const size = 56.0;

  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: 'Stop. Vents the glove now.',
      excludeSemantics: true,
      child: GestureDetector(
        key: stopKey,
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.heavyImpact();
          onStop();
        },
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _OctagonPainter(c.danger),
            child: const Center(
              child: Text(
                'STOP',
                // Fixed size: the sign never scales with text size.
                textScaler: TextScaler.noScaling,
                style: RohabType.navLabelSelected,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OctagonPainter extends CustomPainter {
  _OctagonPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, k = w * 0.2929; // regular octagon inset
    final path = Path()
      ..moveTo(k, 0)
      ..lineTo(w - k, 0)
      ..lineTo(w, k)
      ..lineTo(w, w - k)
      ..lineTo(w - k, w)
      ..lineTo(k, w)
      ..lineTo(0, w - k)
      ..lineTo(0, k)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = RohabPalette.light.onAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_OctagonPainter old) => old.color != color;
}
