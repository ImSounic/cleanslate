// lib/data/models/household_model.dart
class HouseholdModel {
  final String id;
  final String name;
  final String code; // Added code field
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;

  // Room configuration
  final int numKitchens;
  final int numBathrooms;
  final int numLivingRooms;

  // Chore initialization tracking
  final bool choresInitialized;
  final int memberCountAtInit;

  HouseholdModel({
    required this.id,
    required this.name,
    required this.code,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.numKitchens = 1,
    this.numBathrooms = 1,
    this.numLivingRooms = 1,
    this.choresInitialized = false,
    this.memberCountAtInit = 0,
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
      numKitchens: json['num_kitchens'] as int? ?? 1,
      numBathrooms: json['num_bathrooms'] as int? ?? 1,
      numLivingRooms: json['num_living_rooms'] as int? ?? 1,
      choresInitialized: json['chores_initialized'] as bool? ?? false,
      memberCountAtInit: json['member_count_at_init'] as int? ?? 0,
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
      'num_kitchens': numKitchens,
      'num_bathrooms': numBathrooms,
      'num_living_rooms': numLivingRooms,
      'chores_initialized': choresInitialized,
      'member_count_at_init': memberCountAtInit,
    };
  }

  /// Create a copy with updated fields.
  HouseholdModel copyWith({
    String? name,
    int? numKitchens,
    int? numBathrooms,
    int? numLivingRooms,
    bool? choresInitialized,
    int? memberCountAtInit,
  }) {
    return HouseholdModel(
      id: id,
      name: name ?? this.name,
      code: code,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      createdBy: createdBy,
      numKitchens: numKitchens ?? this.numKitchens,
      numBathrooms: numBathrooms ?? this.numBathrooms,
      numLivingRooms: numLivingRooms ?? this.numLivingRooms,
      choresInitialized: choresInitialized ?? this.choresInitialized,
      memberCountAtInit: memberCountAtInit ?? this.memberCountAtInit,
    );
  }

  /// Total room count (useful for workload calculations).
  int get totalRooms => numKitchens + numBathrooms + numLivingRooms;
}
