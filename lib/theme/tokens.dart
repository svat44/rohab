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

  /// Calm clinical palette: a cool mist background, white cards, deep teal
  /// for the one accent, slate text. Contrast (WCAG): text on background
  /// 14:1, secondary on background 6.3:1, white on accent 6.1:1.
  static const light = RohabPalette(
    background: Color(0xFFF3F4F6),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF111418),
    secondary: Color(0xFF5B6470),
    divider: Color(0xFFE6E8EB),
    accent: Color(0xFF0B6E6A),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFE4F1EF),
    danger: Color(0xFFDC2626),
    onDanger: Color(0xFFFFFFFF),
    shadow: Color(0x12000000),
  );

  /// Dark twin. Accent keeps dark text on it (white on #2DD4BF is about
  /// 1.9:1).
  static const dark = RohabPalette(
    background: Color(0xFF0E1012),
    surface: Color(0xFF181B1F),
    text: Color(0xFFF2F4F5),
    secondary: Color(0xFFA0A8B0),
    divider: Color(0xFF2A2E33),
    accent: Color(0xFF2DD4BF),
    onAccent: Color(0xFF062321),
    accentSoft: Color(0xFF12413F),
    danger: Color(0xFFDC2626),
    onDanger: Color(0xFFFFFFFF),
    shadow: Color(0x66000000),
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
  static const double radius = 16;

  /// Cards and hero panels.
  static const double card = 24;
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
