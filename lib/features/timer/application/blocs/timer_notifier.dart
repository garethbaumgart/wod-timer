import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/usecases/pause_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/resume_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/start_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/stop_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/tick_timer.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_state.dart' as domain;
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/infrastructure/services/i_timer_engine.dart';

part 'timer_notifier.g.dart';

/// Notifier for managing timer state during a workout session.
///
/// Integrates with the timer engine for precise timing and
/// triggers audio cues at appropriate moments.
@riverpod
class TimerNotifier extends _$TimerNotifier {
  late final StartTimer _startTimer;
  late final PauseTimer _pauseTimer;
  late final ResumeTimer _resumeTimer;
  late final StopTimer _stopTimer;
  late final TickTimer _tickTimer;
  late final ITimerEngine _timerEngine;
  late final IAudioService _audioService;

  StreamSubscription<Duration>? _tickSubscription;
  Duration _lastTickElapsed = Duration.zero;
  int _lastCountdownSecond = -1;
  bool _playedGo = false;
  int _lastRound = 0;
  bool _isInitialized = false;

  @override
  TimerNotifierState build() {
    // These would normally be injected via Riverpod providers
    // For now, we'll need to pass them in or use ref.read
    ref.onDispose(_dispose);
    return const TimerNotifierState.initial();
  }

  /// Initialize the notifier with dependencies.
  void initialize({
    required StartTimer startTimer,
    required PauseTimer pauseTimer,
    required ResumeTimer resumeTimer,
    required StopTimer stopTimer,
    required TickTimer tickTimer,
    required ITimerEngine timerEngine,
    required IAudioService audioService,
  }) {
    _startTimer = startTimer;
    _pauseTimer = pauseTimer;
    _resumeTimer = resumeTimer;
    _stopTimer = stopTimer;
    _tickTimer = tickTimer;
    _timerEngine = timerEngine;
    _audioService = audioService;
    _isInitialized = true;
  }

  void _assertInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'TimerNotifier.initialize() must be called before use',
      );
    }
  }

  /// Start a timer session for the given workout.
  Future<void> start(Workout workout) async {
    _assertInitialized();
    _resetAudioState();

    final result = await _startTimer(workout);

    result.fold(
      (failure) => state = TimerNotifierState.error(failure: failure),
      (session) {
        state = _stateFromSession(session);
        _startTicking();
      },
    );
  }

  /// Pause the current timer session.
  void pause() {
    _assertInitialized();
    final currentSession = state.sessionOrNull;
    if (currentSession == null) return;

    final result = _pauseTimer(currentSession);

    result.fold(
      (failure) => state = TimerNotifierState.error(
        failure: failure,
        session: currentSession,
      ),
      (session) {
        state = TimerNotifierState.paused(session: session);
        _timerEngine.pause();
      },
    );
  }

  /// Resume the paused timer session.
  void resume() {
    _assertInitialized();
    final currentSession = state.sessionOrNull;
    if (currentSession == null) return;

    final result = _resumeTimer(currentSession);

    result.fold(
      (failure) => state = TimerNotifierState.error(
        failure: failure,
        session: currentSession,
      ),
      (session) {
        state = _stateFromSession(session);
        _timerEngine.resume();
      },
    );
  }

  /// Stop the timer and mark as completed.
  void stop() {
    _assertInitialized();
    final currentSession = state.sessionOrNull;
    if (currentSession == null) return;

    final result = _stopTimer(currentSession);

    result.fold(
      (failure) => state = TimerNotifierState.error(
        failure: failure,
        session: currentSession,
      ),
      (session) {
        state = TimerNotifierState.completed(session: session);
        _stopTicking();
        _audioService.playComplete();
      },
    );
  }

  /// Reset the timer to initial state.
  void reset() {
    _stopTicking();
    _resetAudioState();
    state = const TimerNotifierState.initial();
  }

  void _startTicking() {
    _lastTickElapsed = Duration.zero;
    _timerEngine
      ..reset()
      ..start();

    _tickSubscription = _timerEngine.tickStream.listen(_onTick);
  }

  void _stopTicking() {
    _tickSubscription?.cancel();
    _tickSubscription = null;
    _timerEngine.stop();
  }

  void _onTick(Duration elapsed) {
    final currentSession = state.sessionOrNull;
    if (currentSession == null) return;

    // Calculate delta since last tick
    final delta = elapsed - _lastTickElapsed;
    _lastTickElapsed = elapsed;

    final result = _tickTimer(currentSession, delta);

    result.fold(
      (failure) {
        // Timer not active is expected when completed
        if (currentSession.state == domain.TimerState.completed) {
          state = TimerNotifierState.completed(session: currentSession);
          _stopTicking();
          _audioService.playComplete();
        } else {
          state = TimerNotifierState.error(
            failure: failure,
            session: currentSession,
          );
        }
      },
      (session) {
        // Handle audio cues based on state transitions
        _handleAudioCues(currentSession, session);

        // Update state
        if (session.state == domain.TimerState.completed) {
          state = TimerNotifierState.completed(session: session);
          _stopTicking();
          _audioService.playComplete();
        } else {
          state = _stateFromSession(session);
        }
      },
    );
  }

  void _handleAudioCues(TimerSession oldSession, TimerSession newSession) {
    // Handle countdown during preparation
    if (newSession.state == domain.TimerState.preparing) {
      final remaining = newSession.timeRemaining.seconds;
      if (remaining <= 3 && remaining > 0 && remaining != _lastCountdownSecond) {
        _lastCountdownSecond = remaining;
        _audioService.playCountdown(remaining);
      }
    }

    // Handle "Go" sound when transitioning from preparing to running
    if (oldSession.state == domain.TimerState.preparing &&
        newSession.state == domain.TimerState.running &&
        !_playedGo) {
      _playedGo = true;
      _audioService.playGo();
    }

    // Handle rest period sound
    if (oldSession.state == domain.TimerState.running &&
        newSession.state == domain.TimerState.resting) {
      _audioService.playRest();
    }

    // Handle new round/interval start (for EMOM)
    if (newSession.currentRound != _lastRound && _lastRound != 0) {
      _lastRound = newSession.currentRound;
      _audioService.playIntervalStart();
    } else if (_lastRound == 0) {
      _lastRound = newSession.currentRound;
    }

    // Handle halfway point
    if (newSession.progress >= 0.5 && oldSession.progress < 0.5) {
      _audioService.playHalfway();
    }
  }

  TimerNotifierState _stateFromSession(TimerSession session) {
    switch (session.state) {
      case domain.TimerState.ready:
        return const TimerNotifierState.initial();
      case domain.TimerState.preparing:
        return TimerNotifierState.preparing(session: session);
      case domain.TimerState.running:
        return TimerNotifierState.running(session: session);
      case domain.TimerState.resting:
        return TimerNotifierState.resting(session: session);
      case domain.TimerState.paused:
        return TimerNotifierState.paused(session: session);
      case domain.TimerState.completed:
        return TimerNotifierState.completed(session: session);
    }
  }

  void _resetAudioState() {
    _lastCountdownSecond = -1;
    _playedGo = false;
    _lastRound = 0;
  }

  void _dispose() {
    _stopTicking();
  }
}
