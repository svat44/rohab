/// Rohab design tokens: color, type, spacing, shape, size. Nothing else in
/// lib/ hard-codes these values. Colors come from palette_values.dart so the
/// contrast test and the app read the same numbers.
library;

import 'dart:ui' show Color, FontFeature, FontVariation, FontWeight;

import 'package:material_ui/material_ui.dart' show TextStyle;

import 'palette_values.dart';

class RohabTokens {
  RohabTokens._();
  static const name = 'Rohab';
}

/// The one palette. One accent (deep teal), one danger, one success.
class RohabPalette {
  const RohabPalette({
    required this.background,
    required this.surface,
    required this.text,
    required this.secondary,
    required this.divider,
    required this.accent,
    required this.accentPressed,
    required this.onAccent,
    required this.accentSoft,
    required this.danger,
    required this.onDanger,
    required this.controlFill,
    required this.controlEdge,
    required this.disabledFill,
    required this.disabledText,
    required this.success,
    required this.onSuccess,
    required this.warningText,
    required this.focus,
  });

  /// Page behind the white surfaces.
  final Color background;
  final Color surface;
  final Color text;
  final Color secondary;

  /// 1 dp hairline between rows.
  final Color divider;
  final Color accent;
  final Color accentPressed;
  final Color onAccent;
  final Color accentSoft;

  /// STOP and faults only.
  final Color danger;
  final Color onDanger;

  /// Secondary buttons and square toggles: white.
  final Color controlFill;

  /// Edge of a control.
  final Color controlEdge;
  final Color disabledFill;
  final Color disabledText;

  /// Always paired with a word, never the only signal.
  final Color success;
  final Color onSuccess;
  final Color warningText;

  /// Keyboard and switch-access focus ring.
  final Color focus;

  /// Fully transparent, for places that must draw nothing.
  static const clear = Color(0x00000000);

  static const light = RohabPalette(
    background: Color(RohabHex.page),
    surface: Color(RohabHex.surface),
    text: Color(RohabHex.text),
    secondary: Color(RohabHex.textSecondary),
    divider: Color(RohabHex.hairline),
    accent: Color(RohabHex.accent),
    accentPressed: Color(RohabHex.accentPressed),
    onAccent: Color(RohabHex.onAccent),
    accentSoft: Color(RohabHex.accentTint),
    danger: Color(RohabHex.danger),
    onDanger: Color(RohabHex.onAccent),
    controlFill: Color(RohabHex.surface),
    controlEdge: Color(RohabHex.border),
    disabledFill: Color(RohabHex.disabledFill),
    disabledText: Color(RohabHex.disabledText),
    success: Color(RohabHex.success),
    onSuccess: Color(RohabHex.onAccent),
    warningText: Color(RohabHex.warningText),
    focus: Color(0xFFFFD21F),
  );
}

/// Font families bundled in assets/fonts (all SIL OFL). Never fetched.
class RohabFonts {
  RohabFonts._();

  /// Body and UI text.
  static const body = 'AtkinsonHyperlegibleNext';

  /// Screen titles and the wordmark: the sans companion of Source Serif.
  static const title = 'SourceSans3';

  /// Every number. Atkinson's slashed zero looks odd at size, so numerals use
  /// the same clean sans as the titles. Its default figures are tabular.
  static const numbers = title;
}

/// Type scale in sp. Nothing under 14, no light weights. These are the only
/// text styles in the app; widgets copy one, they never invent one.
class RohabType {
  RohabType._();

  static const _text = Color(RohabHex.text);
  static const _secondary = Color(RohabHex.textSecondary);
  static const _tabular = [FontFeature.tabularFigures()];

  static const title = TextStyle(
    fontFamily: RohabFonts.title,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    fontSize: 24,
    height: 1.2,
    color: _text,
  );

  /// The "Rohab" wordmark: small.
  static const wordmark = TextStyle(
    fontFamily: RohabFonts.title,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    fontSize: 16,
    height: 1.2,
    color: _text,
  );

  static const sectionLabel = TextStyle(
    fontFamily: RohabFonts.body,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    fontSize: 14,
    height: 1.3,
    color: _secondary,
  );

  static const rowTitle = TextStyle(
    fontFamily: RohabFonts.body,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    fontSize: 16,
    height: 1.25,
    color: _text,
  );

  static const rowSub = TextStyle(
    fontFamily: RohabFonts.body,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    fontSize: 15,
    height: 1.3,
    color: _secondary,
  );

  static const body = TextStyle(
    fontFamily: RohabFonts.body,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    fontSize: 16,
    height: 1.4,
    color: _text,
  );

  static const button = TextStyle(
    fontFamily: RohabFonts.body,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    fontSize: 16,
    height: 1.2,
    color: _text,
  );

  static const navLabel = TextStyle(
    fontFamily: RohabFonts.body,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    fontSize: 14,
    height: 1.2,
    color: _secondary,
  );

  static const navLabelSelected = TextStyle(
    fontFamily: RohabFonts.body,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    fontSize: 14,
    height: 1.2,
    color: Color(RohabHex.accent),
  );

  static const metricXL = TextStyle(
    fontFamily: RohabFonts.numbers,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    fontSize: 48,
    height: 1.0,
    color: _text,
    fontFeatures: _tabular,
  );

  /// The live rep counter on the camera screen.
  static const metricCamera = TextStyle(
    fontFamily: RohabFonts.numbers,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    fontSize: 64,
    height: 1.0,
    color: _text,
    fontFeatures: _tabular,
  );

  static const metricL = TextStyle(
    fontFamily: RohabFonts.numbers,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    fontSize: 28,
    height: 1.1,
    color: _text,
    fontFeatures: _tabular,
  );

  static const metricS = TextStyle(
    fontFamily: RohabFonts.numbers,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    fontSize: 16,
    height: 1.2,
    color: _text,
    fontFeatures: _tabular,
  );
}

/// 8 dp grid.
class RohabSpace {
  RohabSpace._();
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;

  /// Side padding of every screen.
  static const double gutter = 16;
}

class RohabShape {
  RohabShape._();

  /// Controls: buttons, steppers, square toggles. Rows, panels and the result
  /// block are 0.
  static const double control = 4;
  static const double radius = 0;
  static const double card = 0;
  static const double border = 1;
  static const double strongBorder = 2;
  static const double focusRing = 4;
  static const double tabUnderline = 3;
  static const double navBar = 3;
  static const double icon = 2;
}

class RohabSize {
  RohabSize._();
  static const double touchTarget = 48;
  static const double rowMin = 64;
  static const double primaryButtonHeight = 64;
  static const double stopButtonHeight = 64;
  static const double stepperButton = 56;
  static const double icon = 24;
  static const double navHeight = 64;
  static const double appBarHeight = 64;
}

/// Motion: functional only, never longer than [max].
class RohabMotion {
  RohabMotion._();
  static const max = Duration(milliseconds: 200);
}
