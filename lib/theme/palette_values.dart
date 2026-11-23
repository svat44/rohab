/// The Rohab palette as plain 0xAARRGGBB integers, with no Flutter imports, so
/// the contrast script (`dart run tool/contrast.dart`) and the contrast test
/// read the very same values the app draws with.
library;

import 'dart:math' as math;

class RohabHex {
  RohabHex._();
  static const page = 0xFFF2F4F6;
  static const surface = 0xFFFFFFFF;
  static const hairline = 0xFFE1E6EA;
  static const border = 0xFFC9D0D6;
  static const text = 0xFF14202B;
  static const textSecondary = 0xFF4F5D6B;
  static const accent = 0xFF0E6B7A;
  static const accentPressed = 0xFF0A5560;
  static const accentTint = 0xFFE3F0F2;
  static const onAccent = 0xFFFFFFFF;
  static const danger = 0xFFB3261E;
  static const success = 0xFF1B6B3A;
  static const warningText = 0xFF8A5A00;
  static const disabledFill = 0xFFE8ECEF;
  static const disabledText = 0xFF5F6B77;
}

/// Opacity of the big hero bubble and of the two smaller ones.
const double kBubbleAlphaLarge = 0.08;
const double kBubbleAlphaSmall = 0.06;

/// [fg] painted over [bg] at [alpha], as opaque 0xFFRRGGBB.
int blendOver(int fg, int bg, double alpha) {
  int ch(int shift) {
    final f = (fg >> shift) & 0xFF;
    final b = (bg >> shift) & 0xFF;
    return (f * alpha + b * (1 - alpha)).round();
  }

  return 0xFF000000 | (ch(16) << 16) | (ch(8) << 8) | ch(0);
}

double _lin(int v) {
  final s = v / 255;
  return s <= 0.03928
      ? s / 12.92
      : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
}

double luminance(int c) =>
    0.2126 * _lin((c >> 16) & 0xFF) +
    0.7152 * _lin((c >> 8) & 0xFF) +
    0.0722 * _lin(c & 0xFF);

/// WCAG 2 contrast ratio between two opaque colors.
double contrastRatio(int a, int b) {
  final la = luminance(a), lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

class ContrastPair {
  const ContrastPair(this.name, this.fg, this.bg, {this.min = 4.5});
  final String name;
  final int fg;
  final int bg;

  /// 4.5 for text, 3.0 for large text and UI edges (WCAG AA).
  final double min;
  double get ratio => contrastRatio(fg, bg);
}

/// Text over the page with the biggest bubble behind it.
final int pageUnderBubble = blendOver(
  RohabHex.accent,
  RohabHex.page,
  kBubbleAlphaLarge,
);

/// Every text/background pair the app uses. AA minimum.
final List<ContrastPair> contrastPairs = [
  const ContrastPair('text on page', RohabHex.text, RohabHex.page),
  const ContrastPair('text on surface', RohabHex.text, RohabHex.surface),
  const ContrastPair(
    'textSecondary on page',
    RohabHex.textSecondary,
    RohabHex.page,
  ),
  const ContrastPair(
    'textSecondary on surface',
    RohabHex.textSecondary,
    RohabHex.surface,
  ),
  ContrastPair('text on page under bubble', RohabHex.text, pageUnderBubble),
  ContrastPair(
    'textSecondary on page under bubble',
    RohabHex.textSecondary,
    pageUnderBubble,
  ),
  ContrastPair('accent on page under bubble', RohabHex.accent, pageUnderBubble),
  const ContrastPair('accent on page', RohabHex.accent, RohabHex.page),
  const ContrastPair('accent on surface', RohabHex.accent, RohabHex.surface),
  const ContrastPair(
    'accent on accentTint',
    RohabHex.accent,
    RohabHex.accentTint,
  ),
  const ContrastPair('text on accentTint', RohabHex.text, RohabHex.accentTint),
  const ContrastPair('onAccent on accent', RohabHex.onAccent, RohabHex.accent),
  const ContrastPair(
    'onAccent on accentPressed',
    RohabHex.onAccent,
    RohabHex.accentPressed,
  ),
  const ContrastPair(
    'accent on surface (white button text on panel)',
    RohabHex.accent,
    RohabHex.surface,
  ),
  const ContrastPair(
    'onAccent on danger (STOP)',
    RohabHex.onAccent,
    RohabHex.danger,
  ),
  const ContrastPair('danger on surface', RohabHex.danger, RohabHex.surface),
  const ContrastPair('danger on page', RohabHex.danger, RohabHex.page),
  const ContrastPair(
    'onAccent on success',
    RohabHex.onAccent,
    RohabHex.success,
  ),
  const ContrastPair('success on surface', RohabHex.success, RohabHex.surface),
  const ContrastPair(
    'warningText on surface',
    RohabHex.warningText,
    RohabHex.surface,
  ),
  const ContrastPair(
    'warningText on page',
    RohabHex.warningText,
    RohabHex.page,
  ),
  const ContrastPair(
    'disabledText on disabledFill',
    RohabHex.disabledText,
    RohabHex.disabledFill,
  ),
  // Edges of controls and the hairline must be visible but are decoration, so
  // they are listed with the 3:1 non-text bar for reference only where a
  // control relies on them. (Rows rely on text, not on their hairline.)
  const ContrastPair(
    'accent bar on surface (3 dp tab underline)',
    RohabHex.accent,
    RohabHex.surface,
    min: 3.0,
  ),
  const ContrastPair(
    'accent segment on hairline segment',
    RohabHex.accent,
    RohabHex.hairline,
    min: 3.0,
  ),
];
