import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
class PreferencesService {
  static const _keyNotifications = 'notifications_enabled';
  static const _keyDarkMode = 'dark_mode_enabled';
  static const _keyPrimaryColor = 'primary_color';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // الإشعارات
  bool get notificationsEnabled => _prefs.getBool(_keyNotifications) ?? true;
  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(_keyNotifications, value);

  // الوضع الليلي
  bool get darkModeEnabled => _prefs.getBool(_keyDarkMode) ?? false;
  Future<void> setDarkModeEnabled(bool value) =>
      _prefs.setBool(_keyDarkMode, value);

  // لون التطبيق الأساسي
  int get primaryColorValue => _prefs.getInt(_keyPrimaryColor) ?? Colors.blue.value;
  Future<void> setPrimaryColor(Color color) =>
      _prefs.setInt(_keyPrimaryColor, color.value);
}