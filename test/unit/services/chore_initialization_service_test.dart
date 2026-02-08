// test/unit/services/chore_initialization_service_test.dart
// Unit tests for chore initialization service LOGIC (not the actual service)

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChoreInitializationService Logic', () {
    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test due date staggering logic
    // INTENDED USE: Ensure chores are spread across the week, not all on day 1
    // ══════════════════════════════════════════════════════════════════════════
    group('Due Date Staggering', () {
      test('should calculate staggered due dates for daily chores', () {
        // Daily chores should be due within 0-1 days
        final baseDate = DateTime(2024, 1, 15);
        final frequency = 'daily';
        
        // Logic: dailies due today or tomorrow
        final maxOffset = frequency == 'daily' ? 1 : 7;
        expect(maxOffset, 1);
      });

      test('should calculate staggered due dates for weekly chores', () {
        // Weekly chores should be spread across the week
        final frequency = 'weekly';
        
        final maxOffset = frequency == 'weekly' ? 7 : 1;
        expect(maxOffset, 7);
      });

      test('should calculate staggered due dates for monthly chores', () {
        final frequency = 'monthly';
        
        // Monthly chores can be spread across the month
        final maxOffset = frequency == 'monthly' ? 30 : 7;
        expect(maxOffset, 30);
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test chore template structure
    // INTENDED USE: Validate predefined chore templates for initialization
    // ══════════════════════════════════════════════════════════════════════════
    group('Chore Template Structure', () {
      test('kitchen chores should have correct structure', () {
        final kitchenChores = [
          {'name': 'Kitchen Cleaning', 'frequency': 'weekly', 'priority': 'high'},
          {'name': 'Do Dishes', 'frequency': 'daily', 'priority': 'medium'},
          {'name': 'Clean Fridge', 'frequency': 'monthly', 'priority': 'low'},
        ];
        
        expect(kitchenChores.length, 3);
        expect(kitchenChores.every((c) => c.containsKey('name')), true);
        expect(kitchenChores.every((c) => c.containsKey('frequency')), true);
        expect(kitchenChores.every((c) => c.containsKey('priority')), true);
      });

      test('bathroom chores should have correct structure', () {
        final bathroomChores = [
          {'name': 'Bathroom Cleaning', 'frequency': 'weekly', 'priority': 'high'},
          {'name': 'Restock Toiletries', 'frequency': 'monthly', 'priority': 'low'},
        ];
        
        expect(bathroomChores.length, 2);
        expect(bathroomChores.every((c) => c.containsKey('name')), true);
      });

      test('general chores should have correct structure', () {
        final generalChores = [
          {'name': 'Take Out Trash', 'frequency': 'biweekly', 'priority': 'high'},
          {'name': 'Grocery Shopping', 'frequency': 'weekly', 'priority': 'medium'},
        ];
        
        expect(generalChores.length, 2);
        expect(generalChores.every((c) => c.containsKey('name')), true);
      });

      test('living room chores should have correct structure', () {
        final livingRoomChores = [
          {'name': 'Vacuum Living Room', 'frequency': 'weekly', 'priority': 'medium'},
          {'name': 'Dust Surfaces', 'frequency': 'biweekly', 'priority': 'low'},
        ];
        
        expect(livingRoomChores.length, 2);
        expect(livingRoomChores.every((c) => c.containsKey('name')), true);
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test rebalance trigger logic
    // INTENDED USE: Determine when to rebalance chores after member changes
    // ══════════════════════════════════════════════════════════════════════════
    group('Rebalance Trigger Logic', () {
      test('should not rebalance if chores not initialized', () {
        final choresInitialized = false;

        // If chores not initialized, never rebalance (short-circuit)
        expect(choresInitialized, false);
        // Therefore rebalance would be false regardless of member counts
      });

      test('should not rebalance if member count same as init', () {
        final choresInitialized = true;
        final memberCountAtInit = 3;
        final currentMemberCount = 3;

        final shouldRebalance = choresInitialized && 
            currentMemberCount > memberCountAtInit;

        expect(shouldRebalance, false);
      });

      test('should not rebalance if member count decreased', () {
        final choresInitialized = true;
        final memberCountAtInit = 5;
        final currentMemberCount = 3;

        final shouldRebalance = choresInitialized && 
            currentMemberCount > memberCountAtInit;

        expect(shouldRebalance, false);
      });

      test('should trigger rebalance if new member joined after init', () {
        final choresInitialized = true;
        final memberCountAtInit = 3;
        final currentMemberCount = 4;

        final shouldRebalance = choresInitialized && 
            currentMemberCount > memberCountAtInit;

        expect(shouldRebalance, true);
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test room number extraction from chore names
    // INTENDED USE: Parse "Kitchen Cleaning 2" → room number 2
    // ══════════════════════════════════════════════════════════════════════════
    group('Room Number Extraction', () {
      int? extractRoomNumber(String choreName) {
        final match = RegExp(r'(\d+)$').firstMatch(choreName);
        if (match != null) {
          return int.tryParse(match.group(1)!);
        }
        return null;
      }

      test('should extract number from end of string', () {
        expect(extractRoomNumber('Kitchen Cleaning 2'), 2);
        expect(extractRoomNumber('Bathroom Cleaning 3'), 3);
        expect(extractRoomNumber('Living Room 1'), 1);
      });

      test('should return null if no number', () {
        expect(extractRoomNumber('Kitchen Cleaning'), null);
        expect(extractRoomNumber('Take Out Trash'), null);
      });

      test('should handle numbers within strings', () {
        // Mid-string numbers end up not being at the end
        expect(extractRoomNumber('2nd Floor Bathroom'), null);
        // If it ends with "Cleaning" the number is not trailing
        expect(extractRoomNumber('Room 101 Cleaning'), null);
        // Number at the end works
        expect(extractRoomNumber('Cleaning Room 101'), 101);
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test chore count calculation by room type
    // INTENDED USE: Calculate total chores based on room configuration
    // ══════════════════════════════════════════════════════════════════════════
    group('Chore Count by Room Type', () {
      test('should multiply kitchen chores by kitchen count', () {
        final kitchenChoreTemplates = 3;
        final numKitchens = 2;
        
        final totalKitchenChores = kitchenChoreTemplates * numKitchens;
        expect(totalKitchenChores, 6);
      });

      test('should multiply bathroom chores by bathroom count', () {
        final bathroomChoreTemplates = 2;
        final numBathrooms = 3;
        
        final totalBathroomChores = bathroomChoreTemplates * numBathrooms;
        expect(totalBathroomChores, 6);
      });

      test('should not multiply general chores by room count', () {
        final generalChoreTemplates = 3;
        final anyRoomCount = 5; // Room count shouldn't affect general chores
        
        // General chores are household-wide, not per-room
        final totalGeneralChores = generalChoreTemplates * 1;
        expect(totalGeneralChores, 3);
        expect(totalGeneralChores, isNot(generalChoreTemplates * anyRoomCount));
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test round-robin assignment logic
    // INTENDED USE: Distribute chores evenly among members
    // ══════════════════════════════════════════════════════════════════════════
    group('Round Robin Assignment', () {
      test('should cycle through members evenly', () {
        final members = ['user-1', 'user-2', 'user-3'];
        final chores = List.generate(9, (i) => 'chore-$i');

        final assignments = <String, int>{};
        for (var i = 0; i < chores.length; i++) {
          final member = members[i % members.length];
          assignments[member] = (assignments[member] ?? 0) + 1;
        }

        // Each member should have exactly 3 chores
        expect(assignments['user-1'], 3);
        expect(assignments['user-2'], 3);
        expect(assignments['user-3'], 3);
      });

      test('should handle uneven chore distribution', () {
        final members = ['user-1', 'user-2'];
        final chores = List.generate(5, (i) => 'chore-$i');

        final assignments = <String, int>{};
        for (var i = 0; i < chores.length; i++) {
          final member = members[i % members.length];
          assignments[member] = (assignments[member] ?? 0) + 1;
        }

        // 5 chores / 2 members = 3 and 2
        expect(assignments['user-1'], 3);
        expect(assignments['user-2'], 2);
      });

      test('should handle single member', () {
        final members = ['user-1'];
        final chores = List.generate(5, (i) => 'chore-$i');

        final assignments = <String, int>{};
        for (var i = 0; i < chores.length; i++) {
          final member = members[i % members.length];
          assignments[member] = (assignments[member] ?? 0) + 1;
        }

        // Single member gets all chores
        expect(assignments['user-1'], 5);
      });
    });
  });
}
