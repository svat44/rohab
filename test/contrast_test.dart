import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:rohab/theme/tokens.dart';

double _lin(double v) =>
    v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

double _lum(Color c) =>
    0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b);

double ratio(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, p) in [
    ('light', RohabPalette.light),
    ('dark', RohabPalette.dark),
  ]) {
    // (label, foreground, background, minimum ratio)
    final pairs = <(String, Color, Color, double)>[
      ('text on page', p.text, p.background, 4.5),
      ('text on card', p.text, p.surface, 4.5),
      ('secondary on page', p.secondary, p.background, 4.5),
      ('secondary on card', p.secondary, p.surface, 4.5),
      ('accent on page', p.accent, p.background, 4.5),
      ('accent on card', p.accent, p.surface, 4.5),
      ('label on primary button', p.onAccent, p.accent, 4.5),
      ('label on STOP button', p.onDanger, p.danger, 4.5),
      ('danger text on card', p.danger, p.surface, 4.5),
      ('label on header', p.secondary, p.header, 4.5),
      ('disabled label', p.disabledText, p.disabledFill, 3.0),
      ('control edge on page', p.controlEdge, p.background, 3.0),
      ('selected tab label', p.accent, p.accentSoft, 4.5),
    ];
    for (final (label, fg, bg, min) in pairs) {
      test('$name: $label is at least $min:1', () {
        expect(ratio(fg, bg), greaterThanOrEqualTo(min),
            reason: '${ratio(fg, bg).toStringAsFixed(2)}:1');
      });
    }
  }
}
