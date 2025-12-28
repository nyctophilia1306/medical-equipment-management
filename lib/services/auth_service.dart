import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as app_user;
import '../constants/constants.dart';
import '../utils/logger.dart';
import '../models/audit_log.dart';
import 'audit_log_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  app_user.User? _currentUser;

  app_user.User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> initialize() async {
    final session = _supabase.auth.currentSession;
    if (session?.user != null) {
      // Try to load user from local storage or database
      await _loadUserProfile(session!.user.id);

      if (_currentUser == null && session.user.email != null) {
        // If we couldn't load a profile, create one based on the email
        Logger.info('Creating temporary user based on email pattern');
        String role = _determineRoleFromEmail(session.user.email!);
        int roleId = _roleStringToId(role);

        _currentUser = app_user.User(
          id: session.user.id,
          userName: session.user.email!.split('@')[0],
          email: session.user.email,
          roleId: roleId,
          createdAt: DateTime.now(),
        );

        // Save this user to local storage for persistence
        await _saveUserToLocal(_currentUser!);

        // Also try to create it in the database for future sessions
        try {
          await _createUserProfile(
            userId: session.user.id,
            email: session.user.email!,
            name: session.user.email!.split('@')[0],
            role: role,
          );
          Logger.info('Created user profile in database with roleId: $roleId');
        } catch (e) {
          Logger.warn('Could not create user profile in database: $e');
        }
      }
    }
  }

  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('Signing in with email: $email');

      // First, attempt to authenticate with Supabase
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        Logger.info('Auth successful, userId: ${response.user!.id}');

        // Try to fetch user profile from the users table
        try {
          final userResponse = await _supabase
              .from('users')
              .select()
              .eq('user_id', response.user!.id)
              .maybeSingle();

          if (userResponse != null) {
            // Response will not be null if it reaches this point
            Logger.info('Found user profile in database');
            _currentUser = app_user.User.fromJson(userResponse);
            await _saveUserToLocal(_currentUser!);
            Logger.info(
              'User profile loaded from DB: ${_currentUser!.email}, roleId: ${_currentUser!.roleId}',
            );

            // Log the login action
            try {
              await AuditLogService().logAction(
                userId: _currentUser!.id,
                actionType: AuditLog.actionLogin,
                details: {'email': email},
              );
            } catch (e) {
              Logger.error('Failed to log login action: $e');
            }

            return AuthResult.success(_currentUser!);
          } else {
            Logger.warn('User found in auth but not in users table');
          }
        } catch (dbError) {
          Logger.warn(
            'Error fetching user from DB: $dbError, will create in-memory user',
          );
        }

        // If we couldn't find a user in the database, create one in memory
        // Determine the role based on the email domain or pattern
        String role = _determineRoleFromEmail(email);
        int roleId = _roleStringToId(role);
        Logger.debug('Determined role from email: $role (roleId: $roleId)');

        // Create a simple user object based on the email
        final user = app_user.User(
          id: response.user!.id,
          userName: email.split('@')[0],
          email: email,
          roleId: roleId,
          createdAt: DateTime.now(),
        );

        // Set as current user
        _currentUser = user;

        // Save to local storage for persistence
        await _saveUserToLocal(user);

        // Log the login action
        try {
          await AuditLogService().logAction(
            userId: user.id,
            actionType: AuditLog.actionLogin,
            details: {'email': email},
          );
        } catch (e) {
          Logger.error('Failed to log login action: $e');
        }

        // Try to create user profile in the database for future sessions
        try {
          await _createUserProfile(
            userId: response.user!.id,
            email: email,
            name: email.split('@')[0],
            role: role,
          );
          Logger.info('Created user profile in database with roleId: $roleId');
        } catch (e) {
          Logger.warn('Could not create user profile in database: $e');
        }

        Logger.info(
          'User profile created in memory: ${user.email}, roleId: ${user.roleId}',
        );
        return AuthResult.success(user);
      } else {
        Logger.warn('Auth response does not contain a user');
      }

      return AuthResult.error('Failed to sign in - no user returned');
    } on AuthException catch (e) {
      Logger.warn('Auth exception: ${e.message}');
      return AuthResult.error(_getAuthErrorMessage(e));
    } catch (e) {
      Logger.error('Unexpected error during sign-in: $e', e);
      return AuthResult.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String role = AppConstants.roleUser,
    String? phoneNumber,
    String? department,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role,
          'phone_number': phoneNumber,
          'department': department,
        },
      );

      if (response.user != null) {
        // Convert role string to roleId
        int roleId = _roleStringToId(role);
        Logger.debug('Role $role maps to roleId: $roleId for new user');

        // Create user profile in the users table
        await _createUserProfile(
          userId: response.user!.id,
          email: email,
          name: name,
          role: role,
          phoneNumber: phoneNumber,
          department: department,
        );

        await _loadUserProfile(response.user!.id);
        if (_currentUser != null) {
          return AuthResult.success(_currentUser!);
        } else {
          // If loading the profile failed, create a temporary user object
          final user = app_user.User(
            id: response.user!.id,
            userName: email.split('@')[0],
            email: email,
            roleId: roleId,
            createdAt: DateTime.now(),
          );
          _currentUser = user;
          await _saveUserToLocal(user);
          return AuthResult.success(user);
        }
      }

      return AuthResult.error('Failed to create account');
    } on AuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred');
    }
  }

  Future<void> signOut() async {
    try {
      // Log the logout action before clearing user
      if (_currentUser != null) {
        try {
          await AuditLogService().logAction(
            userId: _currentUser!.id,
            actionType: AuditLog.actionLogout,
          );
        } catch (e) {
          Logger.error('Failed to log logout action: $e');
        }
      }

      await _supabase.auth.signOut();
      _currentUser = null;
      await _clearLocalStorage();
    } catch (e) {
      // Handle sign out error if needed
    }
  }

  Future<AuthResult> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return AuthResult.success(null);
    } on AuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred');
    }
  }

  Future<AuthResult> updateProfile({
    String? userName,
    String? fullName,
    String? phone,
    String? gender,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) {
      return AuthResult.error('User not authenticated');
    }

    try {
      final updates = <String, dynamic>{};
      if (userName != null) updates['user_name'] = userName;
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (gender != null) updates['gender'] = gender;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('users')
          .update(updates)
          .eq('user_id', _currentUser!.id);

      await _loadUserProfile(_currentUser!.id);
      return AuthResult.success(_currentUser!);
    } catch (e) {
      return AuthResult.error('Failed to update profile');
    }
  }

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return AuthResult.success(_currentUser);
    } on AuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred');
    }
  }

  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String name,
    required String role,
    String? phoneNumber,
    String? department,
  }) async {
    Logger.info(
      'Creating new user profile for ID: $userId, email: $email, role: $role',
    );

    // Convert role string to roleId using our helper method
    int roleId = _roleStringToId(role);
    Logger.debug('Role $role maps to roleId: $roleId');

    try {
      final userData = {
        'user_id': userId,
        'user_name': email.split('@')[0], // Default username from email
        'email': email,
        'full_name': name,
        'role_id': roleId,
        'phone': phoneNumber,
        'created_at': DateTime.now().toIso8601String(),
      };

      Logger.debug('Inserting user data: $userData');

      await _supabase.from('users').insert(userData);
      Logger.info('User profile created successfully');
    } catch (e) {
      Logger.error('Error creating user profile: $e', e);

      // Try alternative approach if schema might use 'id' instead of 'user_id'
      try {
        final userData = {
          'id': userId,
          'user_name': email.split('@')[0],
          'email': email,
          'full_name': name,
          'role_id': roleId,
          'phone': phoneNumber,
          'created_at': DateTime.now().toIso8601String(),
        };

        Logger.debug('Trying alternative schema with id field: $userData');
        await _supabase.from('users').insert(userData);
        Logger.info('User profile created with alternative schema');
      } catch (alternativeError) {
        Logger.error(
          'Alternative approach also failed: $alternativeError',
          alternativeError,
        );
        throw Exception(
          'Failed to create user profile: $e, alternative error: $alternativeError',
        );
      }
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      Logger.info('Attempting to load user profile for ID: $userId');

      // Try to load from local storage first
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.storageKeyUser);

      if (userJson != null) {
        try {
          final userData = jsonDecode(userJson);
          _currentUser = app_user.User.fromJson(userData);
          Logger.info(
            'User profile loaded from local storage: ${_currentUser!.email}, roleId: ${_currentUser!.roleId}',
          );

          // Validate by checking against database (but don't fail if not found)
          try {
            final dbUser = await _supabase
                .from('users')
                .select()
                .eq('user_id', userId)
                .maybeSingle();

            if (dbUser != null) {
              // If database has newer data, use that instead
              _currentUser = app_user.User.fromJson(dbUser);
              await _saveUserToLocal(_currentUser!);
              Logger.info(
                'User profile updated from DB: ${_currentUser!.email}, roleId: ${_currentUser!.roleId}',
              );
            }
          } catch (e) {
            // Using local copy is fine if DB fetch fails
            Logger.debug(
              'Could not refresh user from database, using local storage copy',
            );
          }

          return;
        } catch (e) {
          Logger.error('Error parsing stored user data: $e', e);
        }
      }

      // If we can't load from storage, try to get from database
      try {
        final dbUser = await _supabase
            .from('users')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (dbUser != null) {
          _currentUser = app_user.User.fromJson(dbUser);
          await _saveUserToLocal(_currentUser!);
          Logger.info(
            'User profile loaded from database: ${_currentUser!.email}, roleId: ${_currentUser!.roleId}',
          );
          return;
        }
      } catch (e) {
        Logger.error('Error loading user from database: $e', e);
      }

      // If we still don't have a user, get the current auth session and create a user from email
      final session = _supabase.auth.currentSession;
      if (session != null && session.user.email != null) {
        final email = session.user.email!;
        final role = _determineRoleFromEmail(email);

        _currentUser = app_user.User(
          id: userId,
          userName: email.split('@')[0],
          email: email,
          roleId: _roleStringToId(role),
          createdAt: DateTime.now(),
        );

        await _saveUserToLocal(_currentUser!);
        Logger.info(
          'Created user profile from session: ${_currentUser!.email}, roleId: ${_currentUser!.roleId}',
        );
      } else {
        Logger.warn('No user session available, unable to create user profile');
        _currentUser = null;
      }
    } catch (e) {
      Logger.error('Error loading user profile: $e', e);
      _currentUser = null;
    }
  }

  Future<void> _saveUserToLocal(app_user.User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Convert user to JSON Map and then to String
      final userJson = user.toJson();
      // Use JSON encoding to properly serialize the Map
      await prefs.setString(AppConstants.storageKeyUser, jsonEncode(userJson));
      Logger.debug('User saved to local storage: ${jsonEncode(userJson)}');
    } catch (e) {
      Logger.error('Error saving user to local storage: $e', e);
    }
  }

  Future<void> _clearLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.storageKeyUser);
  }

  String _getAuthErrorMessage(AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Invalid email or password';
      case 'Email not confirmed':
        return 'Please confirm your email address';
      case 'User already registered':
        return 'An account with this email already exists';
      case 'Password should be at least 6 characters':
        return 'Password must be at least 6 characters';
      default:
        return e.message;
    }
  }

  // Determine the role based on the email pattern
  String _determineRoleFromEmail(String email) {
    email = email.toLowerCase();

    // Check for predefined demo accounts
    if (email == 'admin@medequip.com') {
      return AppConstants.roleAdmin;
    } else if (email == 'manager@medequip.com') {
      return AppConstants.roleManager;
    } else if (email == 'user@medequip.com') {
      return AppConstants.roleUser;
    }

    // You can add additional email pattern checks here
    // For example, checking domains or prefixes
    if (email.contains('admin')) {
      return AppConstants.roleAdmin;
    } else if (email.contains('manager')) {
      return AppConstants.roleManager;
    } else {
      // Default role for other emails
      return AppConstants.roleUser;
    }
  }

  // Convert role string to roleId
  int _roleStringToId(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return 0;
      case AppConstants.roleManager:
        return 1;
      default: // User role
        return 2;
    }
  }

  // Convert roleId to role string
  String _roleIdToString(int roleId) {
    switch (roleId) {
      case 0:
        return AppConstants.roleAdmin;
      case 1:
        return AppConstants.roleManager;
      default: // roleId 2 or any other value
        return AppConstants.roleUser;
    }
  }

  // Update a user's role in the database
  Future<void> updateUserRole(String userId, int roleId) async {
    try {
      await _supabase
          .from('users')
          .update({
            'role_id': roleId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
      Logger.info('User role updated to $roleId');

      // If this is the current user, update the current user object
      if (_currentUser != null && _currentUser!.id == userId) {
        _currentUser = _currentUser!.copyWith(roleId: roleId);
        await _saveUserToLocal(_currentUser!);
        Logger.info('Current user roleId updated to: ${_currentUser!.roleId}');
      }
    } catch (e) {
      Logger.error('Error updating user role: $e', e);
      throw Exception('Failed to update user role: $e');
    }
  }

  // Role-based access control helpers - delegate to the User model
  bool canViewEquipment() {
    return _currentUser?.canViewEquipment ?? false;
  }

  bool canCreateBorrowRequests() {
    return _currentUser?.canCreateBorrowRequests ?? false;
  }

  bool canManageEquipment() {
    return _currentUser?.canManageEquipment ?? false;
  }

  bool canManageUsers() {
    return _currentUser?.canManageUsers ?? false;
  }

  bool hasRole(String role) {
    // Convert role string to roleId and compare
    if (_currentUser == null) return false;

    int roleId = _roleStringToId(role);
    return _currentUser!.roleId == roleId;
  }

  bool hasAnyRole(List<String> roles) {
    if (_currentUser == null) return false;

    for (final role in roles) {
      if (hasRole(role)) return true;
    }
    return false;
  }

  // Get the current user's role as a string
  String? getCurrentUserRole() {
    if (_currentUser == null) return null;
    return _roleIdToString(_currentUser!.roleId);
  }
}

class AuthResult {
  final bool isSuccess;
  final app_user.User? user;
  final String? errorMessage;

  AuthResult.success(this.user) : isSuccess = true, errorMessage = null;

  AuthResult.error(this.errorMessage) : isSuccess = false, user = null;
}
