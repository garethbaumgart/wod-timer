import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';

void main() {
  group('AmrapTimer', () {
    test('should create with duration', () {
      final duration = TimerDuration.fromSeconds(600);
      final timer = AmrapTimer(duration: duration);

      expect(timer.duration, duration);
      expect(timer.displayLabel, 'AMRAP');
      expect(timer.typeCode, 'amrap');
    });

    test('should calculate estimated duration', () {
      final duration = TimerDuration.fromSeconds(900);
      final timer = AmrapTimer(duration: duration);

      expect(timer.estimatedDuration, duration);
    });

    test('should be equal for same values', () {
      final duration = TimerDuration.fromSeconds(600);
      final timer1 = AmrapTimer(duration: duration);
      final timer2 = AmrapTimer(duration: duration);

      expect(timer1, equals(timer2));
      expect(timer1.hashCode, equals(timer2.hashCode));
    });

    test('should not be equal for different values', () {
      final timer1 = AmrapTimer(duration: TimerDuration.fromSeconds(600));
      final timer2 = AmrapTimer(duration: TimerDuration.fromSeconds(900));

      expect(timer1, isNot(equals(timer2)));
    });

    test('toString should return readable format', () {
      final timer = AmrapTimer(duration: TimerDuration.fromSeconds(600));

      expect(timer.toString(), contains('AmrapTimer'));
      expect(timer.toString(), contains('duration'));
    });
  });

  group('ForTimeTimer', () {
    test('should create with timeCap and default countUp', () {
      final timeCap = TimerDuration.fromSeconds(1200);
      final timer = ForTimeTimer(timeCap: timeCap);

      expect(timer.timeCap, timeCap);
      expect(timer.countUp, true);
      expect(timer.displayLabel, 'FOR TIME');
      expect(timer.typeCode, 'fortime');
    });

    test('should create with countUp false', () {
      final timeCap = TimerDuration.fromSeconds(900);
      final timer = ForTimeTimer(timeCap: timeCap, countUp: false);

      expect(timer.countUp, false);
    });

    test('should calculate estimated duration', () {
      final timeCap = TimerDuration.fromSeconds(1200);
      final timer = ForTimeTimer(timeCap: timeCap);

      expect(timer.estimatedDuration, timeCap);
    });

    test('should be equal for same values', () {
      final timeCap = TimerDuration.fromSeconds(900);
      final timer1 = ForTimeTimer(timeCap: timeCap, countUp: false);
      final timer2 = ForTimeTimer(timeCap: timeCap, countUp: false);

      expect(timer1, equals(timer2));
      expect(timer1.hashCode, equals(timer2.hashCode));
    });

    test('should not be equal for different countUp', () {
      final timeCap = TimerDuration.fromSeconds(900);
      final timer1 = ForTimeTimer(timeCap: timeCap);
      final timer2 = ForTimeTimer(timeCap: timeCap, countUp: false);

      expect(timer1, isNot(equals(timer2)));
    });
  });

  group('EmomTimer', () {
    test('should create with interval and rounds', () {
      final interval = TimerDuration.fromSeconds(60);
      final rounds = RoundCount.fromInt(10);
      final timer = EmomTimer(intervalDuration: interval, rounds: rounds);

      expect(timer.intervalDuration, interval);
      expect(timer.rounds, rounds);
      expect(timer.displayLabel, 'EMOM');
      expect(timer.typeCode, 'emom');
    });

    test('should calculate estimated duration', () {
      final interval = TimerDuration.fromSeconds(60);
      final rounds = RoundCount.fromInt(10);
      final timer = EmomTimer(intervalDuration: interval, rounds: rounds);

      expect(timer.estimatedDuration.seconds, 600);
    });

    test('should be equal for same values', () {
      final interval = TimerDuration.fromSeconds(60);
      final rounds = RoundCount.fromInt(10);
      final timer1 = EmomTimer(intervalDuration: interval, rounds: rounds);
      final timer2 = EmomTimer(intervalDuration: interval, rounds: rounds);

      expect(timer1, equals(timer2));
      expect(timer1.hashCode, equals(timer2.hashCode));
    });

    test('should not be equal for different rounds', () {
      final interval = TimerDuration.fromSeconds(60);
      final timer1 = EmomTimer(
        intervalDuration: interval,
        rounds: RoundCount.fromInt(10),
      );
      final timer2 = EmomTimer(
        intervalDuration: interval,
        rounds: RoundCount.fromInt(12),
      );

      expect(timer1, isNot(equals(timer2)));
    });
  });

  group('TabataTimer', () {
    test('should create with work, rest, and rounds', () {
      final work = TimerDuration.fromSeconds(20);
      final rest = TimerDuration.fromSeconds(10);
      final rounds = RoundCount.fromInt(8);
      final timer = TabataTimer(
        workDuration: work,
        restDuration: rest,
        rounds: rounds,
      );

      expect(timer.workDuration, work);
      expect(timer.restDuration, rest);
      expect(timer.rounds, rounds);
      expect(timer.displayLabel, 'TABATA');
      expect(timer.typeCode, 'tabata');
    });

    test('should create standard tabata', () {
      final timer = TabataTimer.standard();

      expect(timer.workDuration.seconds, 20);
      expect(timer.restDuration.seconds, 10);
      expect(timer.rounds.value, 8);
    });

    test('should calculate cycle duration', () {
      final timer = TabataTimer(
        workDuration: TimerDuration.fromSeconds(20),
        restDuration: TimerDuration.fromSeconds(10),
        rounds: RoundCount.fromInt(8),
      );

      expect(timer.cycleDuration.seconds, 30);
    });

    test('should calculate estimated duration', () {
      final timer = TabataTimer.standard();

      // 8 rounds * (20s work + 10s rest) = 8 * 30 = 240 seconds
      expect(timer.estimatedDuration.seconds, 240);
    });

    test('should be equal for same values', () {
      final timer1 = TabataTimer.standard();
      final timer2 = TabataTimer(
        workDuration: TimerDuration.fromSeconds(20),
        restDuration: TimerDuration.fromSeconds(10),
        rounds: RoundCount.fromInt(8),
      );

      expect(timer1, equals(timer2));
      expect(timer1.hashCode, equals(timer2.hashCode));
    });

    test('should not be equal for different work duration', () {
      final timer1 = TabataTimer.standard();
      final timer2 = TabataTimer(
        workDuration: TimerDuration.fromSeconds(30),
        restDuration: TimerDuration.fromSeconds(10),
        rounds: RoundCount.fromInt(8),
      );

      expect(timer1, isNot(equals(timer2)));
    });
  });

  group('TimerType sealed class', () {
    test('should work with switch expression', () {
      final timers = <TimerType>[
        AmrapTimer(duration: TimerDuration.fromSeconds(600)),
        ForTimeTimer(timeCap: TimerDuration.fromSeconds(900)),
        EmomTimer(
          intervalDuration: TimerDuration.fromSeconds(60),
          rounds: RoundCount.fromInt(10),
        ),
        TabataTimer.standard(),
      ];

      final labels = timers.map(
        (timer) => switch (timer) {
          AmrapTimer() => 'AMRAP',
          ForTimeTimer() => 'FOR TIME',
          EmomTimer() => 'EMOM',
          TabataTimer() => 'TABATA',
        },
      );

      expect(labels, ['AMRAP', 'FOR TIME', 'EMOM', 'TABATA']);
    });

    test('when extension should match correctly', () {
      final timer = AmrapTimer(duration: TimerDuration.fromSeconds(600));

      final result = timer.when(
        amrap: (t) => 'amrap: ${t.duration.seconds}',
        forTime: (t) => 'fortime',
        emom: (t) => 'emom',
        tabata: (t) => 'tabata',
      );

      expect(result, 'amrap: 600');
    });

    test('maybeWhen extension should use orElse', () {
      final timer = EmomTimer(
        intervalDuration: TimerDuration.fromSeconds(60),
        rounds: RoundCount.fromInt(10),
      );

      final result = timer.maybeWhen(
        amrap: (t) => 'amrap',
        orElse: () => 'other',
      );

      expect(result, 'other');
    });

    test('maybeWhen extension should match when handler provided', () {
      final timer = EmomTimer(
        intervalDuration: TimerDuration.fromSeconds(60),
        rounds: RoundCount.fromInt(10),
      );

      final result = timer.maybeWhen(
        emom: (t) => 'emom: ${t.rounds.value} rounds',
        orElse: () => 'other',
      );

      expect(result, 'emom: 10 rounds');
    });
  });

  group('TimerType displayLabel', () {
    test('all types should have display labels', () {
      final timers = <TimerType>[
        AmrapTimer(duration: TimerDuration.fromSeconds(600)),
        ForTimeTimer(timeCap: TimerDuration.fromSeconds(900)),
        EmomTimer(
          intervalDuration: TimerDuration.fromSeconds(60),
          rounds: RoundCount.fromInt(10),
        ),
        TabataTimer.standard(),
      ];

      for (final timer in timers) {
        expect(timer.displayLabel, isNotEmpty);
        expect(timer.typeCode, isNotEmpty);
      }
    });
  });
}
