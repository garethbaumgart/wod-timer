import 'package:fpdart/fpdart.dart';
import 'package:meta/meta.dart';

import 'package:wod_timer/core/domain/value_objects/value_failures.dart';

/// A validated workout name.
///
/// Ensures the name is not empty and within length limits.
/// Maximum length is 50 characters.
@immutable
class WorkoutName {
  /// Create a WorkoutName from a known-valid value.
  ///
  /// Use only when the value is guaranteed valid (e.g., from database).
  factory WorkoutName.fromString(String value) => WorkoutName._(value);

  const WorkoutName._(this.value);

  /// The workout name string.
  final String value;

  /// Maximum allowed length.
  static const int maxLength = 50;

  /// Default workout names for timer types.
  static const WorkoutName defaultAmrap = WorkoutName._('AMRAP Workout');
  static const WorkoutName defaultForTime = WorkoutName._('For Time');
  static const WorkoutName defaultEmom = WorkoutName._('EMOM');
  static const WorkoutName defaultTabata = WorkoutName._('Tabata');

  /// Create a WorkoutName with validation.
  ///
  /// Returns [Left] with [ValueFailure] if invalid,
  /// or [Right] with the valid [WorkoutName].
  static Either<ValueFailure<String>, WorkoutName> create(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return left(ValueFailure.empty(failedValue: value));
    }
    if (trimmed.length > maxLength) {
      return left(
        ValueFailure.tooLong(failedValue: value, maxLength: maxLength),
      );
    }
    return right(WorkoutName._(trimmed));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutName &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
