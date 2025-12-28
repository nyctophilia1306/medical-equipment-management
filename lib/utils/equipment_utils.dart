import 'dart:math';

class EquipmentUtils {
  static final RegExp _serialNumberFormat = RegExp(r'^[A-Z]{2}\d{6}$');
  static final RegExp _qrCodeFormat = RegExp(r'^[A-Z]{3}-[A-Z0-9]{6}$');

  /// Generates a serial number in format XXYYYYYY where:
  /// - XX is first 2 letters of category name
  /// - YYYYYY is 6 random digits
  static String generateSerialNumber(String categoryName) {
    final prefix = _getCategoryPrefix(categoryName, 2);
    final number = _generateRandomDigits(6);
    return '$prefix$number';
  }

  /// Generates a QR code in format CAT-XXXXXX where:
  /// - CAT is first 3 letters of category name
  /// - XXXXXX is 6 random alphanumeric characters
  static String generateQrCode(String categoryName) {
    final prefix = _getCategoryPrefix(categoryName, 3);
    final code = _generateRandomAlphanumeric(6);
    return '$prefix-$code';
  }

  /// Validates serial number format
  static bool isValidSerialNumber(String? serial) {
    if (serial == null) return false;
    return _serialNumberFormat.hasMatch(serial);
  }

  /// Validates QR code format
  static bool isValidQrCode(String? qrCode) {
    if (qrCode == null) return false;
    return _qrCodeFormat.hasMatch(qrCode);
  }

  /// Gets category prefix for serial/QR numbers
  static String _getCategoryPrefix(String categoryName, int length) {
    final cleaned = categoryName
        .replaceAll(RegExp(r'[^A-Za-z]'), '')
        .toUpperCase();
    if (cleaned.length >= length) return cleaned.substring(0, length);
    return cleaned.padRight(length, 'X');
  }

  /// Generates random digits of specified length
  static String _generateRandomDigits(int length) {
    final random = Random();
    return List.generate(length, (_) => random.nextInt(10)).join();
  }

  /// Generates random alphanumeric string of specified length
  static String _generateRandomAlphanumeric(int length) {
    final random = Random();
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
