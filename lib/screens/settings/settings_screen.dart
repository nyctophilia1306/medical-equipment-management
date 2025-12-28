import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/constants.dart';
import '../../models/user.dart';
import '../../models/user_settings.dart';
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

  User? _currentUser;
  UserSettings? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndSettings();
  }

  Future<void> _loadUserAndSettings() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final settings = await _settingsService.getUserSettings(user.id);
        setState(() {
          _currentUser = user;
          _settings = settings;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // _updateLanguage method removed - Vietnamese only

  Future<void> _updateEmailNotifications(bool enabled) async {
    if (_currentUser == null) return;

    final success = await _settingsService.updateEmailNotifications(
      _currentUser!.id,
      enabled,
    );
    if (success) {
      await _loadUserAndSettings();
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? l10n.emailNotificationsEnabled
                  : l10n.emailNotificationsDisabled,
            ),
          ),
        );
      }
    }
  }

  String _getRoleDisplayName(int roleId, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (roleId) {
      case 0:
        return l10n.administrator;
      case 1:
        return l10n.manager;
      case 2:
        return l10n.user;
      default:
        return l10n.unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    AppLocalizations.of(context)!.settings,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // User Profile Section (only for logged-in users)
                  if (_currentUser != null) ...[
                    _buildSection(
                      title: AppLocalizations.of(context)!.userProfile,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryBlue,
                            child: Text(
                              _currentUser?.fullName
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  _currentUser?.userName
                                      .substring(0, 1)
                                      .toUpperCase() ??
                                  '?',
                              style: const TextStyle(
                                color: AppColors.textOnPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            _currentUser?.fullName ??
                                _currentUser?.userName ??
                                'Unknown',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            _currentUser?.email ?? '',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.badge_outlined),
                          title: Text(AppLocalizations.of(context)!.role),
                          subtitle: Text(
                            _getRoleDisplayName(
                              _currentUser?.roleId ?? 2,
                              context,
                            ),
                          ),
                        ),
                        if (_currentUser?.phone != null)
                          ListTile(
                            leading: const Icon(Icons.phone_outlined),
                            title: Text(AppLocalizations.of(context)!.phone),
                            subtitle: Text(_currentUser!.phone!),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                  ],

                  // Language Section - Removed (Vietnamese only)
                  // Language is now fixed to Vietnamese
                  const SizedBox(height: AppConstants.paddingLarge),

                  // Notifications Section (only for logged-in users)
                  if (_currentUser != null) ...[
                    _buildSection(
                      title: AppLocalizations.of(context)!.notifications,
                      children: [
                        SwitchListTile(
                          title: Text(
                            AppLocalizations.of(context)!.emailNotifications,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!.emailNotificationSubtitle,
                          ),
                          value: _settings?.emailNotifications ?? true,
                          onChanged: _updateEmailNotifications,
                          secondary: const Icon(Icons.email_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                  ],

                  // About Section
                  _buildSection(
                    title: AppLocalizations.of(context)!.about,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outlined),
                        title: Text(AppLocalizations.of(context)!.version),
                        subtitle: const Text('1.0.0'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(
                          AppLocalizations.of(context)!.termsOfService,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to terms
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: Text(
                          AppLocalizations.of(context)!.privacyPolicy,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to privacy policy
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: AppConstants.paddingLarge),

                  // Logout Button (only for logged-in users)
                  if (_currentUser != null)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          await _authService.signOut();
                          navigator.pushReplacementNamed('/');
                        },
                        icon: const Icon(Icons.logout),
                        label: Text(AppLocalizations.of(context)!.signOut),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorRed,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}
