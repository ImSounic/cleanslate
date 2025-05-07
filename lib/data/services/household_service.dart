// lib/data/services/household_service.dart
import 'package:cleanslate/data/models/household_model.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';

class HouseholdService {
  static final HouseholdService _instance = HouseholdService._internal();
  factory HouseholdService() => _instance;
  HouseholdService._internal();

  final HouseholdRepository _repository = HouseholdRepository();
  HouseholdModel? _currentHousehold;

  // Get current household
  HouseholdModel? get currentHousehold => _currentHousehold;

  // Set current household
  void setCurrentHousehold(HouseholdModel household) {
    _currentHousehold = household;
  }

  // Clear current household
  void clearCurrentHousehold() {
    _currentHousehold = null;
  }

  // Initialize household (called after login)
  Future<void> initializeHousehold() async {
    try {
      final households = await _repository.getUserHouseholds();
      if (households.isNotEmpty) {
        // Automatically select the first household
        setCurrentHousehold(households.first);
      } else {
        // No households found
        clearCurrentHousehold();
      }
    } catch (e) {
      // Clear current household on error
      clearCurrentHousehold();
      // Re-throw the exception for the caller to handle
      throw Exception('Failed to initialize household: $e');
    }
  }

  // Create and set new household
  Future<HouseholdModel> createAndSetHousehold(String name) async {
    try {
      final household = await _repository.createHousehold(name);
      setCurrentHousehold(household);
      return household;
    } catch (e) {
      throw Exception('Failed to create household: $e');
    }
  }

  // Switch to a different household
  Future<void> switchHousehold(String householdId) async {
    try {
      final household = await _repository.getHouseholdModel(householdId);
      setCurrentHousehold(household);
    } catch (e) {
      throw Exception('Failed to switch household: $e');
    }
  }
}
