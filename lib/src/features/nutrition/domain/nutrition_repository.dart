import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nutrition_entry.dart';
import 'nutrition_goals.dart';
import 'nutrition_summary.dart';

/// Repository interface for managing nutrition data
abstract class NutritionRepository {
  /// Get all nutrition entries for a specific date
  Future<List<NutritionEntry>> getEntriesForDate(String userId, DateTime date);

  /// Get a stream of nutrition entries for a specific date
  Stream<List<NutritionEntry>> getEntriesForDateStream(
      String userId, DateTime date);

  /// Get all nutrition entries for a date range
  Future<List<NutritionEntry>> getEntriesForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Add a new nutrition entry
  Future<NutritionEntry> addEntry(NutritionEntry entry);

  /// Update an existing nutrition entry
  Future<NutritionEntry> updateEntry(NutritionEntry entry);

  /// Delete a nutrition entry
  Future<void> deleteEntry(String entryId);

  /// Get daily nutrition summary for a specific date
  Future<DailyNutritionSummary> getDailySummary(String userId, DateTime date);

  /// Get daily nutrition summaries for a date range
  Future<List<DailyNutritionSummary>> getDailySummariesForRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get user's nutrition goals
  Future<NutritionGoals> getNutritionGoals(String userId);

  /// Save user's nutrition goals
  Future<void> saveNutritionGoals(NutritionGoals goals);

  /// Log water intake for a specific date (in milliliters)
  Future<void> logWaterIntake(String userId, DateTime date, int amount);

  /// Get water intake for a specific date (in milliliters)
  Future<int> getWaterIntake(String userId, DateTime date);

  /// Get real-time updates for a user's daily nutrition summary
  Stream<DailyNutritionSummary> getDailySummaryStream(
      String userId, DateTime date);
}

/// Provider for the nutrition repository
/// This is just a placeholder and should be overridden in the repository_providers.dart file
final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  // In production, this will be overridden by the actual implementation in repository_providers.dart
  // This fallback is only used in development or if the override is not registered
  // Using a mock implementation instead of throwing an error
  return _MockNutritionRepository();
});

/// A mock implementation to avoid exceptions during development
class _MockNutritionRepository implements NutritionRepository {
  @override
  Future<NutritionEntry> addEntry(NutritionEntry entry) async {
    return entry;
  }

  @override
  Future<void> deleteEntry(String entryId) async {}

  @override
  Future<DailyNutritionSummary> getDailySummary(
    String userId,
    DateTime date,
  ) async {
    return DailyNutritionSummary(
      date: date,
      calorieGoal: 2000,
      proteinGoal: 125.0,
      carbsGoal: 250.0,
      fatGoal: 55.0,
      waterGoal: 2500,
    );
  }

  @override
  Future<List<DailyNutritionSummary>> getDailySummariesForRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final days = endDate.difference(startDate).inDays + 1;
    return List.generate(
      days,
      (index) => DailyNutritionSummary(
        date: startDate.add(Duration(days: index)),
        calorieGoal: 2000,
        proteinGoal: 125.0,
        carbsGoal: 250.0,
        fatGoal: 55.0,
        waterGoal: 2500,
      ),
    );
  }

  @override
  Future<List<NutritionEntry>> getEntriesForDate(
    String userId,
    DateTime date,
  ) async {
    return [];
  }

  @override
  Future<List<NutritionEntry>> getEntriesForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return [];
  }

  @override
  Future<NutritionGoals> getNutritionGoals(String userId) async {
    return NutritionGoals(
      userId: userId,
      calorieGoal: 2000,
      proteinGoal: 125.0,
      carbsGoal: 250.0,
      fatGoal: 55.0,
      waterGoal: 2500,
    );
  }

  @override
  Future<int> getWaterIntake(String userId, DateTime date) async {
    return 0;
  }

  @override
  Future<void> logWaterIntake(String userId, DateTime date, int amount) async {}

  @override
  Future<void> saveNutritionGoals(NutritionGoals goals) async {}

  @override
  Future<NutritionEntry> updateEntry(NutritionEntry entry) async {
    return entry;
  }

  @override
  Stream<DailyNutritionSummary> getDailySummaryStream(
      String userId, DateTime date) {
    // Return a stream with a default summary instead of throwing an error
    return Stream.value(DailyNutritionSummary(
      date: date,
      calorieGoal: 2000,
      proteinGoal: 125.0,
      carbsGoal: 250.0,
      fatGoal: 55.0,
      waterGoal: 2500,
    ));
  }

  @override
  Stream<List<NutritionEntry>> getEntriesForDateStream(
      String userId, DateTime date) {
    // Return an empty stream instead of throwing an error
    return Stream.value([]);
  }
}
