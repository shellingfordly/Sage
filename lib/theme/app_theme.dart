import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData fromPalette({
    required Brightness brightness,
    required AppPalette colors,
  }) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Roboto',
    );
    final textTheme = baseTheme.textTheme.apply(
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    );

    return baseTheme.copyWith(
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: colors.primary,
            brightness: brightness,
          ).copyWith(
            primary: colors.primary,
            surface: colors.surface,
            onSurface: colors.textPrimary,
            error: colors.danger,
          ),
      scaffoldBackgroundColor: colors.pageBackground,
      textTheme: textTheme,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: colors.pageBackground,
        foregroundColor: colors.textPrimary,
        iconTheme: IconThemeData(color: colors.textPrimary),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
