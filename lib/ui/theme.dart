import 'package:material_ui/material_ui.dart';

/// Design tokens. Every color in the app comes from here.
///
/// Rules: one gray, one accent (teal), red only for STOP and faults.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.gray,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.onDanger,
  });

  static const light = AppColors(
    background: Color(0xFFFAFAF9),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF1C1C1E),
    gray: Color(0xFF6B6B70),
    accent: Color(0xFF0F766E),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFDC2626),
    onDanger: Color(0xFFFFFFFF),
  );

  // Same rules in dark. Teal is lightened so it keeps contrast on a dark
  // background; it is still the only accent.
  static const dark = AppColors(
    background: Color(0xFF111113),
    surface: Color(0xFF1C1C1E),
    text: Color(0xFFF2F2F0),
    gray: Color(0xFF9A9AA0),
    accent: Color(0xFF5EC4B6),
    onAccent: Color(0xFF0B1F1D),
    danger: Color(0xFFDC2626),
    onDanger: Color(0xFFFFFFFF),
  );

  final Color background;
  final Color surface;
  final Color text;

  /// The one gray: secondary text, and (at low opacity) dividers.
  final Color gray;
  final Color accent;
  final Color onAccent;

  /// STOP and faults only.
  final Color danger;
  final Color onDanger;

  Color get divider => gray.withValues(alpha: 0.3);

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : other ?? this;
}

/// Spacing on an 8pt grid.
class Space {
  Space._();
  static const double s1 = 8;
  static const double s2 = 16;
  static const double s3 = 24;
  static const double s4 = 32;
  static const double s6 = 48;
}

/// Minimum sizes from the accessibility rules.
class Sizes {
  Sizes._();
  static const double touchTarget = 64;
  static const double stopButton = 80;
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? AppColors.light : AppColors.dark;

  // Hierarchy by size and weight only. Body 20, labels >= 16, numbers 48+.
  final text = TextTheme(
    displayLarge: TextStyle(
      fontSize: 72,
      height: 1.0,
      fontWeight: FontWeight.w600,
      letterSpacing: -1.5,
      color: c.text,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: c.text,
    ),
    titleMedium: TextStyle(
      fontSize: 22,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: c.text,
    ),
    bodyLarge: TextStyle(fontSize: 20, height: 1.4, color: c.text),
    bodyMedium: TextStyle(fontSize: 20, height: 1.4, color: c.text),
    labelLarge: TextStyle(
      fontSize: 20,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: c.text,
    ),
    labelMedium: TextStyle(
      fontSize: 16,
      height: 1.25,
      fontWeight: FontWeight.w500,
      color: c.gray,
    ),
  ).apply(fontFamily: 'Inter'); // so button styles built from it keep Inter

  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    secondary: c.accent,
    onSecondary: c.onAccent,
    error: c.danger,
    onError: c.onDanger,
    surface: c.background,
    onSurface: c.text,
    surfaceTint: Colors.transparent,
    outline: c.divider,
    outlineVariant: c.divider,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Inter',
    textTheme: text,
    scaffoldBackgroundColor: c.background,
    dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
    // Plain ripple, not the Material 3 sparkle.
    splashFactory: InkRipple.splashFactory,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        disabledBackgroundColor: c.gray.withValues(alpha: 0.2),
        disabledForegroundColor: c.gray,
        minimumSize: const Size.fromHeight(Sizes.touchTarget),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        minimumSize: const Size(Sizes.touchTarget, Sizes.touchTarget),
        textStyle: text.labelLarge,
      ),
    ),
    extensions: [c],
  );
}
