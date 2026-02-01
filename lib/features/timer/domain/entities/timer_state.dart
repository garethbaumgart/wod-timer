/// The current state of a timer session.
enum TimerState {
  /// Timer is configured and ready to start.
  ready,

  /// Counting down the preparation period before workout starts.
  preparing,

  /// Actively counting during work period.
  running,

  /// In a rest period between work intervals (EMOM, Tabata).
  resting,

  /// Timer is paused and can be resumed.
  paused,

  /// Workout is complete.
  completed,
}

/// Extension methods for TimerState.
extension TimerStateExtension on TimerState {
  /// Whether the timer is currently active (not paused/ready/completed).
  bool get isActive =>
      this == TimerState.preparing ||
      this == TimerState.running ||
      this == TimerState.resting;

  /// Whether the timer can be started.
  bool get canStart => this == TimerState.ready;

  /// Whether the timer can be paused.
  bool get canPause =>
      this == TimerState.running ||
      this == TimerState.resting ||
      this == TimerState.preparing;

  /// Whether the timer can be resumed.
  bool get canResume => this == TimerState.paused;

  /// Whether the timer is finished.
  bool get isFinished => this == TimerState.completed;

  /// Display label for the state.
  String get displayLabel => switch (this) {
    TimerState.ready => 'Ready',
    TimerState.preparing => 'Get Ready',
    TimerState.running => 'Work',
    TimerState.resting => 'Rest',
    TimerState.paused => 'Paused',
    TimerState.completed => 'Complete',
  };
}
