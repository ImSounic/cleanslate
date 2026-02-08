// lib/data/services/chore_initialization_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanslate/data/models/household_model.dart';
import 'package:cleanslate/data/repositories/chore_repository.dart';
import 'package:cleanslate/core/utils/debug_logger.dart';

/// Service to handle initial chore assignment for a household.
/// 
/// Creates and assigns chores based on:
/// - Room configuration (kitchens, bathrooms, etc.)
/// - Number of household members
/// - Rotation between members
class ChoreInitializationService {
  final SupabaseClient _client = Supabase.instance.client;
  final ChoreRepository _choreRepository = ChoreRepository();

  /// Chore templates with their frequencies
  static const List<Map<String, dynamic>> _choreTemplates = [
    // Kitchen chores
    {
      'name': 'Kitchen Cleaning',
      'description': 'Clean counters, stove, sink and kitchen surfaces',
      'frequency': 'weekly',
      'room_type': 'kitchen',
      'estimated_duration': 30,
    },
    {
      'name': 'Do Dishes',
      'description': 'Wash dishes, clean and dry the sink',
      'frequency': 'daily',
      'room_type': 'kitchen',
      'estimated_duration': 20,
    },
    // Bathroom chores
    {
      'name': 'Bathroom Cleaning',
      'description': 'Clean toilet, shower, sink, and mirror',
      'frequency': 'weekly',
      'room_type': 'bathroom',
      'estimated_duration': 30,
    },
    // General chores
    {
      'name': 'Take Out Trash',
      'description': 'Empty all bins and take to collection point',
      'frequency': 'weekly',
      'room_type': 'general',
      'estimated_duration': 10,
    },
    {
      'name': 'Vacuum Living Areas',
      'description': 'Vacuum carpets, rugs, and floors',
      'frequency': 'weekly',
      'room_type': 'living_room',
      'estimated_duration': 25,
    },
    {
      'name': 'Mop Floors',
      'description': 'Mop kitchen and bathroom floors',
      'frequency': 'weekly',
      'room_type': 'general',
      'estimated_duration': 20,
    },
    // Restocking
    {
      'name': 'Restock Toilet Paper & Supplies',
      'description': 'Check and restock bathroom essentials',
      'frequency': 'biweekly',
      'room_type': 'bathroom',
      'estimated_duration': 15,
    },
    {
      'name': 'Grocery Shopping',
      'description': 'Buy household essentials and groceries',
      'frequency': 'weekly',
      'room_type': 'general',
      'estimated_duration': 60,
    },
    {
      'name': 'Clean Fridge',
      'description': 'Remove expired items and wipe down shelves',
      'frequency': 'monthly',
      'room_type': 'kitchen',
      'estimated_duration': 30,
    },
  ];

  /// Initialize chores for a household based on its configuration.
  /// 
  /// Returns the number of chores created.
  Future<int> initializeChores({
    required HouseholdModel household,
    required List<String> memberIds,
  }) async {
    if (memberIds.isEmpty) {
      throw Exception('Cannot initialize chores without members');
    }

    debugLog('🏠 Initializing chores for ${household.name}');
    debugLog('👥 Members: ${memberIds.length}');
    debugLog('🏠 Config: ${household.numKitchens} kitchens, ${household.numBathrooms} bathrooms');

    final choresToCreate = <Map<String, dynamic>>[];

    // Generate chores based on room configuration
    for (final template in _choreTemplates) {
      final roomType = template['room_type'] as String;
      int count = 1;

      // Multiply by room count for room-specific chores
      if (roomType == 'kitchen') {
        count = household.numKitchens;
      } else if (roomType == 'bathroom') {
        count = household.numBathrooms;
      } else if (roomType == 'living_room') {
        count = household.numLivingRooms;
      }

      for (int i = 0; i < count; i++) {
        String name = template['name'] as String;
        // Add room number if multiple
        if (count > 1) {
          name = '$name ${i + 1}';
        }

        choresToCreate.add({
          ...template,
          'name': name,
        });
      }
    }

    debugLog('📋 Creating ${choresToCreate.length} chores');

    // Create chores and assign to members in rotation
    int memberIndex = 0;
    int created = 0;
    final now = DateTime.now();

    for (final choreData in choresToCreate) {
      try {
        // Create the chore with recurring settings
        final chore = await _choreRepository.createChore(
          householdId: household.id,
          name: choreData['name'],
          description: choreData['description'],
          estimatedDuration: choreData['estimated_duration'],
          frequency: choreData['frequency'],
          isRecurring: true,
        );
        
        // Mark this chore as an "initial instance" by setting recurrence_parent_id to itself
        // This prevents it from being filtered out as a template
        await _client.from('chores').update({
          'recurrence_parent_id': chore['id'],
        }).eq('id', chore['id']);

        // Calculate due date based on frequency
        final dueDate = _calculateInitialDueDate(
          choreData['frequency'] as String,
          now,
          memberIndex, // Stagger due dates
        );

        // Assign to next member in rotation
        final assignedTo = memberIds[memberIndex % memberIds.length];
        
        await _choreRepository.assignChore(
          choreId: chore['id'],
          assignedTo: assignedTo,
          dueDate: dueDate,
          priority: 'medium',
        );

        memberIndex++;
        created++;

        debugLog('✅ Created: ${choreData['name']} → assigned to member $assignedTo');
      } catch (e) {
        debugLog('❌ Failed to create ${choreData['name']}: $e');
      }
    }

    // Mark household as initialized
    await _client.from('households').update({
      'chores_initialized': true,
      'member_count_at_init': memberIds.length,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', household.id);

    debugLog('✅ Chore initialization complete: $created chores created');
    return created;
  }

  /// Calculate the initial due date based on frequency.
  /// Staggers due dates so not all chores are due on the same day.
  DateTime _calculateInitialDueDate(String frequency, DateTime now, int index) {
    final staggerDays = index % 7; // Stagger across the week

    switch (frequency.toLowerCase()) {
      case 'daily':
        return now.add(Duration(days: 1));
      case 'weekly':
        return now.add(Duration(days: staggerDays + 1));
      case 'biweekly':
        return now.add(Duration(days: staggerDays + 7));
      case 'monthly':
        return now.add(Duration(days: staggerDays + 14));
      default:
        return now.add(Duration(days: staggerDays + 1));
    }
  }

  /// Rebalance chores when new members join.
  /// Reassigns pending chores to distribute evenly.
  Future<int> rebalanceChores({
    required String householdId,
    required List<String> memberIds,
  }) async {
    if (memberIds.isEmpty) return 0;

    debugLog('🔄 Rebalancing chores for household $householdId');

    // Get all pending chore assignments
    final pendingAssignments = await _client
        .from('chore_assignments')
        .select('id, chore_id, assigned_to')
        .eq('status', 'pending')
        .inFilter('chore_id', 
          (await _client
              .from('chores')
              .select('id')
              .eq('household_id', householdId)
          ).map((c) => c['id']).toList()
        );

    if ((pendingAssignments as List).isEmpty) {
      debugLog('⚠️ No pending assignments to rebalance');
      return 0;
    }

    // Count current assignments per member
    final assignmentCounts = <String, int>{};
    for (final memberId in memberIds) {
      assignmentCounts[memberId] = 0;
    }

    for (final assignment in pendingAssignments) {
      final assignee = assignment['assigned_to'] as String;
      if (assignmentCounts.containsKey(assignee)) {
        assignmentCounts[assignee] = (assignmentCounts[assignee] ?? 0) + 1;
      }
    }

    // Find overloaded members and redistribute
    final avgPerMember = pendingAssignments.length / memberIds.length;
    int reassigned = 0;

    for (final assignment in pendingAssignments) {
      final currentAssignee = assignment['assigned_to'] as String;
      final currentCount = assignmentCounts[currentAssignee] ?? 0;

      if (currentCount > avgPerMember + 1) {
        // Find member with fewest assignments
        final minMember = memberIds.reduce((a, b) =>
            (assignmentCounts[a] ?? 0) < (assignmentCounts[b] ?? 0) ? a : b);

        if (minMember != currentAssignee) {
          // Reassign
          await _client
              .from('chore_assignments')
              .update({'assigned_to': minMember})
              .eq('id', assignment['id']);

          assignmentCounts[currentAssignee] = currentCount - 1;
          assignmentCounts[minMember] = (assignmentCounts[minMember] ?? 0) + 1;
          reassigned++;

          debugLog('🔄 Reassigned ${assignment['id']} from $currentAssignee to $minMember');
        }
      }
    }

    // Update member count
    await _client.from('households').update({
      'member_count_at_init': memberIds.length,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', householdId);

    debugLog('✅ Rebalance complete: $reassigned chores reassigned');
    return reassigned;
  }

  /// Check if rebalance is needed (new members joined after init).
  Future<bool> needsRebalance(HouseholdModel household, int currentMemberCount) async {
    if (!household.choresInitialized) return false;
    return currentMemberCount > household.memberCountAtInit;
  }

  /// Adjust chores when room configuration changes.
  /// 
  /// Compares old vs new room counts and adds/removes chores accordingly.
  /// Returns a map with 'added' and 'removed' counts.
  Future<Map<String, int>> adjustChoresForRoomConfigChange({
    required HouseholdModel oldHousehold,
    required HouseholdModel newHousehold,
    required List<String> memberIds,
  }) async {
    if (memberIds.isEmpty) {
      return {'added': 0, 'removed': 0};
    }

    debugLog('🔧 Adjusting chores for room config change');
    debugLog('   Kitchens: ${oldHousehold.numKitchens} → ${newHousehold.numKitchens}');
    debugLog('   Bathrooms: ${oldHousehold.numBathrooms} → ${newHousehold.numBathrooms}');
    debugLog('   Living rooms: ${oldHousehold.numLivingRooms} → ${newHousehold.numLivingRooms}');

    int added = 0;
    int removed = 0;
    final now = DateTime.now();
    int memberIndex = 0;

    // Get existing chores for this household
    final existingChores = await _client
        .from('chores')
        .select('id, name, household_id')
        .eq('household_id', newHousehold.id);

    // Helper to count existing chores by base name
    int countChoresByBaseName(String baseName) {
      return (existingChores as List).where((c) {
        final name = c['name'] as String;
        return name == baseName || name.startsWith('$baseName ');
      }).length;
    }

    // Helper to get chores by base name sorted by number (highest first)
    List<Map<String, dynamic>> getChoresByBaseName(String baseName) {
      final matches = (existingChores as List).where((c) {
        final name = c['name'] as String;
        return name == baseName || name.startsWith('$baseName ');
      }).toList();
      
      // Sort by number in name (descending) so we remove highest numbered first
      matches.sort((a, b) {
        final aNum = _extractNumber(a['name'] as String);
        final bNum = _extractNumber(b['name'] as String);
        return bNum.compareTo(aNum);
      });
      
      return matches.cast<Map<String, dynamic>>();
    }

    // Process each room type
    for (final template in _choreTemplates) {
      final roomType = template['room_type'] as String;
      final baseName = template['name'] as String;
      
      int oldCount = 0;
      int newCount = 0;
      
      if (roomType == 'kitchen') {
        oldCount = oldHousehold.numKitchens;
        newCount = newHousehold.numKitchens;
      } else if (roomType == 'bathroom') {
        oldCount = oldHousehold.numBathrooms;
        newCount = newHousehold.numBathrooms;
      } else if (roomType == 'living_room') {
        oldCount = oldHousehold.numLivingRooms;
        newCount = newHousehold.numLivingRooms;
      } else {
        continue; // Skip general chores, they don't scale with rooms
      }

      final currentChoreCount = countChoresByBaseName(baseName);
      final diff = newCount - oldCount;

      if (diff > 0) {
        // Need to add chores
        for (int i = 0; i < diff; i++) {
          final choreNumber = currentChoreCount + i + 1;
          final choreName = newCount > 1 ? '$baseName $choreNumber' : baseName;
          
          try {
            final chore = await _choreRepository.createChore(
              householdId: newHousehold.id,
              name: choreName,
              description: template['description'],
              estimatedDuration: template['estimated_duration'],
              frequency: template['frequency'],
              isRecurring: true,
            );
            
            // Mark as initial instance
            await _client.from('chores').update({
              'recurrence_parent_id': chore['id'],
            }).eq('id', chore['id']);
            
            // Assign to a member
            final dueDate = _calculateInitialDueDate(
              template['frequency'] as String,
              now,
              memberIndex,
            );
            final assignedTo = memberIds[memberIndex % memberIds.length];
            
            await _choreRepository.assignChore(
              choreId: chore['id'],
              assignedTo: assignedTo,
              dueDate: dueDate,
              priority: 'medium',
            );
            
            memberIndex++;
            added++;
            debugLog('➕ Added: $choreName → assigned to $assignedTo');
          } catch (e) {
            debugLog('❌ Failed to add $choreName: $e');
          }
        }
      } else if (diff < 0) {
        // Need to remove chores (remove highest numbered first)
        final choresToRemove = getChoresByBaseName(baseName).take(-diff);
        
        for (final chore in choresToRemove) {
          try {
            // Delete assignments first, then the chore
            await _client
                .from('chore_assignments')
                .delete()
                .eq('chore_id', chore['id']);
            await _client
                .from('chores')
                .delete()
                .eq('id', chore['id']);
            
            removed++;
            debugLog('➖ Removed: ${chore['name']}');
          } catch (e) {
            debugLog('❌ Failed to remove ${chore['name']}: $e');
          }
        }
      }
    }

    debugLog('✅ Room config adjustment complete: $added added, $removed removed');
    return {'added': added, 'removed': removed};
  }

  /// Extract number from chore name (e.g., "Kitchen Cleaning 2" → 2)
  int _extractNumber(String name) {
    final match = RegExp(r'\d+$').firstMatch(name);
    return match != null ? int.parse(match.group(0)!) : 0;
  }
}
