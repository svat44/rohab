/// Rohab brand tokens. The single source of truth for color, type, spacing,
/// shape, size and motion. Nothing else in lib/ hard-codes these values.
library;

import 'dart:ui' show Color;

class RohabTokens {
  RohabTokens._();

  static const name = 'Rohab';
  static const fontFamily = 'Atkinson';
}

/// One palette per brightness. Rules: one accent, red only for STOP and
/// faults, one secondary gray.
class RohabPalette {
  const RohabPalette({
    required this.background,
    required this.surface,
    required this.text,
    required this.secondary,
    required this.divider,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.danger,
    required this.onDanger,
    required this.header,
    required this.controlFill,
    required this.controlEdge,
    required this.disabledFill,
    required this.disabledText,
    required this.success,
    required this.onSuccess,
    required this.focus,
  });

  final Color background;
  final Color surface;
  final Color text;
  final Color secondary;
  final Color divider;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;

  /// STOP and faults only.
  final Color danger;
  final Color onDanger;

  /// Solid title bar.
  final Color header;

  /// Secondary buttons and choice boxes: white, with a dark edge.
  final Color controlFill;

  /// 3:1 edge for every control, so a control never depends on its fill.
  final Color controlEdge;

  /// Disabled controls: flat, with a label that is still readable.
  final Color disabledFill;
  final Color disabledText;

  /// "Done" and "connected". Never the only signal: always with a word.
  final Color success;
  final Color onSuccess;

  /// Keyboard and switch-access focus ring: yellow, 4 px, on every control.
  final Color focus;

  /// Clinical blue on white, like a patient portal. Contrast (WCAG):
  /// text on page 16:1, secondary on page 8:1, white on accent 6.6:1,
  /// white on danger 6.9:1, white on success 5.9:1.
  static const light = RohabPalette(
    background: Color(0xFFF4F7FA),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF14212B),
    secondary: Color(0xFF3F505E),
    divider: Color(0xFF7F8F9C),
    accent: Color(0xFF0B5CAD),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFE1EDF8),
    danger: Color(0xFFB3170F),
    onDanger: Color(0xFFFFFFFF),
    header: Color(0xFF0B5CAD),
    controlFill: Color(0xFFFFFFFF),
    controlEdge: Color(0xFF4B5C69),
    disabledFill: Color(0xFFE3E8EC),
    disabledText: Color(0xFF55646F),
    success: Color(0xFF00703C),
    onSuccess: Color(0xFFFFFFFF),
    focus: Color(0xFFFFD21F),
  );

  /// Dark twin, for people who choose it (or whose phone does).
  static const dark = RohabPalette(
    background: Color(0xFF0F1A24),
    surface: Color(0xFF17232F),
    text: Color(0xFFF2F7FB),
    secondary: Color(0xFFB4C4D2),
    divider: Color(0xFF5E7385),
    accent: Color(0xFF6FB7F2),
    onAccent: Color(0xFF06223A),
    accentSoft: Color(0xFF1B3550),
    danger: Color(0xFFFF8A80),
    onDanger: Color(0xFF2A0505),
    header: Color(0xFF0B3B6B),
    controlFill: Color(0xFF17232F),
    controlEdge: Color(0xFF8FA5B7),
    disabledFill: Color(0xFF223442),
    disabledText: Color(0xFFA9BDCC),
    success: Color(0xFF6CD39A),
    onSuccess: Color(0xFF04210F),
    focus: Color(0xFFFFD21F),
  );
}

/// Type scale in sp. Labels never go below [label].
class RohabType {
  RohabType._();
  static const double display = 56;
  static const double title = 28;
  static const double heading = 24;
  static const double body = 20;
  static const double label = 18;
}

/// 8pt grid.
class RohabSpace {
  RohabSpace._();
  static const double s8 = 8;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
}

class RohabShape {
  RohabShape._();

  /// Square corners, on purpose: every box is an edge a person with low
  /// vision can follow, like the boxes on a paper form.
  static const double radius = 0;
  static const double card = 0;

  /// Panels and list rows.
  static const double border = 1.5;

  /// Controls: buttons, choice boxes, the camera frame.
  static const double strongBorder = 2;

  /// Depth of a button's bottom edge. It sinks when pressed.
  static const double buttonEdge = 4;

  /// Keyboard focus ring.
  static const double focusRing = 4;
}

class RohabSize {
  RohabSize._();
  static const double touchTarget = 64;
  static const double primaryButtonHeight = 64;
  static const double stopButtonHeight = 80;
  static const double stopButtonWidth = 112;
  static const double icon = 28;
}

/// Motion: functional only, never longer than [max].
class RohabMotion {
  RohabMotion._();
  static const max = Duration(milliseconds: 200);
}
