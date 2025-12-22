import 'package:flutter/material.dart';
import '../models/user_settings.dart';
import '../services/user_settings_service.dart';
import '../utils/logger.dart';

class ThemeProvider with ChangeNotifier {
  final UserSettingsService _settingsService = UserSettingsService();
  
  ThemeMode _themeMode = ThemeMode.light;
  String? _userId;

  ThemeMode get themeMode => _themeMode;

  /// Load theme from database for the current user
  Future<void> loadThemeFromDatabase(String userId) async {
    try {
      _userId = userId;
      final settings = await _settingsService.getUserSettings(userId);
      
      _themeMode = _getThemeModeFromString(settings.themeMode);
      notifyListeners();
      
      Logger.info('Loaded theme: ${settings.themeMode} for user $userId');
    } catch (e) {
      Logger.error('Error loading theme: $e');
      _themeMode = ThemeMode.light;
      notifyListeners();
    }
  }

  /// Set theme mode and persist to database
  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    if (_userId != null) {
      try {
        final themeModeString = _getStringFromThemeMode(mode);
        await _settingsService.updateThemeMode(_userId!, themeModeString);
        Logger.info('Theme updated to: $themeModeString');
      } catch (e) {
        Logger.error('Error saving theme: $e');
      }
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    await setTheme(newMode);
  }

  /// Convert ThemeMode enum to string for database
  String _getStringFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return UserSettings.themeModeLight;
      case ThemeMode.dark:
        return UserSettings.themeModeDark;
      case ThemeMode.system:
        return UserSettings.themeModeSystem;
    }
  }

  /// Convert string from database to ThemeMode enum
  ThemeMode _getThemeModeFromString(String themeString) {
    switch (themeString) {
      case UserSettings.themeModeLight:
        return ThemeMode.light;
      case UserSettings.themeModeDark:
        return ThemeMode.dark;
      case UserSettings.themeModeSystem:
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  /// Check if current theme is dark
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Check if current theme is light
  bool get isLightMode => _themeMode == ThemeMode.light;

  /// Check if current theme follows system
  bool get isSystemMode => _themeMode == ThemeMode.system;
}
