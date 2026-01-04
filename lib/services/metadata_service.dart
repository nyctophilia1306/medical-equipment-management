import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import '../utils/logger.dart';
import '../models/audit_log.dart';
import 'audit_log_service.dart';
import 'auth_service.dart';

class MetadataService {
  static final MetadataService _instance = MetadataService._internal();
  factory MetadataService() => _instance;
  MetadataService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Cache to avoid frequent database queries
  List<Category>? _cachedCategories;
  DateTime? _categoriesCacheTime;

  // Cache expiration time (10 minutes)
  final Duration _cacheExpiration = const Duration(minutes: 10);

  // Get all categories
  Future<List<Category>> getCategories({bool forceRefresh = false}) async {
    // Return cached data if available and not expired
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedCategories != null &&
        _categoriesCacheTime != null &&
        now.difference(_categoriesCacheTime!) < _cacheExpiration) {
      Logger.debug(
        'Returning cached categories (${_cachedCategories!.length})',
      );
      return _cachedCategories!;
    }

    try {
      final response = await _supabase
          .from('equipment_categories')
          .select()
          .order('category_name');

      _cachedCategories = response
          .map<Category>((json) => Category.fromJson(json))
          .toList();
      _categoriesCacheTime = now;

      Logger.debug(
        'Fetched ${_cachedCategories!.length} categories from database',
      );
      return _cachedCategories!;
    } catch (e) {
      Logger.error('Failed to fetch categories: $e');
      // Return empty list on error
      return [];
    }
  }

  // Get a category by ID
  Future<Category?> getCategoryById(int id) async {
    // First check the cache
    if (_cachedCategories != null) {
      final cached = _cachedCategories!.where((cat) => cat.id == id).toList();
      if (cached.isNotEmpty) {
        return cached.first;
      }
    }

    try {
      final response = await _supabase
          .from('equipment_categories')
          .select()
          .eq('category_id', id)
          .maybeSingle();

      if (response == null) return null;
      return Category.fromJson(response);
    } catch (e) {
      Logger.error('Failed to fetch category by ID: $e');
      return null;
    }
  }

  // Create a new category
  Future<Category?> createCategory(
    String name, {
    String? description,
    int? parentCategoryId,
  }) async {
    try {
      final categoryData = {
        'category_name': name,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (description != null) categoryData['description'] = description;
      if (parentCategoryId != null) {
        categoryData['parent_category_id'] = parentCategoryId.toString();
      }

      final response = await _supabase
          .from('equipment_categories')
          .insert(categoryData)
          .select()
          .single();

      final newCategory = Category.fromJson(response);

      // Update the cache
      if (_cachedCategories != null) {
        _cachedCategories!.add(newCategory);
      }

      // Log the create action
      try {
        final currentUserId = AuthService().currentUser?.id ?? 'system';
        await AuditLogService().logAction(
          userId: currentUserId,
          actionType: AuditLog.actionCategoryCreate,
          targetType: AuditLog.targetCategory,
          targetId: newCategory.id.toString(),
          details: {
            'name': name,
            'description': description,
            'parentCategoryId': parentCategoryId,
          },
        );
      } catch (e) {
        Logger.error('Failed to log category create action: $e');
      }

      return newCategory;
    } catch (e) {
      Logger.error('Failed to create category: $e');
      return null;
    }
  }

  // Update a category
  Future<bool> updateCategory(Category category) async {
    try {
      await _supabase
          .from('equipment_categories')
          .update(category.toJson())
          .eq('category_id', category.id);

      // Update the cache
      if (_cachedCategories != null) {
        final index = _cachedCategories!.indexWhere((c) => c.id == category.id);
        if (index >= 0) {
          _cachedCategories![index] = category;
        }
      }

      // Log the update action
      try {
        final currentUserId = AuthService().currentUser?.id ?? 'system';
        await AuditLogService().logAction(
          userId: currentUserId,
          actionType: AuditLog.actionCategoryUpdate,
          targetType: AuditLog.targetCategory,
          targetId: category.id.toString(),
          details: {
            'name': category.name,
            'description': category.description,
            'parentCategoryId': category.parentCategoryId,
          },
        );
      } catch (e) {
        Logger.error('Failed to log category update action: $e');
      }

      return true;
    } catch (e) {
      Logger.error('Failed to update category: $e');
      return false;
    }
  }

  // Delete a category
  Future<bool> deleteCategory(int id) async {
    try {
      await _supabase
          .from('equipment_categories')
          .delete()
          .eq('category_id', id);

      // Update the cache
      if (_cachedCategories != null) {
        _cachedCategories!.removeWhere((c) => c.id == id);
      }

      // Log the delete action
      try {
        final currentUserId = AuthService().currentUser?.id ?? 'system';
        await AuditLogService().logAction(
          userId: currentUserId,
          actionType: AuditLog.actionCategoryDelete,
          targetType: AuditLog.targetCategory,
          targetId: id.toString(),
        );
      } catch (e) {
        Logger.error('Failed to log category delete action: $e');
      }

      return true;
    } catch (e) {
      Logger.error('Failed to delete category: $e');
      return false;
    }
  }

  // Clear caches
  void clearCaches() {
    _cachedCategories = null;
    _categoriesCacheTime = null;
    Logger.debug('Metadata caches cleared');
  }
}
