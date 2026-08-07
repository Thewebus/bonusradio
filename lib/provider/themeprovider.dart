import 'package:myBonus/utils/constant.dart';
import 'package:flutter/material.dart';

enum AppThemeMode { auto, day, night }

class ThemeProvider with ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.auto;

  AppThemeMode get mode => _mode;

  ThemeMode get themeMode {
    switch (_mode) {
      case AppThemeMode.auto:
        return ThemeMode.system;
      case AppThemeMode.day:
        return ThemeMode.light;
      case AppThemeMode.night:
        return ThemeMode.dark;
    }
  }

  void setMode(AppThemeMode mode) {
    _mode = mode;
    Constant.themeMode = mode.name;
    notifyListeners();
  }
}

AppThemeMode appThemeModeFromString(String? value) {
  switch (value) {
    case 'day':
      return AppThemeMode.day;
    case 'night':
      return AppThemeMode.night;
    default:
      return AppThemeMode.auto;
  }
}
