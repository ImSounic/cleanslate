// lib/data/repositories/user_preferences_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanslate/data/models/user_preferences_model.dart';

class UserPreferencesRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Get user preferences
  Future<UserPreferences?> getUserPreferences(String userId) async {
    try {
      final response =
          await _client
              .from('user_preferences')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

      if (response == null) {
        return null;
      }

      return UserPreferences.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch user preferences: $e');
    }
  }

  // Get current user's preferences
  Future<UserPreferences> getCurrentUserPreferences() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final preferences = await getUserPreferences(userId);

    // Return existing preferences or create default ones
    if (preferences != null) {
      return preferences;
    }

    // Create default preferences for new user
    return UserPreferences(
      userId: userId,
      availableDays: ['saturday', 'sunday'],
      preferredTimeSlots: {
        'morning': false,
        'afternoon': true,
        'evening': true,
      },
      maxChoresPerWeek: 3,
    );
  }

  // Save or update user preferences
  Future<UserPreferences> saveUserPreferences(
    UserPreferences preferences,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Ensure we're saving for the current user
      final dataToSave = preferences.toJson();
      dataToSave['user_id'] = userId;
      dataToSave['updated_at'] = DateTime.now().toIso8601String();

      final response =
          await _client
              .from('user_preferences')
              .upsert(dataToSave)
              .select()
              .single();

      return UserPreferences.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save user preferences: $e');
    }
  }

  // Update specific preference fields
  Future<UserPreferences> updateUserPreferences(
    Map<String, dynamic> updates,
  ) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      updates['updated_at'] = DateTime.now().toIso8601String();

      final response =
          await _client
              .from('user_preferences')
              .update(updates)
              .eq('user_id', userId)
              .select()
              .single();

      return UserPreferences.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update user preferences: $e');
    }
  }

  // Get all preferences for household members
  Future<Map<String, UserPreferences>> getHouseholdMemberPreferences(
    String householdId,
  ) async {
    try {
      // First get all household members
      final members = await _client
          .from('household_members')
          .select('user_id')
          .eq('household_id', householdId)
          .eq('is_active', true);

      final memberIds =
          (members as List).map((m) => m['user_id'] as String).toList();

      if (memberIds.isEmpty) {
        return {};
      }

      // Then get preferences for all members
      final preferences = await _client
          .from('user_preferences')
          .select()
          .inFilter('user_id', memberIds);

      final Map<String, UserPreferences> result = {};

      for (final pref in preferences as List) {
        result[pref['user_id']] = UserPreferences.fromJson(pref);
      }

      // Add default preferences for members without saved preferences
      for (final memberId in memberIds) {
        if (!result.containsKey(memberId)) {
          result[memberId] = UserPreferences(
            userId: memberId,
            availableDays: ['saturday', 'sunday'],
            preferredTimeSlots: {
              'morning': false,
              'afternoon': true,
              'evening': true,
            },
          );
        }
      }

      return result;
    } catch (e) {
      throw Exception('Failed to fetch household member preferences: $e');
    }
  }

  // Check if user has exam period
  Future<bool> isUserInExamPeriod(String userId) async {
    try {
      final preferences = await getUserPreferences(userId);
      if (preferences == null) return false;

      final now = DateTime.now();

      for (final examPeriod in preferences.examPeriods) {
        if (now.isAfter(examPeriod.start) && now.isBefore(examPeriod.end)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Get user's available time slots for a specific date
  Future<List<TimeSlot>> getUserAvailableSlots(
    String userId,
    DateTime date,
  ) async {
    try {
      final preferences = await getUserPreferences(userId);
      if (preferences == null) return [];

      final dayName = _getDayName(date.weekday);

      // Check if user is available on this day
      if (!preferences.availableDays.contains(dayName.toLowerCase())) {
        return [];
      }

      // Generate time slots based on preferences
      final List<TimeSlot> slots = [];

      if (preferences.preferredTimeSlots['morning'] == true) {
        slots.add(
          TimeSlot(
            start: DateTime(date.year, date.month, date.day, 8, 0),
            end: DateTime(date.year, date.month, date.day, 12, 0),
            type: 'morning',
          ),
        );
      }

      if (preferences.preferredTimeSlots['afternoon'] == true) {
        slots.add(
          TimeSlot(
            start: DateTime(date.year, date.month, date.day, 12, 0),
            end: DateTime(date.year, date.month, date.day, 18, 0),
            type: 'afternoon',
          ),
        );
      }

      if (preferences.preferredTimeSlots['evening'] == true) {
        slots.add(
          TimeSlot(
            start: DateTime(date.year, date.month, date.day, 18, 0),
            end: DateTime(date.year, date.month, date.day, 22, 0),
            type: 'evening',
          ),
        );
      }

      return slots;
    } catch (e) {
      throw Exception('Failed to get user available slots: $e');
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }
}

class TimeSlot {
  final DateTime start;
  final DateTime end;
  final String type;

  TimeSlot({required this.start, required this.end, required this.type});

  Duration get duration => end.difference(start);

  bool overlaps(TimeSlot other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }
}
