import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class AppTheme {
  static const fontFamily = 'packages/patastay_core/PlusJakartaSans';

  static ThemeData light() => _build(
        brightness: Brightness.light,
        scheme: const ColorScheme(
          brightness: Brightness.light,
          primary: PataColors.teal,
          onPrimary: PataColors.white,
          primaryContainer: PataColors.tealContainer,
          onPrimaryContainer: PataColors.tealDeep,
          secondary: PataColors.saffron,
          onSecondary: PataColors.ink,
          secondaryContainer: PataColors.saffronContainer,
          onSecondaryContainer: PataColors.saffronDeep,
          tertiary: Color(0xFF1C5BC7),
          onTertiary: PataColors.white,
          error: Color(0xFFB42318),
          onError: PataColors.white,
          errorContainer: Color(0xFFFDE3E1),
          onErrorContainer: Color(0xFF5F120C),
          surface: PataColors.white,
          onSurface: PataColors.ink,
          onSurfaceVariant: PataColors.inkMuted,
          surfaceContainerLowest: PataColors.white,
          surfaceContainerLow: PataColors.sand,
          surfaceContainer: PataColors.sand,
          surfaceContainerHigh: PataColors.sandDeep,
          surfaceContainerHighest: PataColors.sandDeep,
          outline: Color(0xFF8C867C),
          outlineVariant: PataColors.line,
          inverseSurface: PataColors.ink,
          onInverseSurface: PataColors.sand,
          inversePrimary: PataColors.tealLight,
          shadow: Color(0x1A000000),
          scrim: Color(0x66000000),
        ),
        background: PataColors.sand,
        palette: PataPalette.light,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        scheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: PataColors.tealLight,
          onPrimary: Color(0xFF00363A),
          primaryContainer: Color(0xFF12474A),
          onPrimaryContainer: PataColors.tealContainer,
          secondary: PataColors.saffron,
          onSecondary: Color(0xFF2A1C00),
          secondaryContainer: Color(0xFF4A3500),
          onSecondaryContainer: PataColors.saffronContainer,
          tertiary: Color(0xFF8DB4FF),
          onTertiary: Color(0xFF0B2A5C),
          error: Color(0xFFFF9C92),
          onError: Color(0xFF5F120C),
          errorContainer: Color(0xFF43191A),
          onErrorContainer: Color(0xFFFDE3E1),
          surface: PataColors.nightSurface,
          onSurface: PataColors.mist,
          onSurfaceVariant: PataColors.mistMuted,
          surfaceContainerLowest: PataColors.night,
          surfaceContainerLow: PataColors.night,
          surfaceContainer: PataColors.nightSurface,
          surfaceContainerHigh: PataColors.nightSurfaceHigh,
          surfaceContainerHighest: PataColors.nightSurfaceHigh,
          outline: Color(0xFF8A928E),
          outlineVariant: PataColors.nightLine,
          inverseSurface: PataColors.mist,
          onInverseSurface: PataColors.ink,
          inversePrimary: PataColors.teal,
          shadow: Color(0x66000000),
          scrim: Color(0x99000000),
        ),
        background: PataColors.night,
        palette: PataPalette.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color background,
    required PataPalette palette,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );

    final text = _textTheme(base.textTheme, scheme);
    final fieldRadius = BorderRadius.circular(Radii.md);
    const buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Radii.md)));
    const buttonSize = Size(kMinTouchTarget, 52);
    final buttonText = text.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 15);

    return base.copyWith(
      textTheme: text,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: buttonSize, shape: buttonShape, textStyle: buttonText),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
          textStyle: buttonText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.lg),
        border: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide(color: scheme.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide(color: scheme.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide(color: scheme.error, width: 2)),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
        errorMaxLines: 3,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.pill)),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        labelStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        // The selected tab uses the brand colour, not the accent.
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: Space.md,
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.gutter),
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    TextStyle? style(TextStyle? s, double size, FontWeight weight, {double? height, double spacing = 0}) =>
        s?.copyWith(fontSize: size, fontWeight: weight, height: height, letterSpacing: spacing, color: scheme.onSurface);

    return base.copyWith(
      displaySmall: style(base.displaySmall, 34, FontWeight.w800, height: 1.15, spacing: -0.8),
      headlineLarge: style(base.headlineLarge, 30, FontWeight.w800, height: 1.2, spacing: -0.6),
      headlineMedium: style(base.headlineMedium, 26, FontWeight.w800, height: 1.2, spacing: -0.4),
      headlineSmall: style(base.headlineSmall, 22, FontWeight.w700, height: 1.25, spacing: -0.2),
      titleLarge: style(base.titleLarge, 20, FontWeight.w700, height: 1.3),
      titleMedium: style(base.titleMedium, 16, FontWeight.w700, height: 1.35),
      titleSmall: style(base.titleSmall, 14, FontWeight.w700, height: 1.35),
      bodyLarge: style(base.bodyLarge, 16, FontWeight.w400, height: 1.5),
      bodyMedium: style(base.bodyMedium, 14, FontWeight.w400, height: 1.5),
      bodySmall: style(base.bodySmall, 12.5, FontWeight.w400, height: 1.45)
          ?.copyWith(color: scheme.onSurfaceVariant),
      labelLarge: style(base.labelLarge, 14, FontWeight.w600),
      labelMedium: style(base.labelMedium, 12.5, FontWeight.w600),
      labelSmall: style(base.labelSmall, 11.5, FontWeight.w600, spacing: 0.2),
    );
  }
}
