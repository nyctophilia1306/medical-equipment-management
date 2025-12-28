/// Database content translations for categories and equipment
/// Maps Vietnamese names (from database) to English equivalents
class DatabaseTranslations {
  // Category name translations (Vietnamese -> English)
  static const Map<String, String> categoryTranslations = {
    // Medical Equipment Categories
    'Thiết bị chẩn đoán': 'Diagnostic Equipment',
    'Thiết bị phẫu thuật': 'Surgical Equipment',
    'Thiết bị theo dõi': 'Monitoring Equipment',
    'Thiết bị cấp cứu': 'Emergency Equipment',
    'Thiết bị phòng thí nghiệm': 'Laboratory Equipment',
    'Thiết bị hình ảnh': 'Imaging Equipment',
    'Thiết bị hỗ trợ hô hấp': 'Respiratory Support Equipment',
    'Thiết bị phục hồi chức năng': 'Rehabilitation Equipment',
    'Thiết bị nha khoa': 'Dental Equipment',
    'Thiết bị sát khuẩn': 'Sterilization Equipment',
    'Dụng cụ y tế': 'Medical Instruments',
    'Thiết bị chăm sóc bệnh nhân': 'Patient Care Equipment',
    
    // Diagnostic Equipment Subcategories
    'Máy đo huyết áp': 'Blood Pressure Monitor',
    'Máy đo đường huyết': 'Blood Glucose Meter',
    'Nhiệt kế': 'Thermometer',
    'Máy đo SpO2': 'Pulse Oximeter',
    'Máy ECG': 'ECG Machine',
    'Máy siêu âm': 'Ultrasound Machine',
    'Máy X-quang': 'X-ray Machine',
    'Máy CT': 'CT Scanner',
    'Máy MRI': 'MRI Machine',
    
    // Surgical Equipment Subcategories
    'Dao mổ': 'Scalpel',
    'Kéo phẫu thuật': 'Surgical Scissors',
    'Kìm y tế': 'Forceps',
    'Máy đốt điện': 'Electrocautery',
    'Đèn mổ': 'Surgical Light',
    'Bàn mổ': 'Operating Table',
    
    // Monitoring Equipment Subcategories
    'Máy theo dõi bệnh nhân': 'Patient Monitor',
    'Máy đo nhịp tim': 'Heart Rate Monitor',
    'Máy theo dõi huyết áp': 'Blood Pressure Monitor',
    'Máy theo dõi đa thông số': 'Multi-parameter Monitor',
    
    // Laboratory Equipment Subcategories
    'Kính hiển vi': 'Microscope',
    'Máy ly tâm': 'Centrifuge',
    'Tủ ấm': 'Incubator',
    'Máy xét nghiệm': 'Analyzer',
    'Tủ bảo quản mẫu': 'Sample Storage Cabinet',
    
    // Emergency Equipment Subcategories
    'Máy khử rung tim': 'Defibrillator',
    'Bộ cấp cứu': 'Emergency Kit',
    'Bình oxy': 'Oxygen Cylinder',
    'Xe cấp cứu': 'Emergency Cart',
    
    // Respiratory Support Equipment Subcategories
    'Máy thở': 'Ventilator',
    'Máy tạo oxy': 'Oxygen Concentrator',
    'Máy hút đàm': 'Suction Machine',
    'Máy nebulizer': 'Nebulizer',
    
    // Rehabilitation Equipment Subcategories
    'Xe lăn': 'Wheelchair',
    'Nạng': 'Crutches',
    'Máy tập vật lý trị liệu': 'Physical Therapy Equipment',
    'Gậy đi bộ': 'Walking Cane',
    
    // Patient Care Equipment Subcategories
    'Giường bệnh': 'Hospital Bed',
    'Máy đo nhiệt độ': 'Temperature Monitor',
    'Bơm tiêm': 'Infusion Pump',
    'Máy hút sữa': 'Breast Pump',
    
    // Dental Equipment Subcategories
    'Máy khoan nha khoa': 'Dental Drill',
    'Ghế nha khoa': 'Dental Chair',
    'Đèn chiếu nha khoa': 'Dental Light',
    
    // Sterilization Equipment Subcategories
    'Nồi hấp tiệt trùng': 'Autoclave',
    'Tủ sấy khô': 'Drying Cabinet',
    'Máy khử khuẩn': 'Sterilizer',
    'Đèn UV': 'UV Lamp',
  };

  // Equipment name translations (Vietnamese -> English)
  // For equipment with standard Vietnamese names
  static const Map<String, String> equipmentTranslations = {
    // Common medical equipment
    'Máy đo huyết áp điện tử': 'Digital Blood Pressure Monitor',
    'Nhiệt kế điện tử': 'Digital Thermometer',
    'Nhiệt kế thủy ngân': 'Mercury Thermometer',
    'Máy đo đường huyết': 'Blood Glucose Meter',
    'Máy đo SpO2 ngón tay': 'Fingertip Pulse Oximeter',
    'Máy điện tim': 'ECG Machine',
    'Máy siêu âm 3D': '3D Ultrasound Machine',
    'Máy X-quang kỹ thuật số': 'Digital X-ray Machine',
    'Máy CT 64 lát cắt': '64-Slice CT Scanner',
    'Máy MRI 1.5T': '1.5T MRI Scanner',
    'Máy thở nâng cao': 'Advanced Ventilator',
    'Máy khử rung tim tự động': 'Automatic External Defibrillator',
    'Bình oxy y tế': 'Medical Oxygen Cylinder',
    'Xe đẩy cấp cứu': 'Emergency Crash Cart',
    'Giường bệnh điện': 'Electric Hospital Bed',
    'Xe lăn tiêu chuẩn': 'Standard Wheelchair',
    'Máy hút đàm cầm tay': 'Portable Suction Machine',
    'Máy tạo oxy di động': 'Portable Oxygen Concentrator',
    'Kính hiển vi quang học': 'Optical Microscope',
    'Máy ly tâm tốc độ cao': 'High-Speed Centrifuge',
    'Nồi hấp tiệt trùng': 'Steam Sterilizer',
    'Tủ sấy khô y tế': 'Medical Drying Cabinet',
    'Đèn mổ trần': 'Ceiling-Mounted Surgical Light',
    'Bàn mổ điện': 'Electric Operating Table',
    'Ghế nha khoa điện': 'Electric Dental Chair',
    'Máy khoan nha khoa tốc độ cao': 'High-Speed Dental Handpiece',
    'Máy nebulizer siêu âm': 'Ultrasonic Nebulizer',
    'Bơm tiêm tự động': 'Automatic Infusion Pump',
    'Máy theo dõi bệnh nhân đa thông số': 'Multi-Parameter Patient Monitor',
  };

  /// Get localized category name
  /// Returns English translation if available and language is English,
  /// otherwise returns original Vietnamese name
  static String getCategoryName(String vietnameseName, String languageCode) {
    if (languageCode == 'en') {
      return categoryTranslations[vietnameseName] ?? vietnameseName;
    }
    return vietnameseName;
  }

  /// Get localized equipment name
  /// Returns English translation if available and language is English,
  /// otherwise returns original Vietnamese name
  static String getEquipmentName(String vietnameseName, String languageCode) {
    if (languageCode == 'en') {
      return equipmentTranslations[vietnameseName] ?? vietnameseName;
    }
    return vietnameseName;
  }

  /// Add a new category translation (for dynamic additions)
  static void addCategoryTranslation(String vietnamese, String english) {
    // Note: This modifies a const map at runtime, so we'd need to make it non-const
    // For now, this is a placeholder for future enhancement
  }

  /// Add a new equipment translation (for dynamic additions)
  static void addEquipmentTranslation(String vietnamese, String english) {
    // Note: This modifies a const map at runtime, so we'd need to make it non-const
    // For now, this is a placeholder for future enhancement
  }
}
