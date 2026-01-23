import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/failures/timer_failure.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';

/// Use case for creating a workout from user input.
///
/// Validates and constructs a [Workout] entity from the provided parameters.
@injectable
class CreateWorkout {
  /// Creates a workout with the given configuration.
  ///
  /// Returns [Either<TimerFailure, Workout>]:
  /// - Right(Workout) on success
  /// - Left(TimerFailure) if validation fails
  Either<TimerFailure, Workout> call({
    required String name,
    required TimerType timerType,
    int prepCountdownSeconds = 10,
  }) {
    // Validate name
    if (name.trim().isEmpty) {
      return left(
        const TimerFailure.invalidConfiguration(
          message: 'Workout name cannot be empty',
        ),
      );
    }

    // Validate timer configuration
    final configValidation = _validateTimerType(timerType);
    if (configValidation.isLeft()) {
      return left(configValidation.getLeft().toNullable()!);
    }

    // Validate prep countdown
    if (prepCountdownSeconds < 0) {
      return left(
        const TimerFailure.invalidConfiguration(
          message: 'Prep countdown cannot be negative',
        ),
      );
    }

    // Create the workout name
    final workoutName = WorkoutName.fromString(name.trim());

    // Create the workout
    final workout = Workout(
      id: UniqueId(),
      name: workoutName,
      timerType: timerType,
      prepCountdown: TimerDuration.fromSeconds(prepCountdownSeconds),
      createdAt: DateTime.now(),
    );

    return right(workout);
  }

  Either<TimerFailure, Unit> _validateTimerType(TimerType timerType) {
    return timerType.when(
      amrap: (timer) {
        if (timer.duration.seconds <= 0) {
          return left(
            const TimerFailure.invalidConfiguration(
              message: 'AMRAP duration must be greater than 0',
            ),
          );
        }
        return right(unit);
      },
      forTime: (timer) {
        if (timer.timeCap.seconds <= 0) {
          return left(
            const TimerFailure.invalidConfiguration(
              message: 'For Time time cap must be greater than 0',
            ),
          );
        }
        return right(unit);
      },
      emom: (timer) {
        if (timer.intervalDuration.seconds <= 0) {
          return left(
            const TimerFailure.invalidConfiguration(
              message: 'EMOM interval duration must be greater than 0',
            ),
          );
        }
        if (timer.rounds.value <= 0) {
          return left(
            const TimerFailure.invalidConfiguration(
              message: 'EMOM rounds must be greater than 0',
            ),
          );
        }
        return right(unit);
      },
      tabata: (timer) {
        if (timer.workDuration.seconds <= 0) {
          return left(
            const TimerFailure.invalidConfiguration(
              message: 'Tabata work duration must be greater than 0',
            ),
          );
        }
        if (timer.restDuration.seconds < 0) {
          return left(
            const TimerFailure.invalidConfiguration(
              message: 'Tabata rest duration cannot be negative',
            ),
          );
        }
        if (timer.rounds.value <= 0) {
          return left(
            const TimerFailure.invalidConfiguration(
              message: 'Tabata rounds must be greater than 0',
            ),
          );
        }
        return right(unit);
      },
    );
  }
}
