// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'value_failures.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ValueFailure<T> {
  T get failedValue => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(T failedValue) empty,
    required TResult Function(T failedValue) negativeValue,
    required TResult Function(T failedValue, int max) exceedsMaximum,
    required TResult Function(T failedValue, int min) belowMinimum,
    required TResult Function(T failedValue, int maxLength) tooLong,
    required TResult Function(T failedValue) invalidFormat,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(T failedValue)? empty,
    TResult? Function(T failedValue)? negativeValue,
    TResult? Function(T failedValue, int max)? exceedsMaximum,
    TResult? Function(T failedValue, int min)? belowMinimum,
    TResult? Function(T failedValue, int maxLength)? tooLong,
    TResult? Function(T failedValue)? invalidFormat,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(T failedValue)? empty,
    TResult Function(T failedValue)? negativeValue,
    TResult Function(T failedValue, int max)? exceedsMaximum,
    TResult Function(T failedValue, int min)? belowMinimum,
    TResult Function(T failedValue, int maxLength)? tooLong,
    TResult Function(T failedValue)? invalidFormat,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Empty<T> value) empty,
    required TResult Function(_NegativeValue<T> value) negativeValue,
    required TResult Function(_ExceedsMaximum<T> value) exceedsMaximum,
    required TResult Function(_BelowMinimum<T> value) belowMinimum,
    required TResult Function(_TooLong<T> value) tooLong,
    required TResult Function(_InvalidFormat<T> value) invalidFormat,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Empty<T> value)? empty,
    TResult? Function(_NegativeValue<T> value)? negativeValue,
    TResult? Function(_ExceedsMaximum<T> value)? exceedsMaximum,
    TResult? Function(_BelowMinimum<T> value)? belowMinimum,
    TResult? Function(_TooLong<T> value)? tooLong,
    TResult? Function(_InvalidFormat<T> value)? invalidFormat,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Empty<T> value)? empty,
    TResult Function(_NegativeValue<T> value)? negativeValue,
    TResult Function(_ExceedsMaximum<T> value)? exceedsMaximum,
    TResult Function(_BelowMinimum<T> value)? belowMinimum,
    TResult Function(_TooLong<T> value)? tooLong,
    TResult Function(_InvalidFormat<T> value)? invalidFormat,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ValueFailureCopyWith<T, ValueFailure<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ValueFailureCopyWith<T, $Res> {
  factory $ValueFailureCopyWith(
    ValueFailure<T> value,
    $Res Function(ValueFailure<T>) then,
  ) = _$ValueFailureCopyWithImpl<T, $Res, ValueFailure<T>>;
  @useResult
  $Res call({T failedValue});
}

/// @nodoc
class _$ValueFailureCopyWithImpl<T, $Res, $Val extends ValueFailure<T>>
    implements $ValueFailureCopyWith<T, $Res> {
  _$ValueFailureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? failedValue = freezed}) {
    return _then(
      _value.copyWith(
            failedValue: freezed == failedValue
                ? _value.failedValue
                : failedValue // ignore: cast_nullable_to_non_nullable
                      as T,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EmptyImplCopyWith<T, $Res>
    implements $ValueFailureCopyWith<T, $Res> {
  factory _$$EmptyImplCopyWith(
    _$EmptyImpl<T> value,
    $Res Function(_$EmptyImpl<T>) then,
  ) = __$$EmptyImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call({T failedValue});
}

/// @nodoc
class __$$EmptyImplCopyWithImpl<T, $Res>
    extends _$ValueFailureCopyWithImpl<T, $Res, _$EmptyImpl<T>>
    implements _$$EmptyImplCopyWith<T, $Res> {
  __$$EmptyImplCopyWithImpl(
    _$EmptyImpl<T> _value,
    $Res Function(_$EmptyImpl<T>) _then,
  ) : super(_value, _then);

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? failedValue = freezed}) {
    return _then(
      _$EmptyImpl<T>(
        failedValue: freezed == failedValue
            ? _value.failedValue
            : failedValue // ignore: cast_nullable_to_non_nullable
                  as T,
      ),
    );
  }
}

/// @nodoc

class _$EmptyImpl<T> implements _Empty<T> {
  const _$EmptyImpl({required this.failedValue});

  @override
  final T failedValue;

  @override
  String toString() {
    return 'ValueFailure<$T>.empty(failedValue: $failedValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EmptyImpl<T> &&
            const DeepCollectionEquality().equals(
              other.failedValue,
              failedValue,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(failedValue),
  );

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EmptyImplCopyWith<T, _$EmptyImpl<T>> get copyWith =>
      __$$EmptyImplCopyWithImpl<T, _$EmptyImpl<T>>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(T failedValue) empty,
    required TResult Function(T failedValue) negativeValue,
    required TResult Function(T failedValue, int max) exceedsMaximum,
    required TResult Function(T failedValue, int min) belowMinimum,
    required TResult Function(T failedValue, int maxLength) tooLong,
    required TResult Function(T failedValue) invalidFormat,
  }) {
    return empty(failedValue);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(T failedValue)? empty,
    TResult? Function(T failedValue)? negativeValue,
    TResult? Function(T failedValue, int max)? exceedsMaximum,
    TResult? Function(T failedValue, int min)? belowMinimum,
    TResult? Function(T failedValue, int maxLength)? tooLong,
    TResult? Function(T failedValue)? invalidFormat,
  }) {
    return empty?.call(failedValue);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(T failedValue)? empty,
    TResult Function(T failedValue)? negativeValue,
    TResult Function(T failedValue, int max)? exceedsMaximum,
    TResult Function(T failedValue, int min)? belowMinimum,
    TResult Function(T failedValue, int maxLength)? tooLong,
    TResult Function(T failedValue)? invalidFormat,
    required TResult orElse(),
  }) {
    if (empty != null) {
      return empty(failedValue);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Empty<T> value) empty,
    required TResult Function(_NegativeValue<T> value) negativeValue,
    required TResult Function(_ExceedsMaximum<T> value) exceedsMaximum,
    required TResult Function(_BelowMinimum<T> value) belowMinimum,
    required TResult Function(_TooLong<T> value) tooLong,
    required TResult Function(_InvalidFormat<T> value) invalidFormat,
  }) {
    return empty(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Empty<T> value)? empty,
    TResult? Function(_NegativeValue<T> value)? negativeValue,
    TResult? Function(_ExceedsMaximum<T> value)? exceedsMaximum,
    TResult? Function(_BelowMinimum<T> value)? belowMinimum,
    TResult? Function(_TooLong<T> value)? tooLong,
    TResult? Function(_InvalidFormat<T> value)? invalidFormat,
  }) {
    return empty?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Empty<T> value)? empty,
    TResult Function(_NegativeValue<T> value)? negativeValue,
    TResult Function(_ExceedsMaximum<T> value)? exceedsMaximum,
    TResult Function(_BelowMinimum<T> value)? belowMinimum,
    TResult Function(_TooLong<T> value)? tooLong,
    TResult Function(_InvalidFormat<T> value)? invalidFormat,
    required TResult orElse(),
  }) {
    if (empty != null) {
      return empty(this);
    }
    return orElse();
  }
}

abstract class _Empty<T> implements ValueFailure<T> {
  const factory _Empty({required final T failedValue}) = _$EmptyImpl<T>;

  @override
  T get failedValue;

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EmptyImplCopyWith<T, _$EmptyImpl<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NegativeValueImplCopyWith<T, $Res>
    implements $ValueFailureCopyWith<T, $Res> {
  factory _$$NegativeValueImplCopyWith(
    _$NegativeValueImpl<T> value,
    $Res Function(_$NegativeValueImpl<T>) then,
  ) = __$$NegativeValueImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call({T failedValue});
}

/// @nodoc
class __$$NegativeValueImplCopyWithImpl<T, $Res>
    extends _$ValueFailureCopyWithImpl<T, $Res, _$NegativeValueImpl<T>>
    implements _$$NegativeValueImplCopyWith<T, $Res> {
  __$$NegativeValueImplCopyWithImpl(
    _$NegativeValueImpl<T> _value,
    $Res Function(_$NegativeValueImpl<T>) _then,
  ) : super(_value, _then);

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? failedValue = freezed}) {
    return _then(
      _$NegativeValueImpl<T>(
        failedValue: freezed == failedValue
            ? _value.failedValue
            : failedValue // ignore: cast_nullable_to_non_nullable
                  as T,
      ),
    );
  }
}

/// @nodoc

class _$NegativeValueImpl<T> implements _NegativeValue<T> {
  const _$NegativeValueImpl({required this.failedValue});

  @override
  final T failedValue;

  @override
  String toString() {
    return 'ValueFailure<$T>.negativeValue(failedValue: $failedValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NegativeValueImpl<T> &&
            const DeepCollectionEquality().equals(
              other.failedValue,
              failedValue,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(failedValue),
  );

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NegativeValueImplCopyWith<T, _$NegativeValueImpl<T>> get copyWith =>
      __$$NegativeValueImplCopyWithImpl<T, _$NegativeValueImpl<T>>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(T failedValue) empty,
    required TResult Function(T failedValue) negativeValue,
    required TResult Function(T failedValue, int max) exceedsMaximum,
    required TResult Function(T failedValue, int min) belowMinimum,
    required TResult Function(T failedValue, int maxLength) tooLong,
    required TResult Function(T failedValue) invalidFormat,
  }) {
    return negativeValue(failedValue);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(T failedValue)? empty,
    TResult? Function(T failedValue)? negativeValue,
    TResult? Function(T failedValue, int max)? exceedsMaximum,
    TResult? Function(T failedValue, int min)? belowMinimum,
    TResult? Function(T failedValue, int maxLength)? tooLong,
    TResult? Function(T failedValue)? invalidFormat,
  }) {
    return negativeValue?.call(failedValue);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(T failedValue)? empty,
    TResult Function(T failedValue)? negativeValue,
    TResult Function(T failedValue, int max)? exceedsMaximum,
    TResult Function(T failedValue, int min)? belowMinimum,
    TResult Function(T failedValue, int maxLength)? tooLong,
    TResult Function(T failedValue)? invalidFormat,
    required TResult orElse(),
  }) {
    if (negativeValue != null) {
      return negativeValue(failedValue);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Empty<T> value) empty,
    required TResult Function(_NegativeValue<T> value) negativeValue,
    required TResult Function(_ExceedsMaximum<T> value) exceedsMaximum,
    required TResult Function(_BelowMinimum<T> value) belowMinimum,
    required TResult Function(_TooLong<T> value) tooLong,
    required TResult Function(_InvalidFormat<T> value) invalidFormat,
  }) {
    return negativeValue(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Empty<T> value)? empty,
    TResult? Function(_NegativeValue<T> value)? negativeValue,
    TResult? Function(_ExceedsMaximum<T> value)? exceedsMaximum,
    TResult? Function(_BelowMinimum<T> value)? belowMinimum,
    TResult? Function(_TooLong<T> value)? tooLong,
    TResult? Function(_InvalidFormat<T> value)? invalidFormat,
  }) {
    return negativeValue?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Empty<T> value)? empty,
    TResult Function(_NegativeValue<T> value)? negativeValue,
    TResult Function(_ExceedsMaximum<T> value)? exceedsMaximum,
    TResult Function(_BelowMinimum<T> value)? belowMinimum,
    TResult Function(_TooLong<T> value)? tooLong,
    TResult Function(_InvalidFormat<T> value)? invalidFormat,
    required TResult orElse(),
  }) {
    if (negativeValue != null) {
      return negativeValue(this);
    }
    return orElse();
  }
}

abstract class _NegativeValue<T> implements ValueFailure<T> {
  const factory _NegativeValue({required final T failedValue}) =
      _$NegativeValueImpl<T>;

  @override
  T get failedValue;

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NegativeValueImplCopyWith<T, _$NegativeValueImpl<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ExceedsMaximumImplCopyWith<T, $Res>
    implements $ValueFailureCopyWith<T, $Res> {
  factory _$$ExceedsMaximumImplCopyWith(
    _$ExceedsMaximumImpl<T> value,
    $Res Function(_$ExceedsMaximumImpl<T>) then,
  ) = __$$ExceedsMaximumImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call({T failedValue, int max});
}

/// @nodoc
class __$$ExceedsMaximumImplCopyWithImpl<T, $Res>
    extends _$ValueFailureCopyWithImpl<T, $Res, _$ExceedsMaximumImpl<T>>
    implements _$$ExceedsMaximumImplCopyWith<T, $Res> {
  __$$ExceedsMaximumImplCopyWithImpl(
    _$ExceedsMaximumImpl<T> _value,
    $Res Function(_$ExceedsMaximumImpl<T>) _then,
  ) : super(_value, _then);

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? failedValue = freezed, Object? max = null}) {
    return _then(
      _$ExceedsMaximumImpl<T>(
        failedValue: freezed == failedValue
            ? _value.failedValue
            : failedValue // ignore: cast_nullable_to_non_nullable
                  as T,
        max: null == max
            ? _value.max
            : max // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$ExceedsMaximumImpl<T> implements _ExceedsMaximum<T> {
  const _$ExceedsMaximumImpl({required this.failedValue, required this.max});

  @override
  final T failedValue;
  @override
  final int max;

  @override
  String toString() {
    return 'ValueFailure<$T>.exceedsMaximum(failedValue: $failedValue, max: $max)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExceedsMaximumImpl<T> &&
            const DeepCollectionEquality().equals(
              other.failedValue,
              failedValue,
            ) &&
            (identical(other.max, max) || other.max == max));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(failedValue),
    max,
  );

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExceedsMaximumImplCopyWith<T, _$ExceedsMaximumImpl<T>> get copyWith =>
      __$$ExceedsMaximumImplCopyWithImpl<T, _$ExceedsMaximumImpl<T>>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(T failedValue) empty,
    required TResult Function(T failedValue) negativeValue,
    required TResult Function(T failedValue, int max) exceedsMaximum,
    required TResult Function(T failedValue, int min) belowMinimum,
    required TResult Function(T failedValue, int maxLength) tooLong,
    required TResult Function(T failedValue) invalidFormat,
  }) {
    return exceedsMaximum(failedValue, max);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(T failedValue)? empty,
    TResult? Function(T failedValue)? negativeValue,
    TResult? Function(T failedValue, int max)? exceedsMaximum,
    TResult? Function(T failedValue, int min)? belowMinimum,
    TResult? Function(T failedValue, int maxLength)? tooLong,
    TResult? Function(T failedValue)? invalidFormat,
  }) {
    return exceedsMaximum?.call(failedValue, max);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(T failedValue)? empty,
    TResult Function(T failedValue)? negativeValue,
    TResult Function(T failedValue, int max)? exceedsMaximum,
    TResult Function(T failedValue, int min)? belowMinimum,
    TResult Function(T failedValue, int maxLength)? tooLong,
    TResult Function(T failedValue)? invalidFormat,
    required TResult orElse(),
  }) {
    if (exceedsMaximum != null) {
      return exceedsMaximum(failedValue, max);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Empty<T> value) empty,
    required TResult Function(_NegativeValue<T> value) negativeValue,
    required TResult Function(_ExceedsMaximum<T> value) exceedsMaximum,
    required TResult Function(_BelowMinimum<T> value) belowMinimum,
    required TResult Function(_TooLong<T> value) tooLong,
    required TResult Function(_InvalidFormat<T> value) invalidFormat,
  }) {
    return exceedsMaximum(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Empty<T> value)? empty,
    TResult? Function(_NegativeValue<T> value)? negativeValue,
    TResult? Function(_ExceedsMaximum<T> value)? exceedsMaximum,
    TResult? Function(_BelowMinimum<T> value)? belowMinimum,
    TResult? Function(_TooLong<T> value)? tooLong,
    TResult? Function(_InvalidFormat<T> value)? invalidFormat,
  }) {
    return exceedsMaximum?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Empty<T> value)? empty,
    TResult Function(_NegativeValue<T> value)? negativeValue,
    TResult Function(_ExceedsMaximum<T> value)? exceedsMaximum,
    TResult Function(_BelowMinimum<T> value)? belowMinimum,
    TResult Function(_TooLong<T> value)? tooLong,
    TResult Function(_InvalidFormat<T> value)? invalidFormat,
    required TResult orElse(),
  }) {
    if (exceedsMaximum != null) {
      return exceedsMaximum(this);
    }
    return orElse();
  }
}

abstract class _ExceedsMaximum<T> implements ValueFailure<T> {
  const factory _ExceedsMaximum({
    required final T failedValue,
    required final int max,
  }) = _$ExceedsMaximumImpl<T>;

  @override
  T get failedValue;
  int get max;

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExceedsMaximumImplCopyWith<T, _$ExceedsMaximumImpl<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$BelowMinimumImplCopyWith<T, $Res>
    implements $ValueFailureCopyWith<T, $Res> {
  factory _$$BelowMinimumImplCopyWith(
    _$BelowMinimumImpl<T> value,
    $Res Function(_$BelowMinimumImpl<T>) then,
  ) = __$$BelowMinimumImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call({T failedValue, int min});
}

/// @nodoc
class __$$BelowMinimumImplCopyWithImpl<T, $Res>
    extends _$ValueFailureCopyWithImpl<T, $Res, _$BelowMinimumImpl<T>>
    implements _$$BelowMinimumImplCopyWith<T, $Res> {
  __$$BelowMinimumImplCopyWithImpl(
    _$BelowMinimumImpl<T> _value,
    $Res Function(_$BelowMinimumImpl<T>) _then,
  ) : super(_value, _then);

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? failedValue = freezed, Object? min = null}) {
    return _then(
      _$BelowMinimumImpl<T>(
        failedValue: freezed == failedValue
            ? _value.failedValue
            : failedValue // ignore: cast_nullable_to_non_nullable
                  as T,
        min: null == min
            ? _value.min
            : min // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$BelowMinimumImpl<T> implements _BelowMinimum<T> {
  const _$BelowMinimumImpl({required this.failedValue, required this.min});

  @override
  final T failedValue;
  @override
  final int min;

  @override
  String toString() {
    return 'ValueFailure<$T>.belowMinimum(failedValue: $failedValue, min: $min)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BelowMinimumImpl<T> &&
            const DeepCollectionEquality().equals(
              other.failedValue,
              failedValue,
            ) &&
            (identical(other.min, min) || other.min == min));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(failedValue),
    min,
  );

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BelowMinimumImplCopyWith<T, _$BelowMinimumImpl<T>> get copyWith =>
      __$$BelowMinimumImplCopyWithImpl<T, _$BelowMinimumImpl<T>>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(T failedValue) empty,
    required TResult Function(T failedValue) negativeValue,
    required TResult Function(T failedValue, int max) exceedsMaximum,
    required TResult Function(T failedValue, int min) belowMinimum,
    required TResult Function(T failedValue, int maxLength) tooLong,
    required TResult Function(T failedValue) invalidFormat,
  }) {
    return belowMinimum(failedValue, min);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(T failedValue)? empty,
    TResult? Function(T failedValue)? negativeValue,
    TResult? Function(T failedValue, int max)? exceedsMaximum,
    TResult? Function(T failedValue, int min)? belowMinimum,
    TResult? Function(T failedValue, int maxLength)? tooLong,
    TResult? Function(T failedValue)? invalidFormat,
  }) {
    return belowMinimum?.call(failedValue, min);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(T failedValue)? empty,
    TResult Function(T failedValue)? negativeValue,
    TResult Function(T failedValue, int max)? exceedsMaximum,
    TResult Function(T failedValue, int min)? belowMinimum,
    TResult Function(T failedValue, int maxLength)? tooLong,
    TResult Function(T failedValue)? invalidFormat,
    required TResult orElse(),
  }) {
    if (belowMinimum != null) {
      return belowMinimum(failedValue, min);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Empty<T> value) empty,
    required TResult Function(_NegativeValue<T> value) negativeValue,
    required TResult Function(_ExceedsMaximum<T> value) exceedsMaximum,
    required TResult Function(_BelowMinimum<T> value) belowMinimum,
    required TResult Function(_TooLong<T> value) tooLong,
    required TResult Function(_InvalidFormat<T> value) invalidFormat,
  }) {
    return belowMinimum(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Empty<T> value)? empty,
    TResult? Function(_NegativeValue<T> value)? negativeValue,
    TResult? Function(_ExceedsMaximum<T> value)? exceedsMaximum,
    TResult? Function(_BelowMinimum<T> value)? belowMinimum,
    TResult? Function(_TooLong<T> value)? tooLong,
    TResult? Function(_InvalidFormat<T> value)? invalidFormat,
  }) {
    return belowMinimum?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Empty<T> value)? empty,
    TResult Function(_NegativeValue<T> value)? negativeValue,
    TResult Function(_ExceedsMaximum<T> value)? exceedsMaximum,
    TResult Function(_BelowMinimum<T> value)? belowMinimum,
    TResult Function(_TooLong<T> value)? tooLong,
    TResult Function(_InvalidFormat<T> value)? invalidFormat,
    required TResult orElse(),
  }) {
    if (belowMinimum != null) {
      return belowMinimum(this);
    }
    return orElse();
  }
}

abstract class _BelowMinimum<T> implements ValueFailure<T> {
  const factory _BelowMinimum({
    required final T failedValue,
    required final int min,
  }) = _$BelowMinimumImpl<T>;

  @override
  T get failedValue;
  int get min;

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BelowMinimumImplCopyWith<T, _$BelowMinimumImpl<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TooLongImplCopyWith<T, $Res>
    implements $ValueFailureCopyWith<T, $Res> {
  factory _$$TooLongImplCopyWith(
    _$TooLongImpl<T> value,
    $Res Function(_$TooLongImpl<T>) then,
  ) = __$$TooLongImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call({T failedValue, int maxLength});
}

/// @nodoc
class __$$TooLongImplCopyWithImpl<T, $Res>
    extends _$ValueFailureCopyWithImpl<T, $Res, _$TooLongImpl<T>>
    implements _$$TooLongImplCopyWith<T, $Res> {
  __$$TooLongImplCopyWithImpl(
    _$TooLongImpl<T> _value,
    $Res Function(_$TooLongImpl<T>) _then,
  ) : super(_value, _then);

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? failedValue = freezed, Object? maxLength = null}) {
    return _then(
      _$TooLongImpl<T>(
        failedValue: freezed == failedValue
            ? _value.failedValue
            : failedValue // ignore: cast_nullable_to_non_nullable
                  as T,
        maxLength: null == maxLength
            ? _value.maxLength
            : maxLength // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$TooLongImpl<T> implements _TooLong<T> {
  const _$TooLongImpl({required this.failedValue, required this.maxLength});

  @override
  final T failedValue;
  @override
  final int maxLength;

  @override
  String toString() {
    return 'ValueFailure<$T>.tooLong(failedValue: $failedValue, maxLength: $maxLength)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TooLongImpl<T> &&
            const DeepCollectionEquality().equals(
              other.failedValue,
              failedValue,
            ) &&
            (identical(other.maxLength, maxLength) ||
                other.maxLength == maxLength));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(failedValue),
    maxLength,
  );

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TooLongImplCopyWith<T, _$TooLongImpl<T>> get copyWith =>
      __$$TooLongImplCopyWithImpl<T, _$TooLongImpl<T>>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(T failedValue) empty,
    required TResult Function(T failedValue) negativeValue,
    required TResult Function(T failedValue, int max) exceedsMaximum,
    required TResult Function(T failedValue, int min) belowMinimum,
    required TResult Function(T failedValue, int maxLength) tooLong,
    required TResult Function(T failedValue) invalidFormat,
  }) {
    return tooLong(failedValue, maxLength);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(T failedValue)? empty,
    TResult? Function(T failedValue)? negativeValue,
    TResult? Function(T failedValue, int max)? exceedsMaximum,
    TResult? Function(T failedValue, int min)? belowMinimum,
    TResult? Function(T failedValue, int maxLength)? tooLong,
    TResult? Function(T failedValue)? invalidFormat,
  }) {
    return tooLong?.call(failedValue, maxLength);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(T failedValue)? empty,
    TResult Function(T failedValue)? negativeValue,
    TResult Function(T failedValue, int max)? exceedsMaximum,
    TResult Function(T failedValue, int min)? belowMinimum,
    TResult Function(T failedValue, int maxLength)? tooLong,
    TResult Function(T failedValue)? invalidFormat,
    required TResult orElse(),
  }) {
    if (tooLong != null) {
      return tooLong(failedValue, maxLength);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Empty<T> value) empty,
    required TResult Function(_NegativeValue<T> value) negativeValue,
    required TResult Function(_ExceedsMaximum<T> value) exceedsMaximum,
    required TResult Function(_BelowMinimum<T> value) belowMinimum,
    required TResult Function(_TooLong<T> value) tooLong,
    required TResult Function(_InvalidFormat<T> value) invalidFormat,
  }) {
    return tooLong(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Empty<T> value)? empty,
    TResult? Function(_NegativeValue<T> value)? negativeValue,
    TResult? Function(_ExceedsMaximum<T> value)? exceedsMaximum,
    TResult? Function(_BelowMinimum<T> value)? belowMinimum,
    TResult? Function(_TooLong<T> value)? tooLong,
    TResult? Function(_InvalidFormat<T> value)? invalidFormat,
  }) {
    return tooLong?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Empty<T> value)? empty,
    TResult Function(_NegativeValue<T> value)? negativeValue,
    TResult Function(_ExceedsMaximum<T> value)? exceedsMaximum,
    TResult Function(_BelowMinimum<T> value)? belowMinimum,
    TResult Function(_TooLong<T> value)? tooLong,
    TResult Function(_InvalidFormat<T> value)? invalidFormat,
    required TResult orElse(),
  }) {
    if (tooLong != null) {
      return tooLong(this);
    }
    return orElse();
  }
}

abstract class _TooLong<T> implements ValueFailure<T> {
  const factory _TooLong({
    required final T failedValue,
    required final int maxLength,
  }) = _$TooLongImpl<T>;

  @override
  T get failedValue;
  int get maxLength;

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TooLongImplCopyWith<T, _$TooLongImpl<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$InvalidFormatImplCopyWith<T, $Res>
    implements $ValueFailureCopyWith<T, $Res> {
  factory _$$InvalidFormatImplCopyWith(
    _$InvalidFormatImpl<T> value,
    $Res Function(_$InvalidFormatImpl<T>) then,
  ) = __$$InvalidFormatImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call({T failedValue});
}

/// @nodoc
class __$$InvalidFormatImplCopyWithImpl<T, $Res>
    extends _$ValueFailureCopyWithImpl<T, $Res, _$InvalidFormatImpl<T>>
    implements _$$InvalidFormatImplCopyWith<T, $Res> {
  __$$InvalidFormatImplCopyWithImpl(
    _$InvalidFormatImpl<T> _value,
    $Res Function(_$InvalidFormatImpl<T>) _then,
  ) : super(_value, _then);

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? failedValue = freezed}) {
    return _then(
      _$InvalidFormatImpl<T>(
        failedValue: freezed == failedValue
            ? _value.failedValue
            : failedValue // ignore: cast_nullable_to_non_nullable
                  as T,
      ),
    );
  }
}

/// @nodoc

class _$InvalidFormatImpl<T> implements _InvalidFormat<T> {
  const _$InvalidFormatImpl({required this.failedValue});

  @override
  final T failedValue;

  @override
  String toString() {
    return 'ValueFailure<$T>.invalidFormat(failedValue: $failedValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvalidFormatImpl<T> &&
            const DeepCollectionEquality().equals(
              other.failedValue,
              failedValue,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(failedValue),
  );

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvalidFormatImplCopyWith<T, _$InvalidFormatImpl<T>> get copyWith =>
      __$$InvalidFormatImplCopyWithImpl<T, _$InvalidFormatImpl<T>>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(T failedValue) empty,
    required TResult Function(T failedValue) negativeValue,
    required TResult Function(T failedValue, int max) exceedsMaximum,
    required TResult Function(T failedValue, int min) belowMinimum,
    required TResult Function(T failedValue, int maxLength) tooLong,
    required TResult Function(T failedValue) invalidFormat,
  }) {
    return invalidFormat(failedValue);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(T failedValue)? empty,
    TResult? Function(T failedValue)? negativeValue,
    TResult? Function(T failedValue, int max)? exceedsMaximum,
    TResult? Function(T failedValue, int min)? belowMinimum,
    TResult? Function(T failedValue, int maxLength)? tooLong,
    TResult? Function(T failedValue)? invalidFormat,
  }) {
    return invalidFormat?.call(failedValue);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(T failedValue)? empty,
    TResult Function(T failedValue)? negativeValue,
    TResult Function(T failedValue, int max)? exceedsMaximum,
    TResult Function(T failedValue, int min)? belowMinimum,
    TResult Function(T failedValue, int maxLength)? tooLong,
    TResult Function(T failedValue)? invalidFormat,
    required TResult orElse(),
  }) {
    if (invalidFormat != null) {
      return invalidFormat(failedValue);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Empty<T> value) empty,
    required TResult Function(_NegativeValue<T> value) negativeValue,
    required TResult Function(_ExceedsMaximum<T> value) exceedsMaximum,
    required TResult Function(_BelowMinimum<T> value) belowMinimum,
    required TResult Function(_TooLong<T> value) tooLong,
    required TResult Function(_InvalidFormat<T> value) invalidFormat,
  }) {
    return invalidFormat(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Empty<T> value)? empty,
    TResult? Function(_NegativeValue<T> value)? negativeValue,
    TResult? Function(_ExceedsMaximum<T> value)? exceedsMaximum,
    TResult? Function(_BelowMinimum<T> value)? belowMinimum,
    TResult? Function(_TooLong<T> value)? tooLong,
    TResult? Function(_InvalidFormat<T> value)? invalidFormat,
  }) {
    return invalidFormat?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Empty<T> value)? empty,
    TResult Function(_NegativeValue<T> value)? negativeValue,
    TResult Function(_ExceedsMaximum<T> value)? exceedsMaximum,
    TResult Function(_BelowMinimum<T> value)? belowMinimum,
    TResult Function(_TooLong<T> value)? tooLong,
    TResult Function(_InvalidFormat<T> value)? invalidFormat,
    required TResult orElse(),
  }) {
    if (invalidFormat != null) {
      return invalidFormat(this);
    }
    return orElse();
  }
}

abstract class _InvalidFormat<T> implements ValueFailure<T> {
  const factory _InvalidFormat({required final T failedValue}) =
      _$InvalidFormatImpl<T>;

  @override
  T get failedValue;

  /// Create a copy of ValueFailure
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvalidFormatImplCopyWith<T, _$InvalidFormatImpl<T>> get copyWith =>
      throw _privateConstructorUsedError;
}
