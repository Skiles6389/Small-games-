import 'package:material_ui/material_ui.dart';

/// The "calm dark mode" palette shared by every game.
///
/// Change a color here and every game picks it up. Widgets read it with
/// `CalmColors.of(context)`.
@immutable
class CalmColors extends ThemeExtension<CalmColors> {
  const CalmColors({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.gridLine,
    required this.boxLine,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.error,
  });

  /// Deep navy page background.
  final Color background;

  /// Cards, the board and other raised areas.
  final Color surface;

  /// Buttons and pressed / highlighted areas.
  final Color surfaceHigh;

  /// Thin lines (e.g. between Sudoku cells).
  final Color gridLine;

  /// Thicker lines (e.g. around Sudoku 3x3 boxes).
  final Color boxLine;

  /// Main soft off-white text.
  final Color text;

  /// Secondary text.
  final Color textMuted;

  /// The one gentle highlight color (selection, player digits, buttons).
  final Color accent;

  /// Muted coral used for mistakes.
  final Color error;

  static const calm = CalmColors(
    background: Color(0xFF0D1626),
    surface: Color(0xFF142034),
    surfaceHigh: Color(0xFF1C2B45),
    gridLine: Color(0xFF26375A),
    boxLine: Color(0xFF4B6290),
    text: Color(0xFFECE8E1),
    textMuted: Color(0xFF8D9AB4),
    accent: Color(0xFF7FCFC4),
    error: Color(0xFFE8918C),
  );

  static CalmColors of(BuildContext context) =>
      Theme.of(context).extension<CalmColors>() ?? calm;

  @override
  CalmColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? gridLine,
    Color? boxLine,
    Color? text,
    Color? textMuted,
    Color? accent,
    Color? error,
  }) => CalmColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceHigh: surfaceHigh ?? this.surfaceHigh,
    gridLine: gridLine ?? this.gridLine,
    boxLine: boxLine ?? this.boxLine,
    text: text ?? this.text,
    textMuted: textMuted ?? this.textMuted,
    accent: accent ?? this.accent,
    error: error ?? this.error,
  );

  @override
  CalmColors lerp(CalmColors? other, double t) {
    if (other == null) return this;
    return CalmColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
      boxLine: Color.lerp(boxLine, other.boxLine, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

/// Builds the app-wide [ThemeData] from [CalmColors].
class CalmTheme {
  const CalmTheme._();

  static ThemeData build([CalmColors c = CalmColors.calm]) {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: c.accent,
      onPrimary: c.background,
      primaryContainer: c.surfaceHigh,
      onPrimaryContainer: c.text,
      secondary: c.accent,
      onSecondary: c.background,
      secondaryContainer: c.surfaceHigh,
      onSecondaryContainer: c.text,
      error: c.error,
      onError: c.background,
      surface: c.surface,
      onSurface: c.text,
      surfaceContainerHighest: c.surfaceHigh,
      onSurfaceVariant: c.textMuted,
      outline: c.gridLine,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.dark,
    );

    final text = base.textTheme.apply(bodyColor: c.text, displayColor: c.text);

    return base.copyWith(
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      extensions: [c],
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(
          fontWeight: FontWeight.w300,
          letterSpacing: 0.5,
        ),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.background,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: c.gridLine),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.background : c.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.surfaceHigh,
        ),
      ),
      dividerTheme: DividerThemeData(color: c.gridLine, thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.surfaceHigh,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceHigh,
        contentTextStyle: TextStyle(color: c.text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
