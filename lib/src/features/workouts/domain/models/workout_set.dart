import 'package:freezed_annotation/freezed_annotation.dart';
import 'weight_unit.dart';

part 'workout_set.freezed.dart';
part 'workout_set.g.dart';

/// Represents a single set performed for an exercise during a workout session.
@freezed
class WorkoutSet with _$WorkoutSet {

  // Ensure WeightUnit is JsonSerializable or has a converter
  const factory WorkoutSet({
    required String id,
    required String exerciseId, // Link back to the Exercise
    required int reps,
    required double weight,
    required WeightUnit weightUnit,
    int? restTimeSeconds, // Optional rest time after this set
    String? notes,
    // Add other fields later (e.g., RPE, tempo)
  }) = _WorkoutSet;

  // Factory constructor for creating a new WorkoutSet instance from a map
  factory WorkoutSet.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSetFromJson(json);
}
