import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/infrastructure/dto/workout_dto.dart';

void main() {
  group('WorkoutDto', () {
    group('fromDomain', () {
      test('should convert AMRAP workout to DTO', () {
        final workout = Workout(
          id: UniqueId.fromString('test-id-1'),
          name: WorkoutName.fromString('Test AMRAP'),
          timerType: AmrapTimer(duration: TimerDuration.fromSeconds(600)),
          prepCountdown: TimerDuration.fromSeconds(10),
          createdAt: DateTime(2024, 1, 15, 10, 30),
        );

        final dto = WorkoutDto.fromDomain(workout);

        expect(dto.id, 'test-id-1');
        expect(dto.name, 'Test AMRAP');
        expect(dto.timerType.type, 'amrap');
        expect(dto.prepCountdownSeconds, 10);
        expect(dto.createdAt, '2024-01-15T10:30:00.000');
      });

      test('should convert Tabata workout to DTO', () {
        final workout = Workout(
          id: UniqueId.fromString('test-id-2'),
          name: WorkoutName.fromString('My Tabata'),
          timerType: TabataTimer.standard(),
          prepCountdown: TimerDuration.fromSeconds(5),
          createdAt: DateTime(2024, 2, 20, 14, 0),
        );

        final dto = WorkoutDto.fromDomain(workout);

        expect(dto.id, 'test-id-2');
        expect(dto.name, 'My Tabata');
        expect(dto.timerType.type, 'tabata');
        expect(dto.prepCountdownSeconds, 5);
      });
    });

    group('toDomain', () {
      test('should convert DTO to AMRAP workout', () {
        final dto = WorkoutDto(
          id: 'test-id-3',
          name: 'Quick AMRAP',
          timerType: WorkoutDto.fromDomain(Workout.defaultAmrap()).timerType,
          prepCountdownSeconds: 15,
          createdAt: '2024-03-10T08:00:00.000',
        );

        final workout = dto.toDomain();

        expect(workout.id.value, 'test-id-3');
        expect(workout.name.value, 'Quick AMRAP');
        expect(workout.timerType, isA<AmrapTimer>());
        expect(workout.prepCountdown.seconds, 15);
        expect(workout.createdAt, DateTime(2024, 3, 10, 8, 0));
      });

      test('should convert DTO to EMOM workout', () {
        final dto = WorkoutDto(
          id: 'test-id-4',
          name: 'Morning EMOM',
          timerType: WorkoutDto.fromDomain(Workout.defaultEmom()).timerType,
          prepCountdownSeconds: 10,
          createdAt: '2024-04-05T06:30:00.000',
        );

        final workout = dto.toDomain();

        expect(workout.id.value, 'test-id-4');
        expect(workout.name.value, 'Morning EMOM');
        expect(workout.timerType, isA<EmomTimer>());
        expect(workout.prepCountdown.seconds, 10);
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON', () {
        final workout = Workout.defaultAmrap();
        final dto = WorkoutDto.fromDomain(workout);

        final json = dto.toJson();

        expect(json['id'], isNotEmpty);
        expect(json['name'], 'AMRAP Workout');
        expect(json['timerType'], isA<Map>());
        expect(json['prepCountdownSeconds'], 10);
        expect(json['createdAt'], isNotEmpty);
      });

      test('should deserialize from JSON', () {
        final json = <String, dynamic>{
          'id': 'json-workout-id',
          'name': 'JSON Workout',
          'timerType': <String, dynamic>{
            'type': 'amrap',
            'durationSeconds': 900,
          },
          'prepCountdownSeconds': 20,
          'createdAt': '2024-05-15T12:00:00.000',
        };

        final dto = WorkoutDto.fromJson(json);

        expect(dto.id, 'json-workout-id');
        expect(dto.name, 'JSON Workout');
        expect(dto.timerType.type, 'amrap');
        expect(dto.prepCountdownSeconds, 20);
        expect(dto.createdAt, '2024-05-15T12:00:00.000');
      });

      test('should round-trip correctly', () {
        final original = Workout(
          id: UniqueId.fromString('round-trip-id'),
          name: WorkoutName.fromString('Round Trip Test'),
          timerType: EmomTimer(
            intervalDuration: TimerDuration.fromSeconds(90),
            rounds: RoundCount.fromInt(12),
          ),
          prepCountdown: TimerDuration.fromSeconds(15),
          createdAt: DateTime(2024, 6, 1, 9, 0),
        );

        final dto = WorkoutDto.fromDomain(original);
        final json = dto.toJson();
        final restored = WorkoutDto.fromJson(json).toDomain();

        expect(restored.id.value, 'round-trip-id');
        expect(restored.name.value, 'Round Trip Test');
        expect(restored.timerType, isA<EmomTimer>());
        final emom = restored.timerType as EmomTimer;
        expect(emom.intervalDuration.seconds, 90);
        expect(emom.rounds.value, 12);
        expect(restored.prepCountdown.seconds, 15);
        expect(restored.createdAt, DateTime(2024, 6, 1, 9, 0));
      });
    });

    group('all timer types', () {
      test('should serialize and deserialize AMRAP', () {
        final original = Workout.defaultAmrap();
        final json = WorkoutDto.fromDomain(original).toJson();
        final restored = WorkoutDto.fromJson(json).toDomain();

        expect(restored.timerType, isA<AmrapTimer>());
        expect(
          (restored.timerType as AmrapTimer).duration.seconds,
          (original.timerType as AmrapTimer).duration.seconds,
        );
      });

      test('should serialize and deserialize For Time', () {
        final original = Workout.defaultForTime();
        final json = WorkoutDto.fromDomain(original).toJson();
        final restored = WorkoutDto.fromJson(json).toDomain();

        expect(restored.timerType, isA<ForTimeTimer>());
        expect(
          (restored.timerType as ForTimeTimer).timeCap.seconds,
          (original.timerType as ForTimeTimer).timeCap.seconds,
        );
      });

      test('should serialize and deserialize EMOM', () {
        final original = Workout.defaultEmom();
        final json = WorkoutDto.fromDomain(original).toJson();
        final restored = WorkoutDto.fromJson(json).toDomain();

        expect(restored.timerType, isA<EmomTimer>());
        final originalEmom = original.timerType as EmomTimer;
        final restoredEmom = restored.timerType as EmomTimer;
        expect(
          restoredEmom.intervalDuration.seconds,
          originalEmom.intervalDuration.seconds,
        );
        expect(restoredEmom.rounds.value, originalEmom.rounds.value);
      });

      test('should serialize and deserialize Tabata', () {
        final original = Workout.defaultTabata();
        final json = WorkoutDto.fromDomain(original).toJson();
        final restored = WorkoutDto.fromJson(json).toDomain();

        expect(restored.timerType, isA<TabataTimer>());
        final originalTabata = original.timerType as TabataTimer;
        final restoredTabata = restored.timerType as TabataTimer;
        expect(
          restoredTabata.workDuration.seconds,
          originalTabata.workDuration.seconds,
        );
        expect(
          restoredTabata.restDuration.seconds,
          originalTabata.restDuration.seconds,
        );
        expect(restoredTabata.rounds.value, originalTabata.rounds.value);
      });
    });
  });
}
