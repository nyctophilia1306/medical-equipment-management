import '../models/equipment.dart';

extension EquipmentValidation on Equipment {
  bool isValidSerialNumber() {
    if (serialNumber == null) return false;
    // Format: XXYYYY (new) or XX###### (old) - supports both 4 and 6 digit formats
    return RegExp(r'^[A-Z]{2}\d{4,6}$').hasMatch(serialNumber!);
  }

  bool isValidQrCode() {
    if (qrCode == null) return false;
    // QR code now matches serial number format (same value)
    return RegExp(r'^[A-Z]{2}\d{4,6}$').hasMatch(qrCode!);
  }

  bool hasValidIdentifiers() {
    return isValidSerialNumber() && isValidQrCode();
  }
}
