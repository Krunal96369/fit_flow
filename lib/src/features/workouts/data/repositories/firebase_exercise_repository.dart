import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../../domain/models/exercise.dart';
import '../../domain/models/muscle.dart';
import '../../domain/repositories/exercise_repository.dart';

/// Implementation of [ExerciseRepository] using Firebase Firestore.
class FirebaseExerciseRepository implements ExerciseRepository {
  FirebaseExerciseRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String _collection = 'exercises';

  CollectionReference<Map<String, dynamic>> get _exercisesRef =>
      _firestore.collection(_collection);

  @override
  Future<List<Exercise>> getAllExercises() async {
    try {
      // Limit the initial fetch to avoid retrieving too many documents at once
      final snapshot = await _exercisesRef.limit(100).get();
      return snapshot.docs
          .map((doc) => Exercise.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all exercises: $e');
      rethrow;
    }
  }

  @override
  Future<Exercise?> getExerciseById(String id) async {
    try {
      final doc = await _exercisesRef.doc(id).get();
      if (!doc.exists) return null;

      return Exercise.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      debugPrint('Error fetching exercise by ID: $e');
      rethrow;
    }
  }

  @override
  Future<List<Exercise>> getExercisesByMuscle(String muscleId) async {
    try {
      // Convert string muscleId to enum value if needed
      Muscle? muscle;
      try {
        muscle = Muscle.values.firstWhere((m) =>
            m.toString().split('.').last == muscleId.toLowerCase() ||
            m.displayName.toLowerCase() == muscleId.toLowerCase());
      } catch (e) {
        // If no exact match, we'll use the string as-is in the query
        debugPrint('Warning: Could not find muscle enum for "$muscleId"');
      }

      final query = muscle != null
          ? _exercisesRef
              .where('primaryMuscle',
                  isEqualTo: muscle.toString().split('.').last)
              .limit(50)
          : _exercisesRef.where('primaryMuscle', isEqualTo: muscleId).limit(50);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => Exercise.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching exercises by muscle: $e');
      rethrow;
    }
  }

  @override
  Future<Exercise> addExercise(Exercise exercise) async {
    try {
      // Let Firestore generate the ID
      final docRef = _exercisesRef.doc();
      final exerciseWithId = exercise.copyWith(id: docRef.id);

      await docRef.set(_removeIdField(exerciseWithId.toJson()));
      return exerciseWithId;
    } catch (e) {
      debugPrint('Error adding exercise: $e');
      rethrow;
    }
  }

  @override
  Future<Exercise> updateExercise(Exercise exercise) async {
    try {
      await _exercisesRef
          .doc(exercise.id)
          .update(_removeIdField(exercise.toJson()));
      return exercise;
    } catch (e) {
      debugPrint('Error updating exercise: $e');
      rethrow;
    }
  }

  @override
  Future<bool> deleteExercise(String id) async {
    try {
      await _exercisesRef.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting exercise: $e');
      return false;
    }
  }

  @override
  Future<List<Exercise>> searchExercises(String searchTerm) async {
    try {
      final term = searchTerm.toLowerCase();

      // For simple searches, limit the number of documents to search
      final snapshot = await _exercisesRef.limit(100).get();

      return snapshot.docs
          .map((doc) => Exercise.fromJson({...doc.data(), 'id': doc.id}))
          .where((exercise) =>
              exercise.name.toLowerCase().contains(term) ||
              (exercise.description?.toLowerCase().contains(term) ?? false))
          .toList();
    } catch (e) {
      debugPrint('Error searching exercises: $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    try {
      await _exercisesRef.doc(id).update({'isFavorite': isFavorite});
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }

  @override
  Future<List<Exercise>> getFavoriteExercises() async {
    try {
      // Get user ID from auth service
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return [];
      }

      final exercisesQuery = await _exercisesRef
          .where('isFavorite', isEqualTo: true)
          .where('userId', isEqualTo: userId)
          .get();

      return exercisesQuery.docs
          .map((doc) => Exercise.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting favorite exercises: $e');
      return [];
    }
  }

  // Helper to remove the id field before saving to Firestore
  // (since id is stored as document id)
  Map<String, dynamic> _removeIdField(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    result.remove('id');
    return result;
  }

  // Added for backward compatibility with dependent code
  Future<List<Exercise>> fetchExercises() async {
    return getAllExercises();
  }

  // Added for backward compatibility with dependent code
  Future<Exercise?> fetchExerciseById(String id) async {
    return getExerciseById(id);
  }
}
