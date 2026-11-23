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
    required this.leather,
    required this.steel,
    required this.silver,
    required this.silverEdge,
    required this.onSteel,
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

  /// Drop shadow under raised panels and buttons.
  final Color shadow;

  /// Blue leather of the title bar.
  final Color leather;

  /// Brushed steel of the tab bar, and the light text and icons on it.
  final Color steel;
  final Color onSteel;

  /// Secondary (silver) buttons and their edge.
  final Color silver;
  final Color silverEdge;

  /// Light blue and deep blue, from the app icon (#54C5F8, #29B6F6,
  /// #01579B). The base colours of the classic raised-and-textured look
  /// (see widgets/skeuo.dart). Contrast (WCAG): text on background 12:1,
  /// secondary on background 6:1, white on accent 7.6:1.
  static const light = RohabPalette(
    background: Color(0xFFD6E4EF),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF0B1F2E),
    secondary: Color(0xFF3B5367),
    divider: Color(0xFFB3C8D8),
    accent: Color(0xFF01579B),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFE3F1FB),
    danger: Color(0xFFD32020),
    onDanger: Color(0xFFFFFFFF),
    shadow: Color(0x40102030),
    leather: Color(0xFF0B5CA8),
    steel: Color(0xFF3F5A74),
    onSteel: Color(0xFFD3E0EA),
    silver: Color(0xFFE6EEF5),
    silverEdge: Color(0xFF7F99AE),
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
    shadow: Color(0x99000000),
    leather: Color(0xFF123B5F),
    steel: Color(0xFF1E3144),
    onSteel: Color(0xFFC4D5E3),
    silver: Color(0xFF2C4559),
    silverEdge: Color(0xFF557692),
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
  static const double radius = 10;

  /// Cards and panels.
  static const double card = 12;
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
