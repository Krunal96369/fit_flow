import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout_session.dart';
import '../../data/firestore_workout_repository.dart';

/// Repository interface for managing workout data
abstract class WorkoutRepository {
  /// Get all workout sessions for a specific date
  Future<List<WorkoutSession>> getWorkoutsForDate(String userId, DateTime date);

  /// Get a specific workout session by ID
  Future<WorkoutSession?> getWorkoutById(String workoutId);

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

  /// Saves a completed workout session.
  Future<WorkoutSession> saveWorkoutSession(WorkoutSession workout);
}

/// Provider for the workout repository
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  // Provide the Firestore implementation
  final firestore = ref.watch(firestoreProvider);
  return FirestoreWorkoutRepository(firestore);
});
