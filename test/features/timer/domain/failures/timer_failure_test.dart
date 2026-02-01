import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_state.dart';
import 'package:wod_timer/features/timer/domain/failures/timer_failure.dart';

void main() {
  group('TimerFailure', () {
    group('invalidStateTransition', () {
      test('should have correct message', () {
        const failure = TimerFailure.invalidStateTransition(
          from: TimerState.ready,
          to: TimerState.completed,
        );

        expect(failure.message, 'Cannot transition from Ready to Complete');
      });

      test('should include state names in message', () {
        const failure = TimerFailure.invalidStateTransition(
          from: TimerState.paused,
          to: TimerState.running,
        );

        expect(failure.message, contains('Paused'));
        expect(failure.message, contains('Work'));
      });
    });

    group('timerNotActive', () {
      test('should have correct message', () {
        const failure = TimerFailure.timerNotActive();

        expect(failure.message, 'Timer is not active');
      });
    });

    group('alreadyCompleted', () {
      test('should have correct message', () {
        const failure = TimerFailure.alreadyCompleted();

        expect(failure.message, 'Workout is already completed');
      });
    });

    group('invalidWorkout', () {
      test('should have default message when message is null', () {
        const failure = TimerFailure.invalidWorkout();

        expect(failure.message, 'Invalid workout configuration');
      });

      test('should use provided message', () {
        const failure = TimerFailure.invalidWorkout(message: 'Custom error');

        expect(failure.message, 'Custom error');
      });
    });

    group('invalidConfiguration', () {
      test('should have default message when message is null', () {
        const failure = TimerFailure.invalidConfiguration();

        expect(failure.message, 'Invalid timer configuration');
      });

      test('should use provided message', () {
        const failure = TimerFailure.invalidConfiguration(
          message: 'Duration must be positive',
        );

        expect(failure.message, 'Duration must be positive');
      });
    });

    group('sessionNotFound', () {
      test('should have correct message', () {
        const failure = TimerFailure.sessionNotFound();

        expect(failure.message, 'Timer session not found');
      });
    });

    group('unexpected', () {
      test('should have default message when message is null', () {
        const failure = TimerFailure.unexpected();

        expect(failure.message, 'An unexpected error occurred');
      });

      test('should use provided message', () {
        const failure = TimerFailure.unexpected(
          message: 'Something went wrong',
        );

        expect(failure.message, 'Something went wrong');
      });
    });

    group('equality', () {
      test('same failures should be equal', () {
        const failure1 = TimerFailure.timerNotActive();
        const failure2 = TimerFailure.timerNotActive();

        expect(failure1, equals(failure2));
      });

      test('different failures should not be equal', () {
        const failure1 = TimerFailure.timerNotActive();
        const failure2 = TimerFailure.alreadyCompleted();

        expect(failure1, isNot(equals(failure2)));
      });

      test('same state transition failures should be equal', () {
        const failure1 = TimerFailure.invalidStateTransition(
          from: TimerState.ready,
          to: TimerState.completed,
        );
        const failure2 = TimerFailure.invalidStateTransition(
          from: TimerState.ready,
          to: TimerState.completed,
        );

        expect(failure1, equals(failure2));
      });
    });

    group('when pattern matching', () {
      test('should match all failure types', () {
        final failures = <TimerFailure>[
          const TimerFailure.invalidStateTransition(
            from: TimerState.ready,
            to: TimerState.completed,
          ),
          const TimerFailure.timerNotActive(),
          const TimerFailure.alreadyCompleted(),
          const TimerFailure.invalidWorkout(),
          const TimerFailure.invalidConfiguration(),
          const TimerFailure.sessionNotFound(),
          const TimerFailure.unexpected(),
        ];

        for (final failure in failures) {
          expect(failure.message, isNotEmpty);
        }
      });
    });
  });
}
