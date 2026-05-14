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
    return BoxDecoration(
      color: context.colors.strongSurface,
      borderRadius: AppRadii.card,
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
