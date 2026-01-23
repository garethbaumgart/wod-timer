import 'package:fpdart/fpdart.dart';
import 'package:meta/meta.dart';

import 'package:wod_timer/core/domain/value_objects/value_failures.dart';

/// A validated duration in seconds for timer operations.
///
/// Ensures the duration is non-negative and within acceptable bounds.
/// Maximum duration is 2 hours (7200 seconds).
@immutable
class TimerDuration {
  /// Create a TimerDuration from known-valid seconds.
  ///
  /// Use only when the value is guaranteed valid (e.g., from database).
  factory TimerDuration.fromSeconds(int seconds) => TimerDuration._(seconds);

  const TimerDuration._(this.seconds);

  /// The duration in seconds.
  final int seconds;

  /// Maximum allowed duration (2 hours).
  static const int maxSeconds = 7200;

  /// Zero duration constant.
  static const TimerDuration zero = TimerDuration._(0);

  /// Create a TimerDuration with validation.
  ///
  /// Returns [Left] with [ValueFailure] if invalid,
  /// or [Right] with the valid [TimerDuration].
  static Either<ValueFailure<int>, TimerDuration> create(int seconds) {
    if (seconds < 0) {
      return left(ValueFailure.negativeValue(failedValue: seconds));
    }
    if (seconds > maxSeconds) {
      return left(
        ValueFailure.exceedsMaximum(failedValue: seconds, max: maxSeconds),
      );
    }
    return right(TimerDuration._(seconds));
  }

  /// Create a TimerDuration from minutes and seconds.
  static Either<ValueFailure<int>, TimerDuration> fromMinutesAndSeconds(
    int minutes,
    int seconds,
  ) {
    final totalSeconds = (minutes * 60) + seconds;
    return create(totalSeconds);
  }

  /// The minutes component of this duration.
  int get minutes => seconds ~/ 60;

  /// The remaining seconds after extracting minutes.
  int get remainingSeconds => seconds % 60;

  /// Format as MM:SS string.
  String get formatted =>
      '${minutes.toString().padLeft(2, '0')}:'
      '${remainingSeconds.toString().padLeft(2, '0')}';

  /// Convert to Dart Duration.
  Duration toDuration() => Duration(seconds: seconds);

  /// Add two durations together.
  TimerDuration operator +(TimerDuration other) =>
      TimerDuration._(seconds + other.seconds);

  /// Subtract a duration (result clamped to zero).
  TimerDuration operator -(TimerDuration other) =>
      TimerDuration._((seconds - other.seconds).clamp(0, maxSeconds));

  /// Check if this duration is greater than another.
  bool operator >(TimerDuration other) => seconds > other.seconds;

  /// Check if this duration is less than another.
  bool operator <(TimerDuration other) => seconds < other.seconds;

  /// Check if this duration is greater than or equal to another.
  bool operator >=(TimerDuration other) => seconds >= other.seconds;

  /// Check if this duration is less than or equal to another.
  bool operator <=(TimerDuration other) => seconds <= other.seconds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerDuration &&
          runtimeType == other.runtimeType &&
          seconds == other.seconds;

  @override
  int get hashCode => seconds.hashCode;

  @override
  String toString() => 'TimerDuration($formatted)';
}
