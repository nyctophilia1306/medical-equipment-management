import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_settings.dart';
import '../utils/logger.dart';

class UserSettingsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get settings for a specific user
  /// Returns default settings if user settings don't exist
  Future<UserSettings> getUserSettings(String userId) async {
    try {
      final response = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // User settings don't exist, create default settings
        Logger.info('No settings found for user $userId, creating defaults');
        return await createDefaultSettings(userId);
      }

      return UserSettings.fromJson(response);
    } catch (e) {
      Logger.error('Error fetching user settings: $e');
      // Return default settings on error
      return UserSettings.defaultSettings(userId);
    }
  }

  /// Create default settings for a new user
  Future<UserSettings> createDefaultSettings(String userId) async {
    try {
      final defaultSettings = UserSettings.defaultSettings(userId);
      
      await _supabase.from('user_settings').insert({
        'user_id': userId,
        'theme_mode': defaultSettings.themeMode,
        'language': defaultSettings.language,
        'email_notifications': defaultSettings.emailNotifications,
      });

      Logger.info('Created default settings for user $userId');
      return defaultSettings;
    } catch (e) {
      Logger.error('Error creating default settings: $e');
      // Return in-memory default settings even if DB insert fails
      return UserSettings.defaultSettings(userId);
    }
  }

  /// Update user settings
  Future<bool> updateSettings({
    required String userId,
    String? themeMode,
    String? language,
    bool? emailNotifications,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (themeMode != null) updates['theme_mode'] = themeMode;
      if (language != null) updates['language'] = language;
      if (emailNotifications != null) updates['email_notifications'] = emailNotifications;

      if (updates.isEmpty) {
        Logger.info('No settings to update for user $userId');
        return true;
      }

      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('user_settings')
          .update(updates)
          .eq('user_id', userId);

      Logger.info('Updated settings for user $userId: $updates');
      return true;
    } catch (e) {
      Logger.error('Error updating user settings: $e');
      return false;
    }
  }

  /// Update theme mode only
  Future<bool> updateThemeMode(String userId, String themeMode) async {
    return await updateSettings(userId: userId, themeMode: themeMode);
  }

  /// Update language only
  Future<bool> updateLanguage(String userId, String language) async {
    return await updateSettings(userId: userId, language: language);
  }

  /// Update email notifications only
  Future<bool> updateEmailNotifications(String userId, bool enabled) async {
    return await updateSettings(userId: userId, emailNotifications: enabled);
  }

  /// Check if settings exist for a user
  Future<bool> settingsExist(String userId) async {
    try {
      final response = await _supabase
          .from('user_settings')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      Logger.error('Error checking if settings exist: $e');
      return false;
    }
  }

  /// Get all users with email notifications enabled (for admin/manager)
  Future<List<String>> getUsersWithEmailNotifications({
    List<int>? roleIds,
  }) async {
    try {
      var query = _supabase
          .from('user_settings')
          .select('user_id, users!inner(role_id)')
          .eq('email_notifications', true);

      if (roleIds != null && roleIds.isNotEmpty) {
        query = query.inFilter('users.role_id', roleIds);
      }

      final response = await query;

      return (response as List)
          .map((item) => item['user_id'] as String)
          .toList();
    } catch (e) {
      Logger.error('Error fetching users with email notifications: $e');
      return [];
    }
  }

  /// Delete user settings (used when deleting a user)
  Future<bool> deleteSettings(String userId) async {
    try {
      await _supabase
          .from('user_settings')
          .delete()
          .eq('user_id', userId);

      Logger.info('Deleted settings for user $userId');
      return true;
    } catch (e) {
      Logger.error('Error deleting user settings: $e');
      return false;
    }
  }
}
