import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/exercise_repository_provider.dart';
import '../data/repositories/workout_repository_provider.dart';
import '../domain/models/exercise.dart';
import '../domain/models/workout_session.dart';
import '../domain/models/workout_set.dart';
import '../domain/repositories/exercise_repository.dart';
import '../domain/repositories/workout_repository.dart'
    hide workoutRepositoryProvider;

/// Controller for managing workout tracking features
class WorkoutController {
  final WorkoutRepository _repository;
  final ExerciseRepository _exerciseRepository;

  WorkoutController(this._repository, this._exerciseRepository);

  /// Fetch all available exercises
  Future<List<Exercise>> getExercises() async {
    try {
      return await _exerciseRepository.getAllExercises();
    } catch (e) {
      debugPrint('Error in getExercises: $e');
      // Return empty list to avoid crashing the UI
      return [];
    }
  }

  /// Fetch a specific exercise by ID
  Future<Exercise?> getExerciseById(String id) async {
    try {
      return await _exerciseRepository.getExerciseById(id);
    } catch (e) {
      debugPrint('Error in getExerciseById: $e');
      return null;
    }
  }

  /// Get all workout sessions for a specific date
  Future<List<WorkoutSession>> getWorkoutsForDate(
      String userId, DateTime date) async {
    try {
      return await _repository.getWorkoutsForDate(userId, date);
    } catch (e) {
      debugPrint('Error in getWorkoutsForDate: $e');
      // Return empty list to avoid crashing the UI
      return [];
    }
  }

  /// Get a specific workout session by ID
  Future<WorkoutSession?> getWorkoutById(String workoutId) async {
    try {
      return await _repository.getWorkoutById(workoutId);
    } catch (e) {
      debugPrint('Error in getWorkoutById: $e');
      return null;
    }
  }

  /// Start a new workout session
  Future<WorkoutSession> startWorkout(String userId) async {
    try {
      // Create a new workout session with the current time
      final workout = WorkoutSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        startTime: DateTime.now(),
        performedExercises: {},
      );

      return await _repository.saveWorkout(workout);
    } catch (e) {
      debugPrint('Error in startWorkout: $e');
      rethrow;
    }
  }

  /// End an ongoing workout session
  Future<WorkoutSession> endWorkout(WorkoutSession workout) async {
    try {
      // Update the workout with the end time
      final updatedWorkout = WorkoutSession(
        id: workout.id,
        userId: workout.userId,
        startTime: workout.startTime,
        endTime: DateTime.now(),
        performedExercises: workout.performedExercises,
        notes: workout.notes,
      );

      return await _repository.saveWorkout(updatedWorkout);
    } catch (e) {
      debugPrint('Error in endWorkout: $e');
      rethrow;
    }
  }

  /// Add a set to a workout
  Future<WorkoutSession> addSetToWorkout(
    WorkoutSession workout,
    String exerciseId,
    int reps,
    double weight, {
    int? restTimeSeconds,
    String? notes,
  }) async {
    try {
      // Create a deep copy of the performed exercises map
      final performedExercises =
          Map<String, List<WorkoutSet>>.from(workout.performedExercises);

      // Create the new workout set
      final workoutSet = WorkoutSet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        exerciseId: exerciseId,
        reps: reps,
        weight: weight,
        restTimeSeconds: restTimeSeconds,
        notes: notes,
      );

      // Add the set to the exercise's list (or create a new list if it doesn't exist)
      if (performedExercises.containsKey(exerciseId)) {
        performedExercises[exerciseId] = [
          ...performedExercises[exerciseId]!,
          workoutSet
        ];
      } else {
        performedExercises[exerciseId] = [workoutSet];
      }

      // Create the updated workout
      final updatedWorkout = WorkoutSession(
        id: workout.id,
        userId: workout.userId,
        startTime: workout.startTime,
        endTime: workout.endTime,
        performedExercises: performedExercises,
        notes: workout.notes,
      );

      // Save and return the updated workout
      return await _repository.saveWorkout(updatedWorkout);
    } catch (e) {
      debugPrint('Error in addSetToWorkout: $e');
      rethrow;
    }
  }

  /// Remove a set from a workout
  Future<WorkoutSession> removeSetFromWorkout(
    WorkoutSession workout,
    String exerciseId,
    String setId,
  ) async {
    try {
      // Create a deep copy of the performed exercises map
      final performedExercises =
          Map<String, List<WorkoutSet>>.from(workout.performedExercises);

      // Remove the set from the exercise's list
      if (performedExercises.containsKey(exerciseId)) {
        performedExercises[exerciseId] = performedExercises[exerciseId]!
            .where((set) => set.id != setId)
            .toList();

        // If no sets remain for this exercise, remove the exercise from the map
        if (performedExercises[exerciseId]!.isEmpty) {
          performedExercises.remove(exerciseId);
        }
      }

      // Create the updated workout
      final updatedWorkout = WorkoutSession(
        id: workout.id,
        userId: workout.userId,
        startTime: workout.startTime,
        endTime: workout.endTime,
        performedExercises: performedExercises,
        notes: workout.notes,
      );

      // Save and return the updated workout
      return await _repository.saveWorkout(updatedWorkout);
    } catch (e) {
      debugPrint('Error in removeSetFromWorkout: $e');
      rethrow;
    }
  }

  /// Update a workout session's notes
  Future<WorkoutSession> updateWorkoutNotes(
    WorkoutSession workout,
    String notes,
  ) async {
    try {
      // Create the updated workout
      final updatedWorkout = WorkoutSession(
        id: workout.id,
        userId: workout.userId,
        startTime: workout.startTime,
        endTime: workout.endTime,
        performedExercises: workout.performedExercises,
        notes: notes,
      );

      // Save and return the updated workout
      return await _repository.saveWorkout(updatedWorkout);
    } catch (e) {
      debugPrint('Error in updateWorkoutNotes: $e');
      rethrow;
    }
  }

  /// Delete a workout session
  Future<void> deleteWorkout(String workoutId) async {
    try {
      await _repository.deleteWorkout(workoutId);
    } catch (e) {
      debugPrint('Error in deleteWorkout: $e');
      rethrow;
    }
  }

  /// Get recent workouts for a user
  Future<List<WorkoutSession>> getRecentWorkouts(String userId,
      {int limit = 10}) async {
    try {
      return await _repository.getRecentWorkouts(userId, limit: limit);
    } catch (e) {
      debugPrint('Error in getRecentWorkouts: $e');
      // Return empty list to avoid crashing the UI
      return [];
    }
  }
}

/// Provider for the workout controller
final workoutControllerProvider = Provider<WorkoutController>((ref) {
  final exerciseRepository = ref.watch(exerciseRepositoryProvider);
  final workoutRepository = ref.watch(workoutRepositoryProvider);
  return WorkoutController(workoutRepository, exerciseRepository);
});

/// Provider for the current user ID (workaround for missing auth controller)
final currentUserIdProvider = Provider<String>((ref) {
  // This is a workaround/fallback for development
  // In the real app, this would come from the auth controller
  return 'test-user-id';
});

/// Provider for recent workouts
final recentWorkoutsProvider =
    FutureProvider<List<WorkoutSession>>((ref) async {
  final userId = ref.read(currentUserIdProvider);
  final controller = ref.watch(workoutControllerProvider);
  return controller.getRecentWorkouts(userId);
});

/// Provider for workouts on a specific date
final workoutsForDateProvider =
    FutureProvider.family<List<WorkoutSession>, DateTime>((ref, date) async {
  final userId = ref.read(currentUserIdProvider);
  final controller = ref.watch(workoutControllerProvider);
  return controller.getWorkoutsForDate(userId, date);
});

/// Provider for a specific workout by ID
final workoutByIdProvider =
    FutureProvider.family<WorkoutSession?, String>((ref, workoutId) async {
  final controller = ref.watch(workoutControllerProvider);
  return controller.getWorkoutById(workoutId);
});
