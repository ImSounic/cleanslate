// lib/data/models/household_model.dart
class HouseholdModel {
  final String id;
  final String name;
  final String code; // Added code field
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;

  HouseholdModel({
    required this.id,
    required this.name,
    required this.code,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
  });

  factory HouseholdModel.fromJson(Map<String, dynamic> json) {
    return HouseholdModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      createdBy: json['created_by'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }
}
