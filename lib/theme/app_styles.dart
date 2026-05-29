import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppRadii {
  const AppRadii._();

  static const card = BorderRadius.all(Radius.circular(8));
  static const progress = BorderRadius.all(Radius.circular(4));
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
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final leadingTint = isLightTheme ? 0.52 : 0.18;
    final trailingTint = isLightTheme ? 0.34 : 0.06;
    final borderAlpha = isLightTheme ? 0.5 : 0.35;
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
