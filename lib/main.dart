import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'l10n/app_localizations.dart';
import 'constants/app_theme.dart';
import 'constants/constants.dart';
import 'services/auth_service.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/dashboard/main_dashboard.dart';
import 'screens/admin/category_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const MedEquipApp());
}

class MedEquipApp extends StatelessWidget {
  const MedEquipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: const Locale('vi'), // Vietnamese only
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi')], // Vietnamese only
      home: const AuthGate(),
      routes: {
        '/dashboard': (context) => const MainDashboard(),
        CategoryManagementScreen.routeName: (context) =>
            const CategoryManagementScreen(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    try {
      await _authService.initialize();
    } catch (e) {
      // Handle initialization error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If not authenticated, redirect to sign in screen
    // Sign in screen will have a Guest button to access the app without login
    if (!_authService.isAuthenticated) {
      return const SignInScreen();
    }

    // If authenticated, show the main dashboard
    return const MainDashboard();
  }
}
