import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';
import 'package:wod_timer/features/timer/domain/failures/timer_failure.dart';

part 'timer_state.freezed.dart';

/// State for the timer notifier.
///
/// Represents all possible states of the timer during a workout session.
@freezed
class TimerNotifierState with _$TimerNotifierState {
  /// Initial state before any workout is started.
  const factory TimerNotifierState.initial() = TimerInitial;

  /// Preparing state during countdown before workout begins.
  const factory TimerNotifierState.preparing({
    required TimerSession session,
  }) = TimerPreparing;

  /// Running state when the workout timer is active.
  const factory TimerNotifierState.running({
    required TimerSession session,
  }) = TimerRunning;

  /// Resting state during rest intervals (Tabata, etc.).
  const factory TimerNotifierState.resting({
    required TimerSession session,
  }) = TimerResting;

  /// Paused state when the user has paused the timer.
  const factory TimerNotifierState.paused({
    required TimerSession session,
  }) = TimerPaused;

  /// Completed state when the workout has finished.
  const factory TimerNotifierState.completed({
    required TimerSession session,
  }) = TimerCompleted;

  /// Error state when something goes wrong.
  const factory TimerNotifierState.error({
    required TimerFailure failure,
    TimerSession? session,
  }) = TimerError;
}

/// Extension methods for [TimerNotifierState].
extension TimerNotifierStateX on TimerNotifierState {
  /// Returns the current session if available.
  TimerSession? get sessionOrNull => maybeMap(
        preparing: (s) => s.session,
        running: (s) => s.session,
        resting: (s) => s.session,
        paused: (s) => s.session,
        completed: (s) => s.session,
        error: (s) => s.session,
        orElse: () => null,
      );

  /// Whether the timer can be paused.
  bool get canPause => maybeMap(
        preparing: (_) => true,
        running: (_) => true,
        resting: (_) => true,
        orElse: () => false,
      );

  /// Whether the timer can be resumed.
  bool get canResume => maybeMap(
        paused: (_) => true,
        orElse: () => false,
      );

  /// Whether the timer can be stopped.
  bool get canStop => maybeMap(
        preparing: (_) => true,
        running: (_) => true,
        resting: (_) => true,
        paused: (_) => true,
        orElse: () => false,
      );

  /// Whether the timer is in an active state (ticking).
  bool get isActive => maybeMap(
        preparing: (_) => true,
        running: (_) => true,
        resting: (_) => true,
        orElse: () => false,
      );
}
