import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:wod_timer/features/timer/infrastructure/services/i_timer_engine.dart';

/// Implementation of [ITimerEngine] using Stopwatch and Timer.periodic.
///
/// Uses a [Stopwatch] for precise time measurement and a [Timer.periodic]
/// to emit tick events at the configured interval.
@LazySingleton(as: ITimerEngine)
class TimerEngine implements ITimerEngine {
  /// Creates a timer engine with the specified tick interval.
  ///
  /// The [tickInterval] determines how often the [tickStream] emits.
  /// Default is 100ms for smooth UI updates.
  TimerEngine({
    Duration tickInterval = const Duration(milliseconds: 100),
  }) : _tickInterval = tickInterval;

  final Duration _tickInterval;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  StreamController<Duration>? _tickController;

  Duration _pausedElapsed = Duration.zero;
  bool _isPaused = false;

  @override
  Stream<Duration> get tickStream {
    _tickController ??= StreamController<Duration>.broadcast();
    return _tickController!.stream;
  }

  @override
  Duration get elapsed {
    if (_isPaused) {
      return _pausedElapsed;
    }
    return _pausedElapsed + _stopwatch.elapsed;
  }

  @override
  bool get isRunning => _stopwatch.isRunning;

  @override
  bool get isPaused => _isPaused;

  @override
  void start() {
    _pausedElapsed = Duration.zero;
    _isPaused = false;
    _stopwatch
      ..reset()
      ..start();
    _startTicking();
  }

  @override
  void pause() {
    if (!_stopwatch.isRunning) return;

    _pausedElapsed = elapsed;
    _isPaused = true;
    _stopwatch.stop();
    _stopTicking();
  }

  @override
  void resume() {
    if (!_isPaused) return;

    _isPaused = false;
    _stopwatch
      ..reset()
      ..start();
    _startTicking();
  }

  @override
  void stop() {
    _stopwatch
      ..stop()
      ..reset();
    _pausedElapsed = Duration.zero;
    _isPaused = false;
    _stopTicking();
  }

  @override
  void reset() {
    final wasRunning = isRunning;
    _stopwatch.reset();
    _pausedElapsed = Duration.zero;
    _isPaused = false;

    if (wasRunning) {
      _stopwatch.start();
    }
  }

  @override
  void dispose() {
    stop();
    _tickController?.close();
    _tickController = null;
  }

  void _startTicking() {
    _stopTicking();
    _timer = Timer.periodic(_tickInterval, _onTick);
    // Emit initial tick
    _tickController?.add(elapsed);
  }

  void _stopTicking() {
    _timer?.cancel();
    _timer = null;
  }

  void _onTick(Timer timer) {
    if (_tickController?.isClosed ?? true) {
      timer.cancel();
      return;
    }
    _tickController?.add(elapsed);
  }
}
