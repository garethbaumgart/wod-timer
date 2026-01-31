import 'dart:async';
import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
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
/// triggers audio and haptic cues at appropriate moments.
@Riverpod(keepAlive: true)
class TimerNotifier extends _$TimerNotifier {
  late final StartTimer _startTimer;
  late final PauseTimer _pauseTimer;
  late final ResumeTimer _resumeTimer;
  late final StopTimer _stopTimer;
  late final TickTimer _tickTimer;
  late final ITimerEngine _timerEngine;
  late final IAudioService _audioService;
  late final IHapticService _hapticService;

  StreamSubscription<Duration>? _tickSubscription;
  Duration _lastTickElapsed = Duration.zero;
  int _lastCountdownSecond = -1;
  bool _playedGo = false;
  int _lastRound = 0;
  bool _isInitialized = false;
  Workout? _lastWorkout;
  bool _playedGetReady = false;
  bool _playedTenSeconds = false;
  bool _playedLastRound = false;
  bool _playedAlmostThere = false;
  bool _playedKeepGoing = false;
  bool _playedFinalCountdown = false;
  int _completionCueToken = 0;
  final _random = Random();

  @override
  TimerNotifierState build() {
    // Auto-initialize from providers
    _startTimer = ref.watch(startTimerProvider);
    _pauseTimer = ref.watch(pauseTimerProvider);
    _resumeTimer = ref.watch(resumeTimerProvider);
    _stopTimer = ref.watch(stopTimerProvider);
    _tickTimer = ref.watch(tickTimerProvider);
    _timerEngine = ref.watch(timerEngineProvider);
    _audioService = ref.watch(audioServiceProvider);
    _hapticService = ref.watch(hapticServiceProvider);
    _isInitialized = true;

    ref.onDispose(_dispose);
    return const TimerNotifierState.initial();
  }

  /// Configure the audio service voice from the current setting.
  ///
  /// For [VoiceOption.random], enables per-cue randomization so each
  /// voice cue picks a different voice pack at random.
  void _configureVoice() {
    final voice = ref.read(appSettingsNotifierProvider).voice;
    switch (voice) {
      case VoiceOption.major:
        _audioService
          ..setRandomizePerCue(enabled: false)
          ..setVoicePack('major');
      case VoiceOption.liam:
        _audioService
          ..setRandomizePerCue(enabled: false)
          ..setVoicePack('liam');
      case VoiceOption.holly:
        _audioService
          ..setRandomizePerCue(enabled: false)
          ..setVoicePack('holly');
      case VoiceOption.random:
        _audioService.setRandomizePerCue(enabled: true);
    }
  }

  /// Start a timer session for the given workout.
  Future<void> start(Workout workout) async {
    _lastWorkout = workout;
    _resetAudioState();
    _configureVoice();

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
        _hapticService.mediumImpact();
      },
    );
  }

  /// Resume the paused timer session.
  void resume() {
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
        _hapticService.mediumImpact();
      },
    );
  }

  /// Stop the timer and mark as completed.
  void stop() {
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
        // Play only the encouragement cue (e.g. "Good job" or "That's it,
        // you're done") — not playComplete() as well, to avoid overlap.
        _playCompletionEncouragement();
        _hapticService.success();
      },
    );
  }

  /// Reset the timer to initial state.
  ///
  /// Clears the stored workout so [restart] cannot reuse a stale
  /// configuration after a full reset.
  void reset() {
    _stopTicking();
    _resetAudioState();
    _lastWorkout = null;
    state = const TimerNotifierState.initial();
  }

  /// Restart the timer with the same workout configuration.
  ///
  /// Only valid from the [TimerCompleted] state. Resets and re-starts
  /// the timer using the last workout, keeping the user on the active
  /// timer screen. Does nothing if no workout has been started yet or
  /// the timer is not in a completed state.
  Future<void> restart() async {
    if (_lastWorkout == null) return;
    if (state is! TimerCompleted) return;
    _stopTicking();
    await start(_lastWorkout!);
  }

  void _startTicking() {
    _lastTickElapsed = Duration.zero;

    // Subscribe to tick stream BEFORE starting the engine
    // to ensure we don't miss any ticks
    _tickSubscription = _timerEngine.tickStream.listen(_onTick);

    _timerEngine
      ..reset()
      ..start();
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
          _playCompletionEncouragement();
          _hapticService.success(); // Haptic success for natural completion
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
          _playCompletionEncouragement();
          _hapticService.success(); // Haptic success for natural completion
        } else {
          state = _stateFromSession(session);
        }
      },
    );
  }

  void _handleAudioCues(TimerSession oldSession, TimerSession newSession) {
    // Track whether a voice cue already played this tick so we don't
    // overlap two spoken clips (e.g. "Halfway" + "Next round").
    bool voiceCuePlayed = false;

    // Handle "Get ready" when entering preparation phase
    if (newSession.state == domain.TimerState.preparing && !_playedGetReady) {
      _playedGetReady = true;
      _audioService.playGetReady();
      voiceCuePlayed = true;
    }

    // Handle countdown during preparation
    // Skip if "Get ready" already played this tick (e.g. prep is exactly 3s)
    if (!voiceCuePlayed && newSession.state == domain.TimerState.preparing) {
      final remaining = newSession.timeRemaining.seconds;
      if (remaining <= 3 && remaining > 0 && remaining != _lastCountdownSecond) {
        _lastCountdownSecond = remaining;
        _audioService.playCountdown(remaining);
        _hapticService.mediumImpact(); // Haptic for each countdown tick
        voiceCuePlayed = true;
      }
    }

    // Handle "Go" or "Let's go" when transitioning from preparing to running
    if (oldSession.state == domain.TimerState.preparing &&
        newSession.state == domain.TimerState.running &&
        !_playedGo) {
      _playedGo = true;
      // Randomly alternate between "Go" and "Let's go"
      if (_random.nextBool()) {
        _audioService.playGo();
      } else {
        _audioService.playLetsGo();
      }
      _hapticService.heavyImpact(); // Strong haptic for GO!
      voiceCuePlayed = true;
    }

    // Handle rest period sound
    // For Tabata, rest + round change can happen on the same tick.
    // Prefer the round cue (more informative) — only play rest if no
    // round transition occurred.
    final bool roundChanged =
        newSession.currentRound != _lastRound && _lastRound != 0;

    if (oldSession.state == domain.TimerState.running &&
        newSession.state == domain.TimerState.resting &&
        !roundChanged) {
      _audioService.playRest();
      _hapticService.warning(); // Haptic pattern for rest transition
      voiceCuePlayed = true;
    }

    // Handle transition back to work from rest
    if (oldSession.state == domain.TimerState.resting &&
        newSession.state == domain.TimerState.running) {
      _hapticService.heavyImpact(); // Strong haptic for WORK!
    }

    // Handle new round/interval start (for EMOM/Tabata)
    if (roundChanged) {
      _lastRound = newSession.currentRound;
      _hapticService.heavyImpact(); // Strong haptic for new round

      // Play "Last round" if final round, otherwise "Next round"
      final totalRounds = newSession.totalRounds;
      if (totalRounds != null &&
          newSession.currentRound == totalRounds &&
          !_playedLastRound) {
        _playedLastRound = true;
        _audioService.playLastRound();
      } else {
        _audioService.playNextRound();
      }
      voiceCuePlayed = true;
    } else if (_lastRound == 0) {
      _lastRound = newSession.currentRound;
    }

    // Handle motivational cue around 33% progress
    // Skip if another voice cue already played this tick
    if (!voiceCuePlayed &&
        newSession.progress >= 0.33 &&
        oldSession.progress < 0.33 &&
        !_playedKeepGoing) {
      _playedKeepGoing = true;
      // Randomly alternate between motivation cues
      if (_random.nextBool()) {
        _audioService.playKeepGoing();
      } else {
        _audioService.playComeOn();
      }
      voiceCuePlayed = true;
    }

    // Handle halfway point
    // Skip if another voice cue already played this tick (e.g. round transition)
    if (!voiceCuePlayed &&
        newSession.progress >= 0.5 && oldSession.progress < 0.5) {
      _audioService.playHalfway();
      _hapticService.mediumImpact();
      voiceCuePlayed = true;
    }

    // Handle "Almost there" at ~85% progress
    // Skip if another voice cue already played this tick
    if (!voiceCuePlayed &&
        newSession.progress >= 0.85 &&
        oldSession.progress < 0.85 &&
        !_playedAlmostThere) {
      _playedAlmostThere = true;
      _audioService.playAlmostThere();
      voiceCuePlayed = true;
    }

    // Handle "Ten seconds" warning — only if workout is long enough (>15s)
    // to avoid overlapping with the final countdown clip.
    if (!voiceCuePlayed &&
        newSession.state == domain.TimerState.running &&
        !_playedTenSeconds) {
      final remaining = newSession.timeRemaining.seconds;
      if (remaining <= 10 && remaining > 7) {
        _playedTenSeconds = true;
        _audioService.playTenSeconds();
        voiceCuePlayed = true;
      }
    }

    // Handle spoken "5, 4, 3, 2, 1" final countdown.
    // This is a single pre-recorded clip (~5s long) so we trigger it
    // once at 5 seconds remaining and let it play through naturally.
    if (!voiceCuePlayed &&
        newSession.state == domain.TimerState.running &&
        !_playedFinalCountdown) {
      final remaining = newSession.timeRemaining.seconds;
      if (remaining <= 5 && remaining > 0) {
        _playedFinalCountdown = true;
        _audioService.playFinalCountdown();
      }
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

  /// Play a random encouragement cue on workout completion.
  ///
  /// If the final countdown clip is still playing (triggered at 5s remaining),
  /// delay the encouragement cue to avoid overlapping.
  void _playCompletionEncouragement() {
    final delay = _playedFinalCountdown
        ? const Duration(milliseconds: 600)
        : Duration.zero;

    final token = ++_completionCueToken;
    Future.delayed(delay, () {
      if (token != _completionCueToken) return;
      if (_random.nextBool()) {
        _audioService.playGoodJob();
      } else {
        _audioService.playThatsIt();
      }
    });
  }

  void _resetAudioState() {
    _completionCueToken++;
    _lastCountdownSecond = -1;
    _playedGo = false;
    _lastRound = 0;
    _playedGetReady = false;
    _playedTenSeconds = false;
    _playedLastRound = false;
    _playedAlmostThere = false;
    _playedKeepGoing = false;
    _playedFinalCountdown = false;
  }

  void _dispose() {
    // Only stop ticking if we were initialized
    if (_isInitialized) {
      _stopTicking();
    } else {
      // Just cancel subscription if it exists
      _tickSubscription?.cancel();
      _tickSubscription = null;
    }
  }
}
