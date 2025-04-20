// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseImpl _$$ExerciseImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      primaryMuscle: $enumDecode(_$MuscleEnumMap, json['primaryMuscle']),
      description: json['description'] as String?,
      secondaryMuscles: (json['secondaryMuscles'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$MuscleEnumMap, e))
          .toList(),
      difficulty: $enumDecodeNullable(_$DifficultyEnumMap, json['difficulty']),
      equipmentNeeded: (json['equipmentNeeded'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$EquipmentEnumMap, e))
          .toList(),
      movementPattern: $enumDecodeNullable(
          _$MovementPatternEnumMap, json['movementPattern']),
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      instructions: json['instructions'] as String?,
      properForm: json['properForm'] as String?,
      commonMistakes: json['commonMistakes'] as String?,
      alternativeExercises: (json['alternativeExercises'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      equipmentVariations: (json['equipmentVariations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      calories: (json['calories'] as num?)?.toInt(),
      isFavorite: json['isFavorite'] as bool?,
      isCompoundMovement: json['isCompoundMovement'] as bool?,
      muscleGroupImageUrl: json['muscleGroupImageUrl'] as String?,
    );

Map<String, dynamic> _$$ExerciseImplToJson(_$ExerciseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'primaryMuscle': _$MuscleEnumMap[instance.primaryMuscle]!,
      'description': instance.description,
      'secondaryMuscles':
          instance.secondaryMuscles?.map((e) => _$MuscleEnumMap[e]!).toList(),
      'difficulty': _$DifficultyEnumMap[instance.difficulty],
      'equipmentNeeded':
          instance.equipmentNeeded?.map((e) => _$EquipmentEnumMap[e]!).toList(),
      'movementPattern': _$MovementPatternEnumMap[instance.movementPattern],
      'imageUrl': instance.imageUrl,
      'videoUrl': instance.videoUrl,
      'instructions': instance.instructions,
      'properForm': instance.properForm,
      'commonMistakes': instance.commonMistakes,
      'alternativeExercises': instance.alternativeExercises,
      'equipmentVariations': instance.equipmentVariations,
      'calories': instance.calories,
      'isFavorite': instance.isFavorite,
      'isCompoundMovement': instance.isCompoundMovement,
      'muscleGroupImageUrl': instance.muscleGroupImageUrl,
    };

const _$MuscleEnumMap = {
  Muscle.chest: 'chest',
  Muscle.back: 'back',
  Muscle.shoulders: 'shoulders',
  Muscle.biceps: 'biceps',
  Muscle.triceps: 'triceps',
  Muscle.forearms: 'forearms',
  Muscle.abs: 'abs',
  Muscle.quads: 'quads',
  Muscle.hamstrings: 'hamstrings',
  Muscle.calves: 'calves',
  Muscle.glutes: 'glutes',
  Muscle.traps: 'traps',
  Muscle.lats: 'lats',
  Muscle.obliques: 'obliques',
  Muscle.lowerBack: 'lowerBack',
  Muscle.upperBack: 'upperBack',
  Muscle.fullBody: 'fullBody',
};

const _$DifficultyEnumMap = {
  Difficulty.beginner: 'beginner',
  Difficulty.intermediate: 'intermediate',
  Difficulty.advanced: 'advanced',
};

const _$EquipmentEnumMap = {
  Equipment.noEquipment: 'noEquipment',
  Equipment.dumbbells: 'dumbbells',
  Equipment.barbell: 'barbell',
  Equipment.kettlebell: 'kettlebell',
  Equipment.resistanceBands: 'resistanceBands',
  Equipment.cable: 'cable',
  Equipment.machine: 'machine',
  Equipment.medicineBall: 'medicineBall',
  Equipment.foam: 'foam',
  Equipment.bench: 'bench',
  Equipment.pullUpBar: 'pullUpBar',
  Equipment.dipBars: 'dipBars',
  Equipment.swissBall: 'swissBall',
  Equipment.rings: 'rings',
  Equipment.trx: 'trx',
  Equipment.rope: 'rope',
  Equipment.box: 'box',
  Equipment.other: 'other',
};

const _$MovementPatternEnumMap = {
  MovementPattern.push: 'push',
  MovementPattern.pull: 'pull',
  MovementPattern.squat: 'squat',
  MovementPattern.hinge: 'hinge',
  MovementPattern.lunge: 'lunge',
  MovementPattern.rotation: 'rotation',
  MovementPattern.carry: 'carry',
  MovementPattern.isometric: 'isometric',
};
