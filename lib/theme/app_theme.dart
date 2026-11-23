import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'tokens.dart';

export 'app_colors.dart';
export 'tokens.dart';

/// Builds the one Rohab theme: light, square, flat, bundled fonts.
ThemeData buildTheme([Brightness brightness = Brightness.light]) {
  const p = RohabPalette.light;

  const text = TextTheme(
    displayLarge: RohabType.metricXL,
    displayMedium: RohabType.metricL,
    displaySmall: RohabType.metricS,
    headlineMedium: RohabType.title,
    headlineSmall: RohabType.rowTitle,
    titleLarge: RohabType.body,
    titleMedium: RohabType.rowTitle,
    titleSmall: RohabType.rowSub,
    bodyLarge: RohabType.body,
    bodyMedium: RohabType.body,
    bodySmall: RohabType.rowSub,
    labelLarge: RohabType.button,
    labelMedium: RohabType.rowSub,
    labelSmall: RohabType.sectionLabel,
  );

  final control = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(RohabShape.control),
  );

  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: p.accent,
    onPrimary: p.onAccent,
    secondary: p.accent,
    onSecondary: p.onAccent,
    error: p.danger,
    onError: p.onDanger,
    surface: p.background,
    onSurface: p.text,
    surfaceTint: RohabPalette.clear,
    outline: p.controlEdge,
    outlineVariant: p.divider,
  );

  ButtonStyle base(ButtonStyle s) => s.copyWith(
    elevation: const WidgetStatePropertyAll(0),
    shadowColor: const WidgetStatePropertyAll(RohabPalette.clear),
    surfaceTintColor: const WidgetStatePropertyAll(RohabPalette.clear),
    splashFactory: NoSplash.splashFactory,
    shape: WidgetStatePropertyAll(control),
    side: WidgetStateProperty.resolveWith((s) {
      if (s.contains(WidgetState.focused)) {
        return BorderSide(color: p.focus, width: RohabShape.focusRing);
      }
      return null;
    }),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    fontFamily: RohabFonts.body,
    textTheme: text,
    scaffoldBackgroundColor: p.background,
    dividerTheme: DividerThemeData(
      color: p.divider,
      thickness: RohabShape.border,
      space: 1,
    ),
    splashFactory: NoSplash.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _InstantTransitions(),
        TargetPlatform.iOS: _InstantTransitions(),
      },
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    focusColor: p.focus.withValues(alpha: 0.4),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          base(
            FilledButton.styleFrom(
              backgroundColor: p.accent,
              foregroundColor: p.onAccent,
              disabledBackgroundColor: p.disabledFill,
              disabledForegroundColor: p.disabledText,
              minimumSize: const Size.fromHeight(RohabSize.primaryButtonHeight),
              textStyle: RohabType.button,
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.pressed)
                  ? p.accentPressed.withValues(alpha: 0.5)
                  : null,
            ),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base(
        OutlinedButton.styleFrom(
          foregroundColor: p.accent,
          backgroundColor: p.controlFill,
          disabledBackgroundColor: p.disabledFill,
          disabledForegroundColor: p.disabledText,
          minimumSize: const Size.fromHeight(RohabSize.primaryButtonHeight),
          side: BorderSide(color: p.controlEdge),
          textStyle: RohabType.button,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: base(
        TextButton.styleFrom(
          foregroundColor: p.accent,
          disabledForegroundColor: p.disabledText,
          minimumSize: const Size(RohabSize.touchTarget, RohabSize.touchTarget),
          textStyle: RohabType.button,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(p.surface),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.accent : p.secondary,
      ),
      trackOutlineColor: WidgetStatePropertyAll(p.controlEdge),
    ),
    extensions: const [AppColors(p)],
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
    Widget child,
  ) => child;
}
