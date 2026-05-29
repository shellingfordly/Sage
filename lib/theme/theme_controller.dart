import 'package:flutter/material.dart';

import 'app_colors.dart';

final themeController = ThemeController();

class AppThemeOption {
  const AppThemeOption({
    required this.id,
    required this.name,
    required this.brightness,
    required this.palette,
    required this.previewColor,
  });

  final String id;
  final String name;
  final Brightness brightness;
  final AppPalette palette;
  final Color previewColor;
}

class ThemeController extends ValueNotifier<AppThemeOption> {
  ThemeController() : super(_defaultTheme);

  static const _defaultThemeId = 'black';
  static final _defaultTheme = themes.firstWhere(
    (option) => option.id == _defaultThemeId,
  );

  static final List<AppThemeOption> themes = [
    const AppThemeOption(
      id: 'black',
      name: '黑色',
      brightness: Brightness.dark,
      palette: AppPalette.dark,
      previewColor: Color(0xFF1A211F),
    ),
    const AppThemeOption(
      id: 'white',
      name: '白色',
      brightness: Brightness.light,
      palette: AppPalette.light,
      previewColor: Color(0xFFFFFFFF),
    ),
    AppThemeOption(
      id: 'blue',
      name: '蓝色',
      brightness: Brightness.light,
      palette: _paletteFromSeed(
        seed: const Color(0xFF3B82F6),
        brightness: Brightness.light,
      ),
      previewColor: const Color(0xFF3B82F6),
    ),
    AppThemeOption(
      id: 'pink',
      name: '粉色',
      brightness: Brightness.light,
      palette: _paletteFromSeed(
        seed: const Color(0xFFEC4899),
        brightness: Brightness.light,
      ),
      previewColor: const Color(0xFFEC4899),
    ),
    AppThemeOption(
      id: 'yellow',
      name: '黄色',
      brightness: Brightness.light,
      palette: _paletteFromSeed(
        seed: const Color(0xFFF59E0B),
        brightness: Brightness.light,
      ),
      previewColor: const Color(0xFFF59E0B),
    ),
    AppThemeOption(
      id: 'green',
      name: '绿色',
      brightness: Brightness.light,
      palette: _paletteFromSeed(
        seed: const Color(0xFF22C55E),
        brightness: Brightness.light,
      ),
      previewColor: const Color(0xFF22C55E),
    ),
    AppThemeOption(
      id: 'red',
      name: '红色',
      brightness: Brightness.light,
      palette: _paletteFromSeed(
        seed: const Color(0xFFEF4444),
        brightness: Brightness.light,
      ),
      previewColor: const Color(0xFFEF4444),
    ),
  ];

  List<AppThemeOption> get availableThemes => themes;

  bool get isDarkMode => value.brightness == Brightness.dark;

  void setTheme(AppThemeOption option) {
    if (option.id == value.id) {
      return;
    }
    value = option;
  }

  void setThemeById(String themeId) {
    for (final option in themes) {
      if (option.id == themeId) {
        setTheme(option);
        return;
      }
    }
  }

  void setDarkMode(bool enabled) {
    setThemeById(enabled ? 'black' : 'white');
  }
}

AppPalette _paletteFromSeed({
  required Color seed,
  required Brightness brightness,
}) {
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  final isDark = brightness == Brightness.dark;
  final base = isDark ? AppPalette.dark : AppPalette.light;
  final softAlpha = isDark ? 0.38 : 0.22;
  final navigationAlpha = isDark ? 0.42 : 0.28;

  return base.copyWith(
    primary: scheme.primary,
    primarySoft: scheme.primary.withValues(alpha: softAlpha),
    info: scheme.secondary,
    navigationIndicator: scheme.primary.withValues(alpha: navigationAlpha),
    chevron: Color.lerp(base.chevron, scheme.primary, 0.25),
  );
}
