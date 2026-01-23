import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_state.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/failures/timer_failure.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';

part 'timer_session.freezed.dart';

/// The aggregate root for managing an active timer session.
///
/// All timer state modifications must go through this aggregate.
/// State transitions return Either to handle invalid transitions.
@freezed
class TimerSession with _$TimerSession {
  const factory TimerSession({
    /// Unique identifier for this session.
    required UniqueId id,

    /// The workout configuration for this session.
    required Workout workout,

    /// Current state of the timer.
    required TimerState state,

    /// Current round number (1-based).
    required int currentRound,

    /// Total elapsed time since workout started (excluding prep).
    required TimerDuration elapsed,

    /// Elapsed time in the current interval (for interval-based workouts).
    required TimerDuration currentIntervalElapsed,

    /// The state before pausing (to restore on resume).
    TimerState? stateBeforePause,

    /// When the session was started.
    DateTime? startedAt,

    /// When the session was completed.
    DateTime? completedAt,
  }) = _TimerSession;

  const TimerSession._();

  /// Create a new session from a workout configuration.
  factory TimerSession.fromWorkout(Workout workout) => TimerSession(
        id: UniqueId(),
        workout: workout,
        state: TimerState.ready,
        currentRound: 1,
        elapsed: TimerDuration.zero,
        currentIntervalElapsed: TimerDuration.zero,
      );

  /// Start the timer session.
  ///
  /// Valid from: ready
  /// Transitions to: preparing (if prep countdown > 0) or running
  Either<TimerFailure, TimerSession> start() {
    if (!state.canStart) {
      return left(
        TimerFailure.invalidStateTransition(
          from: state,
          to: TimerState.preparing,
        ),
      );
    }

    final now = DateTime.now();
    final hasPrepCountdown = workout.prepCountdown.seconds > 0;

    return right(copyWith(
      state: hasPrepCountdown ? TimerState.preparing : TimerState.running,
      startedAt: now,
    ));
  }

  /// Pause the timer.
  ///
  /// Valid from: running, resting, preparing
  /// Transitions to: paused
  Either<TimerFailure, TimerSession> pause() {
    if (!state.canPause) {
      return left(
        TimerFailure.invalidStateTransition(
          from: state,
          to: TimerState.paused,
        ),
      );
    }

    return right(copyWith(
      state: TimerState.paused,
      stateBeforePause: state,
    ));
  }

  /// Resume the timer from paused state.
  ///
  /// Valid from: paused
  /// Transitions to: the state before pause (running/resting/preparing)
  Either<TimerFailure, TimerSession> resume() {
    if (!state.canResume) {
      return left(
        TimerFailure.invalidStateTransition(
          from: state,
          to: TimerState.running,
        ),
      );
    }

    final targetState = stateBeforePause ?? TimerState.running;
    return right(copyWith(
      state: targetState,
      stateBeforePause: null,
    ));
  }

  /// Update elapsed time by the given duration.
  ///
  /// This is the main tick function called by the timer engine.
  /// Returns updated session or signals completion.
  Either<TimerFailure, TimerSession> tick(Duration delta) {
    if (!state.isActive) {
      return left(const TimerFailure.timerNotActive());
    }

    final deltaSeconds = delta.inMilliseconds / 1000;
    final newElapsed = TimerDuration.fromSeconds(
      (elapsed.seconds + deltaSeconds).round(),
    );
    final newIntervalElapsed = TimerDuration.fromSeconds(
      (currentIntervalElapsed.seconds + deltaSeconds).round(),
    );

    // Handle preparation phase
    if (state == TimerState.preparing) {
      if (newIntervalElapsed.seconds >= workout.prepCountdown.seconds) {
        // Prep is done, start the workout
        return right(copyWith(
          state: TimerState.running,
          currentIntervalElapsed: TimerDuration.zero,
        ));
      }
      return right(copyWith(currentIntervalElapsed: newIntervalElapsed));
    }

    // Handle based on timer type
    return workout.timerType.when(
      amrap: (timer) => _tickAmrap(timer, newElapsed),
      forTime: (timer) => _tickForTime(timer, newElapsed),
      emom: (timer) => _tickEmom(timer, newElapsed, newIntervalElapsed),
      tabata: (timer) => _tickTabata(timer, newElapsed, newIntervalElapsed),
    );
  }

  Either<TimerFailure, TimerSession> _tickAmrap(
    AmrapTimer timer,
    TimerDuration newElapsed,
  ) {
    if (newElapsed.seconds >= timer.duration.seconds) {
      return right(_complete());
    }
    return right(copyWith(elapsed: newElapsed));
  }

  Either<TimerFailure, TimerSession> _tickForTime(
    ForTimeTimer timer,
    TimerDuration newElapsed,
  ) {
    if (newElapsed.seconds >= timer.timeCap.seconds) {
      return right(_complete());
    }
    return right(copyWith(elapsed: newElapsed));
  }

  Either<TimerFailure, TimerSession> _tickEmom(
    EmomTimer timer,
    TimerDuration newElapsed,
    TimerDuration newIntervalElapsed,
  ) {
    final intervalSeconds = timer.intervalDuration.seconds;

    // Check if current interval is complete
    if (newIntervalElapsed.seconds >= intervalSeconds) {
      // Move to next round
      if (currentRound >= timer.rounds.value) {
        return right(_complete());
      }
      return right(copyWith(
        elapsed: newElapsed,
        currentIntervalElapsed: TimerDuration.zero,
        currentRound: currentRound + 1,
      ));
    }

    return right(copyWith(
      elapsed: newElapsed,
      currentIntervalElapsed: newIntervalElapsed,
    ));
  }

  Either<TimerFailure, TimerSession> _tickTabata(
    TabataTimer timer,
    TimerDuration newElapsed,
    TimerDuration newIntervalElapsed,
  ) {
    final workSeconds = timer.workDuration.seconds;
    final restSeconds = timer.restDuration.seconds;

    // Determine if we're in work or rest phase
    final isWorkPhase = state == TimerState.running;
    final phaseSeconds = isWorkPhase ? workSeconds : restSeconds;

    // Check if current phase is complete
    if (newIntervalElapsed.seconds >= phaseSeconds) {
      if (isWorkPhase) {
        // Work done, start rest
        return right(copyWith(
          state: TimerState.resting,
          elapsed: newElapsed,
          currentIntervalElapsed: TimerDuration.zero,
        ));
      } else {
        // Rest done, check if workout is complete
        if (currentRound >= timer.rounds.value) {
          return right(_complete());
        }
        // Start next round's work phase
        return right(copyWith(
          state: TimerState.running,
          elapsed: newElapsed,
          currentIntervalElapsed: TimerDuration.zero,
          currentRound: currentRound + 1,
        ));
      }
    }

    return right(copyWith(
      elapsed: newElapsed,
      currentIntervalElapsed: newIntervalElapsed,
    ));
  }

  /// Manually complete the workout (e.g., user finishes For Time early).
  Either<TimerFailure, TimerSession> complete() {
    if (state == TimerState.completed) {
      return left(const TimerFailure.alreadyCompleted());
    }
    if (state == TimerState.ready) {
      return left(
        TimerFailure.invalidStateTransition(
          from: state,
          to: TimerState.completed,
        ),
      );
    }
    return right(_complete());
  }

  TimerSession _complete() => copyWith(
        state: TimerState.completed,
        completedAt: DateTime.now(),
      );

  // Computed properties

  /// Time remaining in the current phase/interval.
  TimerDuration get timeRemaining {
    if (state == TimerState.preparing) {
      final remaining = workout.prepCountdown.seconds - currentIntervalElapsed.seconds;
      return TimerDuration.fromSeconds(remaining.clamp(0, workout.prepCountdown.seconds));
    }

    return workout.timerType.when(
      amrap: (timer) {
        final remaining = timer.duration.seconds - elapsed.seconds;
        return TimerDuration.fromSeconds(remaining.clamp(0, timer.duration.seconds));
      },
      forTime: (timer) {
        final remaining = timer.timeCap.seconds - elapsed.seconds;
        return TimerDuration.fromSeconds(remaining.clamp(0, timer.timeCap.seconds));
      },
      emom: (timer) {
        final remaining = timer.intervalDuration.seconds - currentIntervalElapsed.seconds;
        return TimerDuration.fromSeconds(remaining.clamp(0, timer.intervalDuration.seconds));
      },
      tabata: (timer) {
        final phaseSeconds =
            state == TimerState.running ? timer.workDuration.seconds : timer.restDuration.seconds;
        final remaining = phaseSeconds - currentIntervalElapsed.seconds;
        return TimerDuration.fromSeconds(remaining.clamp(0, phaseSeconds));
      },
    );
  }

  /// Progress through the workout as a value from 0.0 to 1.0.
  double get progress {
    if (state == TimerState.ready) return 0;
    if (state == TimerState.completed) return 1;

    final totalSeconds = workout.timerType.estimatedDuration.seconds;
    if (totalSeconds == 0) return 0;

    return (elapsed.seconds / totalSeconds).clamp(0.0, 1.0);
  }

  /// Total rounds for this workout (null if not applicable).
  int? get totalRounds => workout.roundCount;

  /// Whether this is an interval-based workout.
  bool get isIntervalBased => workout.isIntervalBased;
}
