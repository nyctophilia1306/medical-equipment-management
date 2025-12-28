import 'dart:math';
import '../services/data_service.dart';

class EquipmentIdentifierService {
  final DataService _dataService;

  EquipmentIdentifierService(this._dataService);

  /// Generates a serial number in format XXYYYYYY where:
  /// XX = first 2 letters of category name (uppercase)
  /// YYYYYY = 6 random digits
  Future<String> generateSerial(String categoryName) async {
    String makePrefix() {
      final cleaned = categoryName
          .replaceAll(RegExp(r'[^A-Za-z]'), '')
          .toUpperCase();
      if (cleaned.length >= 2) return cleaned.substring(0, 2);
      return cleaned.padRight(2, 'X');
    }

    bool isUnique = false;
    int attempts = 0;
    const maxAttempts = 10;
    String serial;

    do {
      final prefix = makePrefix();
      final number = Random().nextInt(1000000).toString().padLeft(6, '0');
      serial = '$prefix$number';

      // Check if serial exists
      final exists = await _dataService.serialNumberExists(serial);
      isUnique = !exists;
      attempts++;
    } while (!isUnique && attempts < maxAttempts);

    if (!isUnique) {
      throw Exception(
        'Could not generate unique serial number after $maxAttempts attempts',
      );
    }

    return serial;
  }

  /// Generates a QR code in format CAT-XXXXXX where:
  /// CAT = first 3 letters of category name (uppercase)
  /// XXXXXX = 6 random alphanumeric characters
  Future<String> generateQrCode(String categoryName) async {
    String makePrefix() {
      final cleaned = categoryName
          .replaceAll(RegExp(r'[^A-Za-z]'), '')
          .toUpperCase();
      if (cleaned.length >= 3) return cleaned.substring(0, 3);
      return cleaned.padRight(3, 'X');
    }

    bool isUnique = false;
    int attempts = 0;
    const maxAttempts = 10;
    String qrCode;

    do {
      final prefix = makePrefix();
      final random = Random();
      final chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      final code = List.generate(
        6,
        (_) => chars[random.nextInt(chars.length)],
      ).join();
      qrCode = '$prefix-$code';

      // Check if QR code exists
      final exists = await _dataService.qrCodeExists(qrCode);
      isUnique = !exists;
      attempts++;
    } while (!isUnique && attempts < maxAttempts);

    if (!isUnique) {
      throw Exception(
        'Could not generate unique QR code after $maxAttempts attempts',
      );
    }

    return qrCode;
  }
}
