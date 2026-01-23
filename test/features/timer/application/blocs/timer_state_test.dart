import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/failures/timer_failure.dart';

void main() {
  late Workout workout;
  late TimerSession session;

  setUp(() {
    workout = Workout.defaultAmrap();
    session = TimerSession.fromWorkout(workout);
  });

  group('TimerNotifierState', () {
    group('factory constructors', () {
      test('should create initial state', () {
        const state = TimerNotifierState.initial();
        expect(state, isA<TimerInitial>());
      });

      test('should create preparing state with session', () {
        final state = TimerNotifierState.preparing(session: session);
        expect(state, isA<TimerPreparing>());
        expect((state as TimerPreparing).session, session);
      });

      test('should create running state with session', () {
        final state = TimerNotifierState.running(session: session);
        expect(state, isA<TimerRunning>());
        expect((state as TimerRunning).session, session);
      });

      test('should create resting state with session', () {
        final state = TimerNotifierState.resting(session: session);
        expect(state, isA<TimerResting>());
        expect((state as TimerResting).session, session);
      });

      test('should create paused state with session', () {
        final state = TimerNotifierState.paused(session: session);
        expect(state, isA<TimerPaused>());
        expect((state as TimerPaused).session, session);
      });

      test('should create completed state with session', () {
        final state = TimerNotifierState.completed(session: session);
        expect(state, isA<TimerCompleted>());
        expect((state as TimerCompleted).session, session);
      });

      test('should create error state with failure', () {
        const failure = TimerFailure.invalidConfiguration(message: 'Test error');
        final state = TimerNotifierState.error(failure: failure);
        expect(state, isA<TimerError>());
        expect((state as TimerError).failure, failure);
      });

      test('should create error state with failure and session', () {
        const failure = TimerFailure.invalidConfiguration(message: 'Test error');
        final state = TimerNotifierState.error(failure: failure, session: session);
        expect(state, isA<TimerError>());
        expect((state as TimerError).failure, failure);
        expect((state).session, session);
      });
    });
  });

  group('TimerNotifierStateX extension', () {
    group('sessionOrNull', () {
      test('should return null for initial state', () {
        const state = TimerNotifierState.initial();
        expect(state.sessionOrNull, isNull);
      });

      test('should return session for preparing state', () {
        final state = TimerNotifierState.preparing(session: session);
        expect(state.sessionOrNull, session);
      });

      test('should return session for running state', () {
        final state = TimerNotifierState.running(session: session);
        expect(state.sessionOrNull, session);
      });

      test('should return session for resting state', () {
        final state = TimerNotifierState.resting(session: session);
        expect(state.sessionOrNull, session);
      });

      test('should return session for paused state', () {
        final state = TimerNotifierState.paused(session: session);
        expect(state.sessionOrNull, session);
      });

      test('should return session for completed state', () {
        final state = TimerNotifierState.completed(session: session);
        expect(state.sessionOrNull, session);
      });

      test('should return session for error state with session', () {
        const failure = TimerFailure.invalidConfiguration(message: 'Test');
        final state = TimerNotifierState.error(failure: failure, session: session);
        expect(state.sessionOrNull, session);
      });

      test('should return null for error state without session', () {
        const failure = TimerFailure.invalidConfiguration(message: 'Test');
        const state = TimerNotifierState.error(failure: failure);
        expect(state.sessionOrNull, isNull);
      });
    });

    group('canPause', () {
      test('should be false for initial state', () {
        const state = TimerNotifierState.initial();
        expect(state.canPause, isFalse);
      });

      test('should be true for preparing state', () {
        final state = TimerNotifierState.preparing(session: session);
        expect(state.canPause, isTrue);
      });

      test('should be true for running state', () {
        final state = TimerNotifierState.running(session: session);
        expect(state.canPause, isTrue);
      });

      test('should be true for resting state', () {
        final state = TimerNotifierState.resting(session: session);
        expect(state.canPause, isTrue);
      });

      test('should be false for paused state', () {
        final state = TimerNotifierState.paused(session: session);
        expect(state.canPause, isFalse);
      });

      test('should be false for completed state', () {
        final state = TimerNotifierState.completed(session: session);
        expect(state.canPause, isFalse);
      });

      test('should be false for error state', () {
        const failure = TimerFailure.invalidConfiguration(message: 'Test');
        const state = TimerNotifierState.error(failure: failure);
        expect(state.canPause, isFalse);
      });
    });

    group('canResume', () {
      test('should be false for initial state', () {
        const state = TimerNotifierState.initial();
        expect(state.canResume, isFalse);
      });

      test('should be false for preparing state', () {
        final state = TimerNotifierState.preparing(session: session);
        expect(state.canResume, isFalse);
      });

      test('should be false for running state', () {
        final state = TimerNotifierState.running(session: session);
        expect(state.canResume, isFalse);
      });

      test('should be false for resting state', () {
        final state = TimerNotifierState.resting(session: session);
        expect(state.canResume, isFalse);
      });

      test('should be true for paused state', () {
        final state = TimerNotifierState.paused(session: session);
        expect(state.canResume, isTrue);
      });

      test('should be false for completed state', () {
        final state = TimerNotifierState.completed(session: session);
        expect(state.canResume, isFalse);
      });

      test('should be false for error state', () {
        const failure = TimerFailure.invalidConfiguration(message: 'Test');
        const state = TimerNotifierState.error(failure: failure);
        expect(state.canResume, isFalse);
      });
    });

    group('canStop', () {
      test('should be false for initial state', () {
        const state = TimerNotifierState.initial();
        expect(state.canStop, isFalse);
      });

      test('should be true for preparing state', () {
        final state = TimerNotifierState.preparing(session: session);
        expect(state.canStop, isTrue);
      });

      test('should be true for running state', () {
        final state = TimerNotifierState.running(session: session);
        expect(state.canStop, isTrue);
      });

      test('should be true for resting state', () {
        final state = TimerNotifierState.resting(session: session);
        expect(state.canStop, isTrue);
      });

      test('should be true for paused state', () {
        final state = TimerNotifierState.paused(session: session);
        expect(state.canStop, isTrue);
      });

      test('should be false for completed state', () {
        final state = TimerNotifierState.completed(session: session);
        expect(state.canStop, isFalse);
      });

      test('should be false for error state', () {
        const failure = TimerFailure.invalidConfiguration(message: 'Test');
        const state = TimerNotifierState.error(failure: failure);
        expect(state.canStop, isFalse);
      });
    });

    group('isActive', () {
      test('should be false for initial state', () {
        const state = TimerNotifierState.initial();
        expect(state.isActive, isFalse);
      });

      test('should be true for preparing state', () {
        final state = TimerNotifierState.preparing(session: session);
        expect(state.isActive, isTrue);
      });

      test('should be true for running state', () {
        final state = TimerNotifierState.running(session: session);
        expect(state.isActive, isTrue);
      });

      test('should be true for resting state', () {
        final state = TimerNotifierState.resting(session: session);
        expect(state.isActive, isTrue);
      });

      test('should be false for paused state', () {
        final state = TimerNotifierState.paused(session: session);
        expect(state.isActive, isFalse);
      });

      test('should be false for completed state', () {
        final state = TimerNotifierState.completed(session: session);
        expect(state.isActive, isFalse);
      });

      test('should be false for error state', () {
        const failure = TimerFailure.invalidConfiguration(message: 'Test');
        const state = TimerNotifierState.error(failure: failure);
        expect(state.isActive, isFalse);
      });
    });
  });
}
