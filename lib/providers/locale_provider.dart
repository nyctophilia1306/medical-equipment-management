import 'package:flutter/material.dart';
import '../models/user_settings.dart';
import '../services/auth_service.dart';
import '../services/user_settings_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('vi'); // Default to Vietnamese
  final UserSettingsService _settingsService = UserSettingsService();
  final AuthService _authService = AuthService();

  Locale get locale => _locale;

  /// Initialize locale from user settings
  Future<void> initializeLocale() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final settings = await _settingsService.getUserSettings(currentUser.id);
        // Convert 'vn' to 'vi' for Locale (UserSettings uses 'vn', Locale uses 'vi')
        final languageCode = settings.language == UserSettings.languageEnglish
            ? 'en'
            : 'vi';
        _locale = Locale(languageCode);
        notifyListeners();
      }
    } catch (e) {
      // If there's an error, keep default locale
      debugPrint('Error loading locale: $e');
    }
  }

  /// Change locale and save to user settings
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    // Save to user settings if authenticated
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final language = locale.languageCode == 'en'
            ? UserSettings.languageEnglish
            : UserSettings.languageVietnamese;
        await _settingsService.updateLanguage(currentUser.id, language);
      }
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  /// Quick method to toggle between English and Vietnamese
  Future<void> toggleLocale() async {
    final newLocale = _locale.languageCode == 'vi'
        ? const Locale('en')
        : const Locale('vi');
    await setLocale(newLocale);
  }
}
