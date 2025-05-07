// lib/data/models/household_member_model.dart
class HouseholdMemberModel {
  final String id;
  final String householdId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  final bool isActive;

  // Additional fields to store user details
  final String? fullName;
  final String? email;
  final String? profileImageUrl;

  HouseholdMemberModel({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.isActive,
    this.fullName,
    this.email,
    this.profileImageUrl,
  });

  factory HouseholdMemberModel.fromJson(Map<String, dynamic> json) {
    return HouseholdMemberModel(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      isActive: json['is_active'] as bool,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'household_id': householdId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'is_active': isActive,
      // We don't include the extra fields in the JSON as they're derived from joins
    };
  }
}
