import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/constants.dart';
import '../../services/auth_service.dart';
import '../../utils/logger.dart';
// Removed safe_context import as it's no longer used
import '../dashboard/main_dashboard.dart';
// Sign up is disabled. Admins create accounts.

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
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.medical_services,
            size: 40,
            color: AppColors.textOnPrimary,
          ),
        ),
        
        const SizedBox(height: AppConstants.paddingMedium),
        
        Text(
          'Welcome Back',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: AppConstants.paddingSmall),
        
        Text(
          'Sign in to your ${AppConstants.appName} account',
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
            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
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
                labelText: 'Password',
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
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < AppConstants.minPasswordLength) {
                  return 'Password must be at least ${AppConstants.minPasswordLength} characters';
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
                  'Forgot Password?',
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
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
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
                        'Sign In',
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

  Widget _buildDemoAccountsInfo() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.grayNeutral100,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: AppColors.grayNeutral300,
          width: 1,
        ),
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
          
          _buildDemoAccount('Admin', 'admin@medequip.com', 'password123'),
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
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
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
      Logger.info('Attempting to sign in with email: ${_emailController.text.trim()}');
      
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
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainDashboard(),
            ),
          );
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
  
  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final currentContext = context;  // Store context reference
    
    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Reset Password',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
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
                      const SnackBar(
                        content: Text('Password reset link sent to your email'),
                        backgroundColor: AppColors.successGreen,
                      ),
                    );
                  }
                });
              }
            },
            child: const Text('Send Link'),
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
          'Sign In Failed',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}