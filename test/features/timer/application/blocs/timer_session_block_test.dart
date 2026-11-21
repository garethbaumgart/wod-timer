// The timer notifier's one new switch (2.6.0): a workout started as a
// block of Today's WOD. It must tick exactly as the same workout on its
// own, the large catch-up deltas included; only its end (no cue, no review
// moment) and its events (in_session) differ. A timer on its own is the
// existing suites' job and is checked again here side by side.
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/infrastructure/telemetry/telemetry.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';

import '../../../../helpers/notifier_harness.dart';

void main() {
  final events = <(String, Map<String, dynamic>)>[];
  final harnesses = <NotifierHarness>[];

  NotifierHarness harness() {
    final h = NotifierHarness(
      settings: const AppSettings(voice: VoiceOption.major),
    );
    harnesses.add(h);
    return h;
  }

  setUp(() {
    events.clear();
    telemetryEnabled = true;
    debugTelemetrySend = (name, props) => events.add((name, props));
  });

  tearDown(() {
    for (final h in harnesses) {
      h.dispose();
    }
    harnesses.clear();
    telemetryEnabled = false;
    debugTelemetrySend = null;
  });

  /// Runs [workout] alone and as a session block through the same ticks.
  Future<(NotifierHarness, NotifierHarness)> sideBySide(
    Workout Function() workout,
    void Function(NotifierHarness h) ticks,
  ) async {
    final alone = harness();
    final block = harness();
    await alone.notifier.start(workout());
    await block.notifier.start(workout(), inSession: true);
    ticks(alone);
    ticks(block);
    return (alone, block);
  }

  void expectSameClock(NotifierHarness a, NotifierHarness b) {
    final x = a.state.sessionOrNull!;
    final y = b.state.sessionOrNull!;
    expect(y.state, x.state);
    expect(y.currentRound, x.currentRound);
    expect(y.elapsed, x.elapsed);
    expect(y.currentIntervalElapsed, x.currentIntervalElapsed);
    expect(y.elapsedMillis, x.elapsedMillis);
  }

  group('a session block ticks exactly as the timer on its own', () {
    test('second by second, cues included, up to the end', () async {
      final (alone, block) = await sideBySide(
        () => tabataWorkout(rounds: 2, prep: 10),
        (h) => h.run(0, 69),
      );
      expectSameClock(alone, block);
      expect(block.heard, alone.heard);
    });

    test('a large delta (suspended) through several EMOM rounds', () async {
      final (alone, block) = await sideBySide(
        () => emomWorkout(prep: 10),
        (h) => h
          ..tick(5)
          ..tick(250, 400)
          // The get-ready's overshoot is carried in whole; the next tick
          // catches the rounds up (the engine's behaviour, unchanged).
          ..tick(250, 500),
      );
      expectSameClock(alone, block);
      expect(block.state.sessionOrNull!.currentRound, 5);
    });

    test(
      'a large delta from the get-ready through the whole workout',
      () async {
        final (alone, block) = await sideBySide(
          () => tabataWorkout(rounds: 3, prep: 10),
          (h) => h
            ..tick(1)
            ..tick(900)
            ..tick(901),
        );
        expect(alone.state, isA<TimerCompleted>());
        expect(block.state, isA<TimerCompleted>());
        expect(
          block.state.sessionOrNull!.currentRound,
          alone.state.sessionOrNull!.currentRound,
        );
        expect(
          block.state.sessionOrNull!.elapsed,
          alone.state.sessionOrNull!.elapsed,
        );
      },
    );

    test('pause, a suspended pause, resume', () async {
      final (alone, block) = await sideBySide(amrapWorkout, (h) {
        h.run(0, 30);
        h.notifier.pause();
        h.tick(400);
        h.notifier.resume();
        h.run(31, 60);
      });
      expectSameClock(alone, block);
    });
  });

  group('only the end differs', () {
    test(
      'the clock running out: no cue, no review moment, in_session',
      () async {
        final (alone, block) = await sideBySide(
          () => amrapWorkout(seconds: 30),
          (h) => h.run(0, 30),
        );
        await Future<void>.delayed(Duration.zero);
        expect(alone.played.last, 'good job');
        expect(alone.valueMoments, 1);
        expect(block.played, isNot(contains('good job')));
        expect(block.beeped.last, 'low 1');
        expect(block.valueMoments, 0);
        expect(block.state, isA<TimerCompleted>());

        final completed = events
            .where((e) => e.$1 == 'workout_completed')
            .map((e) => e.$2)
            .toList();
        expect(completed[0], isNot(contains('in_session')));
        expect(completed[1], containsPair('in_session', true));
        expect(completed[1], containsPair('ended_by', 'timer'));
      },
    );

    test('FINISH: the block completes, the session plays the change', () async {
      final block = harness();
      await block.notifier.start(forTimeWorkout(cap: 600), inSession: true);
      block.run(0, 42);
      block.notifier.finish();
      final state = block.state;
      expect(state, isA<TimerCompleted>());
      expect((state as TimerCompleted).endedEarly, isFalse);
      expect(state.session.elapsed.seconds, 42);
      expect(block.played, isNot(contains('good job')));
      expect(block.felt, isNot(contains('success')));
    });

    test('a timer started after a session block is on its own again', () async {
      final h = harness();
      await h.notifier.start(amrapWorkout(seconds: 30), inSession: true);
      h.notifier.reset();
      await h.notifier.start(amrapWorkout(seconds: 30));
      h.run(0, 30);
      expect(h.played.last, 'good job');
      expect(events.last.$2, isNot(contains('in_session')));
    });

    test('AGAIN on a session block stays a session block', () async {
      final h = harness();
      await h.notifier.start(amrapWorkout(seconds: 10), inSession: true);
      h.run(0, 10);
      await h.notifier.restart();
      expect(
        events.where((e) => e.$1 == 'workout_started').last.$2,
        containsPair('in_session', true),
      );
    });
  });
}
