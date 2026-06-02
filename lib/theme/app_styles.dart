import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppRadii {
  const AppRadii._();

  static const card = BorderRadius.all(Radius.circular(8));
}

class AppSpacing {
  const AppSpacing._();

  static const page = EdgeInsets.fromLTRB(20, 16, 20, 24);
}

class AppDecorations {
  const AppDecorations._();

  static BoxDecoration surface(BuildContext context) {
    return BoxDecoration(
      color: context.colors.surface,
      borderRadius: AppRadii.card,
      border: Border.all(color: context.colors.surfaceBorder),
    );
  }

  static BoxDecoration strongSurface(BuildContext context) {
    final colors = context.colors;

    if (colors.isPureBlackTheme) {
      return BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: colors.surfaceBorder.withValues(alpha: 0.65),
        ),
      );
    }

    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    if (isLightTheme) {
      final gradientStart = Color.alphaBlend(
        colors.primary.withValues(alpha: 0.10),
        colors.surface,
      );
      final gradientEnd = Color.alphaBlend(
        colors.primary.withValues(alpha: 0.50),
        colors.surface,
      );

      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
      );
    }

    final leadingTint = 0.18;
    final trailingTint = 0.06;
    final borderAlpha = 0.35;
    final leading = Color.alphaBlend(
      colors.primary.withValues(alpha: leadingTint),
      colors.strongSurface,
    );
    final trailing = Color.alphaBlend(
      colors.primary.withValues(alpha: trailingTint),
      colors.strongSurface,
    );

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [leading, trailing],
      ),
      borderRadius: AppRadii.card,
      border: Border.all(color: colors.surfaceBorder.withValues(alpha: borderAlpha)),
    );
  }

  /// 强调卡片在浅色 / 深色模式下使用不同的前景色。
  static bool usesLightStrongSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light &&
        !context.colors.isPureBlackTheme;
  }

  static Color strongSurfaceForeground(BuildContext context) {
    final colors = context.colors;
    return usesLightStrongSurface(context) ? colors.textPrimary : colors.onStrong;
  }

  static Color strongSurfaceForegroundMuted(BuildContext context) {
    final colors = context.colors;
    return usesLightStrongSurface(context)
        ? colors.textSecondary
        : colors.onStrongMuted;
  }

  static Color strongSurfaceAccent(BuildContext context) {
    final colors = context.colors;
    return usesLightStrongSurface(context) ? colors.primary : colors.positiveText;
  }

  static Color strongSurfaceIconBackground(BuildContext context) {
    final colors = context.colors;
    return usesLightStrongSurface(context)
        ? colors.primarySoft
        : colors.overlayOnStrong;
  }

  static Color strongSurfaceIconForeground(BuildContext context) {
    final colors = context.colors;
    return usesLightStrongSurface(context) ? colors.primary : colors.onStrong;
  }

  static BoxDecoration softFill(BuildContext context) {
    return BoxDecoration(
      color: context.colors.softFill,
      borderRadius: AppRadii.card,
    );
  }

  static BoxDecoration primaryFill(BuildContext context) {
    return BoxDecoration(
      color: context.colors.primary,
      borderRadius: AppRadii.card,
    );
  }
}
