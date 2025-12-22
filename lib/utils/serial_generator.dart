import 'dart:math';
import '../models/category.dart';

/// Utility class for generating serial numbers and QR codes
/// Format: XXYYYY where XX = category code and YYYY = 4 random digits
class SerialGenerator {
  SerialGenerator._();

  // Category code mapping
  // Maps category names to 2-letter codes
  static const Map<String, String> _categoryCodeMap = {
    'Diagnostic Equipment': 'DI',
    'Laboratory Instruments': 'LA',
    'Laboratory Equipment': 'LA',
    'Surgical Tools': 'SU',
    'Surgical Equipment': 'SU',
    'Monitoring Devices': 'MO',
    'Monitoring Equipment': 'MO',
    'Imaging Equipment': 'IM',
    'Therapeutic Equipment': 'TH',
    'Life Support Systems': 'LS',
    'Life Support Equipment': 'LS',
    'Safety Equipment': 'SA',
    'Consumables': 'CO',
    'Other': 'OT',
    'General': 'GE',
  };

  // Reverse mapping: category code to category name
  static const Map<String, String> _codeToCategory = {
    'DI': 'Diagnostic Equipment',
    'LA': 'Laboratory Equipment',
    'SU': 'Surgical Equipment',
    'MO': 'Monitoring Equipment',
    'IM': 'Imaging Equipment',
    'TH': 'Therapeutic Equipment',
    'LS': 'Life Support Equipment',
    'SA': 'Safety Equipment',
    'CO': 'Consumables',
    'OT': 'Other',
    'GE': 'General',
  };

  /// Get category code from category name
  /// Returns 'GE' (General) if category not found
  static String getCategoryCode(String? categoryName) {
    if (categoryName == null || categoryName.isEmpty) {
      return 'GE';
    }
    
    // Try exact match first
    if (_categoryCodeMap.containsKey(categoryName)) {
      return _categoryCodeMap[categoryName]!;
    }
    
    // Try case-insensitive match
    final lowerCaseName = categoryName.toLowerCase();
    for (final entry in _categoryCodeMap.entries) {
      if (entry.key.toLowerCase() == lowerCaseName) {
        return entry.value;
      }
    }
    
    // Try partial match
    for (final entry in _categoryCodeMap.entries) {
      if (entry.key.toLowerCase().contains(lowerCaseName) ||
          lowerCaseName.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    
    // Default to GE (General)
    return 'GE';
  }

  /// Get category code from Category object
  static String getCategoryCodeFromCategory(Category? category) {
    if (category == null) return 'GE';
    return getCategoryCode(category.name);
  }

  /// Get category name from code
  static String? getCategoryNameFromCode(String code) {
    return _codeToCategory[code.toUpperCase()];
  }

  /// Generate a random 4-digit number as string
  static String _generateRandomDigits() {
    final random = Random();
    // Generate a number between 1000 and 9999
    final number = random.nextInt(9000) + 1000;
    return number.toString();
  }

  /// Generate serial number in format XXYYYY
  /// Example: DI5678 for Diagnostic Equipment
  static String generateSerialNumber(String? categoryName) {
    final categoryCode = getCategoryCode(categoryName);
    final randomDigits = _generateRandomDigits();
    return '$categoryCode$randomDigits';
  }

  /// Generate serial number from Category object
  static String generateSerialNumberFromCategory(Category? category) {
    final categoryCode = getCategoryCodeFromCategory(category);
    final randomDigits = _generateRandomDigits();
    return '$categoryCode$randomDigits';
  }

  /// Since serial number and QR code are the same, this is an alias
  static String generateQRCode(String? categoryName) {
    return generateSerialNumber(categoryName);
  }

  /// Validate serial number format
  /// Must be XXYYYY where XX is 2 letters and YYYY is 4 digits
  static bool isValidSerialFormat(String serial) {
    if (serial.length != 6) return false;
    
    // First 2 characters should be uppercase letters
    final code = serial.substring(0, 2);
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(code)) return false;
    
    // Last 4 characters should be digits
    final digits = serial.substring(2);
    if (!RegExp(r'^\d{4}$').hasMatch(digits)) return false;
    
    return true;
  }

  /// Extract category code from serial number
  static String? extractCategoryCode(String serial) {
    if (!isValidSerialFormat(serial)) return null;
    return serial.substring(0, 2);
  }

  /// Get category name from serial number
  static String? getCategoryFromSerial(String serial) {
    final code = extractCategoryCode(serial);
    if (code == null) return null;
    return getCategoryNameFromCode(code);
  }

  /// Get all category codes
  static List<String> getAllCategoryCodes() {
    return _categoryCodeMap.values.toSet().toList()..sort();
  }

  /// Get all category code mappings
  static Map<String, String> getCategoryCodeMap() {
    return Map.from(_categoryCodeMap);
  }

  /// Format serial number for display (adds hyphen: XX-YYYY)
  static String formatSerialForDisplay(String serial) {
    if (serial.length != 6) return serial;
    return '${serial.substring(0, 2)}-${serial.substring(2)}';
  }
}

/// Utility class for generating borrow request serial numbers
class RequestSerialGenerator {
  RequestSerialGenerator._();

  /// Generates a unique request serial number in format DDMMYYSS
  /// DD = day, MM = month, YY = year (last 2 digits), SS = sequence number (01-99)
  static Future<String> generateRequestSerial(DateTime requestDate, dynamic supabase) async {
    final day = requestDate.day.toString().padLeft(2, '0');
    final month = requestDate.month.toString().padLeft(2, '0');
    final year = (requestDate.year % 100).toString().padLeft(2, '0');
    
    final datePrefix = '$day$month$year';
    
    // Get count of requests on this date to determine sequence number
    final startOfDay = DateTime(requestDate.year, requestDate.month, requestDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    try {
      final existingRequests = await supabase
          .from('borrow_request')
          .select('request_serial')
          .gte('request_date', startOfDay.toIso8601String())
          .lt('request_date', endOfDay.toIso8601String())
          .order('request_serial', ascending: false)
          .limit(1);
      
      int sequenceNumber = 1;
      
      if (existingRequests.isNotEmpty) {
        final lastSerial = existingRequests[0]['request_serial'] as String?;
        if (lastSerial != null && lastSerial.startsWith(datePrefix)) {
          final lastSequence = int.tryParse(lastSerial.substring(6)) ?? 0;
          sequenceNumber = lastSequence + 1;
        }
      }
      
      final sequence = sequenceNumber.toString().padLeft(2, '0');
      return '$datePrefix$sequence';
    } catch (e) {
      // Fallback: use timestamp-based serial
      return '$datePrefix${DateTime.now().millisecondsSinceEpoch % 100}'.padLeft(2, '0');
    }
  }

  /// Validates request serial format
  static bool isValidRequestSerial(String serial) {
    if (serial.length != 8) return false;
    return RegExp(r'^\d{8}$').hasMatch(serial);
  }

  /// Extracts date from request serial
  static DateTime? getDateFromSerial(String serial) {
    if (!isValidRequestSerial(serial)) return null;
    
    try {
      final day = int.parse(serial.substring(0, 2));
      final month = int.parse(serial.substring(2, 4));
      final year = 2000 + int.parse(serial.substring(4, 6));
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }
}
