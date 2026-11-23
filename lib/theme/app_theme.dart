import 'package:material_ui/material_ui.dart';

import '../widgets/surfaces.dart';
import 'app_colors.dart';
import 'tokens.dart';

export 'app_colors.dart';
export 'tokens.dart';

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.light
      ? RohabPalette.light
      : RohabPalette.dark;

  // Two weights only (regular and bold). Hierarchy by size and weight.
  final text = TextTheme(
    displayLarge: TextStyle(
      fontSize: RohabType.display,
      height: 1.0,
      fontWeight: FontWeight.w700,
      color: p.text,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
    headlineMedium: TextStyle(
      fontSize: RohabType.title,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: p.text,
    ),
    // Section headings.
    headlineSmall: TextStyle(
      fontSize: RohabType.heading,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: p.text,
    ),
    // Single instruction on a calibration step.
    titleLarge: TextStyle(
      fontSize: RohabType.title,
      height: 1.25,
      fontWeight: FontWeight.w400,
      color: p.text,
    ),
    bodyLarge: TextStyle(fontSize: RohabType.body, height: 1.4, color: p.text),
    bodyMedium: TextStyle(fontSize: RohabType.body, height: 1.4, color: p.text),
    labelLarge: TextStyle(
      fontSize: RohabType.body,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: p.text,
    ),
    labelMedium: TextStyle(
      fontSize: RohabType.label,
      height: 1.3,
      fontWeight: FontWeight.w400,
      color: p.secondary,
    ),
  ).apply(fontFamily: RohabTokens.fontFamily);

  final radius = BorderRadius.circular(RohabShape.radius);
  final shape = RoundedRectangleBorder(borderRadius: radius);
  final darkAccent = Color.lerp(p.accent, const Color(0xFF000000), 0.4)!;

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
    outline: p.controlEdge,
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
      color: p.divider,
      thickness: RohabShape.border,
      space: 1,
    ),
    splashFactory: NoSplash.splashFactory,
    // Screens change instantly: no fades or slides.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _InstantTransitions(),
        TargetPlatform.iOS: _InstantTransitions(),
      },
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    focusColor: p.focus.withValues(alpha: 0.4),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      elevation: 0,
      modalElevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: p.divider, width: RohabShape.strongBorder),
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
        side: BorderSide(color: p.divider, width: RohabShape.border),
      ),
    ),
    // Secondary actions: white buttons with a dark edge and bold blue label.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: solidButton(
        OutlinedButton.styleFrom(
          foregroundColor: p.accent,
          backgroundColor: p.controlFill,
          disabledBackgroundColor: p.disabledFill,
          disabledForegroundColor: p.disabledText,
          minimumSize: const Size.fromHeight(RohabSize.primaryButtonHeight),
          shape: shape,
          textStyle: text.labelLarge,
        ),
        edge: p.controlEdge,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(p.surface),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.accent : p.secondary,
      ),
      trackOutlineColor: WidgetStatePropertyAll(p.controlEdge),
    ),
    // Primary action: solid blue block.
    filledButtonTheme: FilledButtonThemeData(
      style: solidButton(
        FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          disabledBackgroundColor: p.disabledFill,
          disabledForegroundColor: p.disabledText,
          minimumSize: const Size.fromHeight(RohabSize.primaryButtonHeight),
          shape: shape,
          textStyle: text.labelLarge,
        ),
        edge: darkAccent,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: solidButton(
        TextButton.styleFrom(
          foregroundColor: p.accent,
          backgroundColor: p.controlFill,
          disabledBackgroundColor: p.disabledFill,
          disabledForegroundColor: p.disabledText,
          minimumSize: const Size(RohabSize.touchTarget, RohabSize.touchTarget),
          shape: shape,
          textStyle: text.labelLarge,
        ),
        edge: p.controlEdge,
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
