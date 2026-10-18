// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Workout {
  /// Unique identifier for this workout.
  UniqueId get id => throw _privateConstructorUsedError;

  /// User-defined name for the workout.
  WorkoutName get name => throw _privateConstructorUsedError;

  /// The timer configuration for this workout.
  TimerType get timerType => throw _privateConstructorUsedError;

  /// Countdown before the workout starts.
  TimerDuration get prepCountdown => throw _privateConstructorUsedError;

  /// When this workout configuration was created.
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of Workout
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkoutCopyWith<Workout> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutCopyWith<$Res> {
  factory $WorkoutCopyWith(Workout value, $Res Function(Workout) then) =
      _$WorkoutCopyWithImpl<$Res, Workout>;
  @useResult
  $Res call({
    UniqueId id,
    WorkoutName name,
    TimerType timerType,
    TimerDuration prepCountdown,
    DateTime createdAt,
  });
}

/// @nodoc
class _$WorkoutCopyWithImpl<$Res, $Val extends Workout>
    implements $WorkoutCopyWith<$Res> {
  _$WorkoutCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Workout
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? timerType = null,
    Object? prepCountdown = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as UniqueId,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as WorkoutName,
            timerType: null == timerType
                ? _value.timerType
                : timerType // ignore: cast_nullable_to_non_nullable
                      as TimerType,
            prepCountdown: null == prepCountdown
                ? _value.prepCountdown
                : prepCountdown // ignore: cast_nullable_to_non_nullable
                      as TimerDuration,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WorkoutImplCopyWith<$Res> implements $WorkoutCopyWith<$Res> {
  factory _$$WorkoutImplCopyWith(
    _$WorkoutImpl value,
    $Res Function(_$WorkoutImpl) then,
  ) = __$$WorkoutImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    UniqueId id,
    WorkoutName name,
    TimerType timerType,
    TimerDuration prepCountdown,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$WorkoutImplCopyWithImpl<$Res>
    extends _$WorkoutCopyWithImpl<$Res, _$WorkoutImpl>
    implements _$$WorkoutImplCopyWith<$Res> {
  __$$WorkoutImplCopyWithImpl(
    _$WorkoutImpl _value,
    $Res Function(_$WorkoutImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Workout
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? timerType = null,
    Object? prepCountdown = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$WorkoutImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as UniqueId,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as WorkoutName,
        timerType: null == timerType
            ? _value.timerType
            : timerType // ignore: cast_nullable_to_non_nullable
                  as TimerType,
        prepCountdown: null == prepCountdown
            ? _value.prepCountdown
            : prepCountdown // ignore: cast_nullable_to_non_nullable
                  as TimerDuration,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$WorkoutImpl extends _Workout {
  const _$WorkoutImpl({
    required this.id,
    required this.name,
    required this.timerType,
    required this.prepCountdown,
    required this.createdAt,
  }) : super._();

  /// Unique identifier for this workout.
  @override
  final UniqueId id;

  /// User-defined name for the workout.
  @override
  final WorkoutName name;

  /// The timer configuration for this workout.
  @override
  final TimerType timerType;

  /// Countdown before the workout starts.
  @override
  final TimerDuration prepCountdown;

  /// When this workout configuration was created.
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Workout(id: $id, name: $name, timerType: $timerType, prepCountdown: $prepCountdown, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.timerType, timerType) ||
                other.timerType == timerType) &&
            (identical(other.prepCountdown, prepCountdown) ||
                other.prepCountdown == prepCountdown) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, timerType, prepCountdown, createdAt);

  /// Create a copy of Workout
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutImplCopyWith<_$WorkoutImpl> get copyWith =>
      __$$WorkoutImplCopyWithImpl<_$WorkoutImpl>(this, _$identity);
}

abstract class _Workout extends Workout {
  const factory _Workout({
    required final UniqueId id,
    required final WorkoutName name,
    required final TimerType timerType,
    required final TimerDuration prepCountdown,
    required final DateTime createdAt,
  }) = _$WorkoutImpl;
  const _Workout._() : super._();

  /// Unique identifier for this workout.
  @override
  UniqueId get id;

  /// User-defined name for the workout.
  @override
  WorkoutName get name;

  /// The timer configuration for this workout.
  @override
  TimerType get timerType;

  /// Countdown before the workout starts.
  @override
  TimerDuration get prepCountdown;

  /// When this workout configuration was created.
  @override
  DateTime get createdAt;

  /// Create a copy of Workout
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkoutImplCopyWith<_$WorkoutImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
