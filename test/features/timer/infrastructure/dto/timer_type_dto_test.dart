import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/infrastructure/dto/timer_type_dto.dart';

void main() {
  group('TimerTypeDto', () {
    group('AmrapTimer serialization', () {
      test('should serialize to JSON', () {
        final timerType = AmrapTimer(duration: TimerDuration.fromSeconds(600));

        final dto = TimerTypeDto.fromDomain(timerType);
        final json = dto.toJson();

        expect(json['type'], 'amrap');
        expect(json['durationSeconds'], 600);
      });

      test('should deserialize from JSON', () {
        final json = <String, dynamic>{'type': 'amrap', 'durationSeconds': 600};

        final dto = TimerTypeDto.fromJson(json);
        final timerType = dto.toDomain();

        expect(timerType, isA<AmrapTimer>());
        expect((timerType as AmrapTimer).duration.seconds, 600);
      });

      test('should round-trip correctly', () {
        final original = AmrapTimer(duration: TimerDuration.fromSeconds(900));

        final dto = TimerTypeDto.fromDomain(original);
        final json = dto.toJson();
        final restored = TimerTypeDto.fromJson(json).toDomain();

        expect(restored, isA<AmrapTimer>());
        expect((restored as AmrapTimer).duration.seconds, 900);
      });
    });

    group('ForTimeTimer serialization', () {
      test('should serialize to JSON with countUp true', () {
        final timerType = ForTimeTimer(
          timeCap: TimerDuration.fromSeconds(1200),
        );

        final dto = TimerTypeDto.fromDomain(timerType);
        final json = dto.toJson();

        expect(json['type'], 'fortime');
        expect(json['timeCapSeconds'], 1200);
        expect(json['countUp'], true);
      });

      test('should serialize to JSON with countUp false', () {
        final timerType = ForTimeTimer(
          timeCap: TimerDuration.fromSeconds(900),
          countUp: false,
        );

        final dto = TimerTypeDto.fromDomain(timerType);
        final json = dto.toJson();

        expect(json['type'], 'fortime');
        expect(json['timeCapSeconds'], 900);
        expect(json['countUp'], false);
      });

      test('should deserialize from JSON', () {
        final json = <String, dynamic>{
          'type': 'fortime',
          'timeCapSeconds': 1200,
          'countUp': false,
        };

        final dto = TimerTypeDto.fromJson(json);
        final timerType = dto.toDomain();

        expect(timerType, isA<ForTimeTimer>());
        final forTime = timerType as ForTimeTimer;
        expect(forTime.timeCap.seconds, 1200);
        expect(forTime.countUp, false);
      });

      test('should round-trip correctly', () {
        final original = ForTimeTimer(
          timeCap: TimerDuration.fromSeconds(600),
          countUp: false,
        );

        final dto = TimerTypeDto.fromDomain(original);
        final json = dto.toJson();
        final restored = TimerTypeDto.fromJson(json).toDomain();

        expect(restored, isA<ForTimeTimer>());
        final forTime = restored as ForTimeTimer;
        expect(forTime.timeCap.seconds, 600);
        expect(forTime.countUp, false);
      });
    });

    group('EmomTimer serialization', () {
      test('should serialize to JSON', () {
        final timerType = EmomTimer(
          intervalDuration: TimerDuration.fromSeconds(60),
          rounds: RoundCount.fromInt(10),
        );

        final dto = TimerTypeDto.fromDomain(timerType);
        final json = dto.toJson();

        expect(json['type'], 'emom');
        expect(json['intervalDurationSeconds'], 60);
        expect(json['rounds'], 10);
      });

      test('should deserialize from JSON', () {
        final json = <String, dynamic>{
          'type': 'emom',
          'intervalDurationSeconds': 90,
          'rounds': 15,
        };

        final dto = TimerTypeDto.fromJson(json);
        final timerType = dto.toDomain();

        expect(timerType, isA<EmomTimer>());
        final emom = timerType as EmomTimer;
        expect(emom.intervalDuration.seconds, 90);
        expect(emom.rounds.value, 15);
      });

      test('should round-trip correctly', () {
        final original = EmomTimer(
          intervalDuration: TimerDuration.fromSeconds(45),
          rounds: RoundCount.fromInt(20),
        );

        final dto = TimerTypeDto.fromDomain(original);
        final json = dto.toJson();
        final restored = TimerTypeDto.fromJson(json).toDomain();

        expect(restored, isA<EmomTimer>());
        final emom = restored as EmomTimer;
        expect(emom.intervalDuration.seconds, 45);
        expect(emom.rounds.value, 20);
      });
    });

    group('TabataTimer serialization', () {
      test('should serialize to JSON', () {
        final timerType = TabataTimer(
          workDuration: TimerDuration.fromSeconds(20),
          restDuration: TimerDuration.fromSeconds(10),
          rounds: RoundCount.fromInt(8),
        );

        final dto = TimerTypeDto.fromDomain(timerType);
        final json = dto.toJson();

        expect(json['type'], 'tabata');
        expect(json['workDurationSeconds'], 20);
        expect(json['restDurationSeconds'], 10);
        expect(json['rounds'], 8);
      });

      test('should deserialize from JSON', () {
        final json = <String, dynamic>{
          'type': 'tabata',
          'workDurationSeconds': 30,
          'restDurationSeconds': 15,
          'rounds': 10,
        };

        final dto = TimerTypeDto.fromJson(json);
        final timerType = dto.toDomain();

        expect(timerType, isA<TabataTimer>());
        final tabata = timerType as TabataTimer;
        expect(tabata.workDuration.seconds, 30);
        expect(tabata.restDuration.seconds, 15);
        expect(tabata.rounds.value, 10);
      });

      test('should round-trip correctly', () {
        final original = TabataTimer.standard();

        final dto = TimerTypeDto.fromDomain(original);
        final json = dto.toJson();
        final restored = TimerTypeDto.fromJson(json).toDomain();

        expect(restored, isA<TabataTimer>());
        final tabata = restored as TabataTimer;
        expect(tabata.workDuration.seconds, 20);
        expect(tabata.restDuration.seconds, 10);
        expect(tabata.rounds.value, 8);
      });
    });

    group('default values', () {
      test('should use default duration for AMRAP with null', () {
        final json = <String, dynamic>{
          'type': 'amrap',
          'durationSeconds': null,
        };

        final dto = TimerTypeDto.fromJson(json);
        final timerType = dto.toDomain();

        expect((timerType as AmrapTimer).duration.seconds, 600);
      });

      test('should use default values for ForTime with nulls', () {
        final json = <String, dynamic>{
          'type': 'fortime',
          'timeCapSeconds': null,
          'countUp': null,
        };

        final dto = TimerTypeDto.fromJson(json);
        final timerType = dto.toDomain();

        final forTime = timerType as ForTimeTimer;
        expect(forTime.timeCap.seconds, 1200);
        expect(forTime.countUp, true);
      });

      test('should use default values for EMOM with nulls', () {
        final json = <String, dynamic>{
          'type': 'emom',
          'intervalDurationSeconds': null,
          'rounds': null,
        };

        final dto = TimerTypeDto.fromJson(json);
        final timerType = dto.toDomain();

        final emom = timerType as EmomTimer;
        expect(emom.intervalDuration.seconds, 60);
        expect(emom.rounds.value, 10);
      });

      test('should use default values for Tabata with nulls', () {
        final json = <String, dynamic>{
          'type': 'tabata',
          'workDurationSeconds': null,
          'restDurationSeconds': null,
          'rounds': null,
        };

        final dto = TimerTypeDto.fromJson(json);
        final timerType = dto.toDomain();

        final tabata = timerType as TabataTimer;
        expect(tabata.workDuration.seconds, 20);
        expect(tabata.restDuration.seconds, 10);
        expect(tabata.rounds.value, 8);
      });

      test('should default to AMRAP for unknown type', () {
        final json = <String, dynamic>{
          'type': 'unknown',
          'durationSeconds': 300,
        };

        final dto = TimerTypeDto.fromJson(json);
        final timerType = dto.toDomain();

        expect(timerType, isA<AmrapTimer>());
        expect((timerType as AmrapTimer).duration.seconds, 300);
      });
    });
  });
}
