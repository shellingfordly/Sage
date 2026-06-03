import 'package:flutter/material.dart';

/// 应用字号档位：小 / 中 / 大。
enum AppFontScale {
  small('小', 0.88),
  medium('中', 1.0),
  large('大', 1.12);

  const AppFontScale(this.label, this.factor);

  final String label;
  final double factor;

  static AppFontScale? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    for (final scale in AppFontScale.values) {
      if (scale.name == raw) {
        return scale;
      }
    }
    return null;
  }
}

/// 以「中」为基准的字号刻度，各档位按比例缩放。
class AppTypography {
  const AppTypography._();

  static const double displaySmall = 26;
  static const double headlineMedium = 20;
  static const double titleLarge = 16;
  static const double titleMedium = 14;
  static const double bodyLarge = 14;
  static const double bodyMedium = 13;
  static const double bodySmall = 12;
  static const double labelLarge = 13;
  static const double labelSmall = 11;

  static double scaled(AppFontScale scale, double base) =>
      base * scale.factor;

  static TextTheme buildTextTheme(AppFontScale scale) {
    double s(double base) => scaled(scale, base);

    TextStyle style(double size, {FontWeight weight = FontWeight.w400}) {
      return TextStyle(
        fontSize: s(size),
        fontWeight: weight,
        letterSpacing: 0,
        height: 1.35,
      );
    }

    return TextTheme(
      displaySmall: style(displaySmall, weight: FontWeight.w700),
      headlineMedium: style(headlineMedium, weight: FontWeight.w700),
      titleLarge: style(titleLarge, weight: FontWeight.w700),
      titleMedium: style(titleMedium, weight: FontWeight.w700),
      bodyLarge: style(bodyLarge, weight: FontWeight.w600),
      bodyMedium: style(bodyMedium),
      bodySmall: style(bodySmall),
      labelLarge: style(labelLarge, weight: FontWeight.w600),
      labelSmall: style(labelSmall, weight: FontWeight.w500),
    );
  }

  static double buttonHeight(AppFontScale scale) {
    return switch (scale) {
      AppFontScale.small => 32,
      AppFontScale.medium => 34,
      AppFontScale.large => 38,
    };
  }

  static EdgeInsets buttonPadding(AppFontScale scale) {
    final horizontal = scaled(scale, 12);
    final vertical = scaled(scale, 7);
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  static double buttonIconSize(AppFontScale scale) => scaled(scale, 16);

  static double compactControlHeight(AppFontScale scale) => scaled(scale, 32);

  static EdgeInsets compactControlPadding(AppFontScale scale) {
    return EdgeInsets.symmetric(
      horizontal: scaled(scale, 12),
      vertical: scaled(scale, 7),
    );
  }

  static EdgeInsets compactFooterPadding(AppFontScale scale) {
    return EdgeInsets.symmetric(
      horizontal: scaled(scale, 12),
      vertical: scaled(scale, 8),
    );
  }

  static double compactIconSize(AppFontScale scale) => scaled(scale, 15);

  static double compactIconSizeLarge(AppFontScale scale) => scaled(scale, 17);

  static double compactGap(AppFontScale scale) => scaled(scale, 6);

  static double presetItemStride(AppFontScale scale) => scaled(scale, 72);
}
