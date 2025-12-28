import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipment.dart';
import '../models/borrow_request.dart';
import '../models/inventory_log.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';
import '../utils/equipment_identifiers.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  // Expose the Supabase client for diagnostic tools
  SupabaseClient get supabaseClient => _supabase;

  // Equipment CRUD operations
  Future<List<Equipment>> getEquipment({
    String? searchQuery,
    String? category,
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      // Join with equipment_categories table
      var queryBuilder = _supabase.from('equipment').select('''
        *,
        equipment_categories (
          category_name
        )
      ''');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.replaceAll("'", "''");
        final pattern = '%$q%';
        // Search across multiple fields
        queryBuilder = queryBuilder.or(
          'equipment_name.ilike.$pattern,serial_number.ilike.$pattern,manufacturer.ilike.$pattern,qr_code.ilike.$pattern',
        );
      }

      // Filter by category ID instead - first find the category ID for the given name
      if (category != null &&
          category.isNotEmpty &&
          category.toLowerCase() != 'all') {
        try {
          // First get the category ID for the given name
          final categoryResponse = await _supabase
              .from('equipment_categories')
              .select('category_id')
              .eq('category_name', category)
              .maybeSingle();

          if (categoryResponse != null) {
            int categoryId = categoryResponse['category_id'];
            queryBuilder = queryBuilder.eq('category_id', categoryId);
          }
        } catch (categoryError) {
          Logger.error('Error finding category by name: $categoryError');
          // Continue with the query without the category filter
        }
      }

      if (status != null &&
          status.isNotEmpty &&
          status.toLowerCase() != 'all') {
        queryBuilder = queryBuilder.eq('status', status);
      }

      final response = await queryBuilder
          .order('equipment_name') // Use equipment_name for DB
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 1000) - 1);

      // Transform and validate each equipment item
      List<Equipment> equipmentList = [];
      for (var json in response) {
        try {
          // Create a new JSON object with joined data
          final equipmentJson = Map<String, dynamic>.from(json);

          // Add category_name from joined data
          if (json['equipment_categories'] != null) {
            equipmentJson['category_name'] =
                json['equipment_categories']['category_name'];
          }

          final equipment = Equipment.fromJson(equipmentJson);
          equipmentList.add(equipment);
        } catch (itemError) {
          // Log the error but don't fail the entire request
          Logger.error('Error parsing equipment item: $itemError', itemError);
        }
      }

      return equipmentList;
    } catch (e) {
      Logger.error('Failed to fetch equipment: $e', e);
      throw Exception('Failed to fetch equipment: $e');
    }
  }

  Future<Equipment?> getEquipmentById(String id) async {
    try {
      Logger.debug('Fetching equipment with ID: "$id"');

      if (id.isEmpty) {
        Logger.warn('Empty equipment ID provided to getEquipmentById');
        return null;
      }

      // First check if the table exists and has the right columns
      try {
        // Log raw query for diagnostic purposes
        Logger.debug(
          'Running query: SELECT * FROM equipment WHERE equipment_id = \'$id\'',
        );

        final response = await _supabase
            .from('equipment')
            .select()
            .eq(
              'equipment_id',
              id,
            ) // Using equipment_id to match the database field
            .maybeSingle(); // Use maybeSingle instead of single to handle not found case

        if (response == null) {
          Logger.warn('No equipment found with ID: "$id"');
          return null;
        }

        // Log the found record's details for diagnosis
        Logger.debug('Found equipment record: ${response.toString()}');
        Logger.debug(
          'Found equipment name: ${response['equipment_name']}, ID: ${response['equipment_id']}',
        );
        return Equipment.fromJson(response);
      } catch (queryError) {
        Logger.error('Database query error: $queryError');
        return null;
      }
    } catch (e) {
      Logger.error('Error fetching equipment by ID: $e', e);
      return null;
    }
  }

  /// Generate a unique serial number for an equipment item.
  /// Format: <2-LETTER-CATEGORY><8-digit-number>
  /// Example: XR00001234
  Future<String> generateUniqueSerial(String categoryName) async {
    String makePrefix(String name) {
      final cleaned = name.replaceAll(RegExp('[^A-Za-z]'), '').toUpperCase();
      if (cleaned.length >= 2) return cleaned.substring(0, 2);
      if (cleaned.length == 1) return '${cleaned}X';
      return 'XX';
    }

    final prefix = makePrefix(categoryName);
    final rnd = math.Random();

    for (int attempt = 0; attempt < 12; attempt++) {
      final suffix = rnd.nextInt(100000000).toString().padLeft(8, '0');
      final candidate = '$prefix$suffix';

      try {
        // Check collisions against serial_number and qr_code fields
        final existing = await _supabase
            .from('equipment')
            .select('equipment_id')
            .or('serial_number.eq.$candidate,qr_code.eq.$candidate')
            .maybeSingle();

        if (existing == null) {
          return candidate;
        }
      } catch (e) {
        Logger.error('Error checking serial uniqueness: $e');
      }
    }

    // Fallback - use timestamp based serial if random attempts fail
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final fallbackSuffix = ts.substring(ts.length - 8);
    return '${makePrefix(categoryName)}$fallbackSuffix';
  }

  // Distinct lists for filters
  Future<List<String>> getEquipmentCategories() async {
    try {
      // Use the equipment_categories table instead of accessing the 'category' column from equipment table
      final response = await _supabase
          .from('equipment_categories')
          .select('category_name')
          .order('category_name');

      final list = response
          .map<String>((json) => json['category_name'].toString())
          .where((name) => name.isNotEmpty)
          .toList();

      Logger.debug('Fetched ${list.length} categories for dropdown');
      return list;
    } catch (e) {
      Logger.error('Failed to fetch equipment categories: $e', e);
      return [];
    }
  }

  // Location field is removed from the DB schema
  Future<List<String>> getEquipmentLocations() async {
    // Return empty list since location is no longer in schema
    return [];
  }

  Future<Equipment?> getEquipmentByQrCode(String qrCode) async {
    try {
      // Join with equipment_categories table
      final response = await _supabase
          .from('equipment')
          .select('''
            *,
            equipment_categories:category_id (
              category_name
            )
          ''')
          .eq('qr_code', qrCode)
          .maybeSingle();

      if (response == null) return null;

      // Transform the response to include category name
      final equipmentJson = Map<String, dynamic>.from(response);
      if (response['equipment_categories'] != null) {
        equipmentJson['category_name'] =
            response['equipment_categories']['category_name'];
      }

      return Equipment.fromJson(equipmentJson);
    } catch (e) {
      Logger.error('Error fetching equipment by QR code: $e', e);
      return null;
    }
  }

  Future<Equipment?> getEquipmentBySerialNumber(String serialNumber) async {
    try {
      // Join with equipment_categories table
      final response = await _supabase
          .from('equipment')
          .select('''
            *,
            equipment_categories:category_id (
              category_name
            )
          ''')
          .eq('serial_number', serialNumber)
          .maybeSingle();

      if (response == null) return null;

      // Transform the response to include category name
      final equipmentJson = Map<String, dynamic>.from(response);
      if (response['equipment_categories'] != null) {
        equipmentJson['category_name'] =
            response['equipment_categories']['category_name'];
      }

      return Equipment.fromJson(equipmentJson);
    } catch (e) {
      Logger.error('Error fetching equipment by serial number: $e', e);
      return null;
    }
  }

  Future<bool> qrCodeExists(String qrCode) async {
    try {
      final response = await _supabase
          .from('equipment')
          .select('equipment_id')
          .eq('qr_code', qrCode)
          .maybeSingle();
      return response != null;
    } catch (e) {
      Logger.error('Error checking QR code existence: $e', e);
      return false;
    }
  }

  Future<String> getCategoryName(int categoryId) async {
    try {
      final response = await _supabase
          .from('equipment_categories')
          .select('category_name')
          .eq('category_id', categoryId)
          .single();
      return response['category_name'] as String;
    } catch (e) {
      Logger.error('Error getting category name: $e', e);
      return 'General';
    }
  }

  Future<String> generateUniqueSerialNumber(String categoryName) async {
    int attempts = 0;
    const maxAttempts = 10;

    while (attempts < maxAttempts) {
      final serialNumber = EquipmentIdentifiers.generateSerialNumber(
        categoryName,
      );
      if (!await serialNumberExists(serialNumber)) {
        return serialNumber;
      }
      attempts++;
    }
    throw Exception(
      'Could not generate unique serial number after $maxAttempts attempts',
    );
  }

  Future<String> generateUniqueQrCode(String categoryName) async {
    int attempts = 0;
    const maxAttempts = 10;

    while (attempts < maxAttempts) {
      final qrCode = EquipmentIdentifiers.generateQrCode(categoryName);
      if (!await qrCodeExists(qrCode)) {
        return qrCode;
      }
      attempts++;
    }
    throw Exception(
      'Could not generate unique QR code after $maxAttempts attempts',
    );
  }

  Future<bool> serialNumberExists(String serialNumber) async {
    try {
      final response = await _supabase
          .from('equipment')
          .select('equipment_id')
          .eq('serial_number', serialNumber)
          .maybeSingle();
      return response != null;
    } catch (e) {
      Logger.error('Error checking serial number existence: $e', e);
      return false;
    }
  }

  Future<Equipment> createEquipment(Equipment equipment) async {
    if (!_authService.canManageEquipment()) {
      throw Exception('Insufficient permissions');
    }

    try {
      // Validate required fields
      if (equipment.name.isEmpty) {
        throw Exception('Equipment name cannot be empty');
      }

      // Get category name for generating serial and QR code
      String categoryName = 'General';
      if (equipment.categoryId != null) {
        final categoryResponse = await _supabase
            .from('equipment_categories')
            .select('category_name')
            .eq(
              'category_id',
              equipment.categoryId ?? 1,
            ) // Default to General category (ID: 1) if null
            .single();
        categoryName = categoryResponse['category_name'] as String;
      }

      // Generate serial number and QR code if not provided
      final serialNumber =
          equipment.serialNumber ?? await generateUniqueSerial(categoryName);
      final qrCode =
          equipment.qrCode ?? await generateUniqueQrCode(categoryName);

      // Validate formats
      if (!EquipmentIdentifiers.isValidSerialNumber(serialNumber)) {
        throw Exception(
          'Invalid serial number format. Expected: XXYYYY (e.g., DI5678)',
        );
      }
      if (!EquipmentIdentifiers.isValidQrCode(qrCode)) {
        throw Exception(
          'Invalid QR code format. Expected: XXYYYY (same as serial)',
        );
      }

      // Create equipment data with generated fields
      final equipmentData = {
        ...equipment.toJson(),
        'serial_number': serialNumber,
        'qr_code': qrCode,
        'available_qty': equipment
            .quantity, // Set available_qty equal to qty for new equipment
      };

      Logger.debug('Creating equipment with data: ${equipmentData.toString()}');

      final response = await _supabase
          .from('equipment')
          .insert(equipmentData)
          .select()
          .single();

      final createdEquipment = Equipment.fromJson(response);

      try {
        // Log the inventory addition
        await _createInventoryLog(
          equipmentId: createdEquipment.id,
          equipmentName: createdEquipment.name,
          action: 'added',
          quantityChange: createdEquipment.totalQuantity,
          quantityBefore: 0,
          quantityAfter: createdEquipment.totalQuantity,
          reason: 'Initial equipment creation',
        );
      } catch (logError) {
        // Log creation failure shouldn't block the main operation
        Logger.warn('Failed to create inventory log: $logError');
      }

      return createdEquipment;
    } catch (e) {
      throw Exception('Failed to create equipment: $e');
    }
  }

  Future<Equipment> updateEquipment(Equipment equipment) async {
    if (!_authService.canManageEquipment()) {
      throw Exception('Insufficient permissions');
    }

    try {
      // Validate equipment ID with enhanced checks
      final equipmentId = equipment.id.trim();
      Logger.debug('Validating equipment ID for update', {
        'raw_id': equipment.id,
        'trimmed_id': equipmentId,
      });

      if (equipmentId.isEmpty) {
        Logger.error('Empty equipment ID after trimming');
        throw Exception('Equipment ID cannot be empty');
      }

      // Check if equipment exists first with better diagnostics
      Logger.debug('Checking if equipment exists', {'id': equipmentId});
      final existing = await getEquipmentById(equipmentId);

      if (existing == null) {
        Logger.error('Equipment not found for update', {'id': equipmentId});
        throw Exception('Equipment not found with ID: $equipmentId');
      }

      Logger.debug('Found existing equipment', {
        'name': existing.name,
        'id': existing.id,
      });

      // Prepare update data with proper field mapping for the database
      final updateData = equipment.toJson();

      // Include updated timestamp
      updateData['updated_at'] = DateTime.now().toIso8601String();

      // Log the update operation details
      Logger.debug(
        'Updating equipment: ID=${equipment.id}, Name=${equipment.name}',
      );
      Logger.debug('Update data: ${updateData.toString()}');

      // Check if the equipment ID is valid
      if (equipment.id.isEmpty) {
        throw Exception('Cannot update equipment with empty ID');
      }

      // Perform the update with more robust error handling
      final response = await _supabase
          .from('equipment')
          .update(updateData)
          .eq('equipment_id', equipment.id)
          .select()
          .maybeSingle(); // Use maybeSingle instead of single to handle no rows returned

      // If no records were returned, re-fetch the equipment to ensure we have the latest data
      if (response == null) {
        Logger.warn(
          'No equipment returned from update, fetching latest version',
        );
        final latestEquipment = await getEquipmentById(equipment.id);
        if (latestEquipment == null) {
          throw Exception('Equipment not found after update: ${equipment.id}');
        }
        return latestEquipment;
      }

      Logger.debug(
        'Equipment updated successfully: ${response['equipment_name']}',
      );
      final updatedEquipment = Equipment.fromJson(response);

      // Log quantity changes if they occurred
      if (existing.quantity != updatedEquipment.quantity) {
        try {
          await _createInventoryLog(
            equipmentId: equipment.id,
            equipmentName: equipment.name,
            action: 'updated',
            quantityChange: updatedEquipment.quantity - existing.quantity,
            quantityBefore: existing.quantity,
            quantityAfter: updatedEquipment.quantity,
            reason: 'Equipment details updated',
          );
        } catch (logError) {
          // Log creation failure shouldn't block the main operation
          Logger.warn('Failed to create inventory log: $logError');
        }
      }

      return updatedEquipment;
    } catch (e) {
      throw Exception('Failed to update equipment: $e');
    }
  }

  /// Updates equipment with only specific fields to avoid schema issues
  Future<Equipment> safeUpdateEquipment({
    required String equipmentId,
    String? name,
    String? description,
    String? category, // This is now just for display purposes
    int? quantity,
    String? status,
    String? notes,
    String? imageUrl,
    String? manufacturer,
    String? model,
    String? serialNumber,
    int? categoryId, // Add categoryId parameter
    int? roomId, // Add roomId parameter
  }) async {
    if (!_authService.canManageEquipment()) {
      throw Exception('Insufficient permissions');
    }

    try {
      // Validate equipment ID with verbose logging
      Logger.debug('SafeUpdateEquipment called with ID: "$equipmentId"');

      if (equipmentId.isEmpty) {
        Logger.error('Equipment ID is empty in safeUpdateEquipment');
        throw Exception('Equipment ID cannot be empty');
      }

      // Check if equipment exists first with verbose logging
      Logger.debug('Verifying equipment exists with ID: $equipmentId');
      final existing = await getEquipmentById(equipmentId);

      if (existing == null) {
        Logger.error('Equipment not found with ID: $equipmentId');
        throw Exception('Equipment not found with ID: $equipmentId');
      }

      Logger.debug(
        'Found existing equipment: ${existing.name} (ID: ${existing.id})',
      );

      // Create minimal update data with only specified fields
      final Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Only add fields that are provided (not null) and exist in the database
      // Make sure we use the exact field names as they appear in the database
      if (name != null) updateData['equipment_name'] = name;
      if (description != null) updateData['description'] = description;
      // Do not update the 'category' field anymore - it doesn't exist in the database
      if (categoryId != null) updateData['category_id'] = categoryId;
      if (roomId != null) updateData['room_id'] = roomId;
      if (quantity != null) {
        // Calculate proportional available_qty when updating quantity
        final borrowedQty = existing.quantity - existing.availableQty;
        final newAvailableQty = quantity - borrowedQty;
        updateData['qty'] = quantity;
        updateData['available_qty'] = newAvailableQty > 0 ? newAvailableQty : 0;
      }
      if (status != null) updateData['status'] = status;
      if (notes != null) updateData['notes'] = notes;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (serialNumber != null) updateData['serial_number'] = serialNumber;
      if (manufacturer != null) updateData['manufacturer'] = manufacturer;

      // Optional fields that might need ALTER TABLE first
      // The equipment_simplify.sql script adds these if needed
      if (model != null) updateData['model'] = model;
      if (serialNumber != null) updateData['serial_number'] = serialNumber;

      // Log safe update operation details with enhanced diagnostic info
      Logger.debug('Safe updating equipment: ID=$equipmentId');
      Logger.debug('Safe update data: ${updateData.toString()}');

      // First verify if the record exists to help diagnose the problem
      final checkRecord = await _supabase
          .from('equipment')
          .select('equipment_id')
          .eq('equipment_id', equipmentId)
          .maybeSingle();

      if (checkRecord == null) {
        Logger.error(
          'Critical error: Equipment ID $equipmentId not found in database before update',
        );
        throw Exception('Equipment ID not found in database: $equipmentId');
      } else {
        Logger.debug(
          'Record found in database check: ${checkRecord['equipment_id']}',
        );
      }

      try {
        // Perform the update with more robust error handling and diagnostic output
        Logger.debug('Executing update operation...');
        final response = await _supabase
            .from('equipment')
            .update(updateData)
            .eq('equipment_id', equipmentId)
            .select();

        // Check if any rows were returned
        if (response.isEmpty) {
          Logger.warn('Update succeeded but no rows were returned');

          // Re-fetch the equipment to ensure we have the latest data
          final latestEquipment = await getEquipmentById(equipmentId);
          if (latestEquipment == null) {
            throw Exception('Equipment not found after update: $equipmentId');
          }
          Logger.debug('Successfully fetched updated equipment after update');
          return latestEquipment;
        } else {
          Logger.debug(
            'Update succeeded with ${response.length} rows returned',
          );
          final updatedEquipment = Equipment.fromJson(response[0]);

          // Log quantity changes if they occurred
          if (quantity != null &&
              existing.quantity != updatedEquipment.quantity) {
            try {
              await _createInventoryLog(
                equipmentId: equipmentId,
                equipmentName: existing.name,
                action: 'updated',
                quantityChange: quantity - existing.quantity,
                quantityBefore: existing.quantity,
                quantityAfter: quantity,
                reason: 'Equipment details updated',
              );
            } catch (logError) {
              Logger.warn('Failed to create inventory log: $logError');
            }
          }

          return updatedEquipment;
        }
      } catch (updateError) {
        Logger.error('Update operation failed: $updateError');
        throw Exception('Failed to update equipment: $updateError');
      }
    } catch (e) {
      Logger.error('Failed to update equipment: $e', e);
      throw Exception('Failed to update equipment: $e');
    }
  }

  Future<void> deleteEquipment(String id) async {
    if (!_authService.canManageEquipment()) {
      throw Exception('Insufficient permissions');
    }

    try {
      await _supabase.from('equipment').delete().eq('equipment_id', id);
    } catch (e) {
      throw Exception('Failed to delete equipment: $e');
    }
  }

  Future<void> adjustEquipmentQuantity({
    required String equipmentId,
    required int newQuantity,
    required String reason,
    String? notes,
  }) async {
    if (!_authService.canManageEquipment()) {
      throw Exception('Insufficient permissions');
    }

    try {
      final equipment = await getEquipmentById(equipmentId);
      if (equipment == null) {
        throw Exception('Equipment not found');
      }

      final oldQuantity = equipment.quantity;
      final quantityChange = newQuantity - oldQuantity;

      await _supabase
          .from('equipment')
          .update({
            'qty':
                newQuantity, // In the database, this field is 'qty' not 'quantity'
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('equipment_id', equipmentId); // Updated to use equipment_id

      // Log the inventory adjustment
      await _createInventoryLog(
        equipmentId: equipmentId,
        equipmentName: equipment.name,
        action: 'adjusted',
        quantityChange: quantityChange,
        quantityBefore: oldQuantity,
        quantityAfter: newQuantity,
        reason: reason,
        notes: notes,
      );
    } catch (e) {
      throw Exception('Failed to adjust equipment quantity: $e');
    }
  }

  // Borrow Request CRUD operations
  Future<List<BorrowRequest>> getBorrowRequests({
    String? status,
    String? userId,
    String? equipmentId,
    bool? overdue,
    int? limit,
    int? offset,
  }) async {
    try {
      var queryBuilder = _supabase.from('borrow_request').select('*');

      if (status != null && status.isNotEmpty) {
        queryBuilder = queryBuilder.eq('status', status);
      }

      if (userId != null && userId.isNotEmpty) {
        queryBuilder = queryBuilder.eq('user_id', userId);
      }

      if (equipmentId != null && equipmentId.isNotEmpty) {
        queryBuilder = queryBuilder.eq('equipment_id', equipmentId);
      }

      if (overdue == true) {
        queryBuilder = queryBuilder
            .lt('expected_return_date', DateTime.now().toIso8601String())
            .neq('status', 'returned');
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 1000) - 1);

      return response
          .map<BorrowRequest>((json) => BorrowRequest.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch borrow requests: $e');
    }
  }

  Future<BorrowRequest> createBorrowRequest(BorrowRequest request) async {
    if (!_authService.canCreateBorrowRequests()) {
      throw Exception('Insufficient permissions');
    }

    try {
      // Check equipment availability
      final equipment = await getEquipmentById(request.equipmentId);
      if (equipment == null) {
        throw Exception('Equipment not found');
      }

      if (equipment.quantity < request.quantity) {
        throw Exception('Insufficient quantity available');
      }

      final response = await _supabase
          .from('borrow_request')
          .insert(request.toJson())
          .select()
          .single();

      return BorrowRequest.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create borrow request: $e');
    }
  }

  Future<BorrowRequest> updateBorrowRequestStatus({
    required String id,
    required String status,
    String? notes,
    String? rejectionReason,
  }) async {
    if (!_authService.canCreateBorrowRequests()) {
      throw Exception('Insufficient permissions');
    }

    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (notes != null) updateData['notes'] = notes;
      if (rejectionReason != null)
        updateData['rejection_reason'] = rejectionReason;

      final response = await _supabase
          .from('borrow_requests')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      final borrowRequest = BorrowRequest.fromJson(response);

      // If approved, reduce equipment quantity
      if (status == 'approved') {
        await _updateEquipmentQuantityForBorrow(
          borrowRequest.equipmentId,
          -borrowRequest.quantity,
        );
      }

      return borrowRequest;
    } catch (e) {
      throw Exception('Failed to update borrow request: $e');
    }
  }

  Future<BorrowRequest> markAsReturned({
    required String id,
    String? returnNotes,
  }) async {
    if (!_authService.canCreateBorrowRequests()) {
      throw Exception('Insufficient permissions');
    }

    try {
      final updateData = {
        'status': 'returned',
        'actual_return_date': DateTime.now().toIso8601String().split('T')[0],
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (returnNotes != null) updateData['return_notes'] = returnNotes;

      final response = await _supabase
          .from('borrow_requests')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      final borrowRequest = BorrowRequest.fromJson(response);

      // Increase equipment quantity back
      await _updateEquipmentQuantityForBorrow(
        borrowRequest.equipmentId,
        borrowRequest.quantity,
      );

      // Log the return
      await _createInventoryLog(
        equipmentId: borrowRequest.equipmentId,
        equipmentName: borrowRequest.equipmentName,
        action: 'returned',
        quantityChange: borrowRequest.quantity,
        quantityBefore: 0, // Will be updated with actual value
        quantityAfter: 0, // Will be updated with actual value
        reason: 'Equipment returned from borrow',
        notes: returnNotes,
      );

      return borrowRequest;
    } catch (e) {
      throw Exception('Failed to mark as returned: $e');
    }
  }

  // Inventory Log operations
  Future<List<InventoryLog>> getInventoryLogs({
    String? equipmentId,
    String? action,
    int? limit,
    int? offset,
  }) async {
    try {
      var queryBuilder = _supabase.from('inventory_logs').select('*');

      if (equipmentId != null && equipmentId.isNotEmpty) {
        queryBuilder = queryBuilder.eq('equipment_id', equipmentId);
      }

      if (action != null && action.isNotEmpty) {
        queryBuilder = queryBuilder.eq('action', action);
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 1000) - 1);

      return response
          .map<InventoryLog>((json) => InventoryLog.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch inventory logs: $e');
    }
  }

  // Dashboard stats
  Future<DashboardStats> getDashboardStats() async {
    try {
      // This would typically be a single database view or stored procedure
      // For now, we'll make multiple queries
      final equipmentStats = await _supabase
          .from('equipment')
          .select('status, quantity'); // Updated field name

      final userStats = await _supabase.from('users').select('id');

      final borrowRequestStats = await _supabase
          .from('borrow_requests')
          .select('status');

      // Process the results to calculate stats
      int totalEquipment = equipmentStats.length;
      int availableEquipment = 0;
      int borrowedEquipment = 0;
      int maintenanceEquipment = 0;
      int lowStockItems = 0;
      int outOfStockItems = 0;

      for (final item in equipmentStats) {
        final status = item['status'] as String;
        final quantity = item['quantity'] as int; // Updated field name

        if (status == 'available') availableEquipment++;
        if (status == 'borrowed') borrowedEquipment++;
        if (status == 'maintenance') maintenanceEquipment++;

        if (quantity <= 5 && quantity > 0) lowStockItems++;
        if (quantity <= 0) outOfStockItems++;
      }

      int activeBorrowRequests = 0;
      int overdueRequests = 0;
      int pendingRequests = 0;

      for (final request in borrowRequestStats) {
        final status = request['status'] as String;
        if (status == 'approved') activeBorrowRequests++;
        if (status == 'overdue') overdueRequests++;
        if (status == 'pending') pendingRequests++;
      }

      return DashboardStats(
        totalEquipment: totalEquipment,
        availableEquipment: availableEquipment,
        borrowedEquipment: borrowedEquipment,
        maintenanceEquipment: maintenanceEquipment,
        totalUsers: userStats.length,
        activeBorrowRequests: activeBorrowRequests,
        overdueRequests: overdueRequests,
        pendingRequests: pendingRequests,
        lowStockItems: lowStockItems,
        outOfStockItems: outOfStockItems,
      );
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: $e');
    }
  }

  // Private helper methods
  Future<void> _updateEquipmentQuantityForBorrow(
    String equipmentId,
    int quantityChange,
  ) async {
    try {
      final equipment = await getEquipmentById(equipmentId);
      if (equipment == null) {
        Logger.warn('Equipment not found with ID: $equipmentId');
        return;
      }

      // Ensure quantity doesn't go below zero
      final newQuantity = math.max(0, equipment.quantity + quantityChange);

      await _supabase
          .from('equipment')
          .update({
            'qty': newQuantity, // Database field is 'qty' not 'quantity'
            'updated_at': DateTime.now().toIso8601String(),
            // Update status based on new quantity
            'status': newQuantity == 0 ? 'borrowed' : 'available',
          })
          .eq('equipment_id', equipmentId); // Using equipment_id to match DB

      // Log the quantity change
      try {
        await _createInventoryLog(
          equipmentId: equipmentId,
          equipmentName: equipment.name,
          action: quantityChange > 0 ? 'returned' : 'borrowed',
          quantityChange: quantityChange.abs(),
          quantityBefore: equipment.quantity,
          quantityAfter: newQuantity,
          reason: quantityChange > 0
              ? 'Equipment returned'
              : 'Equipment borrowed',
        );
      } catch (logError) {
        // Log failure shouldn't block the operation
        Logger.warn('Failed to log inventory change: $logError');
      }
    } catch (e) {
      Logger.error('Error updating equipment quantity: $e', e);
    }
  }

  Future<void> _createInventoryLog({
    required String equipmentId,
    required String equipmentName,
    required String action,
    required int quantityChange,
    required int quantityBefore,
    required int quantityAfter,
    required String reason,
    String? notes,
  }) async {
    if (_authService.currentUser == null) return;

    try {
      await _supabase.from('inventory_logs').insert({
        'equipment_id': equipmentId,
        'equipment_name': equipmentName,
        'action': action,
        'quantity_change': quantityChange,
        'quantity_before': quantityBefore,
        'quantity_after': quantityAfter,
        'reason': reason,
        'notes': notes,
        'performed_by': _authService.currentUser!.id,
        'performed_by_name': _authService.currentUser!.userName,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Log creation failure shouldn't block the main operation
    }
  }
}
