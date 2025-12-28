import 'package:flutter/material.dart';
import '../utils/logger.dart';
import '../constants/database_translations.dart';

class Category {
  final int id;
  final String name;
  final String? description;
  final int? parentCategoryId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.parentCategoryId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    try {
      return Category(
        id: json['category_id'] as int,
        name: json['category_name']?.toString() ?? '',
        description: json['description']?.toString(),
        parentCategoryId: json['parent_category_id'] as int?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'].toString())
            : null,
      );
    } catch (e) {
      Logger.error('Error parsing Category from JSON: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'category_name': name,
    };

    // Only add ID for updates, not for inserts (will use the sequence)
    if (id > 0) {
      json['category_id'] = id;
    }

    if (description != null) json['description'] = description;
    if (parentCategoryId != null) json['parent_category_id'] = parentCategoryId;
    json['created_at'] = createdAt.toIso8601String();
    if (updatedAt != null) json['updated_at'] = updatedAt!.toIso8601String();

    return json;
  }

  Category copyWith({
    int? id,
    String? name,
    String? description,
    int? parentCategoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Category(id: $id, name: $name)';

  /// Get localized category name based on current locale
  /// Returns English translation if available and locale is English,
  /// otherwise returns original Vietnamese name
  String getLocalizedName(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return DatabaseTranslations.getCategoryName(name, locale.languageCode);
  }
}
