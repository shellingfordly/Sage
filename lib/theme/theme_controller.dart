import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'theme_preferences.dart';

final themeController = ThemeController();

const _whiteAccent = Color(0xFFF5F5F5);
const _blueAccent = Color(0xFFAED6F1);
const _pinkAccent = Color(0xFFE6B0AA);
const _redAccent = Color(0xFFA93226);
const _greenAccent = Color(0xFF1E8449);
const _yellowAccent = Color(0xFFF9E79F);
const _orangeAccent = Color(0xFFFF6600);

enum ThemeModePreference {
  light('浅色'),
  dark('深色'),
  system('跟随系统');

  const ThemeModePreference(this.label);

  final String label;
}

enum AppColorFamily {
  white,
  blue,
  pink,
  red,
  green,
  yellow,
  orange,
}

class AppColorFamilyOption {
  const AppColorFamilyOption({
    required this.family,
    required this.name,
    required this.previewColor,
  });

  final AppColorFamily family;
  final String name;
  final Color previewColor;
}

class AppThemeOption {
  const AppThemeOption({
    required this.brightness,
    required this.palette,
  });

  final Brightness brightness;
  final AppPalette palette;
}

class ThemeController extends ValueNotifier<AppThemeOption>
    with WidgetsBindingObserver {
  ThemeController()
    : _modePreference = ThemeModePreference.light,
      _colorFamily = AppColorFamily.white,
      _preferences = ThemePreferences(),
      super(
        _buildTheme(
          isDarkMode: false,
          family: AppColorFamily.white,
        ),
      ) {
    WidgetsBinding.instance.addObserver(this);
  }

  ThemeModePreference _modePreference;
  AppColorFamily _colorFamily;
  final ThemePreferences _preferences;
  bool _loaded = false;

  static const List<AppColorFamilyOption> colorFamilies = [
    AppColorFamilyOption(
      family: AppColorFamily.white,
      name: '白',
      previewColor: _whiteAccent,
    ),
    AppColorFamilyOption(
      family: AppColorFamily.blue,
      name: '蓝',
      previewColor: _blueAccent,
    ),
    AppColorFamilyOption(
      family: AppColorFamily.pink,
      name: '粉',
      previewColor: _pinkAccent,
    ),
    AppColorFamilyOption(
      family: AppColorFamily.red,
      name: '红',
      previewColor: _redAccent,
    ),
    AppColorFamilyOption(
      family: AppColorFamily.green,
      name: '绿',
      previewColor: _greenAccent,
    ),
    AppColorFamilyOption(
      family: AppColorFamily.yellow,
      name: '黄',
      previewColor: _yellowAccent,
    ),
    AppColorFamilyOption(
      family: AppColorFamily.orange,
      name: '橙',
      previewColor: _orangeAccent,
    ),
  ];

  ThemeModePreference get modePreference => _modePreference;

  bool get isDarkMode => _effectiveIsDarkMode;

  AppColorFamily get colorFamily => _colorFamily;

  AppColorFamilyOption get currentColorFamilyOption {
    return colorFamilies.firstWhere((option) => option.family == _colorFamily);
  }

  Future<void> load() async {
    final snapshot = await _preferences.load();
    if (snapshot != null) {
      _modePreference = snapshot.mode;
      _colorFamily = snapshot.colorFamily;
    }
    _loaded = true;
    _applyTheme(persist: false);
  }

  void setModePreference(ThemeModePreference preference) {
    if (_modePreference == preference) {
      return;
    }
    _modePreference = preference;
    _applyTheme();
  }

  void setColorFamily(AppColorFamily family) {
    if (_colorFamily == family) {
      return;
    }
    _colorFamily = family;
    _applyTheme();
  }

  @override
  void didChangePlatformBrightness() {
    if (_modePreference == ThemeModePreference.system) {
      _applyTheme(persist: false);
    }
  }

  bool get _effectiveIsDarkMode {
    return switch (_modePreference) {
      ThemeModePreference.light => false,
      ThemeModePreference.dark => true,
      ThemeModePreference.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark,
    };
  }

  void _applyTheme({bool persist = true}) {
    value = _buildTheme(isDarkMode: _effectiveIsDarkMode, family: _colorFamily);
    if (persist && _loaded) {
      _preferences.save(mode: _modePreference, colorFamily: _colorFamily);
    }
  }

  static AppThemeOption _buildTheme({
    required bool isDarkMode,
    required AppColorFamily family,
  }) {
    return AppThemeOption(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      palette: _buildPalette(isDarkMode: isDarkMode, family: family),
    );
  }

  static AppPalette _buildPalette({
    required bool isDarkMode,
    required AppColorFamily family,
  }) {
    if (isDarkMode) {
      return switch (family) {
        AppColorFamily.white => AppPalette.pureBlack,
        AppColorFamily.blue => _darkPaletteFromAccent(_blueAccent),
        AppColorFamily.pink => _darkPaletteFromAccent(_pinkAccent),
        AppColorFamily.red => _darkPaletteFromAccent(_redAccent),
        AppColorFamily.green => _darkPaletteFromAccent(_greenAccent),
        AppColorFamily.yellow => _darkPaletteFromAccent(_yellowAccent),
        AppColorFamily.orange => _darkPaletteFromAccent(_orangeAccent),
      };
    }

    return switch (family) {
      AppColorFamily.white => AppPalette.light,
      AppColorFamily.blue => _lightPaletteFromAccent(_blueAccent),
      AppColorFamily.pink => _lightPaletteFromAccent(_pinkAccent),
      AppColorFamily.red => _lightPaletteFromAccent(_redAccent),
      AppColorFamily.green => _lightPaletteFromAccent(_greenAccent),
      AppColorFamily.yellow => _lightPaletteFromAccent(_yellowAccent),
      AppColorFamily.orange => _lightPaletteFromAccent(_orangeAccent),
    };
  }
}

AppPalette _lightPaletteFromAccent(Color seed) {
  const base = AppPalette.light;
  const softAlpha = 0.22;

  return base.copyWith(
    primary: seed,
    primarySoft: seed.withValues(alpha: softAlpha),
    info: seed,
    chevron: Color.lerp(base.chevron, seed, 0.25),
  );
}

AppPalette _darkPaletteFromAccent(Color seed) {
  const pageBackground = Color(0xFF0A0A0A);
  const surface = Color(0xFF141414);
  const surfaceBorder = Color(0xFF262626);
  const softFill = Color(0xFF1C1C1C);
  const divider = Color(0xFF222222);
  const strongSurface = Color(0xFF050505);

  return AppPalette.pureBlack.copyWith(
    primary: seed,
    primarySoft: Color.alphaBlend(
      seed.withValues(alpha: 0.38),
      surface,
    ),
    info: seed,
    pageBackground: Color.lerp(pageBackground, seed, 0.04)!,
    surface: Color.lerp(surface, seed, 0.06)!,
    surfaceBorder: Color.lerp(surfaceBorder, seed, 0.08)!,
    softFill: Color.lerp(softFill, seed, 0.06)!,
    divider: Color.lerp(divider, seed, 0.05)!,
    strongSurface: Color.lerp(strongSurface, seed, 0.03)!,
    positiveText: seed,
    chevron: Color.lerp(const Color(0xFF707070), seed, 0.22)!,
  );
}
