// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkoutSessionImpl _$$WorkoutSessionImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutSessionImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      startTime: timestampFromJson(json['startTime'] as Timestamp),
      endTime: nullableTimestampFromJson(json['endTime'] as Timestamp?),
      performedExercises:
          (json['performedExercises'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
                .toList()),
      ),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$WorkoutSessionImplToJson(
        _$WorkoutSessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'startTime': timestampToJson(instance.startTime),
      'endTime': nullableTimestampToJson(instance.endTime),
      'performedExercises': instance.performedExercises
          .map((k, e) => MapEntry(k, e.map((e) => e.toJson()).toList())),
      'notes': instance.notes,
    };
