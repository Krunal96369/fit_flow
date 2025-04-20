import 'package:meta/meta.dart';

/// Represents a single set performed for an exercise during a workout.
@immutable
class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.exerciseId, // Link back to the Exercise
    required this.reps,
    required this.weight,
    this.restTimeSeconds, // Optional rest time after this set
    this.notes,
    // Add other fields later (e.g., RPE, tempo)
  });

  final String id;
  final String exerciseId;
  final int reps;
  final double weight; // Assuming weight can be fractional (e.g., kg or lbs)
  final int? restTimeSeconds;
  final String? notes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSet &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          exerciseId == other.exerciseId &&
          reps == other.reps &&
          weight == other.weight;

  @override
  int get hashCode =>
      id.hashCode ^ exerciseId.hashCode ^ reps.hashCode ^ weight.hashCode;

  @override
  String toString() {
    return 'WorkoutSet{id: $id, exerciseId: $exerciseId, reps: $reps, weight: $weight}';
  }

  // Add fromJson/toJson later
}
