import 'dart:async';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/application/providers/review_prompter_provider.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/core/infrastructure/telemetry/telemetry.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/application/usecases/pause_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/resume_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/start_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/stop_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/tick_timer.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_state.dart'
    as domain;
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
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
  String? _lastLowBeep;
  Duration? _lastVoiceAt;
  bool _playedGo = false;
  int _lastRound = 0;
  bool _isInitialized = false;
  Workout? _lastWorkout;
  bool _playedGetReady = false;
  bool _playedTenSeconds = false;
  bool _playedLastRound = false;
  bool _playedAlmostThere = false;
  bool _playedKeepGoing = false;
  final _random = Random();

  /// Taps that count AMRAP rounds are ignored for this long after the last
  /// counted round, after GO and after a resume, so a double tap, a late
  /// prep-skip tap or a tap-to-resume can never count a round.
  static const roundCountCooldown = Duration(milliseconds: 700);

  /// Clock for the round-count cooldown; tests replace it.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  DateTime? _roundCountBlockedUntil;

  void _blockRoundCount() =>
      _roundCountBlockedUntil = clock().add(roundCountCooldown);

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
    // Silent's full mute is synced by AppSettingsNotifier on load and on
    // every voice change; here only the spoken cues need switching off.
    _audioService.setVoiceMuted(
      muted: voice == VoiceOption.off || voice == VoiceOption.silent,
    );
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
      case VoiceOption.off:
      case VoiceOption.silent:
        break;
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
        trackEvent('workout_started', {
          'type': session.workout.timerType.typeCode,
        });
        // With no prep countdown the session starts directly in running —
        // there is no preparing→running tick transition to catch, so play
        // the GO cue here.
        if (session.state == domain.TimerState.running && !_playedGo) {
          _playedGo = true;
          _audioService.playHighBeep();
          _say(
            _random.nextBool()
                ? _audioService.playGo
                : _audioService.playLetsGo,
          );
          _hapticService.heavyImpact();
          _blockRoundCount();
        }
        _startTicking();
      },
    );
  }

  /// Pause the current timer session.
  ///
  /// A no-op when the session can't be paused (already paused, completed)
  /// so external callers can't knock a valid session into the error state.
  void pause() {
    final currentSession = state.sessionOrNull;
    if (currentSession == null) return;
    if (!state.canPause) return;
    if (!currentSession.state.canPause) return;

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
  ///
  /// A no-op when the session isn't paused (see [pause]).
  void resume() {
    final currentSession = state.sessionOrNull;
    if (currentSession == null) return;
    if (!currentSession.state.canResume) return;

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
        _blockRoundCount();
      },
    );
  }

  /// Stop the timer early — an abort, not an achievement.
  ///
  /// Lands on the completed state flagged [TimerCompleted.endedEarly] so
  /// the UI reports "Stopped" honestly instead of "Finished!". No
  /// celebration cues.
  void stop() {
    final currentSession = state.sessionOrNull;
    if (currentSession == null) return;
    // The final tick can land in the same frame as the hold completing:
    // the workout already finished, so let Finished! stand.
    if (state is TimerCompleted) return;

    final result = _stopTimer(currentSession);

    result.fold(
      (failure) => state = TimerNotifierState.error(
        failure: failure,
        session: currentSession,
      ),
      (session) {
        state = TimerNotifierState.completed(
          session: session,
          endedEarly: true,
        );
        _stopTicking();
        trackEvent('workout_completed', {
          'type': session.workout.timerType.typeCode,
          'ended_by': 'user',
        });
        _hapticService.mediumImpact();
      },
    );
  }

  /// Finish the workout deliberately — For Time's success action.
  ///
  /// Same transition as [stop] but this IS the achievement (the athlete
  /// logging their time), so it completes normally with celebration cues.
  void finish() {
    final currentSession = state.sessionOrNull;
    if (currentSession == null) return;
    if (state is TimerCompleted) return;

    final result = _stopTimer(currentSession);

    result.fold(
      (failure) => state = TimerNotifierState.error(
        failure: failure,
        session: currentSession,
      ),
      (session) {
        state = TimerNotifierState.completed(session: session);
        _stopTicking();
        trackEvent('workout_completed', {
          'type': session.workout.timerType.typeCode,
          'ended_by': 'user_finish',
        });
        // The change beep with the encouragement cue on it ("Good job" or
        // "That's it, you're done"); not playComplete() as well.
        _audioService.playHighBeep();
        _playCompletionEncouragement();
        _hapticService.success();
      },
    );
  }

  /// Count a completed round during an AMRAP (tap-to-count).
  ///
  /// AMRAP sessions start at round 1 and the domain never advances them,
  /// so [TimerSession.currentRound] doubles as the manual tally:
  /// completed rounds = currentRound - 1.
  void countRound() {
    final current = state;
    if (current is! TimerRunning) return;
    final session = current.session;
    if (session.workout.timerType is! AmrapTimer) return;
    final now = clock();
    final blockedUntil = _roundCountBlockedUntil;
    if (blockedUntil != null && now.isBefore(blockedUntil)) return;
    _roundCountBlockedUntil = now.add(roundCountCooldown);

    state = TimerNotifierState.running(
      session: session.copyWith(currentRound: session.currentRound + 1),
    );
    _hapticService.mediumImpact();
  }

  /// Correct the AMRAP round tally on the end screen (a stray tap counted
  /// one too many, or the athlete never tapped). Never below zero rounds.
  void adjustRounds(int delta) {
    final current = state;
    if (current is! TimerCompleted) return;
    final session = current.session;
    if (session.workout.timerType is! AmrapTimer) return;
    final next = (session.currentRound + delta).clamp(1, 1000);
    if (next == session.currentRound) return;
    state = TimerNotifierState.completed(
      session: session.copyWith(currentRound: next),
      endedEarly: current.endedEarly,
    );
    _hapticService.selectionClick();
  }

  /// Skip the remaining get-ready countdown and start the work phase now.
  ///
  /// Consumes the remaining prep through the domain's catch-up tick so the
  /// preparing→running transition (and its GO cue) fires normally.
  void skipPrep() {
    final current = state;
    if (current is! TimerPreparing) return;
    final session = current.session;

    final remaining = session.timeRemaining.seconds;
    final result = _tickTimer(session, Duration(seconds: remaining));
    result.fold((_) {}, (newSession) {
      _handleAudioCues(session, newSession);
      state = _stateFromSession(newSession);
    });
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
    // Never double-subscribe: a fast double-tap on start would otherwise
    // leak the first subscription and process every tick twice (~2x clock).
    _stopTicking();

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

    // A tick can already be in flight on the broadcast stream when the user
    // pauses (the subscription stays alive across pause/resume). Drop it —
    // feeding it to the domain returns timerNotActive and flashed the error
    // state. Not updating _lastTickElapsed keeps the time: the next
    // processed tick's delta covers the dropped span.
    if (!currentSession.state.isActive) return;

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
          _endNaturally();
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
          trackEvent('workout_completed', {
            'type': session.workout.timerType.typeCode,
            'ended_by': state.endedAtTimeCap ? 'time_cap' : 'timer',
          });
          _endNaturally();
        } else {
          state = _stateFromSession(session);
        }
      },
    );
  }

  /// The gym-timer cue pattern (2.1.0, matched to the SmartWOD recording
  /// Gareth chose): three low beeps in the last three seconds of every
  /// phase, then on the change a high beep with the voice line starting on
  /// it. The optional voice cues (motivation, halfway, almost there, ten
  /// seconds) keep clear of the countdown and of another line still being
  /// spoken.
  void _handleAudioCues(TimerSession oldSession, TimerSession newSession) {
    // Track whether a voice cue already played this tick so we don't
    // overlap two spoken clips (e.g. "Halfway" + "Next round").
    bool voiceCuePlayed = false;
    // One high beep per change, even when two things change on one tick.
    bool changeBeeped = false;
    void changeBeep() {
      if (changeBeeped) return;
      changeBeeped = true;
      _audioService.playHighBeep();
    }

    // Handle "Get ready" when entering preparation phase
    if (newSession.state == domain.TimerState.preparing && !_playedGetReady) {
      _playedGetReady = true;
      _say(_audioService.playGetReady);
      voiceCuePlayed = true;
    }

    // Low beeps in the last three seconds of the phase (prep included).
    _playPhaseCountdown(newSession);

    // High beep + "Go" or "Let's go" when the prep countdown ends
    if (oldSession.state == domain.TimerState.preparing &&
        newSession.state == domain.TimerState.running &&
        !_playedGo) {
      _playedGo = true;
      changeBeep();
      // Randomly alternate between "Go" and "Let's go"
      _say(
        _random.nextBool() ? _audioService.playGo : _audioService.playLetsGo,
      );
      _hapticService.heavyImpact(); // Strong haptic for GO!
      _blockRoundCount();
      voiceCuePlayed = true;
    }

    // Handle rest period sound
    // For Tabata, rest + round change can happen on the same tick.
    // Prefer the round cue (more informative) — only play rest if no
    // round transition occurred.
    // Interval-based only: AMRAP's currentRound is the user's manual
    // tap-to-count tally, which shouldn't fire round voice cues.
    final bool roundChanged =
        newSession.isIntervalBased &&
        newSession.currentRound != _lastRound &&
        _lastRound != 0;

    if (oldSession.state == domain.TimerState.running &&
        newSession.state == domain.TimerState.resting &&
        !roundChanged) {
      changeBeep();
      _say(_audioService.playRest);
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
      changeBeep();

      // Play "Last round" if final round, otherwise "Next round"
      final totalRounds = newSession.totalRounds;
      if (totalRounds != null &&
          newSession.currentRound == totalRounds &&
          !_playedLastRound) {
        _playedLastRound = true;
        _say(_audioService.playLastRound);
      } else {
        _say(_audioService.playNextRound);
      }
      voiceCuePlayed = true;
    } else if (_lastRound == 0) {
      _lastRound = newSession.currentRound;
    }

    // The optional cues below wait for a clear moment.
    if (voiceCuePlayed || !_clearToSpeak(newSession)) return;

    // Handle motivational cue around 33% progress
    if (newSession.progress >= 0.33 &&
        oldSession.progress < 0.33 &&
        !_playedKeepGoing) {
      _playedKeepGoing = true;
      // Randomly alternate between motivation cues
      _say(
        _random.nextBool()
            ? _audioService.playKeepGoing
            : _audioService.playComeOn,
      );
      return;
    }

    // Handle halfway point
    if (newSession.progress >= 0.5 && oldSession.progress < 0.5) {
      _say(_audioService.playHalfway);
      _hapticService.mediumImpact();
      return;
    }

    // Handle "Almost there" at ~85% progress
    if (newSession.progress >= 0.85 &&
        oldSession.progress < 0.85 &&
        !_playedAlmostThere) {
      _playedAlmostThere = true;
      _say(_audioService.playAlmostThere);
      return;
    }

    // Handle "Ten seconds" warning, said with 10 or 9 seconds to go, in a
    // workout long enough for it to mean something (over 15s).
    // Uses WHOLE-workout remaining: for EMOM/Tabata, timeRemaining is the
    // current interval's remaining, which would fire this at the end of
    // round 1 (and latch, never playing at the actual workout end).
    if (newSession.state != domain.TimerState.preparing &&
        !_playedTenSeconds &&
        newSession.workout.timerType.estimatedDuration.seconds > 15) {
      final remaining = _workoutRemainingSeconds(newSession);
      if (remaining <= 10 && remaining > 8) {
        _playedTenSeconds = true;
        _say(_audioService.playTenSeconds);
      }
    }
  }

  /// Plays a voice cue and notes when, so the optional cues can wait for a
  /// clear moment.
  void _say(Future<Object?> Function() cue) {
    _lastVoiceAt = _lastTickElapsed;
    cue();
  }

  /// A clear moment for an optional voice cue: more than four seconds
  /// before the phase's countdown beeps, and at least two seconds after the
  /// last line started.
  bool _clearToSpeak(TimerSession session) {
    if (!session.state.isActive) return false;
    if (session.timeRemaining.seconds <= 4) return false;
    final last = _lastVoiceAt;
    return last == null ||
        _lastTickElapsed - last >= const Duration(seconds: 2);
  }

  /// A low beep with 3, 2 and 1 seconds left in the current phase: the
  /// prep countdown, an AMRAP or For Time clock, an EMOM interval, a Tabata
  /// work or rest. A phase too short to fit a count (3 seconds or less)
  /// skips the numbers it starts on.
  void _playPhaseCountdown(TimerSession session) {
    if (!session.state.isActive) return;
    final left = session.timeRemaining.seconds;
    if (left < 1 || left > 3 || left >= _phaseSeconds(session)) return;
    final key = '${session.state.name}:${session.currentRound}:$left';
    if (key == _lastLowBeep) return;
    _lastLowBeep = key;
    _audioService.playLowBeep(left);
    if (session.state == domain.TimerState.preparing) {
      _hapticService.mediumImpact(); // Haptic for each countdown tick
    }
  }

  /// The length of the phase the session is in.
  int _phaseSeconds(TimerSession session) {
    if (session.state == domain.TimerState.preparing) {
      return session.workout.prepCountdown.seconds;
    }
    return session.workout.timerType.when(
      amrap: (timer) => timer.duration.seconds,
      forTime: (timer) => timer.timeCap.seconds,
      emom: (timer) => timer.intervalDuration.seconds,
      tabata: (timer) => session.state == domain.TimerState.resting
          ? timer.restDuration.seconds
          : timer.workDuration.seconds,
    );
  }

  /// Seconds left in the WHOLE workout (not the current interval/phase).
  ///
  /// [TimerSession.timeRemaining] is per-interval for EMOM/Tabata; the
  /// end-of-workout cues need the total scale.
  int _workoutRemainingSeconds(TimerSession session) {
    final total = session.workout.timerType.estimatedDuration.seconds;
    return (total - session.elapsed.seconds).clamp(0, total);
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

  /// Cue and haptic for a workout the clock ended, and the review payoff.
  /// Returns false when it ran into a For Time cap: that is a DNF, so a
  /// neutral end sound and a plain haptic, never "Good job".
  ///
  /// The review moment is booked here, on the one path every natural
  /// completion takes (2.0.0: it used to sit on the tick-after-completion
  /// branch, which the pause race guard made unreachable, so the sheet
  /// never asked).
  bool _endNaturally() {
    // The end is a change like any other: the high beep, the line on it.
    _audioService.playHighBeep();
    if (state.endedAtTimeCap) {
      _audioService.playComplete();
      _hapticService.heavyImpact();
      return false;
    }
    _playCompletionEncouragement();
    _hapticService.success(); // Haptic success for natural completion
    // The workout ran all the way out: the payoff, and the only
    // unambiguous one. Deliberately NOT the manual-finish, ended-early or
    // time-cap paths, which say nothing about whether it went well. The
    // prompter stays quiet until the app has earned it and never throws.
    unawaited(ref.read(reviewPrompterProvider).recordValueMoment());
    return true;
  }

  /// Play a random encouragement cue on workout completion, on the high
  /// beep (no spoken final countdown to wait for since 2.1.0).
  void _playCompletionEncouragement() {
    if (_random.nextBool()) {
      _audioService.playGoodJob();
    } else {
      _audioService.playThatsIt();
    }
  }

  void _resetAudioState() {
    _lastLowBeep = null;
    _lastVoiceAt = null;
    // A no-prep GO is spoken before the ticking (re)starts the clock.
    _lastTickElapsed = Duration.zero;
    _playedGo = false;
    _lastRound = 0;
    _playedGetReady = false;
    _playedTenSeconds = false;
    _playedLastRound = false;
    _playedAlmostThere = false;
    _playedKeepGoing = false;
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
