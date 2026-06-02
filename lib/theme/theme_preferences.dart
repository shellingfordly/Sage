import 'package:shared_preferences/shared_preferences.dart';

import 'theme_controller.dart';

class ThemePreferences {
  ThemePreferences({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const modeKey = 'theme_mode_preference_v1';
  static const colorFamilyKey = 'theme_color_family_v1';

  final SharedPreferencesAsync _preferences;

  Future<ThemePreferencesSnapshot?> load() async {
    final modeName = await _preferences.getString(modeKey);
    final familyName = await _preferences.getString(colorFamilyKey);
    if (modeName == null && familyName == null) {
      return null;
    }

    return ThemePreferencesSnapshot(
      mode: _parseMode(modeName) ?? ThemeModePreference.light,
      colorFamily: _parseColorFamily(familyName) ?? AppColorFamily.white,
    );
  }

  Future<void> save({
    required ThemeModePreference mode,
    required AppColorFamily colorFamily,
  }) async {
    await _preferences.setString(modeKey, mode.name);
    await _preferences.setString(colorFamilyKey, colorFamily.name);
  }

  static ThemeModePreference? _parseMode(String? raw) {
    if (raw == null) {
      return null;
    }
    for (final mode in ThemeModePreference.values) {
      if (mode.name == raw) {
        return mode;
      }
    }
    return null;
  }

  static AppColorFamily? _parseColorFamily(String? raw) {
    if (raw == null) {
      return null;
    }
    for (final family in AppColorFamily.values) {
      if (family.name == raw) {
        return family;
      }
    }
    return null;
  }
}

class ThemePreferencesSnapshot {
  const ThemePreferencesSnapshot({
    required this.mode,
    required this.colorFamily,
  });

  final ThemeModePreference mode;
  final AppColorFamily colorFamily;
}
