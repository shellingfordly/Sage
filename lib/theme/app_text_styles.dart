import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_styles.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle pageTitle(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium!.copyWith(
      color: context.colors.textPrimary,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    );
  }

  static TextStyle pageSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: context.colors.textSecondary,
      letterSpacing: 0,
    );
  }

  static TextStyle sectionTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      color: context.colors.textPrimary,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    );
  }

  static TextStyle bodyStrong(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
      color: context.colors.textPrimary,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    );
  }

  static TextStyle bodyMuted(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
      color: context.colors.textSecondary,
      letterSpacing: 0,
    );
  }

  static TextStyle labelMuted(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
      color: context.colors.textSecondary,
      letterSpacing: 0,
    );
  }

  static TextStyle tileValue(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      color: context.colors.textPrimary,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    );
  }

  static TextStyle amount(BuildContext context, Color color) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
      color: color,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    );
  }

  static TextStyle cardLabel(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: AppDecorations.strongSurfaceForegroundMuted(context),
      letterSpacing: 0,
    );
  }

  static TextStyle cardDisplay(BuildContext context) {
    return Theme.of(context).textTheme.displaySmall!.copyWith(
      color: AppDecorations.strongSurfaceForeground(context),
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    );
  }

  static TextStyle cardPositive(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: AppDecorations.strongSurfaceAccent(context),
      letterSpacing: 0,
    );
  }

  static TextStyle chip(BuildContext context, {required bool selected}) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
      color: selected ? context.colors.onStrong : context.colors.textBody,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    );
  }
}
