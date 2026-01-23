import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';

void main() {
  group('Workout', () {
    group('creation', () {
      test('should create workout with all fields', () {
        final id = UniqueId();
        const name = WorkoutName.defaultAmrap;
        final timerType = AmrapTimer(duration: TimerDuration.fromSeconds(600));
        final prepCountdown = TimerDuration.fromSeconds(10);
        final createdAt = DateTime.now();

        final workout = Workout(
          id: id,
          name: name,
          timerType: timerType,
          prepCountdown: prepCountdown,
          createdAt: createdAt,
        );

        expect(workout.id, id);
        expect(workout.name, name);
        expect(workout.timerType, timerType);
        expect(workout.prepCountdown, prepCountdown);
        expect(workout.createdAt, createdAt);
      });
    });

    group('defaultAmrap', () {
      test('should create default AMRAP workout', () {
        final workout = Workout.defaultAmrap();

        expect(workout.name, WorkoutName.defaultAmrap);
        expect(workout.timerType, isA<AmrapTimer>());
        expect(workout.prepCountdown.seconds, 10);

        final amrap = workout.timerType as AmrapTimer;
        expect(amrap.duration.seconds, 600);
      });
    });

    group('defaultForTime', () {
      test('should create default For Time workout', () {
        final workout = Workout.defaultForTime();

        expect(workout.name, WorkoutName.defaultForTime);
        expect(workout.timerType, isA<ForTimeTimer>());
        expect(workout.prepCountdown.seconds, 10);

        final forTime = workout.timerType as ForTimeTimer;
        expect(forTime.timeCap.seconds, 1200);
        expect(forTime.countUp, true);
      });
    });

    group('defaultEmom', () {
      test('should create default EMOM workout', () {
        final workout = Workout.defaultEmom();

        expect(workout.name, WorkoutName.defaultEmom);
        expect(workout.timerType, isA<EmomTimer>());
        expect(workout.prepCountdown.seconds, 10);

        final emom = workout.timerType as EmomTimer;
        expect(emom.intervalDuration.seconds, 60);
        expect(emom.rounds.value, 10);
      });
    });

    group('defaultTabata', () {
      test('should create default Tabata workout', () {
        final workout = Workout.defaultTabata();

        expect(workout.name, WorkoutName.defaultTabata);
        expect(workout.timerType, isA<TabataTimer>());
        expect(workout.prepCountdown.seconds, 10);

        final tabata = workout.timerType as TabataTimer;
        expect(tabata.workDuration.seconds, 20);
        expect(tabata.restDuration.seconds, 10);
        expect(tabata.rounds.value, 8);
      });
    });

    group('defaultForType', () {
      test('should create AMRAP for amrap type code', () {
        final workout = Workout.defaultForType('amrap');
        expect(workout.timerType, isA<AmrapTimer>());
      });

      test('should create For Time for fortime type code', () {
        final workout = Workout.defaultForType('fortime');
        expect(workout.timerType, isA<ForTimeTimer>());
      });

      test('should create EMOM for emom type code', () {
        final workout = Workout.defaultForType('emom');
        expect(workout.timerType, isA<EmomTimer>());
      });

      test('should create Tabata for tabata type code', () {
        final workout = Workout.defaultForType('tabata');
        expect(workout.timerType, isA<TabataTimer>());
      });

      test('should be case insensitive', () {
        final workout1 = Workout.defaultForType('AMRAP');
        final workout2 = Workout.defaultForType('AmRaP');
        expect(workout1.timerType, isA<AmrapTimer>());
        expect(workout2.timerType, isA<AmrapTimer>());
      });

      test('should default to AMRAP for unknown type', () {
        final workout = Workout.defaultForType('unknown');
        expect(workout.timerType, isA<AmrapTimer>());
      });
    });

    group('totalDuration', () {
      test('should include prep countdown in total duration', () {
        final workout = Workout.defaultAmrap();

        // 10s prep + 600s workout = 610s
        expect(workout.totalDuration.seconds, 610);
      });

      test('should calculate correctly for Tabata', () {
        final workout = Workout.defaultTabata();

        // 10s prep + (20s + 10s) * 8 rounds = 10 + 240 = 250s
        expect(workout.totalDuration.seconds, 250);
      });

      test('should calculate correctly for EMOM', () {
        final workout = Workout.defaultEmom();

        // 10s prep + 60s * 10 rounds = 10 + 600 = 610s
        expect(workout.totalDuration.seconds, 610);
      });
    });

    group('hasRestPeriods', () {
      test('should return false for AMRAP', () {
        final workout = Workout.defaultAmrap();
        expect(workout.hasRestPeriods, false);
      });

      test('should return false for For Time', () {
        final workout = Workout.defaultForTime();
        expect(workout.hasRestPeriods, false);
      });

      test('should return true for EMOM', () {
        final workout = Workout.defaultEmom();
        expect(workout.hasRestPeriods, true);
      });

      test('should return true for Tabata', () {
        final workout = Workout.defaultTabata();
        expect(workout.hasRestPeriods, true);
      });
    });

    group('isIntervalBased', () {
      test('should return false for AMRAP', () {
        final workout = Workout.defaultAmrap();
        expect(workout.isIntervalBased, false);
      });

      test('should return false for For Time', () {
        final workout = Workout.defaultForTime();
        expect(workout.isIntervalBased, false);
      });

      test('should return true for EMOM', () {
        final workout = Workout.defaultEmom();
        expect(workout.isIntervalBased, true);
      });

      test('should return true for Tabata', () {
        final workout = Workout.defaultTabata();
        expect(workout.isIntervalBased, true);
      });
    });

    group('timerTypeLabel', () {
      test('should return correct labels', () {
        expect(Workout.defaultAmrap().timerTypeLabel, 'AMRAP');
        expect(Workout.defaultForTime().timerTypeLabel, 'FOR TIME');
        expect(Workout.defaultEmom().timerTypeLabel, 'EMOM');
        expect(Workout.defaultTabata().timerTypeLabel, 'TABATA');
      });
    });

    group('roundCount', () {
      test('should return null for AMRAP', () {
        final workout = Workout.defaultAmrap();
        expect(workout.roundCount, isNull);
      });

      test('should return null for For Time', () {
        final workout = Workout.defaultForTime();
        expect(workout.roundCount, isNull);
      });

      test('should return round count for EMOM', () {
        final workout = Workout.defaultEmom();
        expect(workout.roundCount, 10);
      });

      test('should return round count for Tabata', () {
        final workout = Workout.defaultTabata();
        expect(workout.roundCount, 8);
      });
    });

    group('equality', () {
      test('workouts with same values should be equal', () {
        final id = UniqueId.fromString('test-id');
        final createdAt = DateTime(2024);

        final workout1 = Workout(
          id: id,
          name: WorkoutName.defaultAmrap,
          timerType: AmrapTimer(duration: TimerDuration.fromSeconds(600)),
          prepCountdown: TimerDuration.fromSeconds(10),
          createdAt: createdAt,
        );

        final workout2 = Workout(
          id: id,
          name: WorkoutName.defaultAmrap,
          timerType: AmrapTimer(duration: TimerDuration.fromSeconds(600)),
          prepCountdown: TimerDuration.fromSeconds(10),
          createdAt: createdAt,
        );

        expect(workout1, equals(workout2));
      });

      test('workouts with different ids should not be equal', () {
        final createdAt = DateTime(2024);

        final workout1 = Workout(
          id: UniqueId.fromString('id-1'),
          name: WorkoutName.defaultAmrap,
          timerType: AmrapTimer(duration: TimerDuration.fromSeconds(600)),
          prepCountdown: TimerDuration.fromSeconds(10),
          createdAt: createdAt,
        );

        final workout2 = Workout(
          id: UniqueId.fromString('id-2'),
          name: WorkoutName.defaultAmrap,
          timerType: AmrapTimer(duration: TimerDuration.fromSeconds(600)),
          prepCountdown: TimerDuration.fromSeconds(10),
          createdAt: createdAt,
        );

        expect(workout1, isNot(equals(workout2)));
      });
    });

    group('copyWith', () {
      test('should copy with new name', () {
        final workout = Workout.defaultAmrap();
        final newName = WorkoutName.fromString('My Custom AMRAP');
        final copied = workout.copyWith(name: newName);

        expect(copied.name, newName);
        expect(copied.id, workout.id);
        expect(copied.timerType, workout.timerType);
      });

      test('should copy with new timer type', () {
        final workout = Workout.defaultAmrap();
        final newTimerType = AmrapTimer(
          duration: TimerDuration.fromSeconds(1200),
        );
        final copied = workout.copyWith(timerType: newTimerType);

        expect(copied.timerType, newTimerType);
        expect(copied.name, workout.name);
      });
    });
  });
}
