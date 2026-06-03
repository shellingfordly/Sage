import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_font_scale.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData fromPalette({
    required Brightness brightness,
    required AppPalette colors,
    AppFontScale fontScale = AppFontScale.medium,
  }) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Roboto',
    );
    final textTheme = AppTypography.buildTextTheme(fontScale).apply(
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    );
    final buttonTextStyle = textTheme.labelLarge!;
    final buttonHeight = AppTypography.buttonHeight(fontScale);
    final buttonPadding = AppTypography.buttonPadding(fontScale);
    final buttonIconSize = AppTypography.buttonIconSize(fontScale);

    ButtonStyle baseButtonStyle(OutlinedBorder shape) {
      return ButtonStyle(
        textStyle: WidgetStatePropertyAll(buttonTextStyle),
        padding: WidgetStatePropertyAll(buttonPadding),
        minimumSize: WidgetStatePropertyAll(Size(0, buttonHeight)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        iconSize: WidgetStatePropertyAll(buttonIconSize),
        shape: WidgetStatePropertyAll(shape),
      );
    }

    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
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
      filledButtonTheme: FilledButtonThemeData(
        style: baseButtonStyle(roundedShape).copyWith(
          backgroundColor: WidgetStatePropertyAll(colors.primary),
          foregroundColor: WidgetStatePropertyAll(colors.onStrong),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: baseButtonStyle(roundedShape).copyWith(
          foregroundColor: WidgetStatePropertyAll(colors.primary),
          side: WidgetStatePropertyAll(
            BorderSide(color: colors.surfaceBorder),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: baseButtonStyle(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ).copyWith(
          foregroundColor: WidgetStatePropertyAll(colors.primary),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppTypography.scaled(fontScale, 8),
              vertical: AppTypography.scaled(fontScale, 4),
            ),
          ),
        ),
      ),
    );
  }
}
