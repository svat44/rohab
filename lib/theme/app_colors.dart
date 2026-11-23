import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Exposes the palette to widgets via `context.colors`.
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
  Color get accentPressed => palette.accentPressed;
  Color get onAccent => palette.onAccent;
  Color get accentSoft => palette.accentSoft;
  Color get danger => palette.danger;
  Color get onDanger => palette.onDanger;
  Color get controlFill => palette.controlFill;
  Color get controlEdge => palette.controlEdge;
  Color get disabledFill => palette.disabledFill;
  Color get disabledText => palette.disabledText;
  Color get success => palette.success;
  Color get onSuccess => palette.onSuccess;
  Color get warningText => palette.warningText;
  Color get focus => palette.focus;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : other ?? this;
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
