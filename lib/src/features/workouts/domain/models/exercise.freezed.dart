// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Exercise _$ExerciseFromJson(Map<String, dynamic> json) {
  return _Exercise.fromJson(json);
}

/// @nodoc
mixin _$Exercise {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  Muscle get primaryMuscle => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  List<Muscle>? get secondaryMuscles => throw _privateConstructorUsedError;
  Difficulty? get difficulty => throw _privateConstructorUsedError;
  List<Equipment>? get equipmentNeeded => throw _privateConstructorUsedError;
  MovementPattern? get movementPattern => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get videoUrl => throw _privateConstructorUsedError;
  String? get instructions => throw _privateConstructorUsedError;
  String? get properForm => throw _privateConstructorUsedError;
  String? get commonMistakes => throw _privateConstructorUsedError;
  List<String>? get alternativeExercises => throw _privateConstructorUsedError;
  List<String>? get equipmentVariations => throw _privateConstructorUsedError;
  int? get calories =>
      throw _privateConstructorUsedError; // calories burned in 30 minutes (average)
  bool? get isFavorite => throw _privateConstructorUsedError;
  bool? get isCompoundMovement => throw _privateConstructorUsedError;
  String? get muscleGroupImageUrl => throw _privateConstructorUsedError;

  /// Serializes this Exercise to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Exercise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExerciseCopyWith<Exercise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseCopyWith<$Res> {
  factory $ExerciseCopyWith(Exercise value, $Res Function(Exercise) then) =
      _$ExerciseCopyWithImpl<$Res, Exercise>;
  @useResult
  $Res call(
      {String id,
      String name,
      Muscle primaryMuscle,
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
      int? calories,
      bool? isFavorite,
      bool? isCompoundMovement,
      String? muscleGroupImageUrl});
}

/// @nodoc
class _$ExerciseCopyWithImpl<$Res, $Val extends Exercise>
    implements $ExerciseCopyWith<$Res> {
  _$ExerciseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Exercise
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? primaryMuscle = null,
    Object? description = freezed,
    Object? secondaryMuscles = freezed,
    Object? difficulty = freezed,
    Object? equipmentNeeded = freezed,
    Object? movementPattern = freezed,
    Object? imageUrl = freezed,
    Object? videoUrl = freezed,
    Object? instructions = freezed,
    Object? properForm = freezed,
    Object? commonMistakes = freezed,
    Object? alternativeExercises = freezed,
    Object? equipmentVariations = freezed,
    Object? calories = freezed,
    Object? isFavorite = freezed,
    Object? isCompoundMovement = freezed,
    Object? muscleGroupImageUrl = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      primaryMuscle: null == primaryMuscle
          ? _value.primaryMuscle
          : primaryMuscle // ignore: cast_nullable_to_non_nullable
              as Muscle,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      secondaryMuscles: freezed == secondaryMuscles
          ? _value.secondaryMuscles
          : secondaryMuscles // ignore: cast_nullable_to_non_nullable
              as List<Muscle>?,
      difficulty: freezed == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as Difficulty?,
      equipmentNeeded: freezed == equipmentNeeded
          ? _value.equipmentNeeded
          : equipmentNeeded // ignore: cast_nullable_to_non_nullable
              as List<Equipment>?,
      movementPattern: freezed == movementPattern
          ? _value.movementPattern
          : movementPattern // ignore: cast_nullable_to_non_nullable
              as MovementPattern?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      videoUrl: freezed == videoUrl
          ? _value.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      instructions: freezed == instructions
          ? _value.instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as String?,
      properForm: freezed == properForm
          ? _value.properForm
          : properForm // ignore: cast_nullable_to_non_nullable
              as String?,
      commonMistakes: freezed == commonMistakes
          ? _value.commonMistakes
          : commonMistakes // ignore: cast_nullable_to_non_nullable
              as String?,
      alternativeExercises: freezed == alternativeExercises
          ? _value.alternativeExercises
          : alternativeExercises // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      equipmentVariations: freezed == equipmentVariations
          ? _value.equipmentVariations
          : equipmentVariations // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      calories: freezed == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int?,
      isFavorite: freezed == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool?,
      isCompoundMovement: freezed == isCompoundMovement
          ? _value.isCompoundMovement
          : isCompoundMovement // ignore: cast_nullable_to_non_nullable
              as bool?,
      muscleGroupImageUrl: freezed == muscleGroupImageUrl
          ? _value.muscleGroupImageUrl
          : muscleGroupImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExerciseImplCopyWith<$Res>
    implements $ExerciseCopyWith<$Res> {
  factory _$$ExerciseImplCopyWith(
          _$ExerciseImpl value, $Res Function(_$ExerciseImpl) then) =
      __$$ExerciseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      Muscle primaryMuscle,
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
      int? calories,
      bool? isFavorite,
      bool? isCompoundMovement,
      String? muscleGroupImageUrl});
}

/// @nodoc
class __$$ExerciseImplCopyWithImpl<$Res>
    extends _$ExerciseCopyWithImpl<$Res, _$ExerciseImpl>
    implements _$$ExerciseImplCopyWith<$Res> {
  __$$ExerciseImplCopyWithImpl(
      _$ExerciseImpl _value, $Res Function(_$ExerciseImpl) _then)
      : super(_value, _then);

  /// Create a copy of Exercise
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? primaryMuscle = null,
    Object? description = freezed,
    Object? secondaryMuscles = freezed,
    Object? difficulty = freezed,
    Object? equipmentNeeded = freezed,
    Object? movementPattern = freezed,
    Object? imageUrl = freezed,
    Object? videoUrl = freezed,
    Object? instructions = freezed,
    Object? properForm = freezed,
    Object? commonMistakes = freezed,
    Object? alternativeExercises = freezed,
    Object? equipmentVariations = freezed,
    Object? calories = freezed,
    Object? isFavorite = freezed,
    Object? isCompoundMovement = freezed,
    Object? muscleGroupImageUrl = freezed,
  }) {
    return _then(_$ExerciseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      primaryMuscle: null == primaryMuscle
          ? _value.primaryMuscle
          : primaryMuscle // ignore: cast_nullable_to_non_nullable
              as Muscle,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      secondaryMuscles: freezed == secondaryMuscles
          ? _value._secondaryMuscles
          : secondaryMuscles // ignore: cast_nullable_to_non_nullable
              as List<Muscle>?,
      difficulty: freezed == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as Difficulty?,
      equipmentNeeded: freezed == equipmentNeeded
          ? _value._equipmentNeeded
          : equipmentNeeded // ignore: cast_nullable_to_non_nullable
              as List<Equipment>?,
      movementPattern: freezed == movementPattern
          ? _value.movementPattern
          : movementPattern // ignore: cast_nullable_to_non_nullable
              as MovementPattern?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      videoUrl: freezed == videoUrl
          ? _value.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      instructions: freezed == instructions
          ? _value.instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as String?,
      properForm: freezed == properForm
          ? _value.properForm
          : properForm // ignore: cast_nullable_to_non_nullable
              as String?,
      commonMistakes: freezed == commonMistakes
          ? _value.commonMistakes
          : commonMistakes // ignore: cast_nullable_to_non_nullable
              as String?,
      alternativeExercises: freezed == alternativeExercises
          ? _value._alternativeExercises
          : alternativeExercises // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      equipmentVariations: freezed == equipmentVariations
          ? _value._equipmentVariations
          : equipmentVariations // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      calories: freezed == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int?,
      isFavorite: freezed == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool?,
      isCompoundMovement: freezed == isCompoundMovement
          ? _value.isCompoundMovement
          : isCompoundMovement // ignore: cast_nullable_to_non_nullable
              as bool?,
      muscleGroupImageUrl: freezed == muscleGroupImageUrl
          ? _value.muscleGroupImageUrl
          : muscleGroupImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseImpl implements _Exercise {
  const _$ExerciseImpl(
      {required this.id,
      required this.name,
      required this.primaryMuscle,
      this.description,
      final List<Muscle>? secondaryMuscles,
      this.difficulty,
      final List<Equipment>? equipmentNeeded,
      this.movementPattern,
      this.imageUrl,
      this.videoUrl,
      this.instructions,
      this.properForm,
      this.commonMistakes,
      final List<String>? alternativeExercises,
      final List<String>? equipmentVariations,
      this.calories,
      this.isFavorite,
      this.isCompoundMovement,
      this.muscleGroupImageUrl})
      : _secondaryMuscles = secondaryMuscles,
        _equipmentNeeded = equipmentNeeded,
        _alternativeExercises = alternativeExercises,
        _equipmentVariations = equipmentVariations;

  factory _$ExerciseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final Muscle primaryMuscle;
  @override
  final String? description;
  final List<Muscle>? _secondaryMuscles;
  @override
  List<Muscle>? get secondaryMuscles {
    final value = _secondaryMuscles;
    if (value == null) return null;
    if (_secondaryMuscles is EqualUnmodifiableListView)
      return _secondaryMuscles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final Difficulty? difficulty;
  final List<Equipment>? _equipmentNeeded;
  @override
  List<Equipment>? get equipmentNeeded {
    final value = _equipmentNeeded;
    if (value == null) return null;
    if (_equipmentNeeded is EqualUnmodifiableListView) return _equipmentNeeded;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final MovementPattern? movementPattern;
  @override
  final String? imageUrl;
  @override
  final String? videoUrl;
  @override
  final String? instructions;
  @override
  final String? properForm;
  @override
  final String? commonMistakes;
  final List<String>? _alternativeExercises;
  @override
  List<String>? get alternativeExercises {
    final value = _alternativeExercises;
    if (value == null) return null;
    if (_alternativeExercises is EqualUnmodifiableListView)
      return _alternativeExercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _equipmentVariations;
  @override
  List<String>? get equipmentVariations {
    final value = _equipmentVariations;
    if (value == null) return null;
    if (_equipmentVariations is EqualUnmodifiableListView)
      return _equipmentVariations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final int? calories;
// calories burned in 30 minutes (average)
  @override
  final bool? isFavorite;
  @override
  final bool? isCompoundMovement;
  @override
  final String? muscleGroupImageUrl;

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, primaryMuscle: $primaryMuscle, description: $description, secondaryMuscles: $secondaryMuscles, difficulty: $difficulty, equipmentNeeded: $equipmentNeeded, movementPattern: $movementPattern, imageUrl: $imageUrl, videoUrl: $videoUrl, instructions: $instructions, properForm: $properForm, commonMistakes: $commonMistakes, alternativeExercises: $alternativeExercises, equipmentVariations: $equipmentVariations, calories: $calories, isFavorite: $isFavorite, isCompoundMovement: $isCompoundMovement, muscleGroupImageUrl: $muscleGroupImageUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.primaryMuscle, primaryMuscle) ||
                other.primaryMuscle == primaryMuscle) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._secondaryMuscles, _secondaryMuscles) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            const DeepCollectionEquality()
                .equals(other._equipmentNeeded, _equipmentNeeded) &&
            (identical(other.movementPattern, movementPattern) ||
                other.movementPattern == movementPattern) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.videoUrl, videoUrl) ||
                other.videoUrl == videoUrl) &&
            (identical(other.instructions, instructions) ||
                other.instructions == instructions) &&
            (identical(other.properForm, properForm) ||
                other.properForm == properForm) &&
            (identical(other.commonMistakes, commonMistakes) ||
                other.commonMistakes == commonMistakes) &&
            const DeepCollectionEquality()
                .equals(other._alternativeExercises, _alternativeExercises) &&
            const DeepCollectionEquality()
                .equals(other._equipmentVariations, _equipmentVariations) &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.isCompoundMovement, isCompoundMovement) ||
                other.isCompoundMovement == isCompoundMovement) &&
            (identical(other.muscleGroupImageUrl, muscleGroupImageUrl) ||
                other.muscleGroupImageUrl == muscleGroupImageUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        primaryMuscle,
        description,
        const DeepCollectionEquality().hash(_secondaryMuscles),
        difficulty,
        const DeepCollectionEquality().hash(_equipmentNeeded),
        movementPattern,
        imageUrl,
        videoUrl,
        instructions,
        properForm,
        commonMistakes,
        const DeepCollectionEquality().hash(_alternativeExercises),
        const DeepCollectionEquality().hash(_equipmentVariations),
        calories,
        isFavorite,
        isCompoundMovement,
        muscleGroupImageUrl
      ]);

  /// Create a copy of Exercise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseImplCopyWith<_$ExerciseImpl> get copyWith =>
      __$$ExerciseImplCopyWithImpl<_$ExerciseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseImplToJson(
      this,
    );
  }
}

abstract class _Exercise implements Exercise {
  const factory _Exercise(
      {required final String id,
      required final String name,
      required final Muscle primaryMuscle,
      final String? description,
      final List<Muscle>? secondaryMuscles,
      final Difficulty? difficulty,
      final List<Equipment>? equipmentNeeded,
      final MovementPattern? movementPattern,
      final String? imageUrl,
      final String? videoUrl,
      final String? instructions,
      final String? properForm,
      final String? commonMistakes,
      final List<String>? alternativeExercises,
      final List<String>? equipmentVariations,
      final int? calories,
      final bool? isFavorite,
      final bool? isCompoundMovement,
      final String? muscleGroupImageUrl}) = _$ExerciseImpl;

  factory _Exercise.fromJson(Map<String, dynamic> json) =
      _$ExerciseImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  Muscle get primaryMuscle;
  @override
  String? get description;
  @override
  List<Muscle>? get secondaryMuscles;
  @override
  Difficulty? get difficulty;
  @override
  List<Equipment>? get equipmentNeeded;
  @override
  MovementPattern? get movementPattern;
  @override
  String? get imageUrl;
  @override
  String? get videoUrl;
  @override
  String? get instructions;
  @override
  String? get properForm;
  @override
  String? get commonMistakes;
  @override
  List<String>? get alternativeExercises;
  @override
  List<String>? get equipmentVariations;
  @override
  int? get calories; // calories burned in 30 minutes (average)
  @override
  bool? get isFavorite;
  @override
  bool? get isCompoundMovement;
  @override
  String? get muscleGroupImageUrl;

  /// Create a copy of Exercise
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExerciseImplCopyWith<_$ExerciseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
