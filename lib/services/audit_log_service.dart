import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/audit_log.dart';
import '../utils/logger.dart';

class AuditLogService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Log an action to the audit trail
  Future<void> logAction({
    required String userId,
    required String actionType,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? details,
    String? ipAddress,
  }) async {
    try {
      await _supabase.from('audit_logs').insert({
        'user_id': userId,
        'action_type': actionType,
        'target_type': targetType,
        'target_id': targetId,
        'details': details,
        'ip_address': ipAddress,
        'timestamp': DateTime.now().toIso8601String(),
      });

      Logger.info('Audit log created: $actionType by user $userId');
    } catch (e) {
      Logger.error('Error creating audit log: $e');
      // Don't throw - audit logging should not break app functionality
    }
  }

  /// Get all logs for a specific user
  Future<List<AuditLog>> getUserLogs(String userId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('audit_logs')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(limit);

      return (response as List).map((json) => AuditLog.fromJson(json)).toList();
    } catch (e) {
      Logger.error('Error fetching user logs: $e');
      return [];
    }
  }

  /// Get all system logs with optional pagination
  Future<List<AuditLog>> getSystemLogs({
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('audit_logs')
          .select()
          .order('timestamp', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => AuditLog.fromJson(json)).toList();
    } catch (e) {
      Logger.error('Error fetching system logs: $e');
      return [];
    }
  }

  /// Filter logs by action type
  Future<List<AuditLog>> filterByActionType(
    String actionType, {
    int limit = 100,
  }) async {
    try {
      final response = await _supabase
          .from('audit_logs')
          .select()
          .eq('action_type', actionType)
          .order('timestamp', ascending: false)
          .limit(limit);

      return (response as List).map((json) => AuditLog.fromJson(json)).toList();
    } catch (e) {
      Logger.error('Error filtering logs by action type: $e');
      return [];
    }
  }

  /// Filter logs by date range
  Future<List<AuditLog>> filterByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) async {
    try {
      final response = await _supabase
          .from('audit_logs')
          .select()
          .gte('timestamp', startDate.toIso8601String())
          .lte('timestamp', endDate.toIso8601String())
          .order('timestamp', ascending: false)
          .limit(limit);

      return (response as List).map((json) => AuditLog.fromJson(json)).toList();
    } catch (e) {
      Logger.error('Error filtering logs by date range: $e');
      return [];
    }
  }

  /// Get equipment status changes
  Future<List<AuditLog>> getEquipmentStatusChanges({
    String? equipmentId,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('audit_logs')
          .select()
          .eq('action_type', AuditLog.actionEquipmentStatusChange);

      if (equipmentId != null) {
        query = query.eq('target_id', equipmentId);
      }

      final response = await query
          .order('timestamp', ascending: false)
          .limit(limit);

      return (response as List).map((json) => AuditLog.fromJson(json)).toList();
    } catch (e) {
      Logger.error('Error fetching equipment status changes: $e');
      return [];
    }
  }

  /// Search logs with multiple filters
  Future<List<AuditLog>> searchLogs({
    String? userId,
    String? actionType,
    String? targetType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('audit_logs').select();

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (actionType != null) {
        query = query.eq('action_type', actionType);
      }

      if (targetType != null) {
        query = query.eq('target_type', targetType);
      }

      if (startDate != null) {
        query = query.gte('timestamp', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('timestamp', endDate.toIso8601String());
      }

      final response = await query
          .order('timestamp', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => AuditLog.fromJson(json)).toList();
    } catch (e) {
      Logger.error('Error searching logs: $e');
      return [];
    }
  }

  /// Get logs by action category (Equipment, Borrow Request, Category, User, Authentication)
  Future<List<AuditLog>> getLogsByCategory(
    String category, {
    int limit = 100,
  }) async {
    try {
      List<String> actionTypes = [];

      switch (category.toLowerCase()) {
        case 'equipment':
          actionTypes = [
            AuditLog.actionEquipmentCreate,
            AuditLog.actionEquipmentUpdate,
            AuditLog.actionEquipmentDelete,
            AuditLog.actionEquipmentStatusChange,
          ];
          break;
        case 'borrow request':
          actionTypes = [
            AuditLog.actionBorrowCreate,
            AuditLog.actionBorrowUpdate,
            AuditLog.actionBorrowReturn,
          ];
          break;
        case 'category':
          actionTypes = [
            AuditLog.actionCategoryCreate,
            AuditLog.actionCategoryUpdate,
            AuditLog.actionCategoryDelete,
          ];
          break;
        case 'user':
          actionTypes = [
            AuditLog.actionUserCreate,
            AuditLog.actionUserUpdate,
            AuditLog.actionUserDelete,
            AuditLog.actionUserRoleChange,
          ];
          break;
        case 'authentication':
          actionTypes = [AuditLog.actionLogin, AuditLog.actionLogout];
          break;
        default:
          return [];
      }

      final response = await _supabase
          .from('audit_logs')
          .select()
          .inFilter('action_type', actionTypes)
          .order('timestamp', ascending: false)
          .limit(limit);

      return (response as List).map((json) => AuditLog.fromJson(json)).toList();
    } catch (e) {
      Logger.error('Error fetching logs by category: $e');
      return [];
    }
  }

  /// Get total log count
  Future<int> getTotalLogCount() async {
    try {
      final response = await _supabase.from('audit_logs').select('log_id');

      return (response as List).length;
    } catch (e) {
      Logger.error('Error getting total log count: $e');
      return 0;
    }
  }
}
