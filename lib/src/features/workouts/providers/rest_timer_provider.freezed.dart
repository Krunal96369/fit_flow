// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rest_timer_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$RestTimerState {
  bool get isRunning => throw _privateConstructorUsedError;
  int get totalDurationSeconds =>
      throw _privateConstructorUsedError; // Default rest: 60 seconds
  int get remainingSeconds => throw _privateConstructorUsedError;

  /// Create a copy of RestTimerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RestTimerStateCopyWith<RestTimerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RestTimerStateCopyWith<$Res> {
  factory $RestTimerStateCopyWith(
          RestTimerState value, $Res Function(RestTimerState) then) =
      _$RestTimerStateCopyWithImpl<$Res, RestTimerState>;
  @useResult
  $Res call({bool isRunning, int totalDurationSeconds, int remainingSeconds});
}

/// @nodoc
class _$RestTimerStateCopyWithImpl<$Res, $Val extends RestTimerState>
    implements $RestTimerStateCopyWith<$Res> {
  _$RestTimerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RestTimerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isRunning = null,
    Object? totalDurationSeconds = null,
    Object? remainingSeconds = null,
  }) {
    return _then(_value.copyWith(
      isRunning: null == isRunning
          ? _value.isRunning
          : isRunning // ignore: cast_nullable_to_non_nullable
              as bool,
      totalDurationSeconds: null == totalDurationSeconds
          ? _value.totalDurationSeconds
          : totalDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      remainingSeconds: null == remainingSeconds
          ? _value.remainingSeconds
          : remainingSeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RestTimerStateImplCopyWith<$Res>
    implements $RestTimerStateCopyWith<$Res> {
  factory _$$RestTimerStateImplCopyWith(_$RestTimerStateImpl value,
          $Res Function(_$RestTimerStateImpl) then) =
      __$$RestTimerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isRunning, int totalDurationSeconds, int remainingSeconds});
}

/// @nodoc
class __$$RestTimerStateImplCopyWithImpl<$Res>
    extends _$RestTimerStateCopyWithImpl<$Res, _$RestTimerStateImpl>
    implements _$$RestTimerStateImplCopyWith<$Res> {
  __$$RestTimerStateImplCopyWithImpl(
      _$RestTimerStateImpl _value, $Res Function(_$RestTimerStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of RestTimerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isRunning = null,
    Object? totalDurationSeconds = null,
    Object? remainingSeconds = null,
  }) {
    return _then(_$RestTimerStateImpl(
      isRunning: null == isRunning
          ? _value.isRunning
          : isRunning // ignore: cast_nullable_to_non_nullable
              as bool,
      totalDurationSeconds: null == totalDurationSeconds
          ? _value.totalDurationSeconds
          : totalDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      remainingSeconds: null == remainingSeconds
          ? _value.remainingSeconds
          : remainingSeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$RestTimerStateImpl
    with DiagnosticableTreeMixin
    implements _RestTimerState {
  const _$RestTimerStateImpl(
      {this.isRunning = false,
      this.totalDurationSeconds = 60,
      this.remainingSeconds = 0});

  @override
  @JsonKey()
  final bool isRunning;
  @override
  @JsonKey()
  final int totalDurationSeconds;
// Default rest: 60 seconds
  @override
  @JsonKey()
  final int remainingSeconds;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'RestTimerState(isRunning: $isRunning, totalDurationSeconds: $totalDurationSeconds, remainingSeconds: $remainingSeconds)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'RestTimerState'))
      ..add(DiagnosticsProperty('isRunning', isRunning))
      ..add(DiagnosticsProperty('totalDurationSeconds', totalDurationSeconds))
      ..add(DiagnosticsProperty('remainingSeconds', remainingSeconds));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RestTimerStateImpl &&
            (identical(other.isRunning, isRunning) ||
                other.isRunning == isRunning) &&
            (identical(other.totalDurationSeconds, totalDurationSeconds) ||
                other.totalDurationSeconds == totalDurationSeconds) &&
            (identical(other.remainingSeconds, remainingSeconds) ||
                other.remainingSeconds == remainingSeconds));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, isRunning, totalDurationSeconds, remainingSeconds);

  /// Create a copy of RestTimerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RestTimerStateImplCopyWith<_$RestTimerStateImpl> get copyWith =>
      __$$RestTimerStateImplCopyWithImpl<_$RestTimerStateImpl>(
          this, _$identity);
}

abstract class _RestTimerState implements RestTimerState {
  const factory _RestTimerState(
      {final bool isRunning,
      final int totalDurationSeconds,
      final int remainingSeconds}) = _$RestTimerStateImpl;

  @override
  bool get isRunning;
  @override
  int get totalDurationSeconds; // Default rest: 60 seconds
  @override
  int get remainingSeconds;

  /// Create a copy of RestTimerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RestTimerStateImplCopyWith<_$RestTimerStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
