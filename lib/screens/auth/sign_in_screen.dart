import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/constants.dart';
import '../../services/auth_service.dart';
import '../../utils/logger.dart';
// Removed safe_context import as it's no longer used
import '../dashboard/main_dashboard.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Header
                        _buildHeader(),

                        const SizedBox(height: AppConstants.paddingXLarge),

                        // Sign In Form
                        _buildSignInForm(),

                        const SizedBox(height: AppConstants.paddingMedium),

                        // Guest Access Button
                        _buildGuestAccessButton(),

                        const SizedBox(height: AppConstants.paddingMedium),

                        // Sign Up Link
                        _buildSignUpLink(),

                        const SizedBox(height: AppConstants.paddingLarge),

                        // Demo Accounts Info
                        _buildDemoAccountsInfo(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Logo
        Container(
          constraints: const BoxConstraints(maxWidth: 120, maxHeight: 140),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Image.network(
                'https://aowxsljcxqfkrsvikmzf.supabase.co/storage/v1/object/public/equiqment_image/hcmute-logo.png',
                fit: BoxFit.contain,
                width: 96,
                height: 116,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.medical_services,
                    size: 40,
                    color: AppColors.primaryBlue,
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: AppConstants.paddingMedium),

        Text(
          AppLocalizations.of(context)!.welcome,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: AppConstants.paddingSmall),

        Text(
          AppLocalizations.of(context)!.welcomeTo(AppConstants.appName),
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppConstants.paddingXLarge),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email or Username Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.emailOrUsername,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(
                  Icons.person_outlined,
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusMedium,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterEmailOrUsername;
                }
                return null;
              },
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.password,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(
                  Icons.lock_outlined,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.textSecondary,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusMedium,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterPassword;
                }
                if (value.length < AppConstants.minPasswordLength) {
                  return AppLocalizations.of(context)!.passwordMustBeAtLeast(AppConstants.minPasswordLength);
                }
                return null;
              },
            ),

            const SizedBox(height: AppConstants.paddingSmall),

            // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _showForgotPasswordDialog,
                child: Text(
                  AppLocalizations.of(context)!.forgotPassword,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Sign In Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusMedium,
                    ),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.textOnPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.signIn,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sign up flow removed

  Widget _buildGuestAccessButton() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: OutlinedButton.icon(
        onPressed: _continueAsGuest,
        icon: const Icon(Icons.visibility_outlined, size: 16),
        label: Text(
          AppLocalizations.of(context)!.continueAsGuest,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: BorderSide(color: AppColors.primaryBlue, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadiusMedium,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
    );
  }

  void _continueAsGuest() {
    // Navigate to main dashboard in guest mode (no authentication)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainDashboard()),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.dontHaveAnAccount,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SignUpScreen()),
            );
          },
          child: Text(
            AppLocalizations.of(context)!.signUpNow,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDemoAccountsInfo() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.grayNeutral100,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.grayNeutral300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demo Accounts',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: AppConstants.paddingSmall),

          _buildDemoAccount(
            'Quản Trị Viên',
            'admin@medequip.com',
            'password123',
          ),
          _buildDemoAccount('Manager', 'manager@demo.test', 'Password1!'),
        ],
      ),
    );
  }

  Widget _buildDemoAccount(String role, String email, String password) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getRoleColor(role).withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              role,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getRoleColor(role),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: Text(
              '$email / $password',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _fillDemoAccount(email, password),
            icon: const Icon(
              Icons.content_copy,
              size: 16,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Use this account',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.errorRed;
      case 'manager':
        return AppColors.warningYellow;
      case 'user':
        return AppColors.successGreen;
      default:
        return AppColors.textSecondary;
    }
  }

  void _fillDemoAccount(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Logger.info(
        'Attempting to sign in with email: ${_emailController.text.trim()}',
      );

      // Capture form data before async operation
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final result = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      // ignore: use_build_context_synchronously
      if (mounted) {
        if (result.isSuccess) {
          Logger.info('Sign in successful, navigating to dashboard');

          // Check if user needs to change password
          if (result.user?.needsPasswordChange == true) {
            Logger.info('User needs to change password');
            _showChangePasswordDialog();
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainDashboard()),
            );
          }
        } else {
          Logger.warn('Sign in failed: ${result.errorMessage}');
          _showErrorDialog(result.errorMessage ?? AppConstants.errorAuth);
        }
      }
    } catch (e) {
      Logger.error('Exception during sign in: $e', e);
      // ignore: use_build_context_synchronously
      if (mounted) {
        _showErrorDialog('Sign in error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // No sign-up navigation; accounts are admin-provisioned.

  void _showChangePasswordDialog() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    bool isChangingPassword = false;

    showDialog(
      context: context,
      barrierDismissible: false, // User must change password
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.changePassword,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.youNeedToChangeDefaultPassword,
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: AppLocalizations.of(context)!.newPassword,
                    prefixIcon: Icon(
                      Icons.lock_outlined,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                      icon: Icon(
                        obscureNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: AppLocalizations.of(context)!.confirmPassword,
                    prefixIcon: Icon(
                      Icons.lock_outlined,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isChangingPassword
                  ? null
                  : () async {
                      // Validate passwords
                      if (newPasswordController.text.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterNewPassword)),
                        );
                        return;
                      }
                      if (newPasswordController.text.length <
                          AppConstants.minPasswordLength) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.passwordMustBeAtLeast(AppConstants.minPasswordLength),
                            ),
                          ),
                        );
                        return;
                      }
                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.passwordsDoNotMatch)),
                        );
                        return;
                      }

                      setState(() {
                        isChangingPassword = true;
                      });

                      try {
                        // Update password in Supabase
                        await _authService.updatePassword(
                          newPasswordController.text,
                        );

                        // Update needs_password_change flag in database
                        final currentUser = _authService.currentUser;
                        if (currentUser != null) {
                          await _authService.updateNeedsPasswordChange(false);
                        }

                        // ignore: use_build_context_synchronously
                        if (!context.mounted) return;
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const MainDashboard(),
                          ),
                        );
                      } catch (e) {
                        Logger.error('Failed to change password: $e');
                        // ignore: use_build_context_synchronously
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                      } finally {
                        if (mounted) {
                          setState(() {
                            isChangingPassword = false;
                          });
                        }
                      }
                    },
              child: isChangingPassword
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      AppLocalizations.of(context)!.confirm,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final currentContext = context; // Store context reference

    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.resetPassword,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.enterEmailForReset,
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: AppLocalizations.of(context)!.emailAddress,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                // Capture email before async operation
                final email = emailController.text.trim();

                // Close dialog first before async operation
                Navigator.of(dialogContext).pop();

                // Then perform async operation without BuildContext concern
                _authService.resetPassword(email).then((_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.resetLinkSent,
                        ),
                        backgroundColor: AppColors.successGreen,
                      ),
                    );
                  }
                });
              }
            },
            child: Text(AppLocalizations.of(context)!.sendLink),
          ),
        ],
      ),
    );
  }

  // ignore: use_build_context_synchronously
  void _showErrorDialog(String message) {
    // Use a local context reference that won't be used across async gaps
    final currentContext = context;

    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.signInFailed,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(message, style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context)!.agree),
          ),
        ],
      ),
    );
  }
}
