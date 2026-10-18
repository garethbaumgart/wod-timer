// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timer_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TimerFailure {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(TimerState from, TimerState to)
    invalidStateTransition,
    required TResult Function() timerNotActive,
    required TResult Function() alreadyCompleted,
    required TResult Function(String? message) invalidWorkout,
    required TResult Function(String? message) invalidConfiguration,
    required TResult Function() sessionNotFound,
    required TResult Function(String? message) unexpected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(TimerState from, TimerState to)? invalidStateTransition,
    TResult? Function()? timerNotActive,
    TResult? Function()? alreadyCompleted,
    TResult? Function(String? message)? invalidWorkout,
    TResult? Function(String? message)? invalidConfiguration,
    TResult? Function()? sessionNotFound,
    TResult? Function(String? message)? unexpected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(TimerState from, TimerState to)? invalidStateTransition,
    TResult Function()? timerNotActive,
    TResult Function()? alreadyCompleted,
    TResult Function(String? message)? invalidWorkout,
    TResult Function(String? message)? invalidConfiguration,
    TResult Function()? sessionNotFound,
    TResult Function(String? message)? unexpected,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_InvalidStateTransition value)
    invalidStateTransition,
    required TResult Function(_TimerNotActive value) timerNotActive,
    required TResult Function(_AlreadyCompleted value) alreadyCompleted,
    required TResult Function(_InvalidWorkout value) invalidWorkout,
    required TResult Function(_InvalidConfiguration value) invalidConfiguration,
    required TResult Function(_SessionNotFound value) sessionNotFound,
    required TResult Function(_Unexpected value) unexpected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_InvalidStateTransition value)? invalidStateTransition,
    TResult? Function(_TimerNotActive value)? timerNotActive,
    TResult? Function(_AlreadyCompleted value)? alreadyCompleted,
    TResult? Function(_InvalidWorkout value)? invalidWorkout,
    TResult? Function(_InvalidConfiguration value)? invalidConfiguration,
    TResult? Function(_SessionNotFound value)? sessionNotFound,
    TResult? Function(_Unexpected value)? unexpected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_InvalidStateTransition value)? invalidStateTransition,
    TResult Function(_TimerNotActive value)? timerNotActive,
    TResult Function(_AlreadyCompleted value)? alreadyCompleted,
    TResult Function(_InvalidWorkout value)? invalidWorkout,
    TResult Function(_InvalidConfiguration value)? invalidConfiguration,
    TResult Function(_SessionNotFound value)? sessionNotFound,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimerFailureCopyWith<$Res> {
  factory $TimerFailureCopyWith(
    TimerFailure value,
    $Res Function(TimerFailure) then,
  ) = _$TimerFailureCopyWithImpl<$Res, TimerFailure>;
}

/// @nodoc
class _$TimerFailureCopyWithImpl<$Res, $Val extends TimerFailure>
    implements $TimerFailureCopyWith<$Res> {
  _$TimerFailureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimerFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$InvalidStateTransitionImplCopyWith<$Res> {
  factory _$$InvalidStateTransitionImplCopyWith(
    _$InvalidStateTransitionImpl value,
    $Res Function(_$InvalidStateTransitionImpl) then,
  ) = __$$InvalidStateTransitionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({TimerState from, TimerState to});
}

/// @nodoc
class __$$InvalidStateTransitionImplCopyWithImpl<$Res>
    extends _$TimerFailureCopyWithImpl<$Res, _$InvalidStateTransitionImpl>
    implements _$$InvalidStateTransitionImplCopyWith<$Res> {
  __$$InvalidStateTransitionImplCopyWithImpl(
    _$InvalidStateTransitionImpl _value,
    $Res Function(_$InvalidStateTransitionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TimerFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? from = null, Object? to = null}) {
    return _then(
      _$InvalidStateTransitionImpl(
        from: null == from
            ? _value.from
            : from // ignore: cast_nullable_to_non_nullable
                  as TimerState,
        to: null == to
            ? _value.to
            : to // ignore: cast_nullable_to_non_nullable
                  as TimerState,
      ),
    );
  }
}

/// @nodoc

class _$InvalidStateTransitionImpl implements _InvalidStateTransition {
  const _$InvalidStateTransitionImpl({required this.from, required this.to});

  @override
  final TimerState from;
  @override
  final TimerState to;

  @override
  String toString() {
    return 'TimerFailure.invalidStateTransition(from: $from, to: $to)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvalidStateTransitionImpl &&
            (identical(other.from, from) || other.from == from) &&
            (identical(other.to, to) || other.to == to));
  }

  @override
  int get hashCode => Object.hash(runtimeType, from, to);

  /// Create a copy of TimerFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvalidStateTransitionImplCopyWith<_$InvalidStateTransitionImpl>
  get copyWith =>
      __$$InvalidStateTransitionImplCopyWithImpl<_$InvalidStateTransitionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(TimerState from, TimerState to)
    invalidStateTransition,
    required TResult Function() timerNotActive,
    required TResult Function() alreadyCompleted,
    required TResult Function(String? message) invalidWorkout,
    required TResult Function(String? message) invalidConfiguration,
    required TResult Function() sessionNotFound,
    required TResult Function(String? message) unexpected,
  }) {
    return invalidStateTransition(from, to);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(TimerState from, TimerState to)? invalidStateTransition,
    TResult? Function()? timerNotActive,
    TResult? Function()? alreadyCompleted,
    TResult? Function(String? message)? invalidWorkout,
    TResult? Function(String? message)? invalidConfiguration,
    TResult? Function()? sessionNotFound,
    TResult? Function(String? message)? unexpected,
  }) {
    return invalidStateTransition?.call(from, to);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(TimerState from, TimerState to)? invalidStateTransition,
    TResult Function()? timerNotActive,
    TResult Function()? alreadyCompleted,
    TResult Function(String? message)? invalidWorkout,
    TResult Function(String? message)? invalidConfiguration,
    TResult Function()? sessionNotFound,
    TResult Function(String? message)? unexpected,
    required TResult orElse(),
  }) {
    if (invalidStateTransition != null) {
      return invalidStateTransition(from, to);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_InvalidStateTransition value)
    invalidStateTransition,
    required TResult Function(_TimerNotActive value) timerNotActive,
    required TResult Function(_AlreadyCompleted value) alreadyCompleted,
    required TResult Function(_InvalidWorkout value) invalidWorkout,
    required TResult Function(_InvalidConfiguration value) invalidConfiguration,
    required TResult Function(_SessionNotFound value) sessionNotFound,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return invalidStateTransition(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_InvalidStateTransition value)? invalidStateTransition,
    TResult? Function(_TimerNotActive value)? timerNotActive,
    TResult? Function(_AlreadyCompleted value)? alreadyCompleted,
    TResult? Function(_InvalidWorkout value)? invalidWorkout,
    TResult? Function(_InvalidConfiguration value)? invalidConfiguration,
    TResult? Function(_SessionNotFound value)? sessionNotFound,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return invalidStateTransition?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_InvalidStateTransition value)? invalidStateTransition,
    TResult Function(_TimerNotActive value)? timerNotActive,
    TResult Function(_AlreadyCompleted value)? alreadyCompleted,
    TResult Function(_InvalidWorkout value)? invalidWorkout,
    TResult Function(_InvalidConfiguration value)? invalidConfiguration,
    TResult Function(_SessionNotFound value)? sessionNotFound,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (invalidStateTransition != null) {
      return invalidStateTransition(this);
    }
    return orElse();
  }
}

abstract class _InvalidStateTransition implements TimerFailure {
  const factory _InvalidStateTransition({
    required final TimerState from,
    required final TimerState to,
  }) = _$InvalidStateTransitionImpl;

  TimerState get from;
  TimerState get to;

  /// Create a copy of TimerFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvalidStateTransitionImplCopyWith<_$InvalidStateTransitionImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TimerNotActiveImplCopyWith<$Res> {
  factory _$$TimerNotActiveImplCopyWith(
    _$TimerNotActiveImpl value,
    $Res Function(_$TimerNotActiveImpl) then,
  ) = __$$TimerNotActiveImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$TimerNotActiveImplCopyWithImpl<$Res>
    extends _$TimerFailureCopyWithImpl<$Res, _$TimerNotActiveImpl>
    implements _$$TimerNotActiveImplCopyWith<$Res> {
  __$$TimerNotActiveImplCopyWithImpl(
    _$TimerNotActiveImpl _value,
    $Res Function(_$TimerNotActiveImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TimerFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$TimerNotActiveImpl implements _TimerNotActive {
  const _$TimerNotActiveImpl();

  @override
  String toString() {
    return 'TimerFailure.timerNotActive()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$TimerNotActiveImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(TimerState from, TimerState to)
    invalidStateTransition,
    required TResult Function() timerNotActive,
    required TResult Function() alreadyCompleted,
    required TResult Function(String? message) invalidWorkout,
    required TResult Function(String? message) invalidConfiguration,
    required TResult Function() sessionNotFound,
    required TResult Function(String? message) unexpected,
  }) {
    return timerNotActive();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(TimerState from, TimerState to)? invalidStateTransition,
    TResult? Function()? timerNotActive,
    TResult? Function()? alreadyCompleted,
    TResult? Function(String? message)? invalidWorkout,
    TResult? Function(String? message)? invalidConfiguration,
    TResult? Function()? sessionNotFound,
    TResult? Function(String? message)? unexpected,
  }) {
    return timerNotActive?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(TimerState from, TimerState to)? invalidStateTransition,
    TResult Function()? timerNotActive,
    TResult Function()? alreadyCompleted,
    TResult Function(String? message)? invalidWorkout,
    TResult Function(String? message)? invalidConfiguration,
    TResult Function()? sessionNotFound,
    TResult Function(String? message)? unexpected,
    required TResult orElse(),
  }) {
    if (timerNotActive != null) {
      return timerNotActive();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_InvalidStateTransition value)
    invalidStateTransition,
    required TResult Function(_TimerNotActive value) timerNotActive,
    required TResult Function(_AlreadyCompleted value) alreadyCompleted,
    required TResult Function(_InvalidWorkout value) invalidWorkout,
    required TResult Function(_InvalidConfiguration value) invalidConfiguration,
    required TResult Function(_SessionNotFound value) sessionNotFound,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return timerNotActive(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_InvalidStateTransition value)? invalidStateTransition,
    TResult? Function(_TimerNotActive value)? timerNotActive,
    TResult? Function(_AlreadyCompleted value)? alreadyCompleted,
    TResult? Function(_InvalidWorkout value)? invalidWorkout,
    TResult? Function(_InvalidConfiguration value)? invalidConfiguration,
    TResult? Function(_SessionNotFound value)? sessionNotFound,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return timerNotActive?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_InvalidStateTransition value)? invalidStateTransition,
    TResult Function(_TimerNotActive value)? timerNotActive,
    TResult Function(_AlreadyCompleted value)? alreadyCompleted,
    TResult Function(_InvalidWorkout value)? invalidWorkout,
    TResult Function(_InvalidConfiguration value)? invalidConfiguration,
    TResult Function(_SessionNotFound value)? sessionNotFound,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (timerNotActive != null) {
      return timerNotActive(this);
    }
    return orElse();
  }
}

abstract class _TimerNotActive implements TimerFailure {
  const factory _TimerNotActive() = _$TimerNotActiveImpl;
}

/// @nodoc
abstract class _$$AlreadyCompletedImplCopyWith<$Res> {
  factory _$$AlreadyCompletedImplCopyWith(
    _$AlreadyCompletedImpl value,
    $Res Function(_$AlreadyCompletedImpl) then,
  ) = __$$AlreadyCompletedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AlreadyCompletedImplCopyWithImpl<$Res>
    extends _$TimerFailureCopyWithImpl<$Res, _$AlreadyCompletedImpl>
    implements _$$AlreadyCompletedImplCopyWith<$Res> {
  __$$AlreadyCompletedImplCopyWithImpl(
    _$AlreadyCompletedImpl _value,
    $Res Function(_$AlreadyCompletedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TimerFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$AlreadyCompletedImpl implements _AlreadyCompleted {
  const _$AlreadyCompletedImpl();

  @override
  String toString() {
    return 'TimerFailure.alreadyCompleted()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$AlreadyCompletedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(TimerState from, TimerState to)
    invalidStateTransition,
    required TResult Function() timerNotActive,
    required TResult Function() alreadyCompleted,
    required TResult Function(String? message) invalidWorkout,
    required TResult Function(String? message) invalidConfiguration,
    required TResult Function() sessionNotFound,
    required TResult Function(String? message) unexpected,
  }) {
    return alreadyCompleted();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(TimerState from, TimerState to)? invalidStateTransition,
    TResult? Function()? timerNotActive,
    TResult? Function()? alreadyCompleted,
    TResult? Function(String? message)? invalidWorkout,
    TResult? Function(String? message)? invalidConfiguration,
    TResult? Function()? sessionNotFound,
    TResult? Function(String? message)? unexpected,
  }) {
    return alreadyCompleted?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(TimerState from, TimerState to)? invalidStateTransition,
    TResult Function()? timerNotActive,
    TResult Function()? alreadyCompleted,
    TResult Function(String? message)? invalidWorkout,
    TResult Function(String? message)? invalidConfiguration,
    TResult Function()? sessionNotFound,
    TResult Function(String? message)? unexpected,
    required TResult orElse(),
  }) {
    if (alreadyCompleted != null) {
      return alreadyCompleted();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_InvalidStateTransition value)
    invalidStateTransition,
    required TResult Function(_TimerNotActive value) timerNotActive,
    required TResult Function(_AlreadyCompleted value) alreadyCompleted,
    required TResult Function(_InvalidWorkout value) invalidWorkout,
    required TResult Function(_InvalidConfiguration value) invalidConfiguration,
    required TResult Function(_SessionNotFound value) sessionNotFound,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return alreadyCompleted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_InvalidStateTransition value)? invalidStateTransition,
    TResult? Function(_TimerNotActive value)? timerNotActive,
    TResult? Function(_AlreadyCompleted value)? alreadyCompleted,
    TResult? Function(_InvalidWorkout value)? invalidWorkout,
    TResult? Function(_InvalidConfiguration value)? invalidConfiguration,
    TResult? Function(_SessionNotFound value)? sessionNotFound,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return alreadyCompleted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_InvalidStateTransition value)? invalidStateTransition,
    TResult Function(_TimerNotActive value)? timerNotActive,
    TResult Function(_AlreadyCompleted value)? alreadyCompleted,
    TResult Function(_InvalidWorkout value)? invalidWorkout,
    TResult Function(_InvalidConfiguration value)? invalidConfiguration,
    TResult Function(_SessionNotFound value)? sessionNotFound,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (alreadyCompleted != null) {
      return alreadyCompleted(this);
    }
    return orElse();
  }
}

abstract class _AlreadyCompleted implements TimerFailure {
  const factory _AlreadyCompleted() = _$AlreadyCompletedImpl;
}

/// @nodoc
abstract class _$$InvalidWorkoutImplCopyWith<$Res> {
  factory _$$InvalidWorkoutImplCopyWith(
    _$InvalidWorkoutImpl value,
    $Res Function(_$InvalidWorkoutImpl) then,
  ) = __$$InvalidWorkoutImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$InvalidWorkoutImplCopyWithImpl<$Res>
    extends _$TimerFailureCopyWithImpl<$Res, _$InvalidWorkoutImpl>
    implements _$$InvalidWorkoutImplCopyWith<$Res> {
  __$$InvalidWorkoutImplCopyWithImpl(
    _$InvalidWorkoutImpl _value,
    $Res Function(_$InvalidWorkoutImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TimerFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = freezed}) {
    return _then(
      _$InvalidWorkoutImpl(
        message: freezed == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$InvalidWorkoutImpl implements _InvalidWorkout {
  const _$InvalidWorkoutImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'TimerFailure.invalidWorkout(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvalidWorkoutImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of TimerFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvalidWorkoutImplCopyWith<_$InvalidWorkoutImpl> get copyWith =>
      __$$InvalidWorkoutImplCopyWithImpl<_$InvalidWorkoutImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(TimerState from, TimerState to)
    invalidStateTransition,
    required TResult Function() timerNotActive,
    required TResult Function() alreadyCompleted,
    required TResult Function(String? message) invalidWorkout,
    required TResult Function(String? message) invalidConfiguration,
    required TResult Function() sessionNotFound,
    required TResult Function(String? message) unexpected,
  }) {
    return invalidWorkout(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(TimerState from, TimerState to)? invalidStateTransition,
    TResult? Function()? timerNotActive,
    TResult? Function()? alreadyCompleted,
    TResult? Function(String? message)? invalidWorkout,
    TResult? Function(String? message)? invalidConfiguration,
    TResult? Function()? sessionNotFound,
    TResult? Function(String? message)? unexpected,
  }) {
    return invalidWorkout?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(TimerState from, TimerState to)? invalidStateTransition,
    TResult Function()? timerNotActive,
    TResult Function()? alreadyCompleted,
    TResult Function(String? message)? invalidWorkout,
    TResult Function(String? message)? invalidConfiguration,
    TResult Function()? sessionNotFound,
    TResult Function(String? message)? unexpected,
    required TResult orElse(),
  }) {
    if (invalidWorkout != null) {
      return invalidWorkout(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_InvalidStateTransition value)
    invalidStateTransition,
    required TResult Function(_TimerNotActive value) timerNotActive,
    required TResult Function(_AlreadyCompleted value) alreadyCompleted,
    required TResult Function(_InvalidWorkout value) invalidWorkout,
    required TResult Function(_InvalidConfiguration value) invalidConfiguration,
    required TResult Function(_SessionNotFound value) sessionNotFound,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return invalidWorkout(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_InvalidStateTransition value)? invalidStateTransition,
    TResult? Function(_TimerNotActive value)? timerNotActive,
    TResult? Function(_AlreadyCompleted value)? alreadyCompleted,
    TResult? Function(_InvalidWorkout value)? invalidWorkout,
    TResult? Function(_InvalidConfiguration value)? invalidConfiguration,
    TResult? Function(_SessionNotFound value)? sessionNotFound,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return invalidWorkout?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_InvalidStateTransition value)? invalidStateTransition,
    TResult Function(_TimerNotActive value)? timerNotActive,
    TResult Function(_AlreadyCompleted value)? alreadyCompleted,
    TResult Function(_InvalidWorkout value)? invalidWorkout,
    TResult Function(_InvalidConfiguration value)? invalidConfiguration,
    TResult Function(_SessionNotFound value)? sessionNotFound,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (invalidWorkout != null) {
      return invalidWorkout(this);
    }
    return orElse();
  }
}

abstract class _InvalidWorkout implements TimerFailure {
  const factory _InvalidWorkout({final String? message}) = _$InvalidWorkoutImpl;

  String? get message;

  /// Create a copy of TimerFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvalidWorkoutImplCopyWith<_$InvalidWorkoutImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$InvalidConfigurationImplCopyWith<$Res> {
  factory _$$InvalidConfigurationImplCopyWith(
    _$InvalidConfigurationImpl value,
    $Res Function(_$InvalidConfigurationImpl) then,
  ) = __$$InvalidConfigurationImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$InvalidConfigurationImplCopyWithImpl<$Res>
    extends _$TimerFailureCopyWithImpl<$Res, _$InvalidConfigurationImpl>
    implements _$$InvalidConfigurationImplCopyWith<$Res> {
  __$$InvalidConfigurationImplCopyWithImpl(
    _$InvalidConfigurationImpl _value,
    $Res Function(_$InvalidConfigurationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TimerFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = freezed}) {
    return _then(
      _$InvalidConfigurationImpl(
        message: freezed == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$InvalidConfigurationImpl implements _InvalidConfiguration {
  const _$InvalidConfigurationImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'TimerFailure.invalidConfiguration(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvalidConfigurationImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of TimerFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvalidConfigurationImplCopyWith<_$InvalidConfigurationImpl>
  get copyWith =>
      __$$InvalidConfigurationImplCopyWithImpl<_$InvalidConfigurationImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(TimerState from, TimerState to)
    invalidStateTransition,
    required TResult Function() timerNotActive,
    required TResult Function() alreadyCompleted,
    required TResult Function(String? message) invalidWorkout,
    required TResult Function(String? message) invalidConfiguration,
    required TResult Function() sessionNotFound,
    required TResult Function(String? message) unexpected,
  }) {
    return invalidConfiguration(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(TimerState from, TimerState to)? invalidStateTransition,
    TResult? Function()? timerNotActive,
    TResult? Function()? alreadyCompleted,
    TResult? Function(String? message)? invalidWorkout,
    TResult? Function(String? message)? invalidConfiguration,
    TResult? Function()? sessionNotFound,
    TResult? Function(String? message)? unexpected,
  }) {
    return invalidConfiguration?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(TimerState from, TimerState to)? invalidStateTransition,
    TResult Function()? timerNotActive,
    TResult Function()? alreadyCompleted,
    TResult Function(String? message)? invalidWorkout,
    TResult Function(String? message)? invalidConfiguration,
    TResult Function()? sessionNotFound,
    TResult Function(String? message)? unexpected,
    required TResult orElse(),
  }) {
    if (invalidConfiguration != null) {
      return invalidConfiguration(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_InvalidStateTransition value)
    invalidStateTransition,
    required TResult Function(_TimerNotActive value) timerNotActive,
    required TResult Function(_AlreadyCompleted value) alreadyCompleted,
    required TResult Function(_InvalidWorkout value) invalidWorkout,
    required TResult Function(_InvalidConfiguration value) invalidConfiguration,
    required TResult Function(_SessionNotFound value) sessionNotFound,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return invalidConfiguration(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_InvalidStateTransition value)? invalidStateTransition,
    TResult? Function(_TimerNotActive value)? timerNotActive,
    TResult? Function(_AlreadyCompleted value)? alreadyCompleted,
    TResult? Function(_InvalidWorkout value)? invalidWorkout,
    TResult? Function(_InvalidConfiguration value)? invalidConfiguration,
    TResult? Function(_SessionNotFound value)? sessionNotFound,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return invalidConfiguration?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_InvalidStateTransition value)? invalidStateTransition,
    TResult Function(_TimerNotActive value)? timerNotActive,
    TResult Function(_AlreadyCompleted value)? alreadyCompleted,
    TResult Function(_InvalidWorkout value)? invalidWorkout,
    TResult Function(_InvalidConfiguration value)? invalidConfiguration,
    TResult Function(_SessionNotFound value)? sessionNotFound,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (invalidConfiguration != null) {
      return invalidConfiguration(this);
    }
    return orElse();
  }
}

abstract class _InvalidConfiguration implements TimerFailure {
  const factory _InvalidConfiguration({final String? message}) =
      _$InvalidConfigurationImpl;

  String? get message;

  /// Create a copy of TimerFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvalidConfigurationImplCopyWith<_$InvalidConfigurationImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SessionNotFoundImplCopyWith<$Res> {
  factory _$$SessionNotFoundImplCopyWith(
    _$SessionNotFoundImpl value,
    $Res Function(_$SessionNotFoundImpl) then,
  ) = __$$SessionNotFoundImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SessionNotFoundImplCopyWithImpl<$Res>
    extends _$TimerFailureCopyWithImpl<$Res, _$SessionNotFoundImpl>
    implements _$$SessionNotFoundImplCopyWith<$Res> {
  __$$SessionNotFoundImplCopyWithImpl(
    _$SessionNotFoundImpl _value,
    $Res Function(_$SessionNotFoundImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TimerFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SessionNotFoundImpl implements _SessionNotFound {
  const _$SessionNotFoundImpl();

  @override
  String toString() {
    return 'TimerFailure.sessionNotFound()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SessionNotFoundImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(TimerState from, TimerState to)
    invalidStateTransition,
    required TResult Function() timerNotActive,
    required TResult Function() alreadyCompleted,
    required TResult Function(String? message) invalidWorkout,
    required TResult Function(String? message) invalidConfiguration,
    required TResult Function() sessionNotFound,
    required TResult Function(String? message) unexpected,
  }) {
    return sessionNotFound();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(TimerState from, TimerState to)? invalidStateTransition,
    TResult? Function()? timerNotActive,
    TResult? Function()? alreadyCompleted,
    TResult? Function(String? message)? invalidWorkout,
    TResult? Function(String? message)? invalidConfiguration,
    TResult? Function()? sessionNotFound,
    TResult? Function(String? message)? unexpected,
  }) {
    return sessionNotFound?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(TimerState from, TimerState to)? invalidStateTransition,
    TResult Function()? timerNotActive,
    TResult Function()? alreadyCompleted,
    TResult Function(String? message)? invalidWorkout,
    TResult Function(String? message)? invalidConfiguration,
    TResult Function()? sessionNotFound,
    TResult Function(String? message)? unexpected,
    required TResult orElse(),
  }) {
    if (sessionNotFound != null) {
      return sessionNotFound();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_InvalidStateTransition value)
    invalidStateTransition,
    required TResult Function(_TimerNotActive value) timerNotActive,
    required TResult Function(_AlreadyCompleted value) alreadyCompleted,
    required TResult Function(_InvalidWorkout value) invalidWorkout,
    required TResult Function(_InvalidConfiguration value) invalidConfiguration,
    required TResult Function(_SessionNotFound value) sessionNotFound,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return sessionNotFound(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_InvalidStateTransition value)? invalidStateTransition,
    TResult? Function(_TimerNotActive value)? timerNotActive,
    TResult? Function(_AlreadyCompleted value)? alreadyCompleted,
    TResult? Function(_InvalidWorkout value)? invalidWorkout,
    TResult? Function(_InvalidConfiguration value)? invalidConfiguration,
    TResult? Function(_SessionNotFound value)? sessionNotFound,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return sessionNotFound?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_InvalidStateTransition value)? invalidStateTransition,
    TResult Function(_TimerNotActive value)? timerNotActive,
    TResult Function(_AlreadyCompleted value)? alreadyCompleted,
    TResult Function(_InvalidWorkout value)? invalidWorkout,
    TResult Function(_InvalidConfiguration value)? invalidConfiguration,
    TResult Function(_SessionNotFound value)? sessionNotFound,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (sessionNotFound != null) {
      return sessionNotFound(this);
    }
    return orElse();
  }
}

abstract class _SessionNotFound implements TimerFailure {
  const factory _SessionNotFound() = _$SessionNotFoundImpl;
}

/// @nodoc
abstract class _$$UnexpectedImplCopyWith<$Res> {
  factory _$$UnexpectedImplCopyWith(
    _$UnexpectedImpl value,
    $Res Function(_$UnexpectedImpl) then,
  ) = __$$UnexpectedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$UnexpectedImplCopyWithImpl<$Res>
    extends _$TimerFailureCopyWithImpl<$Res, _$UnexpectedImpl>
    implements _$$UnexpectedImplCopyWith<$Res> {
  __$$UnexpectedImplCopyWithImpl(
    _$UnexpectedImpl _value,
    $Res Function(_$UnexpectedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TimerFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = freezed}) {
    return _then(
      _$UnexpectedImpl(
        message: freezed == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$UnexpectedImpl implements _Unexpected {
  const _$UnexpectedImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'TimerFailure.unexpected(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnexpectedImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of TimerFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnexpectedImplCopyWith<_$UnexpectedImpl> get copyWith =>
      __$$UnexpectedImplCopyWithImpl<_$UnexpectedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(TimerState from, TimerState to)
    invalidStateTransition,
    required TResult Function() timerNotActive,
    required TResult Function() alreadyCompleted,
    required TResult Function(String? message) invalidWorkout,
    required TResult Function(String? message) invalidConfiguration,
    required TResult Function() sessionNotFound,
    required TResult Function(String? message) unexpected,
  }) {
    return unexpected(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(TimerState from, TimerState to)? invalidStateTransition,
    TResult? Function()? timerNotActive,
    TResult? Function()? alreadyCompleted,
    TResult? Function(String? message)? invalidWorkout,
    TResult? Function(String? message)? invalidConfiguration,
    TResult? Function()? sessionNotFound,
    TResult? Function(String? message)? unexpected,
  }) {
    return unexpected?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(TimerState from, TimerState to)? invalidStateTransition,
    TResult Function()? timerNotActive,
    TResult Function()? alreadyCompleted,
    TResult Function(String? message)? invalidWorkout,
    TResult Function(String? message)? invalidConfiguration,
    TResult Function()? sessionNotFound,
    TResult Function(String? message)? unexpected,
    required TResult orElse(),
  }) {
    if (unexpected != null) {
      return unexpected(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_InvalidStateTransition value)
    invalidStateTransition,
    required TResult Function(_TimerNotActive value) timerNotActive,
    required TResult Function(_AlreadyCompleted value) alreadyCompleted,
    required TResult Function(_InvalidWorkout value) invalidWorkout,
    required TResult Function(_InvalidConfiguration value) invalidConfiguration,
    required TResult Function(_SessionNotFound value) sessionNotFound,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return unexpected(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_InvalidStateTransition value)? invalidStateTransition,
    TResult? Function(_TimerNotActive value)? timerNotActive,
    TResult? Function(_AlreadyCompleted value)? alreadyCompleted,
    TResult? Function(_InvalidWorkout value)? invalidWorkout,
    TResult? Function(_InvalidConfiguration value)? invalidConfiguration,
    TResult? Function(_SessionNotFound value)? sessionNotFound,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return unexpected?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_InvalidStateTransition value)? invalidStateTransition,
    TResult Function(_TimerNotActive value)? timerNotActive,
    TResult Function(_AlreadyCompleted value)? alreadyCompleted,
    TResult Function(_InvalidWorkout value)? invalidWorkout,
    TResult Function(_InvalidConfiguration value)? invalidConfiguration,
    TResult Function(_SessionNotFound value)? sessionNotFound,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (unexpected != null) {
      return unexpected(this);
    }
    return orElse();
  }
}

abstract class _Unexpected implements TimerFailure {
  const factory _Unexpected({final String? message}) = _$UnexpectedImpl;

  String? get message;

  /// Create a copy of TimerFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnexpectedImplCopyWith<_$UnexpectedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
