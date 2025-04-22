import '../models/exercise.dart';

/// Interface defining operations for managing exercises
abstract class ExerciseRepository {
  /// Fetches all exercises
  Future<List<Exercise>> getAllExercises();

  /// Fetches exercises for a specific muscle group
  Future<List<Exercise>> getExercisesByMuscle(String muscleId);

  /// Fetches a single exercise by id
  Future<Exercise?> getExerciseById(String id);

  /// Adds a new exercise to the library
  Future<Exercise> addExercise(Exercise exercise);

  /// Updates an existing exercise
  Future<Exercise> updateExercise(Exercise exercise);

  /// Deletes an exercise from the library
  Future<bool> deleteExercise(String id);

  /// Fetches exercises that match the search term
  Future<List<Exercise>> searchExercises(String searchTerm);

  /// Marks an exercise as favorite
  Future<void> toggleFavorite(String id, bool isFavorite);

  /// Fetches all favorite exercises
  Future<List<Exercise>> getFavoriteExercises();
}
