import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/repository_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/repositories/exercise_repository_provider.dart';
import '../domain/models/exercise.dart';
import '../domain/models/weight_unit.dart';
import '../domain/models/workout_session.dart';
import '../domain/models/workout_set.dart';
import '../domain/repositories/exercise_repository.dart';
import '../domain/repositories/workout_repository.dart';

/// Controller for managing workout tracking features
class WorkoutController {
  final WorkoutRepository _repository;
  final ExerciseRepository _exerciseRepository;
  final Ref _ref;

  WorkoutController(this._repository, this._exerciseRepository, this._ref);

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

  /// Get all workout sessions for a specific date range
  Future<List<WorkoutSession>> getWorkoutsForDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) {
        debugPrint('getWorkoutsForDateRange: User not logged in.');
        return []; // Return empty list if no user
      }
      // Ensure endDate includes the whole day
      final adjustedEndDate =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      return await _repository.getWorkoutsForDateRange(
          userId, startDate, adjustedEndDate);
    } catch (e) {
      debugPrint('Error in getWorkoutsForDateRange: $e');
      // Return empty list to avoid crashing the UI
      return [];
    }
  }

  /// Calculate the number of unique exercises performed in a given date range
  Future<int> getUniqueExerciseCountForDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final workouts = await getWorkoutsForDateRange(startDate, endDate);
      final uniqueExerciseIds = <String>{}; // Use a Set for uniqueness

      for (final workout in workouts) {
        uniqueExerciseIds.addAll(workout.performedExercises.keys);
      }

      return uniqueExerciseIds.length;
    } catch (e) {
      debugPrint('Error in getUniqueExerciseCountForDateRange: $e');
      return 0; // Return 0 on error
    }
  }

  /// Get all workout sessions for a specific date
  Future<List<WorkoutSession>> getWorkoutsForDate(DateTime date) async {
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) {
        debugPrint('getWorkoutsForDate: User not logged in.');
        return []; // Return empty list if no user
      }
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
  Future<WorkoutSession> startWorkout() async {
    try {
      // Read our stream-based provider
      final streamUserId = _ref.read(currentUserIdProvider);
      debugPrint(
          '--- startWorkout: streamUserId (from currentUserIdProvider) = $streamUserId ---');

      // Read the AuthController's direct user object
      // Assuming authControllerProvider is defined and imported
      final authController = _ref.read(authControllerProvider); // Read directly
      final directUser = authController.currentUser;
      debugPrint(
          '--- startWorkout: directUser (from AuthController) = ${directUser?.uid} ---');

      // Prefer the stream-based ID, but use the direct one if stream is null FOR NOW
      final userId = streamUserId ?? directUser?.uid;

      if (userId == null) {
        debugPrint(
            '--- startWorkout: Both streamUserId and directUser are null ---');
        // Throw an error or handle appropriately if starting a workout requires a logged-in user
        throw Exception('Cannot start workout: User not logged in.');
      }
      debugPrint('--- startWorkout: Using userId = $userId ---');
      // Create a new workout session with the current time
      final workout = WorkoutSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        startTime: DateTime.now(),
        performedExercises: {},
      );

      return await _repository.saveWorkoutSession(workout);
    } catch (e) {
      debugPrint('Error in startWorkout: $e');
      debugPrintStack(stackTrace: StackTrace.current); // Add stack trace
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
        endTime: workout.endTime ?? DateTime.now(), // Fallback just in case
        performedExercises: workout.performedExercises,
        notes: workout.notes,
      );

      debugPrint(
          '--- endWorkout: About to call repository.saveWorkoutSession ---'); // Add log
      final savedWorkout = await _repository.saveWorkoutSession(updatedWorkout);

      return savedWorkout;
    } catch (e) {
      debugPrint('Error in endWorkout: $e');
      rethrow;
    }
  }

  /// Add a set to a workout
  Future<WorkoutSession> addSetToWorkout(
    WorkoutSession workout,
    String exerciseId,
    WeightUnit weightUnit,
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
        weightUnit: weightUnit,
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
      return await _repository.saveWorkoutSession(updatedWorkout);
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
      return await _repository.saveWorkoutSession(updatedWorkout);
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
      return await _repository.saveWorkoutSession(updatedWorkout);
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
  Future<List<WorkoutSession>> getRecentWorkouts({int limit = 10}) async {
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) {
        debugPrint('getRecentWorkouts: User not logged in.');
        return []; // Return empty list if no user
      }
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
  return WorkoutController(workoutRepository, exerciseRepository, ref);
});

/// Provider for workouts on a specific date
final workoutsForDateProvider =
    FutureProvider.family<List<WorkoutSession>, DateTime>((ref, date) async {
  final controller = ref.watch(workoutControllerProvider);
  return controller.getWorkoutsForDate(date);
});

/// Provider for a specific workout by ID
final workoutByIdProvider =
    FutureProvider.family<WorkoutSession?, String>((ref, workoutId) async {
  final controller = ref.watch(workoutControllerProvider);
  return controller.getWorkoutById(workoutId);
});

// --- New Providers for Exercise Count ---

/// Provider for the user's weekly exercise goal (Placeholder)
/// TODO: Fetch this from user settings/profile
final weeklyExerciseGoalProvider = Provider<int>((ref) {
  return 15; // Example: Goal is 15 unique exercises per week
});

/// Provider for the count of unique exercises performed this week
final weeklyExerciseCountProvider = FutureProvider<int>((ref) async {
  final now = DateTime.now();
  // Calculate the start of the week (assuming Monday is the first day)
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final startOfWeekDate =
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  // Calculate the end of the week (Sunday)
  final endOfWeek = startOfWeekDate.add(const Duration(days: 6));
  final endOfWeekDate =
      DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);

  final controller = ref.watch(workoutControllerProvider);
  return controller.getUniqueExerciseCountForDateRange(
      startOfWeekDate, endOfWeekDate);
});
