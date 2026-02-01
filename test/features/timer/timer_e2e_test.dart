// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/usecases/pause_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/resume_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/start_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/stop_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/tick_timer.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_state.dart'
    as domain;
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/core/domain/value_objects/unique_id.dart';
import 'package:wod_timer/core/domain/value_objects/workout_name.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/infrastructure/services/timer_engine.dart';

class MockAudioService extends Mock implements IAudioService {}

void main() {
  late MockAudioService mockAudioService;
  late TimerEngine timerEngine;
  late StartTimer startTimer;
  late PauseTimer pauseTimer;
  late ResumeTimer resumeTimer;
  late StopTimer stopTimer;
  late TickTimer tickTimer;

  setUp(() {
    mockAudioService = MockAudioService();
    timerEngine = TimerEngine(tickInterval: const Duration(milliseconds: 100));
    startTimer = StartTimer(mockAudioService);
    pauseTimer = PauseTimer();
    resumeTimer = ResumeTimer();
    stopTimer = StopTimer();
    tickTimer = TickTimer();

    when(() => mockAudioService.preloadSounds()).thenAnswer((_) async {});
    when(
      () => mockAudioService.playBeep(),
    ).thenAnswer((_) async => right(unit));
    when(
      () => mockAudioService.playCountdown(any()),
    ).thenAnswer((_) async => right(unit));
    when(() => mockAudioService.playGo()).thenAnswer((_) async => right(unit));
    when(
      () => mockAudioService.playRest(),
    ).thenAnswer((_) async => right(unit));
    when(
      () => mockAudioService.playComplete(),
    ).thenAnswer((_) async => right(unit));
    when(
      () => mockAudioService.playHalfway(),
    ).thenAnswer((_) async => right(unit));
    when(
      () => mockAudioService.playIntervalStart(),
    ).thenAnswer((_) async => right(unit));
    when(
      () => mockAudioService.playGetReady(),
    ).thenAnswer((_) async => right(unit));
    when(
      () => mockAudioService.playTenSeconds(),
    ).thenAnswer((_) async => right(unit));
    when(
      () => mockAudioService.playLastRound(),
    ).thenAnswer((_) async => right(unit));
    when(
      () => mockAudioService.playKeepGoing(),
    ).thenAnswer((_) async => right(unit));
    when(
      () => mockAudioService.playGoodJob(),
    ).thenAnswer((_) async => right(unit));
    when(
      () => mockAudioService.playNextRound(),
    ).thenAnswer((_) async => right(unit));
    when(
      () => mockAudioService.playFinalCountdown(),
    ).thenAnswer((_) async => right(unit));
    when(
      () => mockAudioService.playLetsGo(),
    ).thenAnswer((_) async => right(unit));
    when(
      () => mockAudioService.playComeOn(),
    ).thenAnswer((_) async => right(unit));
    when(
      () => mockAudioService.playAlmostThere(),
    ).thenAnswer((_) async => right(unit));
    when(
      () => mockAudioService.playThatsIt(),
    ).thenAnswer((_) async => right(unit));
    when(
      () => mockAudioService.playNoRep(),
    ).thenAnswer((_) async => right(unit));
    when(() => mockAudioService.dispose()).thenAnswer((_) async {});
    when(() => mockAudioService.setVoicePack(any())).thenReturn(null);
    when(
      () => mockAudioService.setRandomizePerCue(enabled: any(named: 'enabled')),
    ).thenReturn(null);
  });

  tearDown(() {
    timerEngine.dispose();
  });

  group('Timer Engine Tests', () {
    test('TimerEngine emits ticks when started', () async {
      final ticks = <Duration>[];

      // Subscribe to stream
      final subscription = timerEngine.tickStream.listen((elapsed) {
        ticks.add(elapsed);
        print('Tick received: $elapsed');
      });

      // Start the engine
      timerEngine.start();
      expect(timerEngine.isRunning, isTrue);

      // Wait for ticks
      await Future.delayed(const Duration(milliseconds: 350));

      // Stop and cleanup
      timerEngine.stop();
      await subscription.cancel();

      print('Total ticks received: ${ticks.length}');
      expect(
        ticks.length,
        greaterThanOrEqualTo(3),
        reason: 'Should receive at least 3 ticks in 350ms',
      );
    });

    test('TimerEngine pauses and resumes correctly', () async {
      final ticks = <Duration>[];
      final subscription = timerEngine.tickStream.listen(ticks.add);

      timerEngine.start();
      await Future.delayed(const Duration(milliseconds: 250));

      final ticksBeforePause = ticks.length;
      print('Ticks before pause: $ticksBeforePause');

      timerEngine.pause();
      expect(timerEngine.isPaused, isTrue);

      await Future.delayed(const Duration(milliseconds: 200));
      final ticksDuringPause = ticks.length;
      expect(
        ticksDuringPause,
        equals(ticksBeforePause),
        reason: 'No ticks should be received while paused',
      );

      timerEngine.resume();
      expect(timerEngine.isPaused, isFalse);

      await Future.delayed(const Duration(milliseconds: 250));

      timerEngine.stop();
      await subscription.cancel();

      print('Total ticks: ${ticks.length}');
      expect(
        ticks.length,
        greaterThan(ticksBeforePause),
        reason: 'Should receive more ticks after resume',
      );
    });
  });

  group('Full Timer Flow Tests', () {
    test('AMRAP timer with short duration completes correctly', () async {
      // Create a short AMRAP workout (2 seconds)
      final timerType = AmrapTimer(duration: TimerDuration.fromSeconds(2));

      final workout = Workout(
        id: UniqueId(),
        createdAt: DateTime.now(),
        name: WorkoutName.fromString('Test AMRAP'),
        timerType: timerType,
        prepCountdown: TimerDuration.fromSeconds(1), // 1 second prep
      );

      // Start the timer
      final startResult = await startTimer(workout);
      expect(startResult.isRight(), isTrue);

      var session = startResult.getOrElse((l) => throw l);
      print('Initial session state: ${session.state}');
      expect(session.state, equals(domain.TimerState.preparing));

      // Simulate ticks
      final subscription = timerEngine.tickStream.listen((elapsed) {
        print('Tick: $elapsed, Session state: ${session.state}');
      });

      timerEngine.start();

      // Process ticks manually for more control
      Duration lastTick = Duration.zero;

      // Simulate 4 seconds of ticks (1s prep + 2s work + buffer)
      for (int i = 0; i < 40; i++) {
        await Future.delayed(const Duration(milliseconds: 100));

        final now = timerEngine.elapsed;
        final delta = now - lastTick;
        lastTick = now;

        final tickResult = tickTimer(session, delta);
        tickResult.fold(
          (failure) {
            print('Tick failed: $failure');
          },
          (newSession) {
            if (newSession.state != session.state) {
              print('State changed: ${session.state} -> ${newSession.state}');
            }
            session = newSession;
          },
        );

        if (session.state == domain.TimerState.completed) {
          print('Timer completed after ${i + 1} ticks!');
          break;
        }
      }

      timerEngine.stop();
      await subscription.cancel();

      expect(
        session.state,
        equals(domain.TimerState.completed),
        reason: 'Timer should complete after duration',
      );
      print('Final elapsed: ${session.elapsed.seconds}s');
    });

    test('Timer transitions from preparing to running', () async {
      final timerType = AmrapTimer(duration: TimerDuration.fromSeconds(60));

      final workout = Workout(
        id: UniqueId(),
        createdAt: DateTime.now(),
        name: WorkoutName.fromString('Test AMRAP'),
        timerType: timerType,
        prepCountdown: TimerDuration.fromSeconds(1),
      );

      final startResult = await startTimer(workout);
      var session = startResult.getOrElse((l) => throw l);
      expect(session.state, equals(domain.TimerState.preparing));

      // Tick past the prep countdown (1 second = 1000ms)
      // Each tick with 500ms delta should get us there in 2-3 ticks
      for (int i = 0; i < 5; i++) {
        final tickResult = tickTimer(
          session,
          const Duration(milliseconds: 500),
        );
        session = tickResult.getOrElse((l) => throw l);
        print(
          'Tick $i: state=${session.state}, intervalElapsed=${session.currentIntervalElapsed.seconds}s',
        );

        if (session.state == domain.TimerState.running) {
          break;
        }
      }

      expect(
        session.state,
        equals(domain.TimerState.running),
        reason: 'Should transition to running after prep countdown',
      );
    });

    test('Pause and resume works correctly', () async {
      final timerType = AmrapTimer(duration: TimerDuration.fromSeconds(60));

      final workout = Workout(
        id: UniqueId(),
        createdAt: DateTime.now(),
        name: WorkoutName.fromString('Test AMRAP'),
        timerType: timerType,
        prepCountdown: TimerDuration.fromSeconds(0), // No prep for simpler test
      );

      final startResult = await startTimer(workout);
      var session = startResult.getOrElse((l) => throw l);
      expect(session.state, equals(domain.TimerState.running));

      // Tick a bit
      final tickResult = tickTimer(session, const Duration(seconds: 1));
      session = tickResult.getOrElse((l) => throw l);
      expect(session.elapsed.seconds, equals(1));

      // Pause
      final pauseResult = pauseTimer(session);
      session = pauseResult.getOrElse((l) => throw l);
      expect(session.state, equals(domain.TimerState.paused));

      // Resume
      final resumeResult = resumeTimer(session);
      session = resumeResult.getOrElse((l) => throw l);
      expect(session.state, equals(domain.TimerState.running));
    });

    test('Stop timer marks it complete', () async {
      final timerType = AmrapTimer(duration: TimerDuration.fromSeconds(60));

      final workout = Workout(
        id: UniqueId(),
        createdAt: DateTime.now(),
        name: WorkoutName.fromString('Test AMRAP'),
        timerType: timerType,
        prepCountdown: TimerDuration.fromSeconds(0),
      );

      final startResult = await startTimer(workout);
      var session = startResult.getOrElse((l) => throw l);

      // Stop
      final stopResult = stopTimer(session);
      session = stopResult.getOrElse((l) => throw l);
      expect(session.state, equals(domain.TimerState.completed));
    });
  });

  group('Time Remaining Calculation', () {
    test('timeRemaining decreases as elapsed increases', () async {
      final timerType = AmrapTimer(duration: TimerDuration.fromSeconds(10));

      final workout = Workout(
        id: UniqueId(),
        createdAt: DateTime.now(),
        name: WorkoutName.fromString('Test AMRAP'),
        timerType: timerType,
        prepCountdown: TimerDuration.fromSeconds(0),
      );

      final startResult = await startTimer(workout);
      var session = startResult.getOrElse((l) => throw l);

      print('Initial timeRemaining: ${session.timeRemaining.seconds}s');
      expect(session.timeRemaining.seconds, equals(10));

      // Tick 3 seconds
      final tickResult = tickTimer(session, const Duration(seconds: 3));
      session = tickResult.getOrElse((l) => throw l);

      print('After 3s tick, timeRemaining: ${session.timeRemaining.seconds}s');
      expect(session.timeRemaining.seconds, equals(7));
    });

    test('Prep countdown timeRemaining works correctly', () async {
      final timerType = AmrapTimer(duration: TimerDuration.fromSeconds(60));

      final workout = Workout(
        id: UniqueId(),
        createdAt: DateTime.now(),
        name: WorkoutName.fromString('Test AMRAP'),
        timerType: timerType,
        prepCountdown: TimerDuration.fromSeconds(10),
      );

      final startResult = await startTimer(workout);
      var session = startResult.getOrElse((l) => throw l);

      expect(session.state, equals(domain.TimerState.preparing));
      print('Prep timeRemaining: ${session.timeRemaining.seconds}s');
      expect(session.timeRemaining.seconds, equals(10));

      // Tick 3 seconds
      final tickResult = tickTimer(session, const Duration(seconds: 3));
      session = tickResult.getOrElse((l) => throw l);

      print('After 3s, prep timeRemaining: ${session.timeRemaining.seconds}s');
      expect(session.timeRemaining.seconds, equals(7));
    });
  });
}
