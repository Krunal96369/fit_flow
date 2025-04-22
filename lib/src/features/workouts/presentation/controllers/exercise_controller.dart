import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/exercise.dart';
import '../../domain/models/muscle.dart';
import '../../providers/exercise_providers.dart';

/// State for exercise operations to provide better user feedback
enum ExerciseOperationState { idle, loading, success, error }

/// State class for exercise operations
class ExerciseState {
  final ExerciseOperationState operationState;
  final String? errorMessage;
  final bool isProcessing;

  const ExerciseState({
    this.operationState = ExerciseOperationState.idle,
    this.errorMessage,
    this.isProcessing = false,
  });

  ExerciseState copyWith({
    ExerciseOperationState? operationState,
    String? errorMessage,
    bool? isProcessing,
  }) {
    return ExerciseState(
      operationState: operationState ?? this.operationState,
      errorMessage: errorMessage ?? this.errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

/// Controller for exercise operations with better user feedback
class ExerciseController extends StateNotifier<ExerciseState> {
  final Ref ref;

  ExerciseController(this.ref) : super(const ExerciseState());

  /// Toggle favorite state with proper error handling and user feedback
  Future<void> toggleFavorite(String exerciseId, bool isFavorite) async {
    // Don't allow multiple operations at once
    if (state.isProcessing) return;

    // Update state to show processing
    state = state.copyWith(
      isProcessing: true,
      operationState: ExerciseOperationState.loading,
      errorMessage: null,
    );

    try {
      // Get the controller function and call it
      final toggleFavorite = ref.read(
        toggleFavoriteControllerProvider((exerciseId, isFavorite)),
      );
      await toggleFavorite();

      // Update state to show success
      state = state.copyWith(
        isProcessing: false,
        operationState: ExerciseOperationState.success,
      );
    } catch (e) {
      // Update state to show error
      state = state.copyWith(
        isProcessing: false,
        operationState: ExerciseOperationState.error,
        errorMessage: 'Failed to update favorite: $e',
      );
      debugPrint('Error toggling favorite: $e');
    }
  }

  /// Add a new exercise with proper error handling and user feedback
  Future<Exercise?> addExercise(Exercise exercise) async {
    // Don't allow multiple operations at once
    if (state.isProcessing) return null;

    // Update state to show processing
    state = state.copyWith(
      isProcessing: true,
      operationState: ExerciseOperationState.loading,
      errorMessage: null,
    );

    try {
      // Get the repository and add the exercise
      final repository = ref.read(exerciseRepositoryProvider);
      final newExercise = await repository.addExercise(exercise);

      // Invalidate providers to refresh data
      ref.invalidate(allExercisesProvider);
      ref.invalidate(exercisesByMuscleProvider(exercise.primaryMuscle));

      if (exercise.secondaryMuscles != null) {
        for (final muscle in exercise.secondaryMuscles!) {
          ref.invalidate(exercisesByMuscleProvider(muscle));
        }
      }

      // Update state to show success
      state = state.copyWith(
        isProcessing: false,
        operationState: ExerciseOperationState.success,
      );

      return newExercise;
    } catch (e) {
      // Update state to show error
      state = state.copyWith(
        isProcessing: false,
        operationState: ExerciseOperationState.error,
        errorMessage: 'Failed to add exercise: $e',
      );
      debugPrint('Error adding exercise: $e');
      return null;
    }
  }

  /// Delete an exercise with proper error handling and user feedback
  Future<bool> deleteExercise(String exerciseId, Muscle primaryMuscle) async {
    // Don't allow multiple operations at once
    if (state.isProcessing) return false;

    // Update state to show processing
    state = state.copyWith(
      isProcessing: true,
      operationState: ExerciseOperationState.loading,
      errorMessage: null,
    );

    try {
      // Get the repository and delete the exercise
      final repository = ref.read(exerciseRepositoryProvider);
      final success = await repository.deleteExercise(exerciseId);

      if (success) {
        // Invalidate providers to refresh data
        ref.invalidate(allExercisesProvider);
        ref.invalidate(exercisesByMuscleProvider(primaryMuscle));
        ref.invalidate(favoriteExercisesProvider);
        ref.invalidate(exerciseByIdProvider(exerciseId));
      }

      // Update state to show success/failure
      state = state.copyWith(
        isProcessing: false,
        operationState: success
            ? ExerciseOperationState.success
            : ExerciseOperationState.error,
        errorMessage: success ? null : 'Failed to delete exercise',
      );

      return success;
    } catch (e) {
      // Update state to show error
      state = state.copyWith(
        isProcessing: false,
        operationState: ExerciseOperationState.error,
        errorMessage: 'Failed to delete exercise: $e',
      );
      debugPrint('Error deleting exercise: $e');
      return false;
    }
  }

  /// Reset the operation state to idle
  void resetState() {
    state = const ExerciseState();
  }
}

/// Provider for the exercise controller
final exerciseControllerProvider =
    StateNotifierProvider<ExerciseController, ExerciseState>((ref) {
  return ExerciseController(ref);
});
