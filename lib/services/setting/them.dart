import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = Colors.blue;

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;

  void setTheme({required bool darkMode, required Color primaryColor}) {
    _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
    _primaryColor = primaryColor;
    notifyListeners();
  }
}