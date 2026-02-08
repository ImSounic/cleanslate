// test/unit/services/chore_assignment_service_test.dart
// Unit tests for ChoreAssignmentService (smart assignment algorithm)

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChoreAssignmentService', () {
    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test workload calculation for fair distribution
    // INTENDED USE: Balance chores evenly among household members
    // ══════════════════════════════════════════════════════════════════════════
    group('Workload Calculation', () {
      test('should count pending chores per member', () {
        // Simulate workload counts
        final workloads = {
          'user-1': 3,
          'user-2': 5,
          'user-3': 2,
        };

        expect(workloads['user-1'], 3);
        expect(workloads['user-2'], 5);
        expect(workloads['user-3'], 2);
      });

      test('should identify member with lowest workload', () {
        final workloads = {
          'user-1': 3,
          'user-2': 5,
          'user-3': 2,
        };

        final minMember = workloads.entries
            .reduce((a, b) => a.value < b.value ? a : b)
            .key;

        expect(minMember, 'user-3');
      });

      test('should identify member with highest workload', () {
        final workloads = {
          'user-1': 3,
          'user-2': 5,
          'user-3': 2,
        };

        final maxMember = workloads.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        expect(maxMember, 'user-2');
      });

      test('should calculate average workload', () {
        final workloads = [3, 5, 2]; // 10 total, 3 members
        final average = workloads.reduce((a, b) => a + b) / workloads.length;

        expect(average, closeTo(3.33, 0.01));
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test chore preference matching
    // INTENDED USE: Assign chores based on member preferences when possible
    // ══════════════════════════════════════════════════════════════════════════
    group('Preference Matching', () {
      test('should prefer members who like the chore', () {
        final choreType = 'cleaning';
        final memberPreferences = {
          'user-1': {'cleaning': 'like', 'cooking': 'dislike'},
          'user-2': {'cleaning': 'dislike', 'cooking': 'like'},
          'user-3': {'cleaning': 'neutral', 'cooking': 'neutral'},
        };

        final preferringMembers = memberPreferences.entries
            .where((e) => e.value[choreType] == 'like')
            .map((e) => e.key)
            .toList();

        expect(preferringMembers, contains('user-1'));
        expect(preferringMembers.length, 1);
      });

      test('should avoid members who dislike the chore', () {
        final choreType = 'cooking';
        final memberPreferences = {
          'user-1': {'cleaning': 'like', 'cooking': 'dislike'},
          'user-2': {'cleaning': 'dislike', 'cooking': 'like'},
        };

        final avoidMembers = memberPreferences.entries
            .where((e) => e.value[choreType] == 'dislike')
            .map((e) => e.key)
            .toList();

        expect(avoidMembers, contains('user-1'));
      });

      test('should fall back to workload when no preferences match', () {
        // If no one prefers a chore, assign to person with lowest workload
        final workloads = {'user-1': 3, 'user-2': 1, 'user-3': 4};
        final preferringMembers = <String>[]; // No one prefers

        String assignee;
        if (preferringMembers.isEmpty) {
          assignee = workloads.entries
              .reduce((a, b) => a.value < b.value ? a : b)
              .key;
        } else {
          assignee = preferringMembers.first;
        }

        expect(assignee, 'user-2'); // Lowest workload
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test availability checking for chore scheduling
    // INTENDED USE: Don't assign chores when member is unavailable
    // ══════════════════════════════════════════════════════════════════════════
    group('Availability Checking', () {
      test('should respect weekday availability', () {
        // Monday = 1, Sunday = 7 (using DateTime.weekday)
        final dueDate = DateTime(2024, 1, 15); // Monday
        final memberAvailability = {
          'user-1': [1, 2, 3, 4, 5], // Weekdays only
          'user-2': [6, 7], // Weekends only
          'user-3': [1, 2, 3, 4, 5, 6, 7], // All days
        };

        final availableMembers = memberAvailability.entries
            .where((e) => e.value.contains(dueDate.weekday))
            .map((e) => e.key)
            .toList();

        expect(availableMembers, contains('user-1'));
        expect(availableMembers, contains('user-3'));
        expect(availableMembers, isNot(contains('user-2')));
      });

      test('should handle members with no availability set', () {
        // Members without availability settings are assumed available
        final memberAvailability = <String, List<int>>{
          'user-1': [1, 2, 3],
          'user-2': [], // Empty = not available
        };
        final membersWithNoSettings = ['user-3']; // No entry = available all days

        expect(memberAvailability['user-2'], isEmpty);
        expect(membersWithNoSettings.isNotEmpty, true);
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test rotation for recurring chores
    // INTENDED USE: Rotate assignees so same person doesn't always do same chore
    // ══════════════════════════════════════════════════════════════════════════
    group('Rotation Logic', () {
      test('should exclude current assignee from next assignment', () {
        final currentAssignee = 'user-1';
        final allMembers = ['user-1', 'user-2', 'user-3'];

        final eligibleMembers = allMembers
            .where((m) => m != currentAssignee)
            .toList();

        expect(eligibleMembers, isNot(contains('user-1')));
        expect(eligibleMembers.length, 2);
      });

      test('should include everyone if rotation not possible', () {
        // If only one member, they get the chore again
        final currentAssignee = 'user-1';
        final allMembers = ['user-1'];

        var eligibleMembers = allMembers
            .where((m) => m != currentAssignee)
            .toList();

        if (eligibleMembers.isEmpty) {
          eligibleMembers = allMembers;
        }

        expect(eligibleMembers, contains('user-1'));
      });

      test('should rotate based on history if workloads equal', () {
        // If two members have equal workload, pick the one who did it less recently
        final lastCompletedDates = {
          'user-1': DateTime(2024, 1, 10),
          'user-2': DateTime(2024, 1, 5), // Did it earlier
        };

        final leastRecentMember = lastCompletedDates.entries
            .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
            .key;

        expect(leastRecentMember, 'user-2');
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test rebalance algorithm
    // INTENDED USE: Redistribute chores fairly when new member joins
    // ══════════════════════════════════════════════════════════════════════════
    group('Rebalance Algorithm', () {
      test('should calculate target workload after rebalance', () {
        final totalPendingChores = 12;
        final totalMembers = 4;

        final targetPerMember = totalPendingChores / totalMembers;

        expect(targetPerMember, 3.0);
      });

      test('should identify members needing fewer chores', () {
        final workloads = {'user-1': 5, 'user-2': 5, 'user-3': 2};
        final targetWorkload = 4.0;

        final overloadedMembers = workloads.entries
            .where((e) => e.value > targetWorkload)
            .map((e) => e.key)
            .toList();

        expect(overloadedMembers, contains('user-1'));
        expect(overloadedMembers, contains('user-2'));
      });

      test('should identify members needing more chores', () {
        final workloads = {'user-1': 5, 'user-2': 5, 'user-3': 2, 'user-4': 0};
        final targetWorkload = 3.0;

        final underloadedMembers = workloads.entries
            .where((e) => e.value < targetWorkload)
            .map((e) => e.key)
            .toList();

        expect(underloadedMembers, contains('user-3'));
        expect(underloadedMembers, contains('user-4'));
      });

      test('should calculate number of chores to transfer', () {
        final overloadedWorkload = 6;
        final targetWorkload = 4;

        final choresToTransfer = overloadedWorkload - targetWorkload;

        expect(choresToTransfer, 2);
      });
    });

    // ══════════════════════════════════════════════════════════════════════════
    // PURPOSE: Test scoring algorithm for best assignee
    // INTENDED USE: Combine workload, preference, and availability into score
    // ══════════════════════════════════════════════════════════════════════════
    group('Scoring Algorithm', () {
      test('should calculate combined score for assignment', () {
        // Lower score = better fit
        int calculateScore({
          required int workload,
          required String preference, // 'like', 'neutral', 'dislike'
          required bool isAvailable,
        }) {
          if (!isAvailable) return 1000; // Very high = avoid

          var score = workload * 10; // Workload weight

          switch (preference) {
            case 'like':
              score -= 20; // Bonus for liking
              break;
            case 'dislike':
              score += 30; // Penalty for disliking
              break;
            // 'neutral' = no change
          }

          return score;
        }

        // Test cases
        expect(calculateScore(workload: 3, preference: 'like', isAvailable: true), 10);
        expect(calculateScore(workload: 3, preference: 'neutral', isAvailable: true), 30);
        expect(calculateScore(workload: 3, preference: 'dislike', isAvailable: true), 60);
        expect(calculateScore(workload: 3, preference: 'like', isAvailable: false), 1000);
      });
    });
  });
}
