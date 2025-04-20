import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    _saveThemeMode();
    notifyListeners();
  }

  Future<void> _loadThemeMode() async {
    final box = await Hive.openBox('appState');
    final isDark = box.get('isDarkMode', defaultValue: false);
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> _saveThemeMode() async {
    final box = await Hive.openBox('appState');
    await box.put('isDarkMode', _themeMode == ThemeMode.dark);
  }
}
