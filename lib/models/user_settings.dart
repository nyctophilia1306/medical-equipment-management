class UserSettings {
  final String userId;
  final String themeMode; // 'light', 'dark', 'system'
  final String language; // 'en', 'vn'
  final bool emailNotifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Theme mode constants
  static const String themeModeLight = 'light';
  static const String themeModeDark = 'dark';
  static const String themeModeSystem = 'system';

  // Language constants
  static const String languageEnglish = 'en';
  static const String languageVietnamese = 'vn';

  UserSettings({
    required this.userId,
    required this.themeMode,
    required this.language,
    required this.emailNotifications,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['user_id'] as String,
      themeMode: json['theme_mode'] as String? ?? themeModeLight,
      language: json['language'] as String? ?? languageVietnamese,
      emailNotifications: json['email_notifications'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'theme_mode': themeMode,
      'language': language,
      'email_notifications': emailNotifications,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create default settings for a new user
  factory UserSettings.defaultSettings(String userId) {
    return UserSettings(
      userId: userId,
      themeMode: themeModeLight,
      language: languageVietnamese,
      emailNotifications: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  UserSettings copyWith({
    String? themeMode,
    String? language,
    bool? emailNotifications,
  }) {
    return UserSettings(
      userId: userId,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Get theme display name
  String getThemeDisplayName() {
    switch (themeMode) {
      case themeModeLight:
        return 'Light';
      case themeModeDark:
        return 'Dark';
      case themeModeSystem:
        return 'System';
      default:
        return themeMode;
    }
  }

  /// Get language display name
  String getLanguageDisplayName() {
    switch (language) {
      case languageEnglish:
        return 'English';
      case languageVietnamese:
        return 'Tiếng Việt';
      default:
        return language;
    }
  }

  @override
  String toString() {
    return 'UserSettings(userId: $userId, themeMode: $themeMode, language: $language, emailNotifications: $emailNotifications)';
  }
}
