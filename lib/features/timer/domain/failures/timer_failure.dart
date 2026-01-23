import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_state.dart';

part 'timer_failure.freezed.dart';

/// Failures that can occur during timer operations.
@freezed
sealed class TimerFailure with _$TimerFailure {
  /// An invalid state transition was attempted.
  const factory TimerFailure.invalidStateTransition({
    required TimerState from,
    required TimerState to,
  }) = _InvalidStateTransition;

  /// Tried to tick a timer that is not active.
  const factory TimerFailure.timerNotActive() = _TimerNotActive;

  /// Tried to complete an already completed timer.
  const factory TimerFailure.alreadyCompleted() = _AlreadyCompleted;

  /// Workout configuration is invalid.
  const factory TimerFailure.invalidWorkout({String? message}) =
      _InvalidWorkout;

  /// Session not found.
  const factory TimerFailure.sessionNotFound() = _SessionNotFound;

  /// An unexpected error occurred.
  const factory TimerFailure.unexpected({String? message}) = _Unexpected;
}

/// Extension to get user-friendly error messages from TimerFailure.
extension TimerFailureMessage on TimerFailure {
  String get message => when(
        invalidStateTransition: (from, to) =>
            'Cannot transition from ${from.displayLabel} to ${to.displayLabel}',
        timerNotActive: () => 'Timer is not active',
        alreadyCompleted: () => 'Workout is already completed',
        invalidWorkout: (msg) => msg ?? 'Invalid workout configuration',
        sessionNotFound: () => 'Timer session not found',
        unexpected: (msg) => msg ?? 'An unexpected error occurred',
      );
}
