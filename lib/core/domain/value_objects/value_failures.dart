import 'package:freezed_annotation/freezed_annotation.dart';

part 'value_failures.freezed.dart';

/// Failures that can occur when validating value objects.
@freezed
sealed class ValueFailure<T> with _$ValueFailure<T> {
  /// The value was empty when it should not be.
  const factory ValueFailure.empty({required T failedValue}) = _Empty<T>;

  /// The value was negative when it should be positive or zero.
  const factory ValueFailure.negativeValue({required T failedValue}) =
      _NegativeValue<T>;

  /// The value exceeds the maximum allowed.
  const factory ValueFailure.exceedsMaximum({
    required T failedValue,
    required int max,
  }) = _ExceedsMaximum<T>;

  /// The value is below the minimum allowed.
  const factory ValueFailure.belowMinimum({
    required T failedValue,
    required int min,
  }) = _BelowMinimum<T>;

  /// The string exceeds the maximum length.
  const factory ValueFailure.tooLong({
    required T failedValue,
    required int maxLength,
  }) = _TooLong<T>;

  /// The value has an invalid format.
  const factory ValueFailure.invalidFormat({required T failedValue}) =
      _InvalidFormat<T>;
}

/// Extension to get user-friendly error messages from ValueFailure.
extension ValueFailureMessage<T> on ValueFailure<T> {
  String get message => when(
        empty: (_) => 'Value cannot be empty',
        negativeValue: (_) => 'Value cannot be negative',
        exceedsMaximum: (_, max) => 'Value cannot exceed $max',
        belowMinimum: (_, min) => 'Value must be at least $min',
        tooLong: (_, maxLength) => 'Value cannot exceed $maxLength characters',
        invalidFormat: (_) => 'Invalid format',
      );
}
