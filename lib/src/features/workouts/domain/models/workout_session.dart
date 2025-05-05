import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

import 'workout_set.dart'; // Use relative import

part 'workout_session.freezed.dart';
part 'workout_session.g.dart';

// --- Timestamp Converters ---
// Converts Firestore Timestamp to DateTime
DateTime timestampFromJson(Timestamp timestamp) => timestamp.toDate();
// Converts DateTime to Firestore Timestamp
Timestamp timestampToJson(DateTime date) => Timestamp.fromDate(date);
// Handles nullable DateTime <-> Timestamp conversion
DateTime? nullableTimestampFromJson(Timestamp? timestamp) => timestamp?.toDate();
Timestamp? nullableTimestampToJson(DateTime? date) =>
    date == null ? null : Timestamp.fromDate(date);
// --- End Timestamp Converters ---

/// Represents a single logged workout session.
@freezed
class WorkoutSession with _$WorkoutSession {
  // Ensure WorkoutSet also has fromJson/toJson for this to work correctly
  @JsonSerializable(explicitToJson: true) // Ensure nested objects are serialized
  const factory WorkoutSession({
    required String id,
    required String userId, // To associate with a user
    // Apply converters to startTime
    @JsonKey(fromJson: timestampFromJson, toJson: timestampToJson)
    required DateTime startTime,
    // Apply converters to nullable endTime
    @JsonKey(fromJson: nullableTimestampFromJson, toJson: nullableTimestampToJson)
    DateTime? endTime, // Null if the workout is ongoing
    // Map keys must be Strings for JSON. Assumes Exercise ID is String.
    required Map<String, List<WorkoutSet>> performedExercises,
    String? notes,
  }) = _WorkoutSession;

  // Private constructor for Freezed
  const WorkoutSession._();

  // Calculate duration if endTime is set
  Duration? get duration => endTime?.difference(startTime);

  // Factory constructor for creating a new WorkoutSession instance from a map
  factory WorkoutSession.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSessionFromJson(json);
}
