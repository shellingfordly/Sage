import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.primarySoft,
    required this.danger,
    required this.info,
    required this.pageBackground,
    required this.surface,
    required this.surfaceBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textBody,
    required this.strongSurface,
    required this.onStrong,
    required this.onStrongMuted,
    required this.positiveText,
    required this.softFill,
    required this.divider,
    required this.navigationIndicator,
    required this.chevron,
    required this.overlayOnStrong,
  });

  final Color primary;
  final Color primarySoft;
  final Color danger;
  final Color info;
  final Color pageBackground;
  final Color surface;
  final Color surfaceBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textBody;
  final Color strongSurface;
  final Color onStrong;
  final Color onStrongMuted;
  final Color positiveText;
  final Color softFill;
  final Color divider;
  final Color navigationIndicator;
  final Color chevron;
  final Color overlayOnStrong;

  static const light = AppPalette(
    primary: Color(0xFF2F8F83),
    primarySoft: Color(0xFFE1F2EE),
    danger: Color(0xFFD86444),
    info: Color(0xFF4D78A8),
    pageBackground: Color(0xFFF7F5F0),
    surface: Color(0xFFFFFFFF),
    surfaceBorder: Color(0xFFE8E1D7),
    textPrimary: Color(0xFF1F2523),
    textSecondary: Color(0xFF747C78),
    textBody: Color(0xFF3C4541),
    strongSurface: Color(0xFF1F2523),
    onStrong: Color(0xFFFFFFFF),
    onStrongMuted: Color(0xFFC7D0CB),
    positiveText: Color(0xFF9DD7CE),
    softFill: Color(0xFFF2EFE8),
    divider: Color(0xFFF0ECE4),
    navigationIndicator: Color(0xFFE1F2EE),
    chevron: Color(0xFFB4B8B5),
    overlayOnStrong: Color(0x18FFFFFF),
  );

  static const dark = AppPalette(
    primary: Color(0xFF6EC9BA),
    primarySoft: Color(0xFF1D4841),
    danger: Color(0xFFFF9274),
    info: Color(0xFF8DBBEA),
    pageBackground: Color(0xFF101513),
    surface: Color(0xFF1A211F),
    surfaceBorder: Color(0xFF2E3834),
    textPrimary: Color(0xFFF4F0E8),
    textSecondary: Color(0xFFAEB8B3),
    textBody: Color(0xFFD8E0DC),
    strongSurface: Color(0xFF0B0F0E),
    onStrong: Color(0xFFFFFFFF),
    onStrongMuted: Color(0xFFC5D1CB),
    positiveText: Color(0xFF8BE1D5),
    softFill: Color(0xFF26312D),
    divider: Color(0xFF2A3531),
    navigationIndicator: Color(0xFF204B44),
    chevron: Color(0xFF77827D),
    overlayOnStrong: Color(0x24FFFFFF),
  );

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primarySoft,
    Color? danger,
    Color? info,
    Color? pageBackground,
    Color? surface,
    Color? surfaceBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textBody,
    Color? strongSurface,
    Color? onStrong,
    Color? onStrongMuted,
    Color? positiveText,
    Color? softFill,
    Color? divider,
    Color? navigationIndicator,
    Color? chevron,
    Color? overlayOnStrong,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      pageBackground: pageBackground ?? this.pageBackground,
      surface: surface ?? this.surface,
      surfaceBorder: surfaceBorder ?? this.surfaceBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textBody: textBody ?? this.textBody,
      strongSurface: strongSurface ?? this.strongSurface,
      onStrong: onStrong ?? this.onStrong,
      onStrongMuted: onStrongMuted ?? this.onStrongMuted,
      positiveText: positiveText ?? this.positiveText,
      softFill: softFill ?? this.softFill,
      divider: divider ?? this.divider,
      navigationIndicator: navigationIndicator ?? this.navigationIndicator,
      chevron: chevron ?? this.chevron,
      overlayOnStrong: overlayOnStrong ?? this.overlayOnStrong,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }

    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      strongSurface: Color.lerp(strongSurface, other.strongSurface, t)!,
      onStrong: Color.lerp(onStrong, other.onStrong, t)!,
      onStrongMuted: Color.lerp(onStrongMuted, other.onStrongMuted, t)!,
      positiveText: Color.lerp(positiveText, other.positiveText, t)!,
      softFill: Color.lerp(softFill, other.softFill, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      navigationIndicator: Color.lerp(
        navigationIndicator,
        other.navigationIndicator,
        t,
      )!,
      chevron: Color.lerp(chevron, other.chevron, t)!,
      overlayOnStrong: Color.lerp(overlayOnStrong, other.overlayOnStrong, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get colors => Theme.of(this).extension<AppPalette>()!;
}
