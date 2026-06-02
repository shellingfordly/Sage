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
    this.flatStrongSurface = false,
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
  final bool flatStrongSurface;

  /// 纯黑主题用固定色值标识，不依赖 [flatStrongSurface] 字段（热重载期间可能为空）。
  bool get isPureBlackTheme =>
      pageBackground.toARGB32() == 0xFF000000 &&
      surface.toARGB32() == 0xFF050505;

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

  /// 纯白背景，中性灰阶 accent，不带青色调。
  static const pureWhite = AppPalette(
    primary: Color(0xFF2B2B2B),
    primarySoft: Color(0xFFF2F2F2),
    danger: Color(0xFFD86444),
    info: Color(0xFF5C5C5C),
    pageBackground: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    surfaceBorder: Color(0xFFE8E8E8),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF737373),
    textBody: Color(0xFF404040),
    strongSurface: Color(0xFF1A1A1A),
    onStrong: Color(0xFFFFFFFF),
    onStrongMuted: Color(0xFFB0B0B0),
    positiveText: Color(0xFF525252),
    softFill: Color(0xFFF5F5F5),
    divider: Color(0xFFEFEFEF),
    navigationIndicator: Color(0xFFEBEBEB),
    chevron: Color(0xFFADADAD),
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

  /// OLED 纯黑背景，模块仅用极浅灰阶区分层级，不带色相。
  static const pureBlack = AppPalette(
    primary: Color(0xFF7DD3C0),
    primarySoft: Color(0xFF0C0C0C),
    danger: Color(0xFFFF9274),
    info: Color(0xFF8DBBEA),
    pageBackground: Color(0xFF000000),
    surface: Color(0xFF050505),
    surfaceBorder: Color(0xFF121212),
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFF9E9E9E),
    textBody: Color(0xFFD4D4D4),
    strongSurface: Color(0xFF000000),
    onStrong: Color(0xFFFFFFFF),
    onStrongMuted: Color(0xFFAAAAAA),
    positiveText: Color(0xFF7DD3C0),
    softFill: Color(0xFF080808),
    divider: Color(0xFF0A0A0A),
    navigationIndicator: Color(0xFF101010),
    chevron: Color(0xFF555555),
    overlayOnStrong: Color(0x14FFFFFF),
    flatStrongSurface: true,
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
    bool? flatStrongSurface,
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
      flatStrongSurface: flatStrongSurface ?? this.flatStrongSurface,
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
      flatStrongSurface: t < 0.5
          ? flatStrongSurface
          : other.flatStrongSurface,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get colors => Theme.of(this).extension<AppPalette>()!;
}
