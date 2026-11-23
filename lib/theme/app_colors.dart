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
  Color get header => palette.header;
  Color get highlight => palette.highlight;
  Color get silver => palette.silver;
  Color get silverEdge => palette.silverEdge;
  Color get disabledFill => palette.disabledFill;
  Color get disabledText => palette.disabledText;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : other ?? this;
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
