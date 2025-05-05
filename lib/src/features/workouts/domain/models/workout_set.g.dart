// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkoutSetImpl _$$WorkoutSetImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutSetImpl(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      reps: (json['reps'] as num).toInt(),
      weight: (json['weight'] as num).toDouble(),
      weightUnit: $enumDecode(_$WeightUnitEnumMap, json['weightUnit']),
      restTimeSeconds: (json['restTimeSeconds'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$WorkoutSetImplToJson(_$WorkoutSetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'exerciseId': instance.exerciseId,
      'reps': instance.reps,
      'weight': instance.weight,
      'weightUnit': _$WeightUnitEnumMap[instance.weightUnit]!,
      'restTimeSeconds': instance.restTimeSeconds,
      'notes': instance.notes,
    };

const _$WeightUnitEnumMap = {
  WeightUnit.kg: 'kg',
  WeightUnit.lbs: 'lbs',
};
