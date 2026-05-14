import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light =>
      _buildTheme(brightness: Brightness.light, colors: AppPalette.light);

  static ThemeData get dark =>
      _buildTheme(brightness: Brightness.dark, colors: AppPalette.dark);

  static ThemeData _buildTheme({
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
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: colors.surface,
        indicatorColor: colors.navigationIndicator,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colors.primary : colors.textSecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? colors.primary : colors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
