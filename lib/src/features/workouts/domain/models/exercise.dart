import 'package:freezed_annotation/freezed_annotation.dart';

import 'difficulty.dart';
import 'equipment.dart';
import 'movement_pattern.dart';
import 'muscle.dart';

part 'exercise.freezed.dart';
part 'exercise.g.dart';

/// Represents a single exercise in the library.
@freezed
class Exercise with _$Exercise {
  const factory Exercise({
    required String id,
    required String name,
    required Muscle primaryMuscle,
    String? description,
    List<Muscle>? secondaryMuscles,
    Difficulty? difficulty,
    List<Equipment>? equipmentNeeded,
    MovementPattern? movementPattern,
    String? imageUrl,
    String? videoUrl,
    String? instructions,
    String? properForm,
    String? commonMistakes,
    List<String>? alternativeExercises,
    List<String>? equipmentVariations,
    int? calories, // calories burned in 30 minutes (average)
    bool? isFavorite,
    bool? isCompoundMovement,
    String? muscleGroupImageUrl,
  }) = _Exercise;

  /// Creates an Exercise from JSON map
  factory Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);
}
