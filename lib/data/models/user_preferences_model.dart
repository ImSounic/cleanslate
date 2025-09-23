// lib/data/models/user_preferences_model.dart

class UserPreferences {
  final String userId;
  final List<String> preferredChoreTypes;
  final List<String> dislikedChoreTypes;
  final List<String> availableDays;
  final Map<String, bool> preferredTimeSlots;
  final DateTime? semesterStart;
  final DateTime? semesterEnd;
  final List<ExamPeriod> examPeriods;
  final int maxChoresPerWeek;
  final int minHoursBetweenChores;
  final bool preferWeekendChores;
  final bool goHomeWeekends;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPreferences({
    required this.userId,
    this.preferredChoreTypes = const [],
    this.dislikedChoreTypes = const [],
    this.availableDays = const ['saturday', 'sunday'],
    Map<String, bool>? preferredTimeSlots,
    this.semesterStart,
    this.semesterEnd,
    this.examPeriods = const [],
    this.maxChoresPerWeek = 3,
    this.minHoursBetweenChores = 24,
    this.preferWeekendChores = false,
    this.goHomeWeekends = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : preferredTimeSlots =
           preferredTimeSlots ??
           {'morning': false, 'afternoon': true, 'evening': true},
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['user_id'],
      preferredChoreTypes: List<String>.from(
        json['preferred_chore_types'] ?? [],
      ),
      dislikedChoreTypes: List<String>.from(json['disliked_chore_types'] ?? []),
      availableDays: List<String>.from(
        json['available_days'] ?? ['saturday', 'sunday'],
      ),
      preferredTimeSlots: Map<String, bool>.from(
        json['preferred_time_slots'] ??
            {'morning': false, 'afternoon': true, 'evening': true},
      ),
      semesterStart:
          json['semester_start'] != null
              ? DateTime.parse(json['semester_start'])
              : null,
      semesterEnd:
          json['semester_end'] != null
              ? DateTime.parse(json['semester_end'])
              : null,
      examPeriods:
          (json['exam_periods'] as List<dynamic>? ?? [])
              .map((e) => ExamPeriod.fromJson(e))
              .toList(),
      maxChoresPerWeek: json['max_chores_per_week'] ?? 3,
      minHoursBetweenChores: json['min_hours_between_chores'] ?? 24,
      preferWeekendChores: json['prefer_weekend_chores'] ?? false,
      goHomeWeekends: json['go_home_weekends'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'preferred_chore_types': preferredChoreTypes,
      'disliked_chore_types': dislikedChoreTypes,
      'available_days': availableDays,
      'preferred_time_slots': preferredTimeSlots,
      'semester_start': semesterStart?.toIso8601String(),
      'semester_end': semesterEnd?.toIso8601String(),
      'exam_periods': examPeriods.map((e) => e.toJson()).toList(),
      'max_chores_per_week': maxChoresPerWeek,
      'min_hours_between_chores': minHoursBetweenChores,
      'prefer_weekend_chores': preferWeekendChores,
      'go_home_weekends': goHomeWeekends,
    };
  }

  UserPreferences copyWith({
    List<String>? preferredChoreTypes,
    List<String>? dislikedChoreTypes,
    List<String>? availableDays,
    Map<String, bool>? preferredTimeSlots,
    DateTime? semesterStart,
    DateTime? semesterEnd,
    List<ExamPeriod>? examPeriods,
    int? maxChoresPerWeek,
    int? minHoursBetweenChores,
    bool? preferWeekendChores,
    bool? goHomeWeekends,
  }) {
    return UserPreferences(
      userId: userId,
      preferredChoreTypes: preferredChoreTypes ?? this.preferredChoreTypes,
      dislikedChoreTypes: dislikedChoreTypes ?? this.dislikedChoreTypes,
      availableDays: availableDays ?? this.availableDays,
      preferredTimeSlots: preferredTimeSlots ?? this.preferredTimeSlots,
      semesterStart: semesterStart ?? this.semesterStart,
      semesterEnd: semesterEnd ?? this.semesterEnd,
      examPeriods: examPeriods ?? this.examPeriods,
      maxChoresPerWeek: maxChoresPerWeek ?? this.maxChoresPerWeek,
      minHoursBetweenChores:
          minHoursBetweenChores ?? this.minHoursBetweenChores,
      preferWeekendChores: preferWeekendChores ?? this.preferWeekendChores,
      goHomeWeekends: goHomeWeekends ?? this.goHomeWeekends,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class ExamPeriod {
  final DateTime start;
  final DateTime end;

  ExamPeriod({required this.start, required this.end});

  factory ExamPeriod.fromJson(Map<String, dynamic> json) {
    return ExamPeriod(
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'start': start.toIso8601String(), 'end': end.toIso8601String()};
  }
}
