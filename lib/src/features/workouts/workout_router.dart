import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'domain/models/exercise.dart';
import 'domain/models/muscle.dart';
import 'presentation/screens/add_exercise_screen.dart';
import 'presentation/screens/exercise_detail_screen.dart';
import 'presentation/screens/exercise_library_screen.dart';
import 'presentation/screens/log_workout_screen.dart';
import 'presentation/screens/muscle_exercises_screen.dart';
import 'presentation/screens/workout_dashboard_screen.dart';
import 'presentation/screens/workout_detail_screen.dart';

/// Router configuration for workout feature
final workoutRoutes = [
  GoRoute(
    path: '/workouts',
    name: 'workouts',
    builder: (context, state) => const WorkoutDashboardScreen(),
    routes: [
      GoRoute(
        path: 'exercises',
        name: 'exercise-library',
        builder: (context, state) {
          final isSelecting = (state.extra as Map<String, dynamic>?)?['isSelecting'] as bool? ?? false;
          return ExerciseLibraryScreen(isSelecting: isSelecting);
        },
      ),
      GoRoute(
        path: 'exercises/add',
        name: 'add-exercise',
        builder: (context, state) => const AddExerciseScreen(),
      ),
      GoRoute(
        path: 'exercises/:id',
        name: 'exercise-details',
        builder: (context, state) {
          final exerciseId = state.pathParameters['id'] ?? '';
          return ExerciseDetailScreen(exerciseId: exerciseId);
        },
      ),
      GoRoute(
        path: 'muscle/:muscleId',
        name: 'muscle-exercises',
        builder: (context, state) {
          final muscleId = state.pathParameters['muscleId'] ?? '';
          final muscleValue = Muscle.values.firstWhere(
            (m) => m.toString().split('.').last == muscleId,
            orElse: () => Muscle.chest, // Default fallback
          );
          return MuscleExercisesScreen(muscle: muscleValue);
        },
      ),
      GoRoute(
        path: 'log',
        name: 'log-workout',
        builder: (context, state) {
          final date = state.uri.queryParameters['date'] != null
              ? DateTime.parse(state.uri.queryParameters['date']!)
              : DateTime.now();

          final exerciseId = state.uri.queryParameters['exercise_id'];

          return LogWorkoutScreen(
            date: date,
            preSelectedExerciseId: exerciseId,
          );
        },
      ),
      // Route for Workout Details
      GoRoute(
        path: 'details/:workoutId',
        name: 'workout-details',
        builder: (context, state) {
          final workoutId = state.pathParameters['workoutId'] ?? '';
          return WorkoutDetailScreen(workoutId: workoutId);
        },
      ),
    ],
  ),
];

/// Extension methods for navigating to workout screens
extension WorkoutRouterExtension on BuildContext {
  /// Navigate to the workouts dashboard
  void goToWorkoutsDashboard() {
    GoRouter.of(this).goNamed('workouts');
  }

  /// Navigate to the exercise library
  void goToExerciseLibrary() {
    GoRouter.of(this).goNamed('exercise-library');
  }

  /// Navigate to exercise details
  void goToExerciseDetails(String exerciseId) {
    GoRouter.of(this)
        .goNamed('exercise-details', pathParameters: {'id': exerciseId});
  }

  /// Navigate to log workout screen
  void goToLogWorkout({DateTime? date, String? exerciseId}) {
    final queryParams = <String, String>{};
    if (date != null) {
      queryParams['date'] = date.toIso8601String();
    }
    if (exerciseId != null) {
      queryParams['exercise_id'] = exerciseId;
    }
    GoRouter.of(this).goNamed('log-workout', queryParameters: queryParams);
  }

  /// Navigate to add exercise screen
  void goToAddExercise() {
    GoRouter.of(this).goNamed('add-exercise');
  }

  /// Navigate to muscle exercises screen
  void goToMuscleExercises(Muscle muscle) {
    final muscleId = muscle.toString().split('.').last;
    GoRouter.of(this)
        .goNamed('muscle-exercises', pathParameters: {'muscleId': muscleId});
  }

  /// Navigate to the exercise library to select an exercise and return it
  Future<Exercise?> pushExerciseLibraryForSelection() {
    // Use pushNamed to be able to receive a result
    return GoRouter.of(this).pushNamed<Exercise>(
      'exercise-library',
      extra: {'isSelecting': true}, // Pass flag via extra
    );
  }

  /// Navigate to workout details screen
  void pushWorkoutDetails(String workoutId) {
    GoRouter.of(this).pushNamed(
      'workout-details',
      pathParameters: {'workoutId': workoutId},
    );
  }
}
