// Timer domain edges the 2.0.0 screens lean on: the For Time cap under a
// catch-up tick, count-down remaining, sub-second time across a pause,
// a Tabata with no rest, zero and sub-second deltas, and the progress
// scale every cue is timed from.
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/domain/value_objects/round_count.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/domain/value_objects/unique_id.dart';
import 'package:wod_timer/core/domain/value_objects/workout_name.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_state.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';

void main() {
  Workout workout(TimerType type, {int prep = 0}) => Workout(
    id: UniqueId(),
    name: WorkoutName.fromString('edge'),
    timerType: type,
    prepCountdown: TimerDuration.fromSeconds(prep),
    createdAt: DateTime.now(),
  );

  TimerSession running(TimerType type, {int prep = 0}) =>
      TimerSession.fromWorkout(
        workout(type, prep: prep),
      ).start().getOrElse((_) => throw StateError('start'));

  TimerSession tick(TimerSession s, Duration delta) =>
      s.tick(delta).getOrElse((f) => throw StateError('$f'));

  group('For Time', () {
    test('a catch-up tick past the cap completes at exactly the cap', () {
      final s = running(ForTimeTimer(timeCap: TimerDuration.fromSeconds(600)));
      final capped = tick(s, const Duration(seconds: 900));
      expect(capped.state, TimerState.completed);
      expect(capped.elapsed.seconds, 600);
      expect(capped.elapsedMillis, 0);
      expect(capped.timeRemaining.seconds, 0);
      expect(capped.progress, 1);
    });

    test('count-down remaining is the cap less elapsed, never negative', () {
      var s = running(
        ForTimeTimer(timeCap: TimerDuration.fromSeconds(120), countUp: false),
      );
      s = tick(s, const Duration(seconds: 45));
      expect(s.timeRemaining.seconds, 75);
      expect(s.elapsed.seconds, 45);
      s = tick(s, const Duration(seconds: 74));
      expect(s.timeRemaining.seconds, 1);
      expect(s.state, TimerState.running);
    });

    test('FINISH keeps the elapsed time and sub-second part', () {
      var s = running(ForTimeTimer(timeCap: TimerDuration.fromSeconds(600)));
      s = tick(s, const Duration(milliseconds: 12340));
      final done = s.complete().getOrElse((_) => throw StateError('done'));
      expect(done.state, TimerState.completed);
      expect(done.elapsed.seconds, 12);
      expect(done.elapsedMillis, 340);
      expect(done.completedAt, isNotNull);
    });
  });

  group('pause and resume', () {
    test('keep the sub-second remainder so no time is lost', () {
      var s = running(AmrapTimer(duration: TimerDuration.fromSeconds(60)));
      s = tick(s, const Duration(milliseconds: 1700));
      expect(s.elapsed.seconds, 1);
      expect(s.elapsedMillis, 700);
      s = s.pause().getOrElse((_) => throw StateError('pause'));
      expect(s.elapsedMillis, 700);
      expect(s.timeRemaining.seconds, 59);
      s = s.resume().getOrElse((_) => throw StateError('resume'));
      s = tick(s, const Duration(milliseconds: 300));
      expect(s.elapsed.seconds, 2);
      expect(s.elapsedMillis, 0);
    });

    test('a paused session refuses ticks and stays where it was', () {
      var s = running(AmrapTimer(duration: TimerDuration.fromSeconds(60)));
      s = tick(s, const Duration(seconds: 10));
      s = s.pause().getOrElse((_) => throw StateError('pause'));
      expect(s.tick(const Duration(seconds: 5)).isLeft(), isTrue);
      expect(s.elapsed.seconds, 10);
      expect(s.pause().isLeft(), isTrue, reason: 'already paused');
    });

    test('prep can be paused and resumed back into prep', () {
      var s = running(
        AmrapTimer(duration: TimerDuration.fromSeconds(60)),
        prep: 10,
      );
      s = tick(s, const Duration(seconds: 4));
      s = s.pause().getOrElse((_) => throw StateError('pause'));
      expect(s.timeRemaining.seconds, 6);
      s = s.resume().getOrElse((_) => throw StateError('resume'));
      expect(s.state, TimerState.preparing);
      s = tick(s, const Duration(seconds: 6));
      expect(s.state, TimerState.running);
      expect(s.elapsed.seconds, 0);
    });
  });

  group('ticks', () {
    test('a zero delta changes nothing', () {
      final s = running(
        EmomTimer(
          intervalDuration: TimerDuration.fromSeconds(60),
          rounds: RoundCount.fromInt(3),
        ),
      );
      final same = tick(s, Duration.zero);
      expect(same.elapsed, s.elapsed);
      expect(same.currentRound, 1);
      expect(same.state, TimerState.running);
    });

    test('sub-second deltas accumulate into whole seconds', () {
      var s = running(AmrapTimer(duration: TimerDuration.fromSeconds(60)));
      for (var i = 0; i < 25; i++) {
        s = tick(s, const Duration(milliseconds: 100));
      }
      expect(s.elapsed.seconds, 2);
      expect(s.elapsedMillis, 500);
    });

    test('an EMOM interval boundary lands on round 2 at zero', () {
      var s = running(
        EmomTimer(
          intervalDuration: TimerDuration.fromSeconds(60),
          rounds: RoundCount.fromInt(2),
        ),
      );
      s = tick(s, const Duration(milliseconds: 59900));
      expect(s.currentRound, 1);
      expect(s.timeRemaining.seconds, 1);
      s = tick(s, const Duration(milliseconds: 100));
      expect(s.currentRound, 2);
      expect(s.currentIntervalElapsed.seconds, 0);
      expect(s.intervalElapsedMillis, 0);
      expect(s.timeRemaining.seconds, 60);
    });
  });

  group('Tabata', () {
    test(
      'with no rest, rounds follow each other and the workout still ends',
      () {
        var s = running(
          TabataTimer(
            workDuration: TimerDuration.fromSeconds(10),
            restDuration: TimerDuration.zero,
            rounds: RoundCount.fromInt(3),
          ),
        );
        s = tick(s, const Duration(seconds: 10));
        expect(s.state, TimerState.running, reason: 'no rest to enter');
        expect(s.currentRound, 2);
        s = tick(s, const Duration(seconds: 25));
        expect(s.state, TimerState.completed);
        expect(s.currentRound, 3);
        expect(s.elapsed.seconds, 30);
      },
    );

    test('the last rest counts the final round, not a round after it', () {
      var s = running(
        TabataTimer(
          workDuration: TimerDuration.fromSeconds(20),
          restDuration: TimerDuration.fromSeconds(10),
          rounds: RoundCount.fromInt(2),
        ),
      );
      s = tick(s, const Duration(seconds: 55));
      expect(s.state, TimerState.resting);
      expect(s.currentRound, 2);
      expect(s.timeRemaining.seconds, 5);
      s = tick(s, const Duration(seconds: 5));
      expect(s.state, TimerState.completed);
      expect(s.currentRound, 2);
      expect(s.elapsed.seconds, 60);
    });
  });

  group('progress (the scale every cue is timed from)', () {
    test('counts the workout, not the prep, and is 1 at the end', () {
      var s = running(
        AmrapTimer(duration: TimerDuration.fromSeconds(100)),
        prep: 10,
      );
      expect(s.progress, 0);
      s = tick(s, const Duration(seconds: 10));
      expect(s.state, TimerState.running);
      expect(s.progress, 0);
      s = tick(s, const Duration(seconds: 33));
      expect(s.progress, closeTo(0.33, 1e-9));
      s = tick(s, const Duration(seconds: 67));
      expect(s.progress, 1);
    });

    test('an interval workout measures elapsed over every round', () {
      var s = running(
        EmomTimer(
          intervalDuration: TimerDuration.fromSeconds(60),
          rounds: RoundCount.fromInt(4),
        ),
      );
      s = tick(s, const Duration(seconds: 120));
      expect(s.progress, 0.5);
      expect(s.totalRounds, 4);
      expect(s.isIntervalBased, isTrue);
    });
  });
}
