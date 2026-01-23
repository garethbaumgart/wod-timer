import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';

part 'workout.freezed.dart';

/// A configured workout ready to be executed.
///
/// Represents the user's workout configuration including timer type,
/// name, and preparation countdown.
@freezed
class Workout with _$Workout {
  const factory Workout({
    /// Unique identifier for this workout.
    required UniqueId id,

    /// User-defined name for the workout.
    required WorkoutName name,

    /// The timer configuration for this workout.
    required TimerType timerType,

    /// Countdown before the workout starts.
    required TimerDuration prepCountdown,

    /// When this workout configuration was created.
    required DateTime createdAt,
  }) = _Workout;

  const Workout._();

  /// Creates a default AMRAP workout (10 minutes).
  factory Workout.defaultAmrap() => Workout(
        id: UniqueId(),
        name: WorkoutName.defaultAmrap,
        timerType: AmrapTimer(duration: TimerDuration.fromSeconds(600)),
        prepCountdown: TimerDuration.fromSeconds(10),
        createdAt: DateTime.now(),
      );

  /// Creates a default For Time workout (20 minute cap).
  factory Workout.defaultForTime() => Workout(
        id: UniqueId(),
        name: WorkoutName.defaultForTime,
        timerType: ForTimeTimer(timeCap: TimerDuration.fromSeconds(1200)),
        prepCountdown: TimerDuration.fromSeconds(10),
        createdAt: DateTime.now(),
      );

  /// Creates a default EMOM workout (10 rounds of 1 minute).
  factory Workout.defaultEmom() => Workout(
        id: UniqueId(),
        name: WorkoutName.defaultEmom,
        timerType: EmomTimer(
          intervalDuration: TimerDuration.fromSeconds(60),
          rounds: RoundCount.fromInt(10),
        ),
        prepCountdown: TimerDuration.fromSeconds(10),
        createdAt: DateTime.now(),
      );

  /// Creates a default Tabata workout (standard 20/10 x 8).
  factory Workout.defaultTabata() => Workout(
        id: UniqueId(),
        name: WorkoutName.defaultTabata,
        timerType: TabataTimer.standard(),
        prepCountdown: TimerDuration.fromSeconds(10),
        createdAt: DateTime.now(),
      );

  /// Creates a default workout for the given timer type code.
  factory Workout.defaultForType(String typeCode) {
    return switch (typeCode.toLowerCase()) {
      'amrap' => Workout.defaultAmrap(),
      'fortime' => Workout.defaultForTime(),
      'emom' => Workout.defaultEmom(),
      'tabata' => Workout.defaultTabata(),
      _ => Workout.defaultAmrap(),
    };
  }

  /// The total duration of the workout including prep countdown.
  TimerDuration get totalDuration => TimerDuration.fromSeconds(
        prepCountdown.seconds + timerType.estimatedDuration.seconds,
      );

  /// Whether this workout type has built-in rest periods.
  bool get hasRestPeriods => timerType is TabataTimer || timerType is EmomTimer;

  /// Whether this workout is an interval-based workout.
  bool get isIntervalBased => timerType is TabataTimer || timerType is EmomTimer;

  /// The display label for the timer type.
  String get timerTypeLabel => timerType.displayLabel;

  /// Get the number of rounds if applicable, or null otherwise.
  int? get roundCount => timerType.when(
        amrap: (_) => null,
        forTime: (_) => null,
        emom: (t) => t.rounds.value,
        tabata: (t) => t.rounds.value,
      );
}
