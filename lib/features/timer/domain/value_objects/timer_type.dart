import 'package:meta/meta.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';

/// Base sealed class for all timer types.
///
/// Each timer type contains only its relevant configuration.
/// Use pattern matching to handle each type appropriately.
@immutable
sealed class TimerType {
  const TimerType();

  /// Get the display label for this timer type.
  String get displayLabel;

  /// Get a short code for this timer type (used in routing).
  String get typeCode;

  /// Get the total estimated duration for this timer configuration.
  TimerDuration get estimatedDuration;
}

/// AMRAP - As Many Rounds As Possible.
///
/// The athlete completes as many rounds of the workout as possible
/// within the given time cap.
@immutable
final class AmrapTimer extends TimerType {
  const AmrapTimer({required this.duration});

  /// The total duration for the AMRAP workout.
  final TimerDuration duration;

  @override
  String get displayLabel => 'AMRAP';

  @override
  String get typeCode => 'amrap';

  @override
  TimerDuration get estimatedDuration => duration;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AmrapTimer &&
          runtimeType == other.runtimeType &&
          duration == other.duration;

  @override
  int get hashCode => duration.hashCode;

  @override
  String toString() => 'AmrapTimer(duration: $duration)';
}

/// For Time - Complete work as fast as possible.
///
/// The athlete completes the prescribed work as fast as possible,
/// optionally with a time cap.
@immutable
final class ForTimeTimer extends TimerType {
  const ForTimeTimer({required this.timeCap, this.countUp = true});

  /// The maximum time allowed to complete the workout.
  final TimerDuration timeCap;

  /// Whether to count up from zero (true) or down from timeCap (false).
  final bool countUp;

  @override
  String get displayLabel => 'FOR TIME';

  @override
  String get typeCode => 'fortime';

  @override
  TimerDuration get estimatedDuration => timeCap;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForTimeTimer &&
          runtimeType == other.runtimeType &&
          timeCap == other.timeCap &&
          countUp == other.countUp;

  @override
  int get hashCode => Object.hash(timeCap, countUp);

  @override
  String toString() => 'ForTimeTimer(timeCap: $timeCap, countUp: $countUp)';
}

/// EMOM - Every Minute On the Minute.
///
/// The athlete starts a new round of work at the beginning of each minute.
/// Rest is whatever time remains in the minute after completing the work.
@immutable
final class EmomTimer extends TimerType {
  const EmomTimer({required this.intervalDuration, required this.rounds});

  /// The duration of each interval (typically 60 seconds).
  final TimerDuration intervalDuration;

  /// The total number of rounds/minutes.
  final RoundCount rounds;

  @override
  String get displayLabel => 'EMOM';

  @override
  String get typeCode => 'emom';

  @override
  TimerDuration get estimatedDuration =>
      TimerDuration.fromSeconds(intervalDuration.seconds * rounds.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmomTimer &&
          runtimeType == other.runtimeType &&
          intervalDuration == other.intervalDuration &&
          rounds == other.rounds;

  @override
  int get hashCode => Object.hash(intervalDuration, rounds);

  @override
  String toString() =>
      'EmomTimer(intervalDuration: $intervalDuration, rounds: $rounds)';
}

/// Tabata - High-intensity interval training.
///
/// Standard Tabata is 20 seconds of work followed by 10 seconds of rest,
/// repeated for 8 rounds. This class allows customization of these values.
@immutable
final class TabataTimer extends TimerType {
  const TabataTimer({
    required this.workDuration,
    required this.restDuration,
    required this.rounds,
  });

  /// Creates a standard Tabata (20s work, 10s rest, 8 rounds).
  factory TabataTimer.standard() => TabataTimer(
    workDuration: TimerDuration.fromSeconds(20),
    restDuration: TimerDuration.fromSeconds(10),
    rounds: RoundCount.tabataDefault,
  );

  /// The duration of each work interval.
  final TimerDuration workDuration;

  /// The duration of each rest interval.
  final TimerDuration restDuration;

  /// The total number of rounds.
  final RoundCount rounds;

  /// The total duration of one work+rest cycle.
  TimerDuration get cycleDuration =>
      TimerDuration.fromSeconds(workDuration.seconds + restDuration.seconds);

  @override
  String get displayLabel => 'TABATA';

  @override
  String get typeCode => 'tabata';

  @override
  TimerDuration get estimatedDuration =>
      TimerDuration.fromSeconds(cycleDuration.seconds * rounds.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TabataTimer &&
          runtimeType == other.runtimeType &&
          workDuration == other.workDuration &&
          restDuration == other.restDuration &&
          rounds == other.rounds;

  @override
  int get hashCode => Object.hash(workDuration, restDuration, rounds);

  @override
  String toString() =>
      'TabataTimer(workDuration: $workDuration, restDuration: $restDuration, rounds: $rounds)';
}

/// Extension methods for TimerType pattern matching.
extension TimerTypeExtension on TimerType {
  /// Pattern match on timer type with typed callbacks.
  T when<T>({
    required T Function(AmrapTimer) amrap,
    required T Function(ForTimeTimer) forTime,
    required T Function(EmomTimer) emom,
    required T Function(TabataTimer) tabata,
  }) {
    return switch (this) {
      final AmrapTimer t => amrap(t),
      final ForTimeTimer t => forTime(t),
      final EmomTimer t => emom(t),
      final TabataTimer t => tabata(t),
    };
  }

  /// Pattern match with optional handlers and a default.
  T maybeWhen<T>({
    required T Function() orElse,
    T Function(AmrapTimer)? amrap,
    T Function(ForTimeTimer)? forTime,
    T Function(EmomTimer)? emom,
    T Function(TabataTimer)? tabata,
  }) {
    return switch (this) {
      final AmrapTimer t => amrap?.call(t) ?? orElse(),
      final ForTimeTimer t => forTime?.call(t) ?? orElse(),
      final EmomTimer t => emom?.call(t) ?? orElse(),
      final TabataTimer t => tabata?.call(t) ?? orElse(),
    };
  }
}
