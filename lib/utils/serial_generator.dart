import 'dart:math';
import '../models/category.dart';

/// Utility class for generating serial numbers and QR codes
/// Format: XXYYYY where XX = category ID (padded to 2 digits) and YYYY = 4 random digits
class SerialGenerator {
  SerialGenerator._();

  /// Get category code from category ID
  /// Returns '00' (General) if category ID is null or invalid
  static String getCategoryCode(int? categoryId) {
    if (categoryId == null || categoryId < 0) {
      return '00';
    }
    // Pad category ID to 2 digits (01, 02, 03, etc.)
    return categoryId.toString().padLeft(2, '0');
  }

  /// Get category code from Category object
  static String getCategoryCodeFromCategory(Category? category) {
    if (category == null) return '00';
    return getCategoryCode(category.id);
  }

  /// Generate a random 4-digit number as string
  static String _generateRandomDigits() {
    final random = Random();
    // Generate a number between 1000 and 9999
    final number = random.nextInt(9000) + 1000;
    return number.toString();
  }

  /// Generate serial number in format XXYYYY
  /// Example: 015678 for category ID 1
  static String generateSerialNumber(int? categoryId) {
    final categoryCode = getCategoryCode(categoryId);
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
  static String generateQRCode(int? categoryId) {
    return generateSerialNumber(categoryId);
  }

  /// Validate serial number format
  /// Must be XXYYYY where XX is 2 digits and YYYY is 4 digits
  static bool isValidSerialFormat(String serial) {
    if (serial.length != 6) return false;

    // All 6 characters should be digits
    if (!RegExp(r'^\d{6}$').hasMatch(serial)) return false;

    return true;
  }

  /// Extract category code from serial number
  static String? extractCategoryCode(String serial) {
    if (!isValidSerialFormat(serial)) return null;
    return serial.substring(0, 2);
  }

  /// Get category ID from serial number
  static int? getCategoryIdFromSerial(String serial) {
    final code = extractCategoryCode(serial);
    if (code == null) return null;
    return int.tryParse(code);
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
  static Future<String> generateRequestSerial(
    DateTime requestDate,
    dynamic supabase,
  ) async {
    final day = requestDate.day.toString().padLeft(2, '0');
    final month = requestDate.month.toString().padLeft(2, '0');
    final year = (requestDate.year % 100).toString().padLeft(2, '0');

    final datePrefix = '$day$month$year';

    // Get count of requests on this date to determine sequence number
    final startOfDay = DateTime(
      requestDate.year,
      requestDate.month,
      requestDate.day,
    );
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
      return '$datePrefix${DateTime.now().millisecondsSinceEpoch % 100}'
          .padLeft(2, '0');
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
