// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WorkoutSession _$WorkoutSessionFromJson(Map<String, dynamic> json) {
  return _WorkoutSession.fromJson(json);
}

/// @nodoc
mixin _$WorkoutSession {
  String get id => throw _privateConstructorUsedError;
  String get userId =>
      throw _privateConstructorUsedError; // To associate with a user
// Apply converters to startTime
  @JsonKey(fromJson: timestampFromJson, toJson: timestampToJson)
  DateTime get startTime =>
      throw _privateConstructorUsedError; // Apply converters to nullable endTime
  @JsonKey(fromJson: nullableTimestampFromJson, toJson: nullableTimestampToJson)
  DateTime? get endTime =>
      throw _privateConstructorUsedError; // Null if the workout is ongoing
// Map keys must be Strings for JSON. Assumes Exercise ID is String.
  Map<String, List<WorkoutSet>> get performedExercises =>
      throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this WorkoutSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WorkoutSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkoutSessionCopyWith<WorkoutSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutSessionCopyWith<$Res> {
  factory $WorkoutSessionCopyWith(
          WorkoutSession value, $Res Function(WorkoutSession) then) =
      _$WorkoutSessionCopyWithImpl<$Res, WorkoutSession>;
  @useResult
  $Res call(
      {String id,
      String userId,
      @JsonKey(fromJson: timestampFromJson, toJson: timestampToJson)
      DateTime startTime,
      @JsonKey(
          fromJson: nullableTimestampFromJson, toJson: nullableTimestampToJson)
      DateTime? endTime,
      Map<String, List<WorkoutSet>> performedExercises,
      String? notes});
}

/// @nodoc
class _$WorkoutSessionCopyWithImpl<$Res, $Val extends WorkoutSession>
    implements $WorkoutSessionCopyWith<$Res> {
  _$WorkoutSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkoutSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? performedExercises = null,
    Object? notes = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      performedExercises: null == performedExercises
          ? _value.performedExercises
          : performedExercises // ignore: cast_nullable_to_non_nullable
              as Map<String, List<WorkoutSet>>,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkoutSessionImplCopyWith<$Res>
    implements $WorkoutSessionCopyWith<$Res> {
  factory _$$WorkoutSessionImplCopyWith(_$WorkoutSessionImpl value,
          $Res Function(_$WorkoutSessionImpl) then) =
      __$$WorkoutSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      @JsonKey(fromJson: timestampFromJson, toJson: timestampToJson)
      DateTime startTime,
      @JsonKey(
          fromJson: nullableTimestampFromJson, toJson: nullableTimestampToJson)
      DateTime? endTime,
      Map<String, List<WorkoutSet>> performedExercises,
      String? notes});
}

/// @nodoc
class __$$WorkoutSessionImplCopyWithImpl<$Res>
    extends _$WorkoutSessionCopyWithImpl<$Res, _$WorkoutSessionImpl>
    implements _$$WorkoutSessionImplCopyWith<$Res> {
  __$$WorkoutSessionImplCopyWithImpl(
      _$WorkoutSessionImpl _value, $Res Function(_$WorkoutSessionImpl) _then)
      : super(_value, _then);

  /// Create a copy of WorkoutSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? performedExercises = null,
    Object? notes = freezed,
  }) {
    return _then(_$WorkoutSessionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      performedExercises: null == performedExercises
          ? _value._performedExercises
          : performedExercises // ignore: cast_nullable_to_non_nullable
              as Map<String, List<WorkoutSet>>,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$WorkoutSessionImpl extends _WorkoutSession {
  const _$WorkoutSessionImpl(
      {required this.id,
      required this.userId,
      @JsonKey(fromJson: timestampFromJson, toJson: timestampToJson)
      required this.startTime,
      @JsonKey(
          fromJson: nullableTimestampFromJson, toJson: nullableTimestampToJson)
      this.endTime,
      required final Map<String, List<WorkoutSet>> performedExercises,
      this.notes})
      : _performedExercises = performedExercises,
        super._();

  factory _$WorkoutSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutSessionImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
// To associate with a user
// Apply converters to startTime
  @override
  @JsonKey(fromJson: timestampFromJson, toJson: timestampToJson)
  final DateTime startTime;
// Apply converters to nullable endTime
  @override
  @JsonKey(fromJson: nullableTimestampFromJson, toJson: nullableTimestampToJson)
  final DateTime? endTime;
// Null if the workout is ongoing
// Map keys must be Strings for JSON. Assumes Exercise ID is String.
  final Map<String, List<WorkoutSet>> _performedExercises;
// Null if the workout is ongoing
// Map keys must be Strings for JSON. Assumes Exercise ID is String.
  @override
  Map<String, List<WorkoutSet>> get performedExercises {
    if (_performedExercises is EqualUnmodifiableMapView)
      return _performedExercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_performedExercises);
  }

  @override
  final String? notes;

  @override
  String toString() {
    return 'WorkoutSession(id: $id, userId: $userId, startTime: $startTime, endTime: $endTime, performedExercises: $performedExercises, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            const DeepCollectionEquality()
                .equals(other._performedExercises, _performedExercises) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, startTime, endTime,
      const DeepCollectionEquality().hash(_performedExercises), notes);

  /// Create a copy of WorkoutSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutSessionImplCopyWith<_$WorkoutSessionImpl> get copyWith =>
      __$$WorkoutSessionImplCopyWithImpl<_$WorkoutSessionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutSessionImplToJson(
      this,
    );
  }
}

abstract class _WorkoutSession extends WorkoutSession {
  const factory _WorkoutSession(
      {required final String id,
      required final String userId,
      @JsonKey(fromJson: timestampFromJson, toJson: timestampToJson)
      required final DateTime startTime,
      @JsonKey(
          fromJson: nullableTimestampFromJson, toJson: nullableTimestampToJson)
      final DateTime? endTime,
      required final Map<String, List<WorkoutSet>> performedExercises,
      final String? notes}) = _$WorkoutSessionImpl;
  const _WorkoutSession._() : super._();

  factory _WorkoutSession.fromJson(Map<String, dynamic> json) =
      _$WorkoutSessionImpl.fromJson;

  @override
  String get id;
  @override
  String get userId; // To associate with a user
// Apply converters to startTime
  @override
  @JsonKey(fromJson: timestampFromJson, toJson: timestampToJson)
  DateTime get startTime; // Apply converters to nullable endTime
  @override
  @JsonKey(fromJson: nullableTimestampFromJson, toJson: nullableTimestampToJson)
  DateTime? get endTime; // Null if the workout is ongoing
// Map keys must be Strings for JSON. Assumes Exercise ID is String.
  @override
  Map<String, List<WorkoutSet>> get performedExercises;
  @override
  String? get notes;

  /// Create a copy of WorkoutSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkoutSessionImplCopyWith<_$WorkoutSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
