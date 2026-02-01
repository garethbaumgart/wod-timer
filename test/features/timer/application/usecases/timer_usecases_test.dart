import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/features/timer/application/usecases/pause_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/resume_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/start_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/stop_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/tick_timer.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_state.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/failures/timer_failure.dart';

class MockAudioService extends Mock implements IAudioService {}

class FakeTimerSession extends Fake implements TimerSession {}

void main() {
  late MockAudioService mockAudioService;
  late StartTimer startTimer;
  late PauseTimer pauseTimer;
  late ResumeTimer resumeTimer;
  late StopTimer stopTimer;
  late TickTimer tickTimer;

  setUpAll(() {
    registerFallbackValue(FakeTimerSession());
  });

  setUp(() {
    mockAudioService = MockAudioService();
    startTimer = StartTimer(mockAudioService);
    pauseTimer = PauseTimer();
    resumeTimer = ResumeTimer();
    stopTimer = StopTimer();
    tickTimer = TickTimer();
  });

  group('StartTimer', () {
    test('should create session from AMRAP workout', () async {
      final workout = Workout.defaultAmrap();
      when(() => mockAudioService.preloadSounds()).thenAnswer((_) async {});

      final result = await startTimer(workout);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should be right'), (session) {
        expect(session.workout, workout);
        // Session should be preparing or running depending on prep countdown
        expect(
          session.state == TimerState.preparing ||
              session.state == TimerState.running,
          isTrue,
        );
      });
      verify(() => mockAudioService.preloadSounds()).called(1);
    });

    test('should create session from For Time workout', () async {
      final workout = Workout.defaultForTime();
      when(() => mockAudioService.preloadSounds()).thenAnswer((_) async {});

      final result = await startTimer(workout);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should be right'), (session) {
        expect(session.workout, workout);
      });
    });

    test('should create session from EMOM workout', () async {
      final workout = Workout.defaultEmom();
      when(() => mockAudioService.preloadSounds()).thenAnswer((_) async {});

      final result = await startTimer(workout);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should be right'), (session) {
        expect(session.workout, workout);
      });
    });

    test('should create session from Tabata workout', () async {
      final workout = Workout.defaultTabata();
      when(() => mockAudioService.preloadSounds()).thenAnswer((_) async {});

      final result = await startTimer(workout);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should be right'), (session) {
        expect(session.workout, workout);
      });
    });
  });

  group('PauseTimer', () {
    test('should pause running session', () async {
      final workout = Workout.defaultAmrap();
      final startedSession = TimerSession.fromWorkout(workout).start();
      final session = startedSession.getRight().toNullable()!;

      final result = pauseTimer(session);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should be right'), (paused) {
        expect(paused.state, TimerState.paused);
      });
    });

    test('should fail to pause ready session', () {
      final workout = Workout.defaultAmrap();
      final session = TimerSession.fromWorkout(workout);

      final result = pauseTimer(session);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<TimerFailure>()),
        (_) => fail('Should be left'),
      );
    });
  });

  group('ResumeTimer', () {
    test('should resume paused session', () {
      final workout = Workout.defaultAmrap();
      final startedSession = TimerSession.fromWorkout(workout).start();
      final pausedSession = startedSession.getRight().toNullable()!.pause();
      final session = pausedSession.getRight().toNullable()!;

      final result = resumeTimer(session);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should be right'), (resumed) {
        // Should go back to the state before pause
        expect(resumed.state != TimerState.paused, isTrue);
      });
    });

    test('should fail to resume non-paused session', () {
      final workout = Workout.defaultAmrap();
      final startedSession = TimerSession.fromWorkout(workout).start();
      final session = startedSession.getRight().toNullable()!;

      final result = resumeTimer(session);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<TimerFailure>()),
        (_) => fail('Should be left'),
      );
    });
  });

  group('StopTimer', () {
    test('should stop running session', () {
      final workout = Workout.defaultAmrap();
      final startedSession = TimerSession.fromWorkout(workout).start();
      final session = startedSession.getRight().toNullable()!;

      final result = stopTimer(session);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should be right'), (stopped) {
        expect(stopped.state, TimerState.completed);
      });
    });

    test('should stop paused session', () {
      final workout = Workout.defaultAmrap();
      final startedSession = TimerSession.fromWorkout(workout).start();
      final pausedSession = startedSession.getRight().toNullable()!.pause();
      final session = pausedSession.getRight().toNullable()!;

      final result = stopTimer(session);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should be right'), (stopped) {
        expect(stopped.state, TimerState.completed);
      });
    });
  });

  group('TickTimer', () {
    test('should update elapsed time', () {
      final workout = Workout.defaultAmrap();
      final startedSession = TimerSession.fromWorkout(workout).start();
      final session = startedSession.getRight().toNullable()!;

      final result = tickTimer(session, const Duration(seconds: 1));

      expect(result.isRight(), isTrue);
    });

    test('should fail to tick non-active session', () {
      final workout = Workout.defaultAmrap();
      final session = TimerSession.fromWorkout(workout);

      final result = tickTimer(session, const Duration(seconds: 1));

      expect(result.isLeft(), isTrue);
    });
  });
}
