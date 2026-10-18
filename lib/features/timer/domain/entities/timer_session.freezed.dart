// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timer_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TimerSession {
  /// Unique identifier for this session.
  UniqueId get id => throw _privateConstructorUsedError;

  /// The workout configuration for this session.
  Workout get workout => throw _privateConstructorUsedError;

  /// Current state of the timer.
  TimerState get state => throw _privateConstructorUsedError;

  /// Current round number (1-based).
  int get currentRound => throw _privateConstructorUsedError;

  /// Total elapsed time since workout started (excluding prep).
  TimerDuration get elapsed => throw _privateConstructorUsedError;

  /// Elapsed time in the current interval (for interval-based workouts).
  TimerDuration get currentIntervalElapsed =>
      throw _privateConstructorUsedError;

  /// Accumulated milliseconds not yet converted to seconds (for precise timing).
  int get elapsedMillis => throw _privateConstructorUsedError;

  /// Accumulated interval milliseconds not yet converted to seconds.
  int get intervalElapsedMillis => throw _privateConstructorUsedError;

  /// The state before pausing (to restore on resume).
  TimerState? get stateBeforePause => throw _privateConstructorUsedError;

  /// When the session was started.
  DateTime? get startedAt => throw _privateConstructorUsedError;

  /// When the session was completed.
  DateTime? get completedAt => throw _privateConstructorUsedError;

  /// Create a copy of TimerSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimerSessionCopyWith<TimerSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimerSessionCopyWith<$Res> {
  factory $TimerSessionCopyWith(
    TimerSession value,
    $Res Function(TimerSession) then,
  ) = _$TimerSessionCopyWithImpl<$Res, TimerSession>;
  @useResult
  $Res call({
    UniqueId id,
    Workout workout,
    TimerState state,
    int currentRound,
    TimerDuration elapsed,
    TimerDuration currentIntervalElapsed,
    int elapsedMillis,
    int intervalElapsedMillis,
    TimerState? stateBeforePause,
    DateTime? startedAt,
    DateTime? completedAt,
  });

  $WorkoutCopyWith<$Res> get workout;
}

/// @nodoc
class _$TimerSessionCopyWithImpl<$Res, $Val extends TimerSession>
    implements $TimerSessionCopyWith<$Res> {
  _$TimerSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimerSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workout = null,
    Object? state = null,
    Object? currentRound = null,
    Object? elapsed = null,
    Object? currentIntervalElapsed = null,
    Object? elapsedMillis = null,
    Object? intervalElapsedMillis = null,
    Object? stateBeforePause = freezed,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as UniqueId,
            workout: null == workout
                ? _value.workout
                : workout // ignore: cast_nullable_to_non_nullable
                      as Workout,
            state: null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as TimerState,
            currentRound: null == currentRound
                ? _value.currentRound
                : currentRound // ignore: cast_nullable_to_non_nullable
                      as int,
            elapsed: null == elapsed
                ? _value.elapsed
                : elapsed // ignore: cast_nullable_to_non_nullable
                      as TimerDuration,
            currentIntervalElapsed: null == currentIntervalElapsed
                ? _value.currentIntervalElapsed
                : currentIntervalElapsed // ignore: cast_nullable_to_non_nullable
                      as TimerDuration,
            elapsedMillis: null == elapsedMillis
                ? _value.elapsedMillis
                : elapsedMillis // ignore: cast_nullable_to_non_nullable
                      as int,
            intervalElapsedMillis: null == intervalElapsedMillis
                ? _value.intervalElapsedMillis
                : intervalElapsedMillis // ignore: cast_nullable_to_non_nullable
                      as int,
            stateBeforePause: freezed == stateBeforePause
                ? _value.stateBeforePause
                : stateBeforePause // ignore: cast_nullable_to_non_nullable
                      as TimerState?,
            startedAt: freezed == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of TimerSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WorkoutCopyWith<$Res> get workout {
    return $WorkoutCopyWith<$Res>(_value.workout, (value) {
      return _then(_value.copyWith(workout: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TimerSessionImplCopyWith<$Res>
    implements $TimerSessionCopyWith<$Res> {
  factory _$$TimerSessionImplCopyWith(
    _$TimerSessionImpl value,
    $Res Function(_$TimerSessionImpl) then,
  ) = __$$TimerSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    UniqueId id,
    Workout workout,
    TimerState state,
    int currentRound,
    TimerDuration elapsed,
    TimerDuration currentIntervalElapsed,
    int elapsedMillis,
    int intervalElapsedMillis,
    TimerState? stateBeforePause,
    DateTime? startedAt,
    DateTime? completedAt,
  });

  @override
  $WorkoutCopyWith<$Res> get workout;
}

/// @nodoc
class __$$TimerSessionImplCopyWithImpl<$Res>
    extends _$TimerSessionCopyWithImpl<$Res, _$TimerSessionImpl>
    implements _$$TimerSessionImplCopyWith<$Res> {
  __$$TimerSessionImplCopyWithImpl(
    _$TimerSessionImpl _value,
    $Res Function(_$TimerSessionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TimerSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workout = null,
    Object? state = null,
    Object? currentRound = null,
    Object? elapsed = null,
    Object? currentIntervalElapsed = null,
    Object? elapsedMillis = null,
    Object? intervalElapsedMillis = null,
    Object? stateBeforePause = freezed,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(
      _$TimerSessionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as UniqueId,
        workout: null == workout
            ? _value.workout
            : workout // ignore: cast_nullable_to_non_nullable
                  as Workout,
        state: null == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as TimerState,
        currentRound: null == currentRound
            ? _value.currentRound
            : currentRound // ignore: cast_nullable_to_non_nullable
                  as int,
        elapsed: null == elapsed
            ? _value.elapsed
            : elapsed // ignore: cast_nullable_to_non_nullable
                  as TimerDuration,
        currentIntervalElapsed: null == currentIntervalElapsed
            ? _value.currentIntervalElapsed
            : currentIntervalElapsed // ignore: cast_nullable_to_non_nullable
                  as TimerDuration,
        elapsedMillis: null == elapsedMillis
            ? _value.elapsedMillis
            : elapsedMillis // ignore: cast_nullable_to_non_nullable
                  as int,
        intervalElapsedMillis: null == intervalElapsedMillis
            ? _value.intervalElapsedMillis
            : intervalElapsedMillis // ignore: cast_nullable_to_non_nullable
                  as int,
        stateBeforePause: freezed == stateBeforePause
            ? _value.stateBeforePause
            : stateBeforePause // ignore: cast_nullable_to_non_nullable
                  as TimerState?,
        startedAt: freezed == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$TimerSessionImpl extends _TimerSession {
  const _$TimerSessionImpl({
    required this.id,
    required this.workout,
    required this.state,
    required this.currentRound,
    required this.elapsed,
    required this.currentIntervalElapsed,
    this.elapsedMillis = 0,
    this.intervalElapsedMillis = 0,
    this.stateBeforePause,
    this.startedAt,
    this.completedAt,
  }) : super._();

  /// Unique identifier for this session.
  @override
  final UniqueId id;

  /// The workout configuration for this session.
  @override
  final Workout workout;

  /// Current state of the timer.
  @override
  final TimerState state;

  /// Current round number (1-based).
  @override
  final int currentRound;

  /// Total elapsed time since workout started (excluding prep).
  @override
  final TimerDuration elapsed;

  /// Elapsed time in the current interval (for interval-based workouts).
  @override
  final TimerDuration currentIntervalElapsed;

  /// Accumulated milliseconds not yet converted to seconds (for precise timing).
  @override
  @JsonKey()
  final int elapsedMillis;

  /// Accumulated interval milliseconds not yet converted to seconds.
  @override
  @JsonKey()
  final int intervalElapsedMillis;

  /// The state before pausing (to restore on resume).
  @override
  final TimerState? stateBeforePause;

  /// When the session was started.
  @override
  final DateTime? startedAt;

  /// When the session was completed.
  @override
  final DateTime? completedAt;

  @override
  String toString() {
    return 'TimerSession(id: $id, workout: $workout, state: $state, currentRound: $currentRound, elapsed: $elapsed, currentIntervalElapsed: $currentIntervalElapsed, elapsedMillis: $elapsedMillis, intervalElapsedMillis: $intervalElapsedMillis, stateBeforePause: $stateBeforePause, startedAt: $startedAt, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimerSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.workout, workout) || other.workout == workout) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.currentRound, currentRound) ||
                other.currentRound == currentRound) &&
            (identical(other.elapsed, elapsed) || other.elapsed == elapsed) &&
            (identical(other.currentIntervalElapsed, currentIntervalElapsed) ||
                other.currentIntervalElapsed == currentIntervalElapsed) &&
            (identical(other.elapsedMillis, elapsedMillis) ||
                other.elapsedMillis == elapsedMillis) &&
            (identical(other.intervalElapsedMillis, intervalElapsedMillis) ||
                other.intervalElapsedMillis == intervalElapsedMillis) &&
            (identical(other.stateBeforePause, stateBeforePause) ||
                other.stateBeforePause == stateBeforePause) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    workout,
    state,
    currentRound,
    elapsed,
    currentIntervalElapsed,
    elapsedMillis,
    intervalElapsedMillis,
    stateBeforePause,
    startedAt,
    completedAt,
  );

  /// Create a copy of TimerSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimerSessionImplCopyWith<_$TimerSessionImpl> get copyWith =>
      __$$TimerSessionImplCopyWithImpl<_$TimerSessionImpl>(this, _$identity);
}

abstract class _TimerSession extends TimerSession {
  const factory _TimerSession({
    required final UniqueId id,
    required final Workout workout,
    required final TimerState state,
    required final int currentRound,
    required final TimerDuration elapsed,
    required final TimerDuration currentIntervalElapsed,
    final int elapsedMillis,
    final int intervalElapsedMillis,
    final TimerState? stateBeforePause,
    final DateTime? startedAt,
    final DateTime? completedAt,
  }) = _$TimerSessionImpl;
  const _TimerSession._() : super._();

  /// Unique identifier for this session.
  @override
  UniqueId get id;

  /// The workout configuration for this session.
  @override
  Workout get workout;

  /// Current state of the timer.
  @override
  TimerState get state;

  /// Current round number (1-based).
  @override
  int get currentRound;

  /// Total elapsed time since workout started (excluding prep).
  @override
  TimerDuration get elapsed;

  /// Elapsed time in the current interval (for interval-based workouts).
  @override
  TimerDuration get currentIntervalElapsed;

  /// Accumulated milliseconds not yet converted to seconds (for precise timing).
  @override
  int get elapsedMillis;

  /// Accumulated interval milliseconds not yet converted to seconds.
  @override
  int get intervalElapsedMillis;

  /// The state before pausing (to restore on resume).
  @override
  TimerState? get stateBeforePause;

  /// When the session was started.
  @override
  DateTime? get startedAt;

  /// When the session was completed.
  @override
  DateTime? get completedAt;

  /// Create a copy of TimerSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimerSessionImplCopyWith<_$TimerSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
