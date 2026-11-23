import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

export 'tokens.dart';

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

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : other ?? this;
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

ThemeData buildTheme(Brightness brightness) {
  final p =
      brightness == Brightness.light ? RohabPalette.light : RohabPalette.dark;

  // Hierarchy by size and weight only.
  final text = TextTheme(
    displayLarge: TextStyle(
      fontSize: RohabType.display,
      height: 1.0,
      fontWeight: FontWeight.w600,
      letterSpacing: -1,
      color: p.text,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
    headlineMedium: TextStyle(
      fontSize: RohabType.title,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      color: p.text,
    ),
    // Single instruction on a calibration step.
    titleLarge: TextStyle(
      fontSize: RohabType.title,
      height: 1.25,
      fontWeight: FontWeight.w500,
      color: p.text,
    ),
    bodyLarge:
        TextStyle(fontSize: RohabType.body, height: 1.4, color: p.text),
    bodyMedium:
        TextStyle(fontSize: RohabType.body, height: 1.4, color: p.text),
    labelLarge: TextStyle(
      fontSize: RohabType.body,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: p.text,
    ),
    labelMedium: TextStyle(
      fontSize: RohabType.label,
      height: 1.25,
      fontWeight: FontWeight.w500,
      color: p.secondary,
    ),
  ).apply(fontFamily: RohabTokens.fontFamily);

  final radius = BorderRadius.circular(RohabShape.radius);

  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    secondary: p.accent,
    onSecondary: p.onAccent,
    error: p.danger,
    onError: p.onDanger,
    surface: p.background,
    onSurface: p.text,
    surfaceTint: Colors.transparent,
    outline: p.divider,
    outlineVariant: p.divider,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: RohabTokens.fontFamily,
    textTheme: text,
    scaffoldBackgroundColor: p.background,
    dividerTheme: DividerThemeData(
        color: p.divider, thickness: RohabShape.border, space: 1),
    // Plain ripple, not the Material 3 sparkle.
    splashFactory: InkRipple.splashFactory,
    // Screens change instantly: no fades or slides.
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: _InstantTransitions(),
      TargetPlatform.iOS: _InstantTransitions(),
    }),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      elevation: 0,
      modalElevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: p.divider),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(RohabShape.radius)),
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RohabShape.card),
        side: BorderSide.none,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.accent,
        minimumSize: const Size.fromHeight(RohabSize.primaryButtonHeight),
        side: BorderSide(color: p.accent, width: RohabShape.strongBorder),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: text.labelLarge,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(p.surface),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? p.accent : p.secondary),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        disabledBackgroundColor: p.divider,
        disabledForegroundColor: p.secondary,
        minimumSize: const Size.fromHeight(RohabSize.primaryButtonHeight),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.accent,
        minimumSize:
            const Size(RohabSize.touchTarget, RohabSize.touchTarget),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: text.labelLarge,
      ),
    ),
    extensions: [AppColors(p)],
  );
}

class _InstantTransitions extends PageTransitionsBuilder {
  const _InstantTransitions();

  @override
  Widget buildTransitions<T>(
          PageRoute<T> route,
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child) =>
      child;
}
