import 'dart:math';

class EquipmentIdentifiers {
  // Updated to support both old format (XX######) and new format (XXYYYY)
  static final RegExp _serialNumberFormat = RegExp(r'^[A-Z]{2}\d{4,6}$');
  // QR code now matches serial number format (same value)
  static final RegExp _qrCodeFormat = RegExp(r'^[A-Z]{2}\d{4,6}$');

  /// Validates if a serial number matches the format XXYYYY (or XX######)
  /// XX = 2 letter category code
  /// YYYY = 4 digits (new format) or ###### = 6 digits (old format)
  static bool isValidSerialNumber(String? serialNumber) {
    if (serialNumber == null) return false;
    return _serialNumberFormat.hasMatch(serialNumber);
  }

  /// Validates if a QR code matches the serial number format
  /// QR code = Serial number (same value)
  static bool isValidQrCode(String? qrCode) {
    if (qrCode == null) return false;
    return _qrCodeFormat.hasMatch(qrCode);
  }

  /// Generates a serial number in format XX###### where:
  /// XX = first 2 letters of category name (uppercase)
  /// ###### = 6 random digits
  static String generateSerialNumber(String categoryName) {
    final prefix = _getCategoryPrefix(categoryName, 2);
    final number = _generateRandomDigits(6);
    return '$prefix$number';
  }

  /// Generates a QR code in format XXX-###### where:
  /// XXX = first 3 letters of category name (uppercase)
  /// ###### = 6 random alphanumeric characters
  static String generateQrCode(String categoryName) {
    final prefix = _getCategoryPrefix(categoryName, 3);
    final code = _generateRandomAlphanumeric(6);
    return '$prefix-$code';
  }

  /// Gets the category prefix for identifiers
  static String _getCategoryPrefix(String categoryName, int length) {
    final cleaned = categoryName
        .replaceAll(RegExp(r'[^A-Za-z]'), '')
        .toUpperCase();
    if (cleaned.length >= length) return cleaned.substring(0, length);
    return cleaned.padRight(length, 'X');
  }

  /// Generates a random string of digits
  static String _generateRandomDigits(int length) {
    final random = Random();
    return List.generate(length, (_) => random.nextInt(10).toString()).join();
  }

  /// Generates a random alphanumeric string
  static String _generateRandomAlphanumeric(int length) {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
