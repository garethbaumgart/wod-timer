import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_state.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/failures/timer_failure.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';

void main() {
  group('TimerSession', () {
    group('creation', () {
      test('should create session from workout', () {
        final workout = Workout.defaultAmrap();
        final session = TimerSession.fromWorkout(workout);

        expect(session.workout, workout);
        expect(session.state, TimerState.ready);
        expect(session.currentRound, 1);
        expect(session.elapsed.seconds, 0);
        expect(session.currentIntervalElapsed.seconds, 0);
      });
    });

    group('start', () {
      test(
        'should transition from ready to preparing when has prep countdown',
        () {
          final workout = Workout.defaultAmrap();
          final session = TimerSession.fromWorkout(workout);

          final result = session.start();

          expect(result.isRight(), true);
          result.fold((failure) => fail('Should not fail'), (started) {
            expect(started.state, TimerState.preparing);
            expect(started.startedAt, isNotNull);
          });
        },
      );

      test('should transition directly to running when no prep countdown', () {
        final workout = Workout(
          id: UniqueId(),
          name: WorkoutName.defaultAmrap,
          timerType: AmrapTimer(duration: TimerDuration.fromSeconds(600)),
          prepCountdown: TimerDuration.zero,
          createdAt: DateTime.now(),
        );
        final session = TimerSession.fromWorkout(workout);

        final result = session.start();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (started) => expect(started.state, TimerState.running),
        );
      });

      test('should fail when already running', () {
        final workout = Workout.defaultAmrap();
        var session = TimerSession.fromWorkout(workout);
        session = session.start().getOrElse((f) => session);

        final result = session.start();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<TimerFailure>()),
          (_) => fail('Should fail'),
        );
      });
    });

    group('pause', () {
      test('should pause running timer', () {
        final workout = Workout(
          id: UniqueId(),
          name: WorkoutName.defaultAmrap,
          timerType: AmrapTimer(duration: TimerDuration.fromSeconds(600)),
          prepCountdown: TimerDuration.zero,
          createdAt: DateTime.now(),
        );
        var session = TimerSession.fromWorkout(workout);
        session = session.start().getOrElse((f) => session);

        final result = session.pause();

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (paused) {
          expect(paused.state, TimerState.paused);
          expect(paused.stateBeforePause, TimerState.running);
        });
      });

      test('should fail when not running', () {
        final workout = Workout.defaultAmrap();
        final session = TimerSession.fromWorkout(workout);

        final result = session.pause();

        expect(result.isLeft(), true);
      });
    });

    group('resume', () {
      test('should resume to previous state', () {
        final workout = Workout(
          id: UniqueId(),
          name: WorkoutName.defaultAmrap,
          timerType: AmrapTimer(duration: TimerDuration.fromSeconds(600)),
          prepCountdown: TimerDuration.zero,
          createdAt: DateTime.now(),
        );
        var session = TimerSession.fromWorkout(workout);
        session = session.start().getOrElse((f) => session);
        session = session.pause().getOrElse((f) => session);

        final result = session.resume();

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (resumed) {
          expect(resumed.state, TimerState.running);
          expect(resumed.stateBeforePause, isNull);
        });
      });

      test('should fail when not paused', () {
        final workout = Workout.defaultAmrap();
        final session = TimerSession.fromWorkout(workout);

        final result = session.resume();

        expect(result.isLeft(), true);
      });
    });

    group('tick', () {
      test('should update elapsed time for AMRAP', () {
        final workout = Workout(
          id: UniqueId(),
          name: WorkoutName.defaultAmrap,
          timerType: AmrapTimer(duration: TimerDuration.fromSeconds(600)),
          prepCountdown: TimerDuration.zero,
          createdAt: DateTime.now(),
        );
        var session = TimerSession.fromWorkout(workout);
        session = session.start().getOrElse((f) => session);

        final result = session.tick(const Duration(seconds: 5));

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (ticked) => expect(ticked.elapsed.seconds, 5),
        );
      });

      test('should complete AMRAP when duration reached', () {
        final workout = Workout(
          id: UniqueId(),
          name: WorkoutName.defaultAmrap,
          timerType: AmrapTimer(duration: TimerDuration.fromSeconds(10)),
          prepCountdown: TimerDuration.zero,
          createdAt: DateTime.now(),
        );
        var session = TimerSession.fromWorkout(workout);
        session = session.start().getOrElse((f) => session);
        session = session
            .tick(const Duration(seconds: 9))
            .getOrElse((f) => session);

        final result = session.tick(const Duration(seconds: 2));

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (completed) => expect(completed.state, TimerState.completed),
        );
      });

      test(
        'should transition from preparing to running after prep countdown',
        () {
          final workout = Workout(
            id: UniqueId(),
            name: WorkoutName.defaultAmrap,
            timerType: AmrapTimer(duration: TimerDuration.fromSeconds(600)),
            prepCountdown: TimerDuration.fromSeconds(5),
            createdAt: DateTime.now(),
          );
          var session = TimerSession.fromWorkout(workout);
          session = session.start().getOrElse((f) => session);
          expect(session.state, TimerState.preparing);

          final result = session.tick(const Duration(seconds: 6));

          expect(result.isRight(), true);
          result.fold((failure) => fail('Should not fail'), (ticked) {
            expect(ticked.state, TimerState.running);
            expect(ticked.currentIntervalElapsed.seconds, 0);
          });
        },
      );

      test('should fail when not active', () {
        final workout = Workout.defaultAmrap();
        final session = TimerSession.fromWorkout(workout);

        final result = session.tick(const Duration(seconds: 1));

        expect(result.isLeft(), true);
      });
    });

    group('Tabata tick', () {
      test('should transition from work to rest', () {
        final workout = Workout(
          id: UniqueId(),
          name: WorkoutName.defaultTabata,
          timerType: TabataTimer(
            workDuration: TimerDuration.fromSeconds(5),
            restDuration: TimerDuration.fromSeconds(3),
            rounds: RoundCount.fromInt(4),
          ),
          prepCountdown: TimerDuration.zero,
          createdAt: DateTime.now(),
        );
        var session = TimerSession.fromWorkout(workout);
        session = session.start().getOrElse((f) => session);
        expect(session.state, TimerState.running);

        final result = session.tick(const Duration(seconds: 6));

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (ticked) => expect(ticked.state, TimerState.resting),
        );
      });

      test('should advance round after rest', () {
        final workout = Workout(
          id: UniqueId(),
          name: WorkoutName.defaultTabata,
          timerType: TabataTimer(
            workDuration: TimerDuration.fromSeconds(5),
            restDuration: TimerDuration.fromSeconds(3),
            rounds: RoundCount.fromInt(4),
          ),
          prepCountdown: TimerDuration.zero,
          createdAt: DateTime.now(),
        );
        var session = TimerSession.fromWorkout(workout);
        session = session.start().getOrElse((f) => session);
        // Complete work phase
        session = session
            .tick(const Duration(seconds: 6))
            .getOrElse((f) => session);
        expect(session.state, TimerState.resting);
        expect(session.currentRound, 1);

        // Complete rest phase
        final result = session.tick(const Duration(seconds: 4));

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (ticked) {
          expect(ticked.state, TimerState.running);
          expect(ticked.currentRound, 2);
        });
      });
    });

    group('EMOM tick', () {
      test('should advance round after interval', () {
        final workout = Workout(
          id: UniqueId(),
          name: WorkoutName.defaultEmom,
          timerType: EmomTimer(
            intervalDuration: TimerDuration.fromSeconds(10),
            rounds: RoundCount.fromInt(5),
          ),
          prepCountdown: TimerDuration.zero,
          createdAt: DateTime.now(),
        );
        var session = TimerSession.fromWorkout(workout);
        session = session.start().getOrElse((f) => session);
        expect(session.currentRound, 1);

        final result = session.tick(const Duration(seconds: 11));

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (ticked) {
          expect(ticked.currentRound, 2);
          expect(ticked.currentIntervalElapsed.seconds, 0);
        });
      });

      test('should complete after all rounds', () {
        final workout = Workout(
          id: UniqueId(),
          name: WorkoutName.defaultEmom,
          timerType: EmomTimer(
            intervalDuration: TimerDuration.fromSeconds(10),
            rounds: RoundCount.fromInt(2),
          ),
          prepCountdown: TimerDuration.zero,
          createdAt: DateTime.now(),
        );
        var session = TimerSession.fromWorkout(workout);
        session = session.start().getOrElse((f) => session);
        // Round 1
        session = session
            .tick(const Duration(seconds: 11))
            .getOrElse((f) => session);
        expect(session.currentRound, 2);

        // Round 2 complete
        final result = session.tick(const Duration(seconds: 11));

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (ticked) => expect(ticked.state, TimerState.completed),
        );
      });
    });

    group('complete', () {
      test('should manually complete running timer', () {
        final workout = Workout(
          id: UniqueId(),
          name: WorkoutName.defaultForTime,
          timerType: ForTimeTimer(timeCap: TimerDuration.fromSeconds(1200)),
          prepCountdown: TimerDuration.zero,
          createdAt: DateTime.now(),
        );
        var session = TimerSession.fromWorkout(workout);
        session = session.start().getOrElse((f) => session);

        final result = session.complete();

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (completed) {
          expect(completed.state, TimerState.completed);
          expect(completed.completedAt, isNotNull);
        });
      });

      test('should fail when already completed', () {
        final workout = Workout(
          id: UniqueId(),
          name: WorkoutName.defaultAmrap,
          timerType: AmrapTimer(duration: TimerDuration.fromSeconds(10)),
          prepCountdown: TimerDuration.zero,
          createdAt: DateTime.now(),
        );
        var session = TimerSession.fromWorkout(workout);
        session = session.start().getOrElse((f) => session);
        session = session.complete().getOrElse((f) => session);

        final result = session.complete();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<TimerFailure>()),
          (_) => fail('Should fail'),
        );
      });

      test('should fail when not started', () {
        final workout = Workout.defaultAmrap();
        final session = TimerSession.fromWorkout(workout);

        final result = session.complete();

        expect(result.isLeft(), true);
      });
    });

    group('computed properties', () {
      test('timeRemaining should calculate correctly for AMRAP', () {
        final workout = Workout(
          id: UniqueId(),
          name: WorkoutName.defaultAmrap,
          timerType: AmrapTimer(duration: TimerDuration.fromSeconds(600)),
          prepCountdown: TimerDuration.zero,
          createdAt: DateTime.now(),
        );
        var session = TimerSession.fromWorkout(workout);
        session = session.start().getOrElse((f) => session);
        session = session
            .tick(const Duration(seconds: 100))
            .getOrElse((f) => session);

        expect(session.timeRemaining.seconds, 500);
      });

      test('progress should calculate correctly', () {
        final workout = Workout(
          id: UniqueId(),
          name: WorkoutName.defaultAmrap,
          timerType: AmrapTimer(duration: TimerDuration.fromSeconds(100)),
          prepCountdown: TimerDuration.zero,
          createdAt: DateTime.now(),
        );
        var session = TimerSession.fromWorkout(workout);
        session = session.start().getOrElse((f) => session);
        session = session
            .tick(const Duration(seconds: 50))
            .getOrElse((f) => session);

        expect(session.progress, closeTo(0.5, 0.01));
      });

      test('progress should be 0 when ready', () {
        final workout = Workout.defaultAmrap();
        final session = TimerSession.fromWorkout(workout);

        expect(session.progress, 0);
      });

      test('progress should be 1 when completed', () {
        final workout = Workout(
          id: UniqueId(),
          name: WorkoutName.defaultAmrap,
          timerType: AmrapTimer(duration: TimerDuration.fromSeconds(10)),
          prepCountdown: TimerDuration.zero,
          createdAt: DateTime.now(),
        );
        var session = TimerSession.fromWorkout(workout);
        session = session.start().getOrElse((f) => session);
        session = session.complete().getOrElse((f) => session);

        expect(session.progress, 1);
      });
    });
  });

  group('TimerState', () {
    test('isActive should be true for active states', () {
      expect(TimerState.preparing.isActive, true);
      expect(TimerState.running.isActive, true);
      expect(TimerState.resting.isActive, true);
    });

    test('isActive should be false for inactive states', () {
      expect(TimerState.ready.isActive, false);
      expect(TimerState.paused.isActive, false);
      expect(TimerState.completed.isActive, false);
    });

    test('canStart should only be true for ready', () {
      expect(TimerState.ready.canStart, true);
      expect(TimerState.running.canStart, false);
      expect(TimerState.completed.canStart, false);
    });

    test('canPause should be true for active states', () {
      expect(TimerState.running.canPause, true);
      expect(TimerState.resting.canPause, true);
      expect(TimerState.preparing.canPause, true);
      expect(TimerState.paused.canPause, false);
    });

    test('displayLabel should return readable strings', () {
      for (final state in TimerState.values) {
        expect(state.displayLabel, isNotEmpty);
      }
    });
  });
}
