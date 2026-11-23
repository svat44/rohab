import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Exposes the active [RohabPalette] to widgets via `context.colors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors(this.palette);

  final RohabPalette palette;

  Color get background => palette.background;
  Color get surface => palette.surface;
  Color get text => palette.text;
  Color get secondary => palette.secondary;
  Color get divider => palette.divider;
  Color get accent => palette.accent;
  Color get onAccent => palette.onAccent;
  Color get accentSoft => palette.accentSoft;
  Color get danger => palette.danger;
  Color get onDanger => palette.onDanger;
  Color get shadow => palette.shadow;
  Color get leather => palette.leather;
  Color get steel => palette.steel;
  Color get onSteel => palette.onSteel;
  Color get silver => palette.silver;
  Color get silverEdge => palette.silverEdge;

  /// Letterpress effect: light text sits on a light edge below it on the
  /// light theme, dark text on a dark edge above it on the dark theme.
  List<Shadow> get letterpress => palette == RohabPalette.dark
      ? const [Shadow(color: Color(0xAA000000), offset: Offset(0, -1))]
      : const [Shadow(color: Color(0xCCFFFFFF), offset: Offset(0, 1))];

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : other ?? this;
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
