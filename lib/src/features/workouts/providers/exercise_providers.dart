import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/firebase_exercise_repository.dart';
import '../domain/models/exercise.dart';
import '../domain/models/muscle.dart';
import '../domain/repositories/exercise_repository.dart';

/// Provider for the exercise repository
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return FirebaseExerciseRepository();
});

/// Provider for all exercises
final allExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  try {
    final repository = ref.watch(exerciseRepositoryProvider);
    return await repository.getAllExercises();
  } catch (e) {
    // Log the error and rethrow to show in the UI
    debugPrint('Error in allExercisesProvider: $e');
    rethrow;
  }
});

/// Provider for fetching exercises by muscle
final exercisesByMuscleProvider =
    FutureProvider.family<List<Exercise>, Muscle>((ref, muscle) async {
  try {
    final repository = ref.watch(exerciseRepositoryProvider);
    return await repository
        .getExercisesByMuscle(muscle.toString().split('.').last);
  } catch (e) {
    debugPrint('Error in exercisesByMuscleProvider: $e');
    rethrow;
  }
});

/// Provider for fetching a single exercise by ID
final exerciseByIdProvider =
    FutureProvider.family<Exercise?, String>((ref, id) async {
  try {
    final repository = ref.watch(exerciseRepositoryProvider);
    return await repository.getExerciseById(id);
  } catch (e) {
    debugPrint('Error in exerciseByIdProvider: $e');
    rethrow;
  }
});

/// Provider for favorite exercises
final favoriteExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  try {
    final repository = ref.watch(exerciseRepositoryProvider);
    return await repository.getFavoriteExercises();
  } catch (e) {
    debugPrint('Error in favoriteExercisesProvider: $e');
    rethrow;
  }
});

/// Controller to toggle exercise favorites
final toggleFavoriteControllerProvider =
    Provider.family<Future<void> Function(), (String, bool)>((ref, params) {
  final repository = ref.watch(exerciseRepositoryProvider);

  return () async {
    try {
      final (id, isFavorite) = params;
      await repository.toggleFavorite(id, isFavorite);

      // Invalidate related cached providers after updating
      ref.invalidate(favoriteExercisesProvider);
      ref.invalidate(exerciseByIdProvider(id));
      ref.invalidate(allExercisesProvider);

      // Exercise by muscle may need to be invalidated, but we don't know which muscle
      // in this context. A more sophisticated approach could invalidate specific
      // muscle providers if needed.
    } catch (e) {
      debugPrint('Error in toggleFavoriteControllerProvider: $e');
      rethrow;
    }
  };
});

/// Provider for searching exercises
final searchExercisesProvider =
    FutureProvider.family<List<Exercise>, String>((ref, query) async {
  try {
    final repository = ref.watch(exerciseRepositoryProvider);

    if (query.isEmpty) {
      return await repository.getAllExercises();
    }

    return await repository.searchExercises(query);
  } catch (e) {
    debugPrint('Error in searchExercisesProvider: $e');
    rethrow;
  }
});

/// Provider for exercise count
final exerciseCountProvider = FutureProvider<int>((ref) async {
  try {
    final exercises = await ref.watch(allExercisesProvider.future);
    return exercises.length;
  } catch (e) {
    debugPrint('Error in exerciseCountProvider: $e');
    rethrow;
  }
});
