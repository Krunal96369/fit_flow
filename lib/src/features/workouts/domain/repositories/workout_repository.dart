import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout_session.dart';

/// Repository interface for managing workout data
abstract class WorkoutRepository {
  /// Get all workout sessions for a specific date
  Future<List<WorkoutSession>> getWorkoutsForDate(String userId, DateTime date);

  /// Get a specific workout session by ID
  Future<WorkoutSession?> getWorkoutById(String workoutId);

  /// Save a workout session (create or update)
  Future<WorkoutSession> saveWorkout(WorkoutSession workout);

  /// Delete a workout session
  Future<void> deleteWorkout(String workoutId);

  /// Get recent workout sessions
  Future<List<WorkoutSession>> getRecentWorkouts(String userId,
      {int limit = 10});

  /// Get all workout sessions for a date range
  Future<List<WorkoutSession>> getWorkoutsForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
}

/// Provider for the workout repository
/// This is just a placeholder and should be overridden in the repository_providers.dart file
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  // In production, this will be overridden by the actual implementation
  // This fallback is only used in development or if the override is not registered
  return _MockWorkoutRepository();
});

/// A mock implementation to avoid exceptions during development
class _MockWorkoutRepository implements WorkoutRepository {
  final Map<String, WorkoutSession> _workouts = {};

  @override
  Future<void> deleteWorkout(String workoutId) async {
    _workouts.remove(workoutId);
  }

  @override
  Future<WorkoutSession?> getWorkoutById(String workoutId) async {
    return _workouts[workoutId];
  }

  @override
  Future<List<WorkoutSession>> getWorkoutsForDate(
      String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _workouts.values
        .where((workout) =>
            workout.userId == userId &&
            workout.startTime.isAfter(startOfDay) &&
            workout.startTime.isBefore(endOfDay))
        .toList();
  }

  @override
  Future<List<WorkoutSession>> getWorkoutsForDateRange(
      String userId, DateTime startDate, DateTime endDate) async {
    return _workouts.values
        .where((workout) =>
            workout.userId == userId &&
            workout.startTime.isAfter(startDate) &&
            workout.startTime.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }

  @override
  Future<List<WorkoutSession>> getRecentWorkouts(String userId,
      {int limit = 10}) async {
    return _workouts.values
        .where((workout) => workout.userId == userId)
        .toList()
      // Sort by most recent first
      ..sort((a, b) => b.startTime.compareTo(a.startTime))
      // Limit to requested number
      ..take(limit);
  }

  @override
  Future<WorkoutSession> saveWorkout(WorkoutSession workout) async {
    _workouts[workout.id] = workout;
    return workout;
  }
}
