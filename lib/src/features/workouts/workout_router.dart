import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'domain/models/muscle.dart';
import 'presentation/screens/add_exercise_screen.dart';
import 'presentation/screens/exercise_detail_screen.dart';
import 'presentation/screens/exercise_library_screen.dart';
import 'presentation/screens/log_workout_screen.dart';
import 'presentation/screens/muscle_exercises_screen.dart';
import 'presentation/workouts_screen.dart';

/// Router configuration for workout feature
final workoutRoutes = [
  GoRoute(
    path: '/workouts',
    name: 'workouts',
    builder: (context, state) => const WorkoutsScreen(),
    routes: [
      GoRoute(
        path: 'exercises',
        name: 'exercise-library',
        builder: (context, state) => const ExerciseLibraryScreen(),
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
}
