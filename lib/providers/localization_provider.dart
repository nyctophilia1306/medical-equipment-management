import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_settings_service.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

class LocalizationProvider extends ChangeNotifier {
  Locale _locale = const Locale('vi'); // Default to Vietnamese
  static const String _guestLanguageKey = 'guest_language';

  Locale get locale => _locale;

  /// Load language preference from database (for logged in users) or SharedPreferences (for guests)
  Future<void> loadLanguageFromDatabase() async {
    try {
      final userId = AuthService().currentUser?.id;
      if (userId != null) {
        // Logged in user - load from database
        final settings = await UserSettingsService().getUserSettings(userId);
        final languageCode = settings.language == 'vn' ? 'vi' : 'en';
        _locale = Locale(languageCode);
        notifyListeners();
        Logger.info('Loaded language from database: $languageCode');
      } else {
        // Guest user - load from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final guestLanguage =
            prefs.getString(_guestLanguageKey) ?? 'vn'; // Default to Vietnamese
        final languageCode = guestLanguage == 'vn' ? 'vi' : 'en';
        _locale = Locale(languageCode);
        notifyListeners();
        Logger.info('Loaded guest language from preferences: $languageCode');
      }
    } catch (e) {
      Logger.error('Failed to load language: $e');
    }
  }

  /// Set locale and save to database (for logged in users) or SharedPreferences (for guests)
  Future<void> setLocale(String languageCode, {BuildContext? context}) async {
    final flutterLocale = languageCode == 'vn' ? 'vi' : languageCode;
    final locale = Locale(flutterLocale);
    if (_locale == locale) return;

    _locale = locale;

    // Save preference
    final userId = AuthService().currentUser?.id;
    if (userId != null) {
      // Logged in user - save to database
      await UserSettingsService().updateLanguage(userId, languageCode);
      Logger.info('Saved language to database: $languageCode');
    } else {
      // Guest user - save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_guestLanguageKey, languageCode);
      Logger.info('Saved guest language to preferences: $languageCode');
    }

    notifyListeners();
    Logger.info('Changed language to: $languageCode');
  }
}
