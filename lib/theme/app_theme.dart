import 'package:material_ui/material_ui.dart';

import '../widgets/skeuo.dart';
import 'app_colors.dart';
import 'tokens.dart';

export 'app_colors.dart';
export 'tokens.dart';

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.light
      ? RohabPalette.light
      : RohabPalette.dark;

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
    bodyLarge: TextStyle(fontSize: RohabType.body, height: 1.4, color: p.text),
    bodyMedium: TextStyle(fontSize: RohabType.body, height: 1.4, color: p.text),
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
    // The linen shows through (see RohabApp's builder).
    scaffoldBackgroundColor: const Color(0x00000000),
    dividerTheme: DividerThemeData(
      color: p.divider,
      thickness: RohabShape.border,
      space: 1,
    ),
    // Plain ripple, not the Material 3 sparkle.
    splashFactory: InkRipple.splashFactory,
    // Screens change instantly: no fades or slides.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _InstantTransitions(),
        TargetPlatform.iOS: _InstantTransitions(),
      },
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      elevation: 0,
      modalElevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: p.divider),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(RohabShape.radius),
        ),
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
    // Secondary actions are silver raised buttons: they look like buttons,
    // not like loose blue words.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: raised(
        OutlinedButton.styleFrom(
          foregroundColor: p.accent,
          backgroundColor: p.silver,
          disabledBackgroundColor: p.disabledFill,
          disabledForegroundColor: p.disabledText,
          minimumSize: const Size.fromHeight(RohabSize.primaryButtonHeight),
          side: BorderSide(color: p.silverEdge, width: RohabShape.border),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.labelLarge,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(p.surface),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.accent : p.secondary,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: raised(
        FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          disabledBackgroundColor: p.disabledFill,
          disabledForegroundColor: p.disabledText,
          minimumSize: const Size.fromHeight(RohabSize.primaryButtonHeight),
          side: BorderSide(
            color: Color.lerp(p.accent, const Color(0xFF000000), 0.45)!,
            width: RohabShape.border,
          ),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.labelLarge,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: raised(
        TextButton.styleFrom(
          foregroundColor: p.accent,
          backgroundColor: p.silver,
          disabledBackgroundColor: p.disabledFill,
          disabledForegroundColor: p.disabledText,
          minimumSize: const Size(RohabSize.touchTarget, RohabSize.touchTarget),
          side: BorderSide(color: p.silverEdge, width: RohabShape.border),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.labelLarge,
        ),
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
    Widget child,
  ) => child;
}
