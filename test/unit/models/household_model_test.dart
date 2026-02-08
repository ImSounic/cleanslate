// test/unit/models/household_model_test.dart
// Unit tests for HouseholdModel

import 'package:flutter_test/flutter_test.dart';
import 'package:cleanslate/data/models/household_model.dart';

void main() {
  group('HouseholdModel', () {
    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test that HouseholdModel correctly parses JSON from database
    // INTENDED USE: Ensure data from Supabase is correctly deserialized
    // ══════════════════════════════════════════════════════════════════════════
    group('fromJson', () {
      test('should correctly parse complete JSON', () {
        // Arrange
        final json = {
          'id': 'test-household-id',
          'name': 'Test Household',
          'code': 'ABC12345',
          'created_at': '2024-01-15T10:30:00.000Z',
          'updated_at': '2024-01-16T12:00:00.000Z',
          'created_by': 'user-123',
          'num_kitchens': 2,
          'num_bathrooms': 3,
          'num_living_rooms': 1,
          'chores_initialized': true,
          'member_count_at_init': 4,
        };

        // Act
        final household = HouseholdModel.fromJson(json);

        // Assert
        expect(household.id, 'test-household-id');
        expect(household.name, 'Test Household');
        expect(household.code, 'ABC12345');
        expect(household.createdBy, 'user-123');
        expect(household.numKitchens, 2);
        expect(household.numBathrooms, 3);
        expect(household.numLivingRooms, 1);
        expect(household.choresInitialized, true);
        expect(household.memberCountAtInit, 4);
      });

      test('should use default values for missing optional fields', () {
        // Arrange
        final json = {
          'id': 'test-id',
          'name': 'Minimal Household',
          'code': 'XYZ99999',
          'created_at': '2024-01-15T10:30:00.000Z',
          'created_by': 'user-456',
        };

        // Act
        final household = HouseholdModel.fromJson(json);

        // Assert
        expect(household.numKitchens, 1); // Default
        expect(household.numBathrooms, 1); // Default
        expect(household.numLivingRooms, 1); // Default
        expect(household.choresInitialized, false); // Default
        expect(household.memberCountAtInit, 0); // Default
        expect(household.updatedAt, isNull);
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test that HouseholdModel correctly serializes to JSON
    // INTENDED USE: Ensure data can be sent to Supabase correctly
    // ══════════════════════════════════════════════════════════════════════════
    group('toJson', () {
      test('should correctly serialize to JSON', () {
        // Arrange
        final household = HouseholdModel(
          id: 'test-id',
          name: 'My Household',
          code: 'CODE1234',
          createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
          createdBy: 'user-789',
          numKitchens: 2,
          numBathrooms: 2,
          numLivingRooms: 1,
          choresInitialized: true,
          memberCountAtInit: 3,
        );

        // Act
        final json = household.toJson();

        // Assert
        expect(json['id'], 'test-id');
        expect(json['name'], 'My Household');
        expect(json['code'], 'CODE1234');
        expect(json['num_kitchens'], 2);
        expect(json['num_bathrooms'], 2);
        expect(json['num_living_rooms'], 1);
        expect(json['chores_initialized'], true);
        expect(json['member_count_at_init'], 3);
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test copyWith creates correct copies with updated fields
    // INTENDED USE: Used when updating household settings (e.g., room config)
    // ══════════════════════════════════════════════════════════════════════════
    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Arrange
        final original = HouseholdModel(
          id: 'test-id',
          name: 'Original Name',
          code: 'CODE1234',
          createdAt: DateTime.now(),
          createdBy: 'user-1',
          numKitchens: 1,
          numBathrooms: 1,
          numLivingRooms: 1,
        );

        // Act
        final updated = original.copyWith(
          name: 'Updated Name',
          numKitchens: 3,
          choresInitialized: true,
        );

        // Assert
        expect(updated.name, 'Updated Name');
        expect(updated.numKitchens, 3);
        expect(updated.choresInitialized, true);
        // Unchanged fields
        expect(updated.id, original.id);
        expect(updated.code, original.code);
        expect(updated.numBathrooms, original.numBathrooms);
      });

      test('should preserve original values when no updates provided', () {
        // Arrange
        final original = HouseholdModel(
          id: 'test-id',
          name: 'Original Name',
          code: 'CODE1234',
          createdAt: DateTime.now(),
          createdBy: 'user-1',
          numKitchens: 2,
          numBathrooms: 3,
          numLivingRooms: 1,
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.name, original.name);
        expect(copy.numKitchens, original.numKitchens);
        expect(copy.numBathrooms, original.numBathrooms);
        expect(copy.numLivingRooms, original.numLivingRooms);
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test totalRooms calculation
    // INTENDED USE: Used for workload calculations and chore distribution
    // ══════════════════════════════════════════════════════════════════════════
    group('totalRooms', () {
      test('should correctly calculate total rooms', () {
        // Arrange
        final household = HouseholdModel(
          id: 'test-id',
          name: 'Test',
          code: 'CODE1234',
          createdAt: DateTime.now(),
          createdBy: 'user-1',
          numKitchens: 2,
          numBathrooms: 3,
          numLivingRooms: 1,
        );

        // Act & Assert
        expect(household.totalRooms, 6); // 2 + 3 + 1
      });

      test('should handle zero rooms correctly', () {
        // Arrange
        final household = HouseholdModel(
          id: 'test-id',
          name: 'Empty',
          code: 'CODE1234',
          createdAt: DateTime.now(),
          createdBy: 'user-1',
          numKitchens: 0,
          numBathrooms: 0,
          numLivingRooms: 0,
        );

        // Act & Assert
        expect(household.totalRooms, 0);
      });
    });
  });
}
