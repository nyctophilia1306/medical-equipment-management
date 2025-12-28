import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class StatisticsService {
  static final StatisticsService _instance = StatisticsService._internal();
  factory StatisticsService() => _instance;
  StatisticsService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get comprehensive system statistics
  Future<Map<String, dynamic>> getSystemStatistics() async {
    try {
      final stats = <String, dynamic>{};

      // Get user statistics
      stats['users'] = await _getUserStats();

      // Get equipment statistics
      stats['equipment'] = await _getEquipmentStats();

      // Get borrow request statistics
      stats['borrowRequests'] = await _getBorrowRequestStats();

      // Get category statistics
      stats['categories'] = await _getCategoryStats();

      return stats;
    } catch (e) {
      Logger.error('Failed to get system statistics: $e');
      return {};
    }
  }

  Future<Map<String, int>> _getUserStats() async {
    try {
      final response = await _supabase.from('users').select('role_id');
      final users = response as List;

      return {
        'total': users.length,
        'admins': users.where((u) => u['role_id'] == 0).length,
        'managers': users.where((u) => u['role_id'] == 1).length,
        'regularUsers': users.where((u) => u['role_id'] == 2).length,
      };
    } catch (e) {
      Logger.error('Failed to get user stats: $e');
      return {'total': 0, 'admins': 0, 'managers': 0, 'regularUsers': 0};
    }
  }

  Future<Map<String, dynamic>> _getEquipmentStats() async {
    try {
      final response = await _supabase
          .from('equipment')
          .select('qty, available_qty, status');
      final equipment = response as List;

      int totalQty = 0;
      int availableQty = 0;
      int borrowed = 0;

      for (var item in equipment) {
        totalQty += (item['qty'] as int?) ?? 0;
        availableQty += (item['available_qty'] as int?) ?? 0;
      }

      borrowed = totalQty - availableQty;

      return {
        'totalItems': equipment.length,
        'totalQuantity': totalQty,
        'availableQuantity': availableQty,
        'borrowedQuantity': borrowed,
        'utilizationRate': totalQty > 0
            ? ((borrowed / totalQty) * 100).toInt()
            : 0,
      };
    } catch (e) {
      Logger.error('Failed to get equipment stats: $e');
      return {
        'totalItems': 0,
        'totalQuantity': 0,
        'availableQuantity': 0,
        'borrowedQuantity': 0,
        'utilizationRate': 0,
      };
    }
  }

  Future<Map<String, int>> _getBorrowRequestStats() async {
    try {
      final response = await _supabase.from('borrow_requests').select('status');
      final requests = response as List;

      return {
        'total': requests.length,
        'pending': requests.where((r) => r['status'] == 'Pending').length,
        'approved': requests.where((r) => r['status'] == 'Approved').length,
        'returned': requests.where((r) => r['status'] == 'Returned').length,
        'rejected': requests.where((r) => r['status'] == 'Rejected').length,
      };
    } catch (e) {
      Logger.error('Failed to get borrow request stats: $e');
      return {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'returned': 0,
        'rejected': 0,
      };
    }
  }

  Future<Map<String, dynamic>> _getCategoryStats() async {
    try {
      // Get total categories
      final categoriesResponse = await _supabase
          .from('equipment_categories')
          .select('category_id');
      final totalCategories = (categoriesResponse as List).length;

      // Get equipment count by category
      final equipmentResponse = await _supabase
          .from('equipment')
          .select('category_id, equipment_categories(category_name)');

      final equipment = equipmentResponse as List;
      final categoryCount = <String, int>{};

      for (var item in equipment) {
        final categoryData = item['equipment_categories'];
        if (categoryData != null) {
          final categoryName = categoryData['category_name'] as String;
          categoryCount[categoryName] = (categoryCount[categoryName] ?? 0) + 1;
        }
      }

      return {
        'totalCategories': totalCategories,
        'distribution': categoryCount,
      };
    } catch (e) {
      Logger.error('Failed to get category stats: $e');
      return {'totalCategories': 0, 'distribution': <String, int>{}};
    }
  }

  /// Get recent activity (last 10 borrow requests)
  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    try {
      final response = await _supabase
          .from('borrow_requests')
          .select('''
            request_id,
            request_serial,
            status,
            request_date,
            users!borrow_requests_user_id_fkey(user_name),
            equipment!borrow_requests_equipment_id_fkey(equipment_name)
          ''')
          .order('request_date', ascending: false)
          .limit(10);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      Logger.error('Failed to get recent activity: $e');
      return [];
    }
  }

  /// Get equipment by category distribution
  Future<Map<String, int>> getEquipmentByCategory() async {
    try {
      final response = await _supabase
          .from('equipment')
          .select('category_id, equipment_categories(category_name)');

      final equipment = response as List;
      final categoryCount = <String, int>{};

      for (var item in equipment) {
        final categoryData = item['equipment_categories'];
        if (categoryData != null) {
          final categoryName = categoryData['category_name'] as String;
          categoryCount[categoryName] = (categoryCount[categoryName] ?? 0) + 1;
        }
      }

      return categoryCount;
    } catch (e) {
      Logger.error('Failed to get equipment by category: $e');
      return {};
    }
  }
}
