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

  static const light = RohabPalette(
    background: Color(0xFFFAFAF9),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF1C1C1E),
    secondary: Color(0xFF6B7280),
    divider: Color(0xFFE5E7EB),
    accent: Color(0xFF0F766E),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFCCE7E4),
    danger: Color(0xFFDC2626),
    onDanger: Color(0xFFFFFFFF),
  );

  /// Background, surface, text and accent are from the brand spec. Secondary,
  /// divider, accent-soft and on-accent were filled in for contrast (white on
  /// #2DD4BF is about 1.9:1, so buttons use dark text).
  static const dark = RohabPalette(
    background: Color(0xFF111312),
    surface: Color(0xFF1A1D1C),
    text: Color(0xFFF3F4F3),
    secondary: Color(0xFF9CA3AF),
    divider: Color(0xFF2A2E2D),
    accent: Color(0xFF2DD4BF),
    onAccent: Color(0xFF0B1F1D),
    accentSoft: Color(0xFF134E4A),
    danger: Color(0xFFDC2626),
    onDanger: Color(0xFFFFFFFF),
  );
}

/// Type scale in sp. Labels never go below [label].
class RohabType {
  RohabType._();
  static const double display = 56;
  static const double title = 28;
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
  static const double radius = 12;
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
