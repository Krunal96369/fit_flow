import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';
import 'in_memory_exercise_repository.dart';

/// Provider to expose the currently configured ExerciseRepository implementation.
///
/// By default, it provides the InMemoryExerciseRepository.
/// This can be overridden in the ProviderScope for testing or different environments.
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  // For now, we always return the in-memory implementation.
  // Later, we could add logic here to choose between different implementations
  // (e.g., based on environment variables or configuration).
  return InMemoryExerciseRepository();
});

// You might also want providers specifically for fetching data, using FutureProvider:

/// Provider to fetch the list of all exercises.
/// Uses the exerciseRepositoryProvider to get the data.
final exercisesListProvider = FutureProvider<List<Exercise>>((ref) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.getAllExercises();
});

/// Provider to fetch a single exercise by its ID.
/// Takes the exercise ID as an argument.
final exerciseByIdProvider =
    FutureProvider.family<Exercise?, String>((ref, String id) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.getExerciseById(id);
});
