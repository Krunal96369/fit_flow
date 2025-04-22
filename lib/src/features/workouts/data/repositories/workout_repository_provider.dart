import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/workout_repository.dart';
import 'in_memory_workout_repository.dart';

/// Provider to expose the currently configured WorkoutRepository implementation.
///
/// By default, it provides the InMemoryWorkoutRepository.
/// This can be overridden in the ProviderScope for testing or different environments.
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  // For now, we always return the in-memory implementation.
  // Later, we could add logic here to choose between different implementations
  // (e.g., based on environment variables or configuration).
  return InMemoryWorkoutRepository();
});
