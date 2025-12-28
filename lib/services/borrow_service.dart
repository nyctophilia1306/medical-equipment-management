import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../utils/logger.dart';
import '../utils/serial_generator.dart';

class BorrowService {
  static final BorrowService _instance = BorrowService._internal();
  factory BorrowService() => _instance;
  BorrowService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Creates multiple borrow requests with the same request serial
  /// All equipment borrowed by same user at same time share one serial number
  Future<String?> createBulkBorrowRequest({
    required String userId,
    required List<String> equipmentIds,
    required List<int> quantities,
    required DateTime requestDate,
    required DateTime returnDate,
    required String createdBy, // User ID of who creates the request
    String? returnCondition,
    bool isRecurring = false,
    String? recurrencePattern,
  }) async {
    if (equipmentIds.length != quantities.length) {
      Logger.error('Equipment IDs and quantities must have same length');
      return null;
    }

    try {
      // Check creator's role
      final creatorData = await _supabase
          .from('users')
          .select('role_id')
          .eq('user_id', createdBy)
          .maybeSingle();

      final isAdmin = creatorData?['role_id'] == 0; // 0 = admin

      // Generate request serial
      final requestSerial = await RequestSerialGenerator.generateRequestSerial(
        requestDate,
        _supabase,
      );
      Logger.debug('Generated request serial: $requestSerial');

      // Create requests for each equipment
      for (int i = 0; i < equipmentIds.length; i++) {
        final equipmentId = equipmentIds[i];
        final quantity = quantities[i];

        // Check equipment availability
        final equipmentResult = await _supabase
            .from('equipment')
            .select('qty, available_qty, status')
            .eq('equipment_id', equipmentId)
            .maybeSingle();

        if (equipmentResult == null) {
          Logger.error('Equipment not found: $equipmentId');
          continue;
        }

        final availableQty =
            equipmentResult['available_qty'] as int? ??
            equipmentResult['qty'] as int;
        if (availableQty < quantity) {
          Logger.error(
            'Not enough available quantity for $equipmentId. Requested: $quantity, Available: $availableQty',
          );
          continue;
        }

        // Create request - auto-approve if admin, pending if manager
        final data = {
          'user_id': userId,
          'equipment_id': equipmentId,
          'request_date': requestDate.toIso8601String(),
          'return_date': returnDate.toIso8601String(),
          'quantity': quantity,
          'status': isAdmin
              ? 'active'
              : 'pending', // Admin: auto-approve, Manager: pending
          'request_serial': requestSerial,
          'is_equipment_returned': false,
          'is_recurring': isRecurring,
          if (recurrencePattern != null)
            'recurrence_pattern': recurrencePattern,
          // Auto-approve if admin
          if (isAdmin) ...{
            'approved_by': createdBy,
            'approval_date': DateTime.now().toIso8601String(),
          },
          if (returnCondition != null) 'return_condition': returnCondition,
        };

        await _supabase.from('borrow_request').insert(data);

        // Reduce equipment quantity immediately if admin, otherwise wait for approval
        if (isAdmin) {
          await _updateEquipmentQuantityForBorrow(
            equipmentId,
            -quantity, // Negative for borrowing
          );
        }
      }

      return requestSerial;
    } catch (e) {
      Logger.error('Failed to create bulk borrow request: $e');
      return null;
    }
  }

  // Create a single borrow request with auto-generated request serial
  Future<bool> createBorrowRequest({
    required String userId,
    required String equipmentId,
    required DateTime requestDate,
    required DateTime returnDate,
    required String createdBy, // User ID of who creates the request
    int quantity = 1,
    String? returnCondition,
    bool isRecurring = false,
    String? recurrencePattern,
  }) async {
    try {
      // Check creator's role
      final creatorData = await _supabase
          .from('users')
          .select('role_id')
          .eq('user_id', createdBy)
          .maybeSingle();

      final isAdmin = creatorData?['role_id'] == 0; // 0 = admin

      // Generate request serial
      final requestSerial = await RequestSerialGenerator.generateRequestSerial(
        requestDate,
        _supabase,
      );

      // First, check if equipment has enough available quantity
      final equipmentResult = await _supabase
          .from('equipment')
          .select('qty, available_qty, status')
          .eq('equipment_id', equipmentId)
          .maybeSingle();

      if (equipmentResult == null) {
        Logger.error('Equipment not found: $equipmentId');
        return false;
      }

      final availableQty =
          equipmentResult['available_qty'] as int? ??
          equipmentResult['qty'] as int;
      if (availableQty < quantity) {
        Logger.error(
          'Not enough available quantity. Requested: $quantity, Available: $availableQty',
        );
        return false;
      }

      // Create request - auto-approve if admin, pending if manager
      final data = {
        'user_id': userId,
        'equipment_id': equipmentId,
        'request_date': requestDate.toIso8601String(),
        'return_date': returnDate.toIso8601String(),
        'quantity': quantity,
        'status': isAdmin
            ? 'active'
            : 'pending', // Admin: auto-approve, Manager: pending
        'request_serial': requestSerial,
        'is_equipment_returned': false,
        'is_recurring': isRecurring,
        if (recurrencePattern != null) 'recurrence_pattern': recurrencePattern,
        // Auto-approve if admin
        if (isAdmin) ...{
          'approved_by': createdBy,
          'approval_date': DateTime.now().toIso8601String(),
        },
        if (returnCondition != null) 'return_condition': returnCondition,
      };

      await _supabase.from('borrow_request').insert(data);

      // Reduce equipment quantity immediately if admin, otherwise wait for approval
      if (isAdmin) {
        await _updateEquipmentQuantityForBorrow(equipmentId, -quantity);
      }

      return true;
    } catch (e) {
      Logger.error('Failed to create borrow request: $e');
      return false;
    }
  }

  // Approve a pending borrow request - update status AND reduce equipment quantity
  Future<bool> approveBorrowRequest(
    String requestId, {
    required String approvedBy,
  }) async {
    try {
      // Fetch the request
      final req = await _supabase
          .from('borrow_request')
          .select()
          .eq('request_id', requestId)
          .maybeSingle();
      if (req == null) return false;

      final equipmentId = req['equipment_id'] as String;
      final quantity = req['quantity'] as int;

      // Check equipment availability
      final equipmentResult = await _supabase
          .from('equipment')
          .select('qty, available_qty, status')
          .eq('equipment_id', equipmentId)
          .maybeSingle();

      if (equipmentResult == null) {
        Logger.error('Equipment not found: $equipmentId');
        return false;
      }

      final availableQty =
          equipmentResult['available_qty'] as int? ??
          equipmentResult['qty'] as int;
      if (availableQty < quantity) {
        Logger.error(
          'Not enough available quantity. Requested: $quantity, Available: $availableQty',
        );
        return false;
      }

      // Update request status to active
      await _supabase
          .from('borrow_request')
          .update({
            'status': 'active',
            'approved_by': approvedBy,
            'approval_date': DateTime.now().toIso8601String(),
          })
          .eq('request_id', requestId);

      // NOW reduce equipment quantity after approval
      final newAvailableQty = availableQty - quantity;
      final updateData = {
        'available_qty': newAvailableQty,
        'status': newAvailableQty <= 0 ? 'borrowed' : 'available',
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('equipment')
          .update(updateData)
          .eq('equipment_id', equipmentId);

      Logger.info(
        'Borrow request approved: $requestId, equipment quantity updated',
      );
      return true;
    } catch (e) {
      Logger.error('Failed to approve borrow request: $e');
      return false;
    }
  }

  // Reject a pending borrow request
  Future<bool> rejectBorrowRequest(String requestId, String reason) async {
    try {
      await _supabase
          .from('borrow_request')
          .update({
            'status': 'rejected',
            'rejection_reason': reason,
            'rejection_date': DateTime.now().toIso8601String(),
          })
          .eq('request_id', requestId);

      Logger.info('Borrow request rejected: $requestId');
      return true;
    } catch (e) {
      Logger.error('Failed to reject borrow request: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getBorrowRequests({
    String? status,
    bool? isReturned,
    String? userId,
    String? equipmentId,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _supabase.from('borrow_request').select('''
        *,
        equipment:equipment_id (
          equipment_name,
          serial_number,
          model,
          equipment_categories:category_id (
            category_name
          )
        ),
        users:user_id (
          full_name,
          phone
        )
      ''');

      if (status != null) {
        query = query.eq('status', status);
      }
      if (isReturned != null) {
        query = query.eq('is_returned', isReturned);
      }
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      if (equipmentId != null) {
        query = query.eq('equipment_id', equipmentId);
      }

      final response = await query
          .order('request_date', ascending: false)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 100) - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Failed to fetch borrow requests: $e');
      throw Exception('Failed to fetch borrow requests: $e');
    }
  }

  /// Mark equipment as returned - supports partial returns
  /// Accepts a list of request IDs to return
  /// Updates is_equipment_returned for each, restores quantity, updates status
  Future<bool> markAsReturned({
    String? requestId, // For backward compatibility - single request
    List<String>? requestIds, // For new bulk return functionality
    String? returnCondition,
  }) async {
    try {
      // Determine which requests to process
      List<String> idsToReturn = [];
      if (requestIds != null && requestIds.isNotEmpty) {
        idsToReturn = requestIds;
      } else if (requestId != null) {
        idsToReturn = [requestId];
      } else {
        Logger.error('No request IDs provided to markAsReturned');
        return false;
      }

      Logger.debug('Marking ${idsToReturn.length} equipment as returned');

      // Process each request
      for (final id in idsToReturn) {
        // Get the request and equipment information
        final request = await _supabase
            .from('borrow_request')
            .select(
              'equipment_id, quantity, request_serial, is_equipment_returned',
            )
            .eq('request_id', id)
            .maybeSingle();

        if (request == null) {
          Logger.error('Request not found: $id');
          continue;
        }

        // Skip if already returned
        if (request['is_equipment_returned'] == true) {
          Logger.debug('Request $id already marked as returned, skipping');
          continue;
        }

        final equipment = await _supabase
            .from('equipment')
            .select('qty, available_qty')
            .eq('equipment_id', request['equipment_id'])
            .maybeSingle();

        if (equipment == null) {
          Logger.error('Equipment not found: ${request['equipment_id']}');
          continue;
        }

        final currentAvailableQty =
            equipment['available_qty'] as int? ?? equipment['qty'] as int;
        final returnedQty = request['quantity'] as int;
        final newAvailableQty = currentAvailableQty + returnedQty;

        // Update the request - mark as equipment returned
        final updateData = {
          'is_equipment_returned': true,
          'actual_return_date': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (returnCondition != null)
          updateData['return_condition'] = returnCondition;

        await _supabase
            .from('borrow_request')
            .update(updateData)
            .eq('request_id', id);

        // Update equipment available quantity
        await _supabase
            .from('equipment')
            .update({
              'available_qty': newAvailableQty,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('equipment_id', request['equipment_id']);

        Logger.debug('Returned equipment $id, restored $returnedQty units');

        // Check if all equipment in the request serial are returned
        final requestSerial = request['request_serial'] as String?;
        if (requestSerial != null) {
          final allRequestsInSerial = await _supabase
              .from('borrow_request')
              .select('request_id, is_equipment_returned')
              .eq('request_serial', requestSerial);

          final allReturned = allRequestsInSerial.every(
            (r) => r['is_equipment_returned'] == true,
          );

          if (allReturned) {
            // Update all requests in this serial to have status 'returned'
            await _supabase
                .from('borrow_request')
                .update({'status': 'returned', 'is_returned': true})
                .eq('request_serial', requestSerial);

            Logger.debug(
              'All equipment in serial $requestSerial returned, status updated',
            );
          }
        }

        // Update equipment status to 'available' if quantity allows
        final totalQty = equipment['qty'] as int;
        if (newAvailableQty > 0) {
          await _supabase
              .from('equipment')
              .update({
                'status': newAvailableQty >= totalQty
                    ? 'available'
                    : 'partially_available',
              })
              .eq('equipment_id', request['equipment_id']);
        }
      }

      return true;
    } catch (e) {
      Logger.error('Failed to mark request as returned: $e');
      return false;
    }
  }

  // Simple user search
  Future<List<Map<String, dynamic>>> findUsers(String q) async {
    try {
      final resp = await _supabase
          .from('users')
          .select('user_id, full_name, phone, dob, gender')
          .ilike('full_name', '%$q%')
          .limit(20);
      return List<Map<String, dynamic>>.from(resp);
    } catch (e) {
      Logger.error('User search failed: $e');
      return [];
    }
  }

  // Create a simple user record (if you have a users table)
  Future<void> _updateEquipmentQuantityForBorrow(
    String equipmentId,
    int quantityChange,
  ) async {
    try {
      // Update equipment quantity
      await _supabase.rpc(
        'update_equipment_quantity',
        params: {
          'p_equipment_id': equipmentId,
          'p_quantity_change': quantityChange,
        },
      );
    } catch (e) {
      Logger.error('Failed to update equipment quantity: $e');
      throw Exception('Failed to update equipment quantity: $e');
    }
  }

  Future<String?> createUser({
    required String userName,
    required String fullName,
    String? phone,
    required DateTime dob,
    required String gender,
  }) async {
    try {
      // Generate a UUID v4 for the user_id
      final userId = const Uuid().v4();
      Logger.debug('Creating user with generated UUID: $userId');

      final data = {
        'user_id': userId,
        'user_name': userName,
        'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'dob': dob.toIso8601String().split('T')[0], // Store only the date part
        'gender': gender,
        'role_id': 2, // Normal user role
      };
      Logger.debug('Inserting user data: $data');

      await _supabase.from('users').insert(data);
      return userId; // Return the generated UUID
    } catch (e) {
      Logger.error('Failed to create user: $e');
      return null;
    }
  }
}
