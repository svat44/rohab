/// Rohab brand tokens. The single source of truth for color, type, spacing,
/// shape, size and motion. Nothing else in lib/ hard-codes these values.
library;

import 'dart:ui' show Color;

class RohabTokens {
  RohabTokens._();

  static const name = 'Rohab';
  static const fontFamily = 'Inter';
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
    required this.shadow,
    required this.header,
    required this.highlight,
    required this.silver,
    required this.silverEdge,
    required this.disabledFill,
    required this.disabledText,
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

  /// Dark side of the soft extruded look: shadow falling to the bottom right.
  final Color shadow;

  /// Light side: the glow on the top left of a raised surface.
  final Color highlight;

  /// Solid title bar.
  final Color header;

  /// Secondary buttons and choice tiles: same material as the page, raised.
  final Color silver;

  /// 3:1 edge for controls, so they never depend on the shadow alone.
  final Color silverEdge;

  /// Disabled controls: flat, with a label that is still readable.
  final Color disabledFill;
  final Color disabledText;

  /// Light blue and deep blue, from the app icon (#54C5F8, #29B6F6,
  /// #01579B). The base colours of the classic raised-and-textured look
  /// (see widgets/skeuo.dart). Contrast (WCAG): text on background 12:1,
  /// secondary on background 6:1, white on accent 7.6:1.
  static const light = RohabPalette(
    background: Color(0xFFDFE7EF),
    surface: Color(0xFFE9EFF5),
    text: Color(0xFF0B1F2E),
    secondary: Color(0xFF3B5367),
    divider: Color(0xFFB3C8D8),
    accent: Color(0xFF01579B),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFD3E6F5),
    danger: Color(0xFFC62020),
    onDanger: Color(0xFFFFFFFF),
    shadow: Color(0x4D5B7691),
    highlight: Color(0xCCFFFFFF),
    header: Color(0xFF01579B),
    silver: Color(0xFFE9EFF5),
    silverEdge: Color(0xFF5A7388),
    disabledFill: Color(0xFFD0D9E2),
    disabledText: Color(0xFF465B6D),
  );

  /// Dark twin. Accent keeps dark text on it (white on #54C5F8 is about
  /// 1.9:1).
  static const dark = RohabPalette(
    background: Color(0xFF0E1A25),
    surface: Color(0xFF142331),
    text: Color(0xFFEAF3FA),
    secondary: Color(0xFF9DB4C6),
    divider: Color(0xFF244058),
    accent: Color(0xFF54C5F8),
    onAccent: Color(0xFF04202F),
    accentSoft: Color(0xFF143650),
    danger: Color(0xFFF07070),
    onDanger: Color(0xFF1A0505),
    shadow: Color(0xB3000000),
    highlight: Color(0x14FFFFFF),
    header: Color(0xFF123B5F),
    silver: Color(0xFF142331),
    silverEdge: Color(0xFF557692),
    disabledFill: Color(0xFF1E3141),
    disabledText: Color(0xFFA9BDCC),
  );
}

/// Type scale in sp. Labels never go below [label].
class RohabType {
  RohabType._();
  static const double display = 64;
  static const double title = 30;
  static const double body = 20;
  static const double label = 16;
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

  /// Buttons and small tiles: the gently rounded corners of classic apps.
  static const double radius = 12;

  /// Cards and panels.
  static const double card = 20;
  static const double border = 1;

  /// Marker lines and the camera's hand frame.
  static const double strongBorder = 2;
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
