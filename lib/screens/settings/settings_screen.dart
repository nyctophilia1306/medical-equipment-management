import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/constants.dart';
import '../../models/user_settings.dart';
import '../../providers/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final UserSettingsService _settingsService = UserSettingsService();

  bool _loading = true;
  UserSettings? _settings;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception(AppLocalizations.of(context)!.noAuthenticatedUser);
      }

      final settings = await _settingsService.getUserSettings(currentUser.id);
      setState(() {
        _settings = settings;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '${AppLocalizations.of(context)!.failedToLoadSettings}: $e';
        _loading = false;
      });
    }
  }

  Future<void> _updateLanguage(String language) async {
    if (_settings == null) return;

    setState(() => _loading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception(AppLocalizations.of(context)!.noAuthenticatedUser);
      }

      // Update language in database
      await _settingsService.updateLanguage(currentUser.id, language);

      // Update locale provider to change app language immediately
      if (mounted) {
        final localeProvider = Provider.of<LocaleProvider>(
          context,
          listen: false,
        );
        final newLocale = language == UserSettings.languageEnglish
            ? const Locale('en')
            : const Locale('vi');
        await localeProvider.setLocale(newLocale);
      }

      // Reload settings to get updated data
      await _loadSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              language == UserSettings.languageVietnamese
                  ? 'Đã chuyển sang Tiếng Việt'
                  : 'Changed to English',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '${AppLocalizations.of(context)!.failedToUpdateLanguage}: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.failedToUpdateLanguage}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateEmailNotifications(bool enabled) async {
    if (_settings == null) return;

    setState(() => _loading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception(AppLocalizations.of(context)!.noAuthenticatedUser);
      }

      await _settingsService.updateEmailNotifications(currentUser.id, enabled);

      // Reload settings to get updated data
      await _loadSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled ? AppLocalizations.of(context)!.emailNotificationsEnabled : AppLocalizations.of(context)!.emailNotificationsDisabled,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '${AppLocalizations.of(context)!.failedToUpdateEmailNotifications}: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.failedToUpdateEmailNotifications}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: const BoxDecoration(
              color: AppColors.backgroundWhite,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.settings, size: 32, color: AppColors.primaryBlue),
                const SizedBox(width: 16),
                Text(
                  'Cài Đặt',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSettings,
                          child: Text(AppLocalizations.of(context)!.retry),
                        ),
                      ],
                    ),
                  )
                : _buildSettingsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    if (_settings == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language Settings Card
          _buildSettingsCard(
            title: AppLocalizations.of(context)!.language,
            icon: Icons.language,
            children: [
              _buildLanguageOption(
                AppLocalizations.of(context)!.vietnamese,
                UserSettings.languageVietnamese,
                _settings!.language == UserSettings.languageVietnamese,
              ),
              const Divider(height: 1),
              _buildLanguageOption(
                AppLocalizations.of(context)!.english,
                UserSettings.languageEnglish,
                _settings!.language == UserSettings.languageEnglish,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Notification Settings Card
          _buildSettingsCard(
            title: AppLocalizations.of(context)!.notifications,
            icon: Icons.notifications,
            children: [_buildNotificationToggle()],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusMedium,
                    ),
                  ),
                  child: Icon(icon, color: AppColors.primaryBlue, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Card Content
          ...children,
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String label, String value, bool isSelected) {
    return ListTile(
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppColors.primaryBlue)
          : null,
      onTap: isSelected ? null : () => _updateLanguage(value),
    );
  }

  Widget _buildNotificationToggle() {
    return SwitchListTile(
      title: Text(
        AppLocalizations.of(context)!.emailNotifications,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.emailNotificationSubtitle,
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
      ),
      value: _settings?.emailNotifications ?? true,
      activeThumbColor: AppColors.primaryBlue,
      onChanged: _updateEmailNotifications,
    );
  }
}
