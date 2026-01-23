import 'package:fpdart/fpdart.dart';
import 'package:meta/meta.dart';

import 'package:wod_timer/core/domain/value_objects/value_failures.dart';

/// A validated count of rounds/intervals for workouts.
///
/// Ensures the count is at least 1 and within acceptable bounds.
/// Maximum rounds is 100.
@immutable
class RoundCount {
  /// Create a RoundCount from a known-valid value.
  ///
  /// Use only when the value is guaranteed valid (e.g., from database).
  factory RoundCount.fromInt(int value) => RoundCount._(value);

  const RoundCount._(this.value);

  /// The number of rounds.
  final int value;

  /// Minimum allowed rounds.
  static const int minRounds = 1;

  /// Maximum allowed rounds.
  static const int maxRounds = 100;

  /// Default round count of 1.
  static const RoundCount one = RoundCount._(1);

  /// Common preset: 8 rounds (Tabata).
  static const RoundCount tabataDefault = RoundCount._(8);

  /// Create a RoundCount with validation.
  ///
  /// Returns [Left] with [ValueFailure] if invalid,
  /// or [Right] with the valid [RoundCount].
  static Either<ValueFailure<int>, RoundCount> create(int value) {
    if (value < minRounds) {
      return left(
        ValueFailure.belowMinimum(failedValue: value, min: minRounds),
      );
    }
    if (value > maxRounds) {
      return left(
        ValueFailure.exceedsMaximum(failedValue: value, max: maxRounds),
      );
    }
    return right(RoundCount._(value));
  }

  /// Increment the round count by 1 (clamped to max).
  RoundCount increment() =>
      RoundCount._((value + 1).clamp(minRounds, maxRounds));

  /// Decrement the round count by 1 (clamped to min).
  RoundCount decrement() =>
      RoundCount._((value - 1).clamp(minRounds, maxRounds));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoundCount &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'RoundCount($value)';
}
