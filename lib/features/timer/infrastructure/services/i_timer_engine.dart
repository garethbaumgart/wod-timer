/// Interface for the timer engine that provides precise timing.
///
/// The timer engine emits ticks at a configurable interval while running,
/// allowing the UI and timer logic to update based on elapsed time.
abstract class ITimerEngine {
  /// Stream that emits the total elapsed duration since the timer started.
  ///
  /// This stream emits a new value at the configured tick interval
  /// (typically 100ms) while the timer is running.
  Stream<Duration> get tickStream;

  /// The current elapsed duration since start.
  Duration get elapsed;

  /// Whether the timer is currently running.
  bool get isRunning;

  /// Whether the timer is paused.
  bool get isPaused;

  /// Start the timer from zero.
  void start();

  /// Pause the timer, preserving the current elapsed time.
  void pause();

  /// Resume the timer from where it was paused.
  void resume();

  /// Stop and reset the timer to zero.
  void stop();

  /// Dispose of resources.
  void dispose();

  /// Reset the timer to zero without stopping.
  void reset();
}
