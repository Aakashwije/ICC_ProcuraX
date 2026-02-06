import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  // Method to switch theme
  void setTheme(String theme) {
    _themeMode = theme == "Dark" ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
