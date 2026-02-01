import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/domain/value_objects/round_count.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/features/timer/application/usecases/create_workout.dart';
import 'package:wod_timer/features/timer/domain/failures/timer_failure.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';

void main() {
  late CreateWorkout createWorkout;

  setUp(() {
    createWorkout = CreateWorkout();
  });

  group('CreateWorkout', () {
    group('valid configurations', () {
      test('should create AMRAP workout successfully', () {
        final timerType = AmrapTimer(duration: TimerDuration.fromSeconds(600));

        final result = createWorkout(name: 'Test AMRAP', timerType: timerType);

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Should be right'), (workout) {
          expect(workout.name.value, 'Test AMRAP');
          expect(workout.timerType, isA<AmrapTimer>());
          expect(workout.prepCountdown.seconds, 10);
        });
      });

      test('should create For Time workout successfully', () {
        final timerType = ForTimeTimer(
          timeCap: TimerDuration.fromSeconds(1200),
        );

        final result = createWorkout(
          name: 'Test For Time',
          timerType: timerType,
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Should be right'), (workout) {
          expect(workout.name.value, 'Test For Time');
          expect(workout.timerType, isA<ForTimeTimer>());
        });
      });

      test('should create EMOM workout successfully', () {
        final timerType = EmomTimer(
          intervalDuration: TimerDuration.fromSeconds(60),
          rounds: RoundCount.fromInt(10),
        );

        final result = createWorkout(name: 'Test EMOM', timerType: timerType);

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Should be right'), (workout) {
          expect(workout.name.value, 'Test EMOM');
          expect(workout.timerType, isA<EmomTimer>());
        });
      });

      test('should create Tabata workout successfully', () {
        final timerType = TabataTimer(
          workDuration: TimerDuration.fromSeconds(20),
          restDuration: TimerDuration.fromSeconds(10),
          rounds: RoundCount.fromInt(8),
        );

        final result = createWorkout(name: 'Test Tabata', timerType: timerType);

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Should be right'), (workout) {
          expect(workout.name.value, 'Test Tabata');
          expect(workout.timerType, isA<TabataTimer>());
        });
      });

      test('should use custom prep countdown', () {
        final timerType = AmrapTimer(duration: TimerDuration.fromSeconds(600));

        final result = createWorkout(
          name: 'Test Workout',
          timerType: timerType,
          prepCountdownSeconds: 5,
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Should be right'), (workout) {
          expect(workout.prepCountdown.seconds, 5);
        });
      });

      test('should trim whitespace from name', () {
        final timerType = AmrapTimer(duration: TimerDuration.fromSeconds(600));

        final result = createWorkout(
          name: '  Test Workout  ',
          timerType: timerType,
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Should be right'), (workout) {
          expect(workout.name.value, 'Test Workout');
        });
      });
    });

    group('invalid configurations', () {
      test('should fail with empty name', () {
        final timerType = AmrapTimer(duration: TimerDuration.fromSeconds(600));

        final result = createWorkout(name: '', timerType: timerType);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<TimerFailure>()),
          (_) => fail('Should be left'),
        );
      });

      test('should fail with whitespace-only name', () {
        final timerType = AmrapTimer(duration: TimerDuration.fromSeconds(600));

        final result = createWorkout(name: '   ', timerType: timerType);

        expect(result.isLeft(), isTrue);
      });

      test('should fail with zero AMRAP duration', () {
        final timerType = AmrapTimer(duration: TimerDuration.fromSeconds(0));

        final result = createWorkout(name: 'Test', timerType: timerType);

        expect(result.isLeft(), isTrue);
      });

      test('should fail with zero For Time time cap', () {
        final timerType = ForTimeTimer(timeCap: TimerDuration.fromSeconds(0));

        final result = createWorkout(name: 'Test', timerType: timerType);

        expect(result.isLeft(), isTrue);
      });

      test('should fail with zero EMOM interval', () {
        final timerType = EmomTimer(
          intervalDuration: TimerDuration.fromSeconds(0),
          rounds: RoundCount.fromInt(10),
        );

        final result = createWorkout(name: 'Test', timerType: timerType);

        expect(result.isLeft(), isTrue);
      });

      test('should fail with zero EMOM rounds', () {
        final timerType = EmomTimer(
          intervalDuration: TimerDuration.fromSeconds(60),
          rounds: RoundCount.fromInt(0),
        );

        final result = createWorkout(name: 'Test', timerType: timerType);

        expect(result.isLeft(), isTrue);
      });

      test('should fail with zero Tabata work duration', () {
        final timerType = TabataTimer(
          workDuration: TimerDuration.fromSeconds(0),
          restDuration: TimerDuration.fromSeconds(10),
          rounds: RoundCount.fromInt(8),
        );

        final result = createWorkout(name: 'Test', timerType: timerType);

        expect(result.isLeft(), isTrue);
      });

      test('should fail with zero Tabata rounds', () {
        final timerType = TabataTimer(
          workDuration: TimerDuration.fromSeconds(20),
          restDuration: TimerDuration.fromSeconds(10),
          rounds: RoundCount.fromInt(0),
        );

        final result = createWorkout(name: 'Test', timerType: timerType);

        expect(result.isLeft(), isTrue);
      });

      test('should fail with negative prep countdown', () {
        final timerType = AmrapTimer(duration: TimerDuration.fromSeconds(600));

        final result = createWorkout(
          name: 'Test',
          timerType: timerType,
          prepCountdownSeconds: -1,
        );

        expect(result.isLeft(), isTrue);
      });
    });
  });
}
