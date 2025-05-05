import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/workout_session.dart';
import '../domain/repositories/workout_repository.dart';

/// Provider to fetch a specific workout session by its ID.
final workoutByIdProvider =
    FutureProvider.family<WorkoutSession?, String>((ref, workoutId) async {
  final repository = ref.watch(workoutRepositoryProvider);
  // Directly call the repository method
  return repository.getWorkoutById(workoutId);
});
