import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;
import '../utils/logger.dart';
import '../models/audit_log.dart';
import 'audit_log_service.dart';
import 'auth_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all users from the database
  Future<List<app_user.User>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => app_user.User.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error('Failed to fetch users: $e');
      rethrow;
    }
  }

  /// Create a new user (admin only)
  Future<app_user.User> createUser({
    required String email,
    required String password,
    required String username,
    String? fullName,
    DateTime? dob,
    String? gender,
    String? phone,
    required int roleId,
  }) async {
    try {
      // First, create the auth user
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create auth user');
      }

      // Then create the user profile in the users table
      final userData = {
        'user_id': authResponse.user!.id,
        'user_name': username,
        'email': email,
        'full_name': fullName,
        'dob': dob?.toIso8601String(),
        'gender': gender,
        'phone': phone,
        'role_id': roleId,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('users')
          .insert(userData)
          .select()
          .single();

      Logger.info('User created successfully: $username');

      // Log the create action
      try {
        final currentUserId =
            AuthService().currentUser?.id ?? authResponse.user!.id;
        await AuditLogService().logAction(
          userId: currentUserId,
          actionType: AuditLog.actionUserCreate,
          targetType: AuditLog.targetUser,
          targetId: authResponse.user!.id,
          details: {'userName': username, 'email': email, 'roleId': roleId},
        );
      } catch (e) {
        Logger.error('Failed to log user create action: $e');
      }

      return app_user.User.fromJson(response);
    } catch (e) {
      Logger.error('Failed to create user: $e');
      rethrow;
    }
  }

  /// Update an existing user (admin only)
  Future<void> updateUser({
    required String userId,
    String? username,
    String? fullName,
    DateTime? dob,
    String? gender,
    String? phone,
    int? roleId,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (username != null) updates['user_name'] = username;
      if (fullName != null) updates['full_name'] = fullName;
      if (dob != null) updates['dob'] = dob.toIso8601String();
      if (gender != null) updates['gender'] = gender;
      if (phone != null) updates['phone'] = phone;
      if (roleId != null) updates['role_id'] = roleId;

      if (updates.isEmpty) {
        Logger.warn('No updates provided for user $userId');
        return;
      }

      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('users').update(updates).eq('user_id', userId);

      Logger.info('User updated successfully: $userId');

      // Log the update action
      try {
        final currentUserId = AuthService().currentUser?.id ?? 'system';
        await AuditLogService().logAction(
          userId: currentUserId,
          actionType: AuditLog.actionUserUpdate,
          targetType: AuditLog.targetUser,
          targetId: userId,
          details: {'updates': updates},
        );
      } catch (e) {
        Logger.error('Failed to log user update action: $e');
      }
    } catch (e) {
      Logger.error('Failed to update user: $e');
      rethrow;
    }
  }

  /// Delete a user (admin only)
  Future<void> deleteUser(String userId) async {
    try {
      // Delete the user profile
      await _supabase.from('users').delete().eq('user_id', userId);

      // Note: Deleting auth users requires admin API access
      // This would typically be done via a backend function with service role key

      Logger.info('User deleted successfully: $userId');

      // Log the delete action
      try {
        final currentUserId = AuthService().currentUser?.id ?? 'system';
        await AuditLogService().logAction(
          userId: currentUserId,
          actionType: AuditLog.actionUserDelete,
          targetType: AuditLog.targetUser,
          targetId: userId,
        );
      } catch (e) {
        Logger.error('Failed to log user delete action: $e');
      }
    } catch (e) {
      Logger.error('Failed to delete user: $e');
      rethrow;
    }
  }

  /// Get a single user by ID
  Future<app_user.User?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return app_user.User.fromJson(response);
    } catch (e) {
      Logger.error('Failed to fetch user: $e');
      return null;
    }
  }

  /// Search users by name, email, or phone
  Future<List<app_user.User>> searchUsers(String query) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .or(
            'user_name.ilike.%$query%,full_name.ilike.%$query%,phone.ilike.%$query%',
          )
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => app_user.User.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error('Failed to search users: $e');
      rethrow;
    }
  }

  /// Get users by role
  Future<List<app_user.User>> getUsersByRole(int roleId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role_id', roleId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => app_user.User.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error('Failed to fetch users by role: $e');
      rethrow;
    }
  }

  /// Update user role (admin only)
  Future<void> updateUserRole(String userId, int newRoleId) async {
    try {
      await _supabase
          .from('users')
          .update({
            'role_id': newRoleId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      Logger.info('User role updated: $userId -> role $newRoleId');

      // Log the role change action
      try {
        final currentUserId = AuthService().currentUser?.id ?? 'system';
        await AuditLogService().logAction(
          userId: currentUserId,
          actionType: AuditLog.actionUserRoleChange,
          targetType: AuditLog.targetUser,
          targetId: userId,
          details: {'newRoleId': newRoleId},
        );
      } catch (e) {
        Logger.error('Failed to log role change action: $e');
      }
    } catch (e) {
      Logger.error('Failed to update user role: $e');
      rethrow;
    }
  }

  /// Reset user password via email
  Future<void> resetUserPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      Logger.info('Password reset email sent to: $email');
    } catch (e) {
      Logger.error('Failed to send password reset email: $e');
      rethrow;
    }
  }

  /// Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final allUsers = await getAllUsers();

      final stats = {
        'total': allUsers.length,
        'admins': allUsers.where((u) => u.roleId == 0).length,
        'managers': allUsers.where((u) => u.roleId == 1).length,
        'users': allUsers.where((u) => u.roleId == 2).length,
      };

      return stats;
    } catch (e) {
      Logger.error('Failed to get user statistics: $e');
      return {'total': 0, 'admins': 0, 'managers': 0, 'users': 0};
    }
  }
}
