import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/database_translations.dart';

class Equipment {
  final String id; // equipment_id in DB
  final String name; // equipment_name in DB
  final String description;
  final String? category; // Old category field
  final int quantity; // Total quantity (qty in DB)
  final int availableQty; // Currently available quantity
  final String status; // 'available', 'borrowed', 'maintenance', 'out_of_order'
  final String? imageUrl;
  final String? qrCode;
  final String? serialNumber;
  final String? manufacturer;
  final String? model;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? categoryId; // References equipment_categories table
  final String? categoryName; // From equipment_categories table

  const Equipment({
    required this.id,
    required this.name,
    required this.description,
    this.category,
    required this.quantity,
    int? availableQty,
    required this.status,
    this.imageUrl,
    this.qrCode,
    this.serialNumber,
    this.manufacturer,
    this.model,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.categoryId,
    this.categoryName,
  }) : availableQty = availableQty ?? quantity;

  factory Equipment.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse int values
    int parseIntSafely(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Helper function to safely parse nullable int values
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        if (value.isEmpty) return null;
        return int.tryParse(value);
      }
      return null;
    }

    // Helper function to safely handle image URL
    String? sanitizeImageUrl(dynamic url) {
      if (url == null) return null;
      final urlStr = url.toString().trim();
      if (urlStr.isEmpty) return null;

      // Validate URL format to prevent display errors
      if (urlStr.startsWith('http://') || urlStr.startsWith('https://')) {
        // Basic validation for common image formats
        final lowerUrl = urlStr.toLowerCase();
        if (lowerUrl.endsWith('.jpg') ||
            lowerUrl.endsWith('.jpeg') ||
            lowerUrl.endsWith('.png') ||
            lowerUrl.endsWith('.gif') ||
            lowerUrl.endsWith('.webp') ||
            lowerUrl.contains('image')) {
          return urlStr;
        }
      }

      // Check for relative URLs and add base URL if needed
      if (urlStr.startsWith('/')) {
        // You can add your base URL here if needed
        // return 'https://your-base-url.com$urlStr';
        return null; // Skip relative URLs for now
      }

      // Handle data URLs (base64 encoded images)
      if (urlStr.startsWith('data:image/')) {
        return urlStr;
      }

      return null; // Invalid URL format
    }

    // Extract and validate the ID first
    final rawId = json['equipment_id'];
    String id = '';

    if (rawId != null) {
      id = rawId.toString().trim();
      if (id.isEmpty) {
        throw Exception('Equipment JSON has empty ID after trimming: $json');
      }
    } else {
      // This is potentially serious - log it unless it's a new item
      if (json['created_at'] != null) {
        // We should use Logger here but we can't import it due to circular dependencies
        // This only happens in debug mode anyway
        if (kDebugMode) {
          print('[Equipment] WARNING: JSON missing equipment_id: $json');
        }
      }
    }

    // Get category name from joined data
    String? categoryName;

    // Handle nested category data
    if (json['equipment_categories'] != null) {
      categoryName = json['equipment_categories']['category_name']?.toString();
    }

    // Handle null values and type conversions safely
    return Equipment(
      id: id,
      name: json['equipment_name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      quantity: parseIntSafely(json['qty']),
      availableQty: parseIntSafely(json['available_qty']),
      status: json['status']?.toString() ?? 'available',
      imageUrl: sanitizeImageUrl(json['image_url']),
      // Match database schema fields
      qrCode: json['qr_code']?.toString(),
      serialNumber: json['serial_number']?.toString(),
      manufacturer: json['manufacturer']?.toString(),
      model: json['model']?.toString(),
      notes: json['notes']?.toString(),
      createdAt:
          _tryParseDateTime(json['created_at']?.toString()) ?? DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? _tryParseDateTime(json['updated_at'].toString())
          : null,
      // Category ID from foreign key
      categoryId: parseNullableInt(json['category_id']),
      categoryName: categoryName, // Set from joined data
    );
  }

  Map<String, dynamic> toJson() {
    // Create base map with required fields - aligned with current DB schema
    // Ensure we use the exact field names that match the database schema
    final Map<String, dynamic> json = {
      // Only include equipment_id if it's not empty (for new equipment, let Supabase generate UUID)
      'equipment_name': name,
      'description': description,
      'qty': quantity,
      'available_qty': availableQty,
      'status': status,
    };

    // Only add ID if it's not empty (for updates)
    if (id.isNotEmpty) {
      json['equipment_id'] = id;
    }

    // Add optional fields if they exist
    if (notes != null) json['notes'] = notes;
    if (imageUrl != null) json['image_url'] = imageUrl;
    if (serialNumber != null) json['serial_number'] = serialNumber;
    if (manufacturer != null) json['manufacturer'] = manufacturer;

    // Add category ID
    if (categoryId != null) json['category_id'] = categoryId;

    // Fields that might not exist in the current schema
    // These will be added if the ALTER TABLE script was run
    if (qrCode != null) json['qr_code'] = qrCode;
    if (model != null) json['model'] = model;

    json['created_at'] = createdAt.toIso8601String();
    if (updatedAt != null) {
      json['updated_at'] = updatedAt?.toIso8601String();
    }

    return json;
  }

  Equipment copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? quantity,
    int? availableQty,
    String? status,
    String? imageUrl,
    String? qrCode,
    String? serialNumber,
    String? manufacturer,
    String? model,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? categoryId,
    String? categoryName,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      availableQty: availableQty ?? this.availableQty,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      qrCode: qrCode ?? this.qrCode,
      serialNumber: serialNumber ?? this.serialNumber,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  bool get isAvailable => status == 'available' && availableQty > 0;
  bool get isBorrowed => status == 'borrowed';
  bool get isInMaintenance => status == 'maintenance';
  bool get isOutOfOrder => status == 'out_of_order';
  bool get isLowStock => availableQty <= 5 && availableQty > 0;
  bool get isOutOfStock => availableQty <= 0;

  int get borrowedQuantity => quantity - availableQty;
  double get utilizationRate =>
      quantity > 0 ? (quantity - availableQty) / quantity : 0.0;

  // For backwards compatibility
  int get availableQuantity => availableQty;
  int get totalQuantity => quantity;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Equipment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Equipment(id: $id, name: $name, category: $category, status: $status)';
  }

  // Helper method to safely parse date strings with multiple format handling
  static DateTime? _tryParseDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    // Try standard ISO format first
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      // Try different formats
      try {
        // Try common formats
        if (dateString.contains('/')) {
          // MM/dd/yyyy or dd/MM/yyyy format
          List<String> parts = dateString.split('/');
          if (parts.length == 3) {
            // Assume MM/dd/yyyy for now
            return DateTime(
              int.parse(parts[2]),
              int.parse(parts[0]),
              int.parse(parts[1]),
            );
          }
        } else if (dateString.contains('-')) {
          // yyyy-MM-dd format (without time)
          List<String> parts = dateString.split('-');
          if (parts.length == 3) {
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }
        }

        // Use logger instead of print
        return null;
      } catch (e2) {
        // Use logger instead of print
        return null;
      }
    }
  }

  /// Get localized equipment name based on current locale
  /// Returns English translation if available and locale is English,
  /// otherwise returns original Vietnamese name
  String getLocalizedName(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return DatabaseTranslations.getEquipmentName(name, locale.languageCode);
  }

  /// Get localized category name based on current locale
  /// Returns English translation if available and locale is English,
  /// otherwise returns original Vietnamese categoryName
  String? getLocalizedCategoryName(BuildContext context) {
    if (categoryName == null) return null;
    final locale = Localizations.localeOf(context);
    return DatabaseTranslations.getCategoryName(
      categoryName!,
      locale.languageCode,
    );
  }
}
