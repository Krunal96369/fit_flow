import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/workout_session.dart';
import '../domain/repositories/workout_repository.dart';

/// Provides the Firestore instance.
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

/// Firestore implementation of the WorkoutRepository.
class FirestoreWorkoutRepository implements WorkoutRepository {
  final FirebaseFirestore _firestore;

  FirestoreWorkoutRepository(this._firestore);

  /// Returns the collection reference for a specific user's workouts.
  CollectionReference<WorkoutSession> _workoutsRef(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('workouts')
      .withConverter<WorkoutSession>(
        fromFirestore: (snapshot, _) =>
            WorkoutSession.fromJson(snapshot.data()!),
        toFirestore: (workout, _) => workout.toJson(),
      );

  @override
  Future<WorkoutSession?> getWorkoutById(String workoutId) async {
    // Note: This implementation assumes workout IDs are globally unique across users,
    // or that we somehow know the userId to look under. For simplicity,
    // this might need adjustment if workout IDs are only unique per user.
    // A more robust approach might require userId as well.
    try {
      // This is a simplification. A real app might need to search across users
      // or have a different structure if workout IDs aren't globally unique.
      // For now, we'll assume a top-level 'workouts' collection for this specific method,
      // which might differ from the user-centric storage for other methods.
      // Consider revising based on actual ID uniqueness and data structure.

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('No user is currently logged in.');
        return null;
      }

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .doc(workoutId);

      final snapshot = await docRef.get();

      if (snapshot.exists) {
        return WorkoutSession.fromJson(snapshot.data()!);
      }
      return null;
    } catch (e) {
      rethrow; // Or handle more gracefully
    }
  }

  @override
  Future<List<WorkoutSession>> getRecentWorkouts(String userId,
      {int limit = 10}) async {
    try {
      final snapshot = await _workoutsRef(userId)
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting recent workouts for user $userId: $e');
      rethrow;
    }
  }

  @override
  Future<List<WorkoutSession>> getWorkoutsForDate(
      String userId, DateTime date) async {
    final startOfDay =
        Timestamp.fromDate(DateTime(date.year, date.month, date.day));
    final endOfDay = Timestamp.fromDate(
        DateTime(date.year, date.month, date.day, 23, 59, 59, 999));
    try {
      final snapshot = await _workoutsRef(userId)
          .where('startTime', isGreaterThanOrEqualTo: startOfDay)
          .where('startTime', isLessThanOrEqualTo: endOfDay)
          .orderBy('startTime', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting workouts for date $date for user $userId: $e');
      rethrow;
    }
  }

  @override
  Future<List<WorkoutSession>> getWorkoutsForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Ensure endDate covers the entire day
    final preciseEndDate =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
    final startTimestamp = Timestamp.fromDate(startDate);
    final endTimestamp = Timestamp.fromDate(preciseEndDate);
    try {
      // --- Add Logging ---
      final collectionPath = _workoutsRef(userId).path;
      debugPrint(
          '[FirestoreWorkoutRepository] Querying path: $collectionPath'); // Log full path
      debugPrint(
          '[FirestoreWorkoutRepository] Querying workouts for user: $userId');
      debugPrint(
          '[FirestoreWorkoutRepository] Start Timestamp: ${startTimestamp.toDate()}');
      debugPrint(
          '[FirestoreWorkoutRepository] End Timestamp: ${endTimestamp.toDate()}');
      // --- End Logging ---

      final query = _workoutsRef(userId)
          .where('startTime', isGreaterThanOrEqualTo: startTimestamp)
          .where('startTime', isLessThanOrEqualTo: endTimestamp);

      final snapshot = await query.get();

      // --- Add Logging ---
      debugPrint(
          '[FirestoreWorkoutRepository] Found ${snapshot.docs.length} workouts in range.');
      // --- End Logging ---

      // Original order and map logic
      final orderedSnapshot = await query
          .orderBy('startTime',
              descending: true) // Re-apply query with ordering
          .get();

      return orderedSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e, stackTrace) {
      debugPrint(
          'Error getting workouts for date range $startDate - $endDate for user $userId: $e');
      // --- Add Specific Error Logging ---
      if (e is FirebaseException && e.code == 'failed-precondition') {
        debugPrint(
            '[FirestoreWorkoutRepository] Firestore Index Missing? Check console for index creation link.');
      }
      debugPrint(
          '[FirestoreWorkoutRepository] StackTrace: $stackTrace'); // Log stack trace
      // --- End Specific Error Logging ---
      rethrow;
    }
  }

  @override
  Future<WorkoutSession> saveWorkoutSession(WorkoutSession workout) async {
    debugPrint('--- saveWorkoutSession started ---');
    debugPrint(
        '--- Saving Workout ID: ${workout.id}, User ID: ${workout.userId} ---');
    debugPrint('--- Workout JSON: ${workout.toJson()} ---');
    try {
      final docRef = _workoutsRef(workout.userId).doc(workout.id);
      debugPrint('--- Attempting docRef.set() ---');
      await docRef.set(
          workout, SetOptions(merge: true)); // Use merge to allow updates
      debugPrint('--- docRef.set() successful ---');
      // Fetch the potentially merged document to return the final state
      final updatedDoc = await docRef.get();
      debugPrint('--- Fetched updated doc successfully ---');
      return updatedDoc.data()!;
    } catch (e, stackTrace) {
      debugPrint('--- saveWorkoutSession: Error caught ---');
      debugPrint('Firestore Error: $e');
      debugPrint('Firestore StackTrace: $stackTrace');
      debugPrint(
          'Error saving workout ${workout.id} for user ${workout.userId}: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteWorkout(String workoutId) async {
    // This requires knowing the userId associated with the workoutId.
    // This implementation might need adjustment based on how userId is obtained.
    // Assuming we have the userId (e.g., from the current session or passed in):
    // String userId = getCurrentUserId(); // Placeholder for getting the user ID
    // await _workoutsRef(userId).doc(workoutId).delete();
    debugPrint(
        'Warning: deleteWorkout needs userId associated with workoutId $workoutId. Implementation incomplete.');
    // For now, this method is incomplete due to the userId requirement.
    // A possible solution is to change the interface or use a collection group query.
    // Or require userId to be passed to this method.
    throw UnimplementedError(
        'deleteWorkout requires userId. Revise implementation or interface.');
  }
}
