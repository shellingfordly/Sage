import 'package:flutter/material.dart';

final themeController = ThemeController();

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.light);

  bool get isDarkMode => value == ThemeMode.dark;

  void setDarkMode(bool enabled) {
    value = enabled ? ThemeMode.dark : ThemeMode.light;
  }
}
