import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'workout_set.dart'; // Use relative import

/// Represents a single logged workout session.
@immutable
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.userId, // To associate with a user
    required this.startTime,
    this.endTime,
    required this.performedExercises, // Map: Exercise ID -> List of Sets
    this.notes,
  });

  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime; // Null if the workout is ongoing
  final Map<String, List<WorkoutSet>> performedExercises;
  final String? notes;

  // Calculate duration if endTime is set
  Duration? get duration => endTime?.difference(startTime);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          // Deep map equality check
          const MapEquality()
              .equals(performedExercises, other.performedExercises);

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      startTime.hashCode ^
      endTime.hashCode ^
      const MapEquality().hash(performedExercises);

  @override
  String toString() {
    return 'WorkoutSession{id: $id, userId: $userId, startTime: $startTime, endTime: $endTime}';
  }

  // Add fromJson/toJson later
}
