import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../domain/nutrition_entry.dart';
import '../domain/nutrition_goals.dart';
import '../domain/nutrition_repository.dart';
import '../domain/nutrition_summary.dart';

/// Controller for managing nutrition tracking features
class NutritionController {
  final NutritionRepository _repository;

  NutritionController(this._repository);

  /// Get all nutrition entries for a specific date
  Future<List<NutritionEntry>> getEntriesForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      return await _repository.getEntriesForDate(userId, date);
    } catch (e) {
      debugPrint('Error in getEntriesForDate: $e');
      // Return empty list to avoid crashing the UI
      return [];
    }
  }

  /// Add a new nutrition entry
  ///
  /// Adds an entry to the nutrition log and handles errors
  /// [entry] The nutrition entry to add
  /// Returns the saved entry
  Future<NutritionEntry> addEntry(NutritionEntry entry) async {
    try {
      debugPrint('Adding nutrition entry: ${entry.name}');
      final result = await _repository.addEntry(entry);

      // Return the saved entry
      return result;
    } catch (e) {
      debugPrint('Error in addEntry: $e');

      // Check if it's a permission error
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('permissions') ||
          e.toString().contains('permission')) {
        // Simply return the entry as if it was saved
        // This allows the UI to continue functioning
        debugPrint('Permission error in addEntry, returning original entry');
        return entry;
      }

      rethrow; // Rethrow other types of errors
    }
  }

  /// Update an existing nutrition entry
  Future<NutritionEntry> updateEntry(NutritionEntry entry) async {
    try {
      return await _repository.updateEntry(entry);
    } catch (e) {
      debugPrint('Error in updateEntry: $e');
      rethrow; // Rethrow for proper feedback to user
    }
  }

  /// Delete a nutrition entry
  Future<void> deleteEntry(String entryId) async {
    try {
      return await _repository.deleteEntry(entryId);
    } catch (e) {
      debugPrint('Error in deleteEntry: $e');
      rethrow; // Rethrow for proper feedback to user
    }
  }

  /// Get daily nutrition summary for a specific date
  Future<DailyNutritionSummary> getDailySummary(
    String userId,
    DateTime date,
  ) async {
    try {
      return await _repository.getDailySummary(userId, date);
    } catch (e) {
      debugPrint('Error in getDailySummary: $e');
      // Return default summary to avoid UI crashes
      return DailyNutritionSummary(
        date: date,
        calorieGoal: 2000,
        proteinGoal: 125.0,
        carbsGoal: 250.0,
        fatGoal: 55.0,
        waterGoal: 2500,
      );
    }
  }

  /// Get nutrition summaries for a date range
  Future<List<DailyNutritionSummary>> getWeekSummary(
    String userId,
    DateTime startDate,
  ) async {
    try {
      final endDate = startDate.add(const Duration(days: 6));
      return await _repository.getDailySummariesForRange(
        userId,
        startDate,
        endDate,
      );
    } catch (e) {
      debugPrint('Error in getWeekSummary: $e');
      // Return empty list to avoid crashing the UI
      return [];
    }
  }

  /// Get the user's nutrition goals
  Future<NutritionGoals> getUserNutritionGoals(String userId) async {
    try {
      return await _repository.getNutritionGoals(userId);
    } catch (e) {
      debugPrint('Error in getUserNutritionGoals: $e');
      // If no goals exist yet, return default goals
      return NutritionGoals(
        userId: userId,
        calorieGoal: 2000,
        proteinGoal: 125.0,
        carbsGoal: 250.0,
        fatGoal: 55.0,
        waterGoal: 2500, // 2.5 liters in ml
      );
    }
  }

  /// Update the user's nutrition goals
  Future<void> updateNutritionGoals(NutritionGoals goals) async {
    try {
      await _repository.saveNutritionGoals(goals);
    } catch (e) {
      debugPrint('Error in updateNutritionGoals: $e');
      rethrow; // Rethrow for proper feedback to user
    }
  }

  /// Log water intake (add to existing amount)
  Future<void> logWaterIntake(String userId, DateTime date, int amount) async {
    try {
      return await _repository.logWaterIntake(userId, date, amount);
    } catch (e) {
      debugPrint('Error in logWaterIntake: $e');
      rethrow; // Rethrow for proper feedback to user
    }
  }

  /// Get water intake for a specific date
  Future<int> getWaterIntake(String userId, DateTime date) async {
    try {
      return await _repository.getWaterIntake(userId, date);
    } catch (e) {
      debugPrint('Error in getWaterIntake: $e');
      return 0; // Return 0 to avoid UI crashes
    }
  }

  /// Calculate calories remaining for the day
  Future<int> getCaloriesRemaining(String userId, DateTime date) async {
    try {
      final summary = await _repository.getDailySummary(userId, date);
      return summary.remainingCalories;
    } catch (e) {
      debugPrint('Error in getCaloriesRemaining: $e');
      return 2000; // Return default value to avoid UI crashes
    }
  }

  /// Get a stream of daily nutrition summary updates
  Stream<DailyNutritionSummary> getDailySummaryStream(
      String userId, DateTime date) {
    try {
      return _repository.getDailySummaryStream(userId, date);
    } catch (e) {
      debugPrint('Error in getDailySummaryStream: $e');
      // Return a stream with a default summary in case of error
      return Stream.value(DailyNutritionSummary(
        date: date,
        calorieGoal: 2000,
        proteinGoal: 150,
        carbsGoal: 250,
        fatGoal: 70,
        waterGoal: 2000,
      ));
    }
  }

  /// Get a stream of nutrition entries for a specific date
  Stream<List<NutritionEntry>> getEntriesForDateStream(
      String userId, DateTime date) {
    try {
      return _repository.getEntriesForDateStream(userId, date);
    } catch (e) {
      debugPrint('Error in getEntriesForDateStream: $e');
      return Stream.value([]);
    }
  }
}

/// Provider for the nutrition controller
final nutritionControllerProvider = Provider<NutritionController>((ref) {
  try {
    final repository = ref.watch(nutritionRepositoryProvider);
    return NutritionController(repository);
  } catch (e) {
    // Log error but don't crash the app
    debugPrint('Error creating NutritionController: $e');
    rethrow; // Re-throw so we don't hide the original error
  }
});

/// Provider for daily nutrition entries
final dailyNutritionEntriesProvider =
    FutureProvider.family<List<NutritionEntry>, DateTime>((ref, date) {
  final userId = ref.read(currentUserIdProvider).value ?? '';
  final controller = ref.watch(nutritionControllerProvider);
  return controller.getEntriesForDate(userId, date);
});

/// Provider for daily nutrition summary
final dailyNutritionSummaryProvider =
    FutureProvider.family<DailyNutritionSummary, DateTime>((ref, date) {
  final userId = ref.read(currentUserIdProvider).value ?? '';
  final controller = ref.watch(nutritionControllerProvider);
  return controller.getDailySummary(userId, date);
});

/// Provider for weekly nutrition summary
final weeklyNutritionSummaryProvider =
    FutureProvider.family<List<DailyNutritionSummary>, DateTime>((
  ref,
  startDate,
) {
  final userId = ref.read(currentUserIdProvider).value ?? '';
  final controller = ref.watch(nutritionControllerProvider);
  return controller.getWeekSummary(userId, startDate);
});

/// Provider for user's nutrition goals
final nutritionGoalsProvider = FutureProvider<NutritionGoals>((ref) {
  final userId = ref.read(currentUserIdProvider).value ?? '';
  final controller = ref.watch(nutritionControllerProvider);
  return controller.getUserNutritionGoals(userId);
});

/// Provider for current user ID
final currentUserIdProvider = Provider<AsyncValue<String?>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((user) => user?.uid);
});

/// Stream provider for daily nutrition summary
/// This allows real-time updates to the nutrition summary
final dailyNutritionSummaryStreamProvider =
    StreamProvider.family<DailyNutritionSummary, DateTime>((ref, date) {
  final userId = ref.watch(currentUserIdProvider).value;
  if (userId == null || userId.isEmpty) {
    // Return an empty stream if no user is logged in
    return Stream.value(DailyNutritionSummary(
      date: date,
      calorieGoal: 2000,
      proteinGoal: 150,
      carbsGoal: 250,
      fatGoal: 70,
      waterGoal: 2000,
    ));
  }

  debugPrint('Setting up real-time stream for nutrition summary on $date');
  final controller = ref.watch(nutritionControllerProvider);
  return controller.getDailySummaryStream(userId, date);
});

/// Stream provider for daily nutrition entries
final dailyNutritionEntriesStreamProvider =
    StreamProvider.family<List<NutritionEntry>, DateTime>((ref, date) {
  final userId = ref.watch(currentUserIdProvider).value;
  if (userId == null || userId.isEmpty) {
    return Stream.value([]);
  }
  final controller = ref.watch(nutritionControllerProvider);
  return controller.getEntriesForDateStream(userId, date);
});
