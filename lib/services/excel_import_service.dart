import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipment.dart';
import '../utils/logger.dart';
import '../utils/serial_generator.dart';

/// Result of an import operation
class ImportResult {
  final int totalRows;
  final int successCount;
  final int errorCount;
  final int updatedCount; // Count of existing equipment updated
  final List<String> errors;
  final List<Equipment> importedEquipment;

  ImportResult({
    required this.totalRows,
    required this.successCount,
    required this.errorCount,
    required this.updatedCount,
    required this.errors,
    required this.importedEquipment,
  });

  bool get hasErrors => errorCount > 0;
  bool get isSuccess => errorCount == 0 && successCount > 0;
  String get summary =>
      'Total: $totalRows | New: $successCount | Updated: $updatedCount | Errors: $errorCount';
}

/// Validates an Excel row
class RowValidation {
  final bool isValid;
  final String? error;
  final Map<String, dynamic>? data;

  RowValidation.valid(this.data) : isValid = true, error = null;

  RowValidation.invalid(this.error) : isValid = false, data = null;
}

/// Result of create or update operation
class _CreateUpdateResult {
  final Equipment equipment;
  final bool isUpdate;

  _CreateUpdateResult(this.equipment, this.isUpdate);
}

/// Service for importing equipment data from Excel files
/// Expected columns: A=Number, B=Serial, C=Name, D=Description, E=Date Bought, F=Quantity
class ExcelImportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Import equipment from Excel file bytes
  Future<ImportResult> importFromExcel(
    Uint8List fileBytes, {
    int? defaultCategoryId,
    String Function(int rowIndex)? onProgress,
  }) async {
    final errors = <String>[];
    final importedEquipment = <Equipment>[];
    int successCount = 0;
    int updatedCount = 0;
    int errorCount = 0;

    try {
      // Parse Excel file
      final excel = Excel.decodeBytes(fileBytes);

      if (excel.tables.isEmpty) {
        errors.add('Excel file contains no sheets');
        return ImportResult(
          totalRows: 0,
          successCount: 0,
          updatedCount: 0,
          errorCount: 1,
          errors: errors,
          importedEquipment: [],
        );
      }

      // Get the first sheet
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null) {
        errors.add('Failed to read Excel sheet');
        return ImportResult(
          totalRows: 0,
          successCount: 0,
          updatedCount: 0,
          errorCount: 1,
          errors: errors,
          importedEquipment: [],
        );
      }

      // Skip header row (index 0), start from row 1
      final dataRows = sheet.rows.skip(1).toList();

      if (dataRows.isEmpty) {
        errors.add('No data rows found in Excel file');
        return ImportResult(
          totalRows: 0,
          successCount: 0,
          updatedCount: 0,
          errorCount: 1,
          errors: errors,
          importedEquipment: [],
        );
      }

      // Process each row
      for (var i = 0; i < dataRows.length; i++) {
        final rowIndex =
            i +
            2; // +2 because: +1 for skipping header, +1 for 1-based indexing
        final row = dataRows[i];

        // Report progress
        onProgress?.call(rowIndex);

        // Validate and extract data from row
        final validation = _validateAndExtractRow(row, rowIndex);

        if (!validation.isValid) {
          errors.add('Row $rowIndex: ${validation.error}');
          errorCount++;
          continue;
        }

        // Try to create or update equipment
        try {
          final result = await _createOrUpdateEquipment(
            validation.data!,
            rowIndex,
            defaultCategoryId,
          );

          if (result != null) {
            importedEquipment.add(result.equipment);
            if (result.isUpdate) {
              updatedCount++;
            } else {
              successCount++;
            }
          } else {
            errors.add('Row $rowIndex: Failed to process equipment');
            errorCount++;
          }
        } catch (e) {
          errors.add('Row $rowIndex: ${e.toString()}');
          errorCount++;
          Logger.error('Error importing row $rowIndex: $e', e);
        }
      }

      return ImportResult(
        totalRows: dataRows.length,
        successCount: successCount,
        updatedCount: updatedCount,
        errorCount: errorCount,
        errors: errors,
        importedEquipment: importedEquipment,
      );
    } catch (e) {
      Logger.error('Error parsing Excel file: $e', e);
      errors.add('Failed to parse Excel file: $e');
      return ImportResult(
        totalRows: 0,
        successCount: successCount,
        updatedCount: updatedCount,
        errorCount: errorCount + 1,
        errors: errors,
        importedEquipment: importedEquipment,
      );
    }
  }

  /// Validate and extract data from Excel row
  /// Expected columns: A=Number, B=Serial, C=Name, D=Description, E=Date Bought, F=Quantity
  RowValidation _validateAndExtractRow(List<Data?> row, int rowIndex) {
    try {
      // Check if row has enough columns (at least name and quantity)
      if (row.length < 3) {
        return RowValidation.invalid('Row has too few columns');
      }

      // Extract values (null-safe)
      String? serialNumber;
      if (row.length > 1 && row[1] != null) {
        serialNumber = row[1]!.value?.toString().trim();
      }

      String? name;
      if (row.length > 2 && row[2] != null) {
        name = row[2]!.value?.toString().trim();
      }

      String description = '';
      if (row.length > 3 && row[3] != null) {
        description = row[3]!.value?.toString().trim() ?? '';
      }

      // Note: Date bought (column E) is not currently used in equipment model
      // You can add it if needed in the future

      String? quantityStr;
      if (row.length > 5 && row[5] != null) {
        quantityStr = row[5]!.value?.toString().trim();
      }

      // Validate required fields
      if (name == null || name.isEmpty) {
        return RowValidation.invalid('Equipment name is required');
      }

      // Parse quantity
      int quantity = 1;
      if (quantityStr != null && quantityStr.isNotEmpty) {
        final parsed = int.tryParse(quantityStr);
        if (parsed == null) {
          return RowValidation.invalid('Invalid quantity: $quantityStr');
        }
        if (parsed <= 0) {
          return RowValidation.invalid('Quantity must be greater than 0');
        }
        quantity = parsed;
      }

      return RowValidation.valid({
        'serial_number': serialNumber,
        'name': name,
        'description': description,
        'quantity': quantity,
      });
    } catch (e) {
      return RowValidation.invalid('Error reading row: $e');
    }
  }

  /// Create equipment in database from extracted data
  Future<Equipment?> _createEquipmentFromData(
    Map<String, dynamic> data,
    int rowIndex,
    int? defaultCategoryId,
  ) async {
    try {
      // Generate serial number and QR code if not provided
      String? serialNumber = data['serial_number'];
      if (serialNumber == null || serialNumber.isEmpty) {
        // Generate new serial number based on category
        serialNumber = SerialGenerator.generateSerialNumber(defaultCategoryId);
      }

      // Prepare equipment data
      final equipmentData = {
        'equipment_name': data['name'],
        'description': data['description'],
        'qty': data['quantity'],
        'available_qty': data['quantity'], // Initially all available
        'status': 'available',
        'serial_number': serialNumber,
        'qr_code': serialNumber, // Same as serial number
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add category if provided
      if (defaultCategoryId != null) {
        equipmentData['category_id'] = defaultCategoryId;
      }

      // Insert into database
      final response = await _supabase
          .from('equipment')
          .insert(equipmentData)
          .select()
          .single();

      return Equipment.fromJson(response);
    } catch (e) {
      Logger.error('Error creating equipment from row $rowIndex: $e', e);
      rethrow;
    }
  }

  /// Create new equipment or update existing one based on equipment name and category
  Future<_CreateUpdateResult?> _createOrUpdateEquipment(
    Map<String, dynamic> data,
    int rowIndex,
    int? defaultCategoryId,
  ) async {
    try {
      final equipmentName = data['name'] as String;
      final quantity = data['quantity'] as int;

      // Check if equipment with same name and category already exists
      var query = _supabase
          .from('equipment')
          .select()
          .eq('equipment_name', equipmentName);

      if (defaultCategoryId != null) {
        query = query.eq('category_id', defaultCategoryId);
      }

      final existingResponse = await query.maybeSingle();

      if (existingResponse != null) {
        // Equipment exists - update quantity
        final existingEquipment = Equipment.fromJson(existingResponse);
        final newQty = existingEquipment.quantity + quantity;
        final newAvailableQty = existingEquipment.availableQty + quantity;

        final updateData = {
          'qty': newQty,
          'available_qty': newAvailableQty,
          'updated_at': DateTime.now().toIso8601String(),
        };

        final updatedResponse = await _supabase
            .from('equipment')
            .update(updateData)
            .eq('equipment_id', existingEquipment.id)
            .select()
            .single();

        Logger.info(
          'Updated equipment ${existingEquipment.name}: qty $quantity added (total: $newQty)',
        );

        return _CreateUpdateResult(
          Equipment.fromJson(updatedResponse),
          true, // isUpdate
        );
      } else {
        // Equipment doesn't exist - create new one
        final newEquipment = await _createEquipmentFromData(
          data,
          rowIndex,
          defaultCategoryId,
        );

        if (newEquipment != null) {
          Logger.info('Created new equipment: ${newEquipment.name}');
          return _CreateUpdateResult(newEquipment, false); // isNew
        }
        return null;
      }
    } catch (e) {
      Logger.error('Error in createOrUpdateEquipment for row $rowIndex: $e', e);
      rethrow;
    }
  }

  /// Check if serial number already exists
  Future<bool> serialNumberExists(String serialNumber) async {
    try {
      final response = await _supabase
          .from('equipment')
          .select('equipment_id')
          .eq('serial_number', serialNumber)
          .maybeSingle();

      return response != null;
    } catch (e) {
      Logger.error('Error checking serial number: $e', e);
      return false;
    }
  }

  /// Validate Excel file structure
  Future<bool> validateExcelStructure(Uint8List fileBytes) async {
    try {
      final excel = Excel.decodeBytes(fileBytes);

      if (excel.tables.isEmpty) {
        return false;
      }

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty) {
        return false;
      }

      // Check if has at least 3 columns (Number, Serial, Name)
      final firstRow = sheet.rows.first;
      return firstRow.length >= 3;
    } catch (e) {
      Logger.error('Error validating Excel structure: $e', e);
      return false;
    }
  }
}
