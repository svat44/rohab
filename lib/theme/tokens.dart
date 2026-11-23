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

  /// Soft card shadow.
  final Color shadow;

  /// Light blue and deep blue, from the app icon (#54C5F8, #29B6F6,
  /// #01579B). Flat colours, square corners, no gradients. Contrast (WCAG):
  /// text on background 15:1, secondary on background 6.1:1, white on
  /// accent 7.6:1.
  static const light = RohabPalette(
    background: Color(0xFFF1F7FB),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF0B1F2E),
    secondary: Color(0xFF475F72),
    divider: Color(0xFFC9DBE8),
    accent: Color(0xFF01579B),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFDCEEFA),
    danger: Color(0xFFDC2626),
    onDanger: Color(0xFFFFFFFF),
    shadow: Color(0x00000000),
  );

  /// Dark twin. Accent keeps dark text on it (white on #54C5F8 is about
  /// 1.9:1).
  static const dark = RohabPalette(
    background: Color(0xFF0A1621),
    surface: Color(0xFF112331),
    text: Color(0xFFEAF3FA),
    secondary: Color(0xFF9DB4C6),
    divider: Color(0xFF244058),
    accent: Color(0xFF54C5F8),
    onAccent: Color(0xFF04202F),
    accentSoft: Color(0xFF143650),
    danger: Color(0xFFDC2626),
    onDanger: Color(0xFFFFFFFF),
    shadow: Color(0x00000000),
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
  static const double radius = 0;

  /// Cards and panels. Square, on purpose.
  static const double card = 0;
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
