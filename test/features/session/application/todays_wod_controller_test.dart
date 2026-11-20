// The session engine (2.6.0) on a fake clock: blocks in order, the
// hand-overs and their cues, skipping, pause and stop in every state, the
// shapes the plan names (one block, two timers back to back, one set,
// twelve blocks) and the app-suspension catch-up, with every timer block
// run by the real timer notifier.
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';

import '../../../helpers/notifier_harness.dart';
import '../../../helpers/session_harness.dart';

const sets2 = SetsBlock(sets: 2, restSeconds: 30);
const rest20 = RestBlock(seconds: 20);
const emom = EmomBlock(intervalSeconds: 30, rounds: 2);
const forTime = ForTimeBlock(capSeconds: 120, countUp: true);
const amrap = AmrapBlock(durationSeconds: 60);
const tabata = TabataBlock(workSeconds: 10, restSeconds: 5, rounds: 2);

void main() {
  late SessionHarness s;

  setUp(() => s = SessionHarness());
  tearDown(() => s.dispose());

  /// Runs a Sets block's get-ready and every set, resting in full.
  Future<void> runSets(SetsBlock block) async {
    await s.advance(10);
    for (var set = 1; set <= block.sets; set++) {
      s.later();
      s.controller.setDone();
      if (set < block.sets) await s.advance(block.restSeconds);
    }
    await s.flush();
  }

  group('a session with every block kind', () {
    test('runs start to finish in order with the right phases', () async {
      await s.start(const [sets2, rest20, emom, forTime, amrap, tabata]);
      expect(s.run.phase, WodPhase.getReady);

      await runSets(sets2);
      expect(s.run.phase, WodPhase.rest);
      await s.advance(20);
      expect(s.run.index, 2);
      expect(s.run.phase, WodPhase.timer);
      expect(s.timer, isA<TimerPreparing>());

      // EMOM: its own 10s get-ready, then 2 x 30s.
      await s.advance(70);
      expect(s.run.index, 3);
      expect(s.timer, isA<TimerPreparing>());

      // For Time: get-ready, 20s of work, FINISH.
      await s.advance(30);
      s.h.notifier.finish();
      await s.flush();
      expect(s.run.index, 4);

      // AMRAP: two rounds counted.
      await s.advance(15);
      s.later();
      s.h.notifier.countRound();
      await s.advance(5);
      s.later();
      s.h.notifier.countRound();
      await s.advance(50);
      expect(s.run.index, 5);

      // Tabata: get-ready and 2 x (10 + 5).
      await s.advance(40);
      expect(s.run.isFinished, isTrue);
      expect(s.run.stopped, isFalse);

      expect(s.steps, [
        '0 getReady',
        '0 setWork 1',
        '0 setRest 1',
        '0 setWork 2',
        '1 rest',
        '2 timer',
        '3 timer',
        '4 timer',
        '5 timer',
        '5 finished',
      ]);
      final outcomes = s.run.outcomes;
      expect(outcomes.map((o) => o.block), [
        sets2,
        rest20,
        emom,
        forTime,
        amrap,
        tabata,
      ]);
      expect(outcomes[0].count, 2);
      expect(outcomes[2].count, 2);
      expect(outcomes[3].seconds, 20);
      expect(outcomes[3].capped, isFalse);
      expect(outcomes[4].count, 2);
      expect(outcomes[5].count, 2);
      // 10 + 0 + 30 + 20 + 70 + 30 + 70 + 40 seconds of session time.
      expect(s.run.totalMs, 270000);
      expect(s.timer, isA<TimerInitial>());
    });

    test('plays the hand-overs with the existing beeps and lines', () async {
      await s.start(const [sets2, rest20, emom]);
      await runSets(sets2);
      await s.advance(20);
      await s.advance(70);

      expect(s.h.heard.where((c) => !c.contains('mid')).map(_cue), [
        // Sets: the get-ready, its 3-2-1, the high beep with Go.
        'get ready', 'low 3', 'low 2', 'low 1', 'high', 'go',
        // SET DONE: the change with Rest on it; the rest's 3-2-1 into set 2.
        'high', 'rest', 'low 3', 'low 2', 'low 1', 'high', 'go',
        // The last SET DONE ends the block: the change, Rest (a Rest block
        // follows), which ends silently into the EMOM's get-ready.
        'high', 'rest', 'get ready', 'low 3', 'low 2', 'low 1', 'high', 'go',
        // The EMOM as on its own: its countdown, the next round, the
        // countdown, and the end: the timer's high beep with Good job.
        'low 3', 'low 2', 'low 1', 'high', 'last round', 'ten seconds',
        'low 3', 'low 2', 'low 1', 'high', 'good job',
      ]);
      expect(s.h.valueMoments, 1);
      expect(s.h.played.where((c) => c == 'good job'), hasLength(1));
    });

    test(
      'a timer block ending mid-session hands over without its own end',
      () async {
        await s.start(const [amrap, rest20]);
        await s.advance(70);
        expect(s.run.phase, WodPhase.rest);
        expect(s.h.played, isNot(contains('good job')));
        expect(s.h.valueMoments, 0);
        // The change into the rest: one high beep with Rest on it.
        expect(s.h.heard.skip(s.h.heard.length - 2).map(_cue), [
          'high',
          'rest',
        ]);
        await s.advance(20);
        expect(s.run.isFinished, isTrue);
        expect(s.h.valueMoments, 1);
      },
    );

    test(
      'a For Time capped on the last block ends neutral, as on its own',
      () async {
        await s.start(const [ForTimeBlock(capSeconds: 60, countUp: true)]);
        await s.advance(70);
        expect(s.run.isFinished, isTrue);
        expect(s.run.outcomes.single.capped, isTrue);
        expect(s.h.played.last, 'complete');
        expect(s.h.valueMoments, 0);
      },
    );
  });

  group('analytics', () {
    test('session events, and in_session on every timer block event', () async {
      await s.start(const [sets2, emom, rest20]);
      await runSets(sets2);
      await s.advance(70);
      await s.advance(20);
      expect(
        s.eventsNamed('session_started').single.$2,
        containsPair('kinds', 'emom,rest,sets'),
      );
      expect(s.eventsNamed('session_started').single.$2['blocks'], 3);
      final completed = s.eventsNamed('session_completed').single.$2;
      expect(completed['ended_by'], 'finished');
      expect(completed['blocks'], 3);
      expect(s.eventsNamed('workout_started').single.$2, {
        'type': 'emom',
        'in_session': true,
        'is_test': 0,
        'test_reason': 'none',
      });
      expect(
        s.eventsNamed('workout_completed').single.$2,
        containsPair('in_session', true),
      );
    });

    test('a session sends its events in order, stopped or finished', () async {
      await s.start(const [rest20, amrap]);
      await s.advance(20 + 70);
      // AGAIN waits out the end screen's first 700ms (retest fix 12).
      s.later();
      await s.controller.again();
      await s.flush();
      await s.advance(25);
      s.controller.stop();
      expect(s.events.map((e) => e.$1), [
        'session_started',
        'workout_started',
        'workout_completed',
        'session_completed',
        'session_started',
        'workout_started',
        'workout_completed',
        'session_completed',
      ]);
      expect(s.eventsNamed('session_completed').map((e) => e.$2['ended_by']), [
        'finished',
        'stopped',
      ]);
      expect(s.eventsNamed('workout_completed').map((e) => e.$2['ended_by']), [
        'timer',
        'user',
      ]);
    });

    test('a timer on its own sends exactly what it always has', () async {
      await s.h.notifier.start(emomWorkout(interval: 10, rounds: 1));
      s.h.run(0, 10);
      await s.flush();
      expect(s.eventsNamed('workout_started').single.$2, {
        'type': 'emom',
        'is_test': 0,
        'test_reason': 'none',
      });
      expect(s.eventsNamed('workout_completed').single.$2, {
        'type': 'emom',
        'ended_by': 'timer',
        'is_test': 0,
        'test_reason': 'none',
      });
      expect(s.h.played.last, 'good job');
      expect(s.h.valueMoments, 1);
    });
  });

  group('skipping', () {
    test(
      'TAP TO SKIP ends a Rest block now, into the next get-ready',
      () async {
        await s.start(const [rest20, amrap]);
        await s.advance(5);
        s.controller.skip();
        await s.flush();
        expect(s.run.index, 1);
        expect(s.timer, isA<TimerPreparing>());
        // No 3-2-1 from the rest itself.
        expect(s.h.beeped, isEmpty);
      },
    );

    test("TAP TO SKIP ends a Sets get-ready and a set's rest", () async {
      await s.start(const [sets2]);
      await s.advance(3);
      s.controller.skip();
      expect(s.run.phase, WodPhase.setWork);
      expect(s.h.played.last, 'go');
      s.later();
      s.controller.setDone();
      expect(s.run.phase, WodPhase.setRest);
      s.later();
      s.controller.skip();
      expect(s.run.phase, WodPhase.setWork);
      expect(s.run.set, 2);
    });

    test("a timer block's get-ready skips as on its own", () async {
      await s.start(const [emom]);
      s.h.notifier.skipPrep();
      expect(s.timer, isA<TimerRunning>());
      expect(s.h.played.last, 'go');
    });

    test('a double tap on SET DONE never also pauses or skips', () async {
      await s.start(const [sets2]);
      await s.advance(10);
      s.later();
      s.controller
        ..setDone()
        ..pause()
        ..skip();
      expect(s.run.phase, WodPhase.setRest);
      expect(s.run.paused, isFalse);
    });
  });

  group('pause and resume', () {
    test('in a Rest block: the countdown and session time hold', () async {
      await s.start(const [rest20, amrap]);
      await s.advance(5);
      s.later();
      s.controller.pause();
      expect(s.run.paused, isTrue);
      await s.advance(30);
      expect(s.run.remainingSeconds, 15);
      s.controller.resume();
      await s.advance(15);
      expect(s.run.index, 1);
      expect(s.run.totalMs, 20000);
    });

    test('on a set and in its rest', () async {
      await s.start(const [sets2]);
      await s.advance(10);
      s.later();
      s.controller.pause();
      expect(s.run.paused, isTrue);
      s.controller.setDone();
      expect(s.run.phase, WodPhase.setWork, reason: 'paused: no SET DONE');
      s.controller.resume();
      s.later();
      s.controller.setDone();
      await s.advance(10);
      s.later();
      s.controller.pause();
      await s.advance(60);
      expect(s.run.remainingSeconds, 20);
      s.controller.resume();
      await s.advance(20);
      expect(s.run.phase, WodPhase.setWork);
      expect(s.run.set, 2);
    });

    test(
      'in a timer block, through the timer, the session clock with it',
      () async {
        await s.start(const [amrap, rest20]);
        await s.advance(20);
        s.later();
        s.controller.pause();
        expect(s.timer, isA<TimerPaused>());
        expect(s.run.paused, isTrue);
        await s.advance(100);
        s.controller.resume();
        expect(s.timer, isA<TimerRunning>());
        expect(s.run.paused, isFalse);
        await s.advance(50);
        expect(s.run.phase, WodPhase.rest);
        expect(s.run.totalMs, 70000);
      },
    );

    test("the timer's own PAUSE pauses the session clock too", () async {
      await s.start(const [amrap]);
      await s.advance(20);
      s.h.notifier.pause();
      expect(s.run.paused, isTrue);
      expect(s.sessionEngine.isPaused, isTrue);
      s.h.notifier.resume();
      expect(s.sessionEngine.isPaused, isFalse);
    });

    test('not in a get-ready: skip or stop only, as on its own', () async {
      await s.start(const [sets2, amrap]);
      s.controller.pause();
      expect(s.run.paused, isFalse);
      await runSets(sets2);
      expect(s.timer, isA<TimerPreparing>());
      s.controller.pause();
      expect(s.run.paused, isFalse);
      expect(s.timer, isA<TimerPreparing>());
    });
  });

  group('HOLD TO STOP ends the whole session', () {
    Future<void> expectStopped({required int completed}) async {
      s.controller.stop();
      await s.flush();
      expect(s.run.isFinished, isTrue);
      expect(s.run.stopped, isTrue);
      expect(s.run.outcomes, hasLength(completed));
      expect(s.timer, isA<TimerInitial>());
      expect(s.h.played, isNot(contains('good job')));
      expect(
        s.eventsNamed('session_completed').single.$2['ended_by'],
        'stopped',
      );
      // Nothing ticks on.
      final total = s.run.totalMs;
      await s.advance(30);
      expect(s.run.totalMs, total);
    }

    test('in a get-ready', () async {
      await s.start(const [sets2, rest20]);
      await s.advance(4);
      expect(s.controller.nothingDoneYet, isTrue);
      await expectStopped(completed: 0);
    });

    test('on a set', () async {
      await s.start(const [sets2]);
      await s.advance(12);
      await expectStopped(completed: 0);
    });

    test("in a set's rest", () async {
      await s.start(const [sets2]);
      await s.advance(10);
      s.later();
      s.controller.setDone();
      await s.advance(4);
      await expectStopped(completed: 0);
    });

    test('in a Rest block', () async {
      await s.start(const [amrap, rest20, emom]);
      await s.advance(75);
      expect(s.run.phase, WodPhase.rest);
      expect(s.controller.nothingDoneYet, isFalse);
      await expectStopped(completed: 1);
    });

    test('in a timer block, running or paused', () async {
      await s.start(const [rest20, emom, amrap]);
      await s.advance(45);
      expect(s.timer, isA<TimerRunning>());
      s.later();
      s.controller.pause();
      await expectStopped(completed: 1);
      // The timer's own stop event, as a session block.
      expect(
        s.eventsNamed('workout_completed').single.$2,
        containsPair('ended_by', 'user'),
      );
    });

    test("in the first timer's get-ready nothing is done yet", () async {
      await s.start(const [emom]);
      expect(s.controller.nothingDoneYet, isTrue);
      s.controller.exit();
      expect(s.runOrNull, isNull);
      expect(s.timer, isA<TimerInitial>());
      expect(s.eventsNamed('session_completed'), isEmpty);
    });
  });

  group('shapes', () {
    test('a one-block session', () async {
      await s.start(const [amrap]);
      await s.advance(70);
      expect(s.steps, ['0 timer', '0 finished']);
      expect(s.run.outcomes.single.count, 0);
      expect(s.h.played.last, 'good job');
    });

    test(
      'two timer blocks back to back: each gets its own get-ready',
      () async {
        await s.start(const [emom, emom]);
        // The hand-over at 70s, and the second EMOM's first tick.
        await s.advance(71);
        expect(s.run.index, 1);
        expect(s.timer, isA<TimerPreparing>());
        expect(s.h.played.where((c) => c == 'get ready'), hasLength(2));
        // The first EMOM's end: a high beep, not Good job.
        expect(s.h.played, isNot(contains('good job')));
        await s.advance(70);
        expect(s.run.isFinished, isTrue);
        expect(s.run.outcomes.map((o) => o.count), [2, 2]);
      },
    );

    test('Sets with 1 set: SET DONE ends it, no rest after', () async {
      await s.start(const [SetsBlock(sets: 1, restSeconds: 60), amrap]);
      await s.advance(10);
      s.later();
      s.controller.setDone();
      await s.flush();
      expect(s.run.index, 1);
      expect(s.steps, ['0 getReady', '0 setWork 1', '1 timer']);
    });

    test('a 12-block session runs every block', () async {
      final blocks = [
        for (var i = 0; i < 6; i++) ...[
          const AmrapBlock(durationSeconds: 60),
          const RestBlock(seconds: 15),
        ],
      ];
      await s.start(blocks);
      for (var i = 0; i < 6; i++) {
        await s.advance(70 + 15);
      }
      expect(s.run.isFinished, isTrue);
      expect(s.run.outcomes, hasLength(12));
      expect(s.eventsNamed('workout_started'), hasLength(6));
    });

    test('AGAIN runs the same session from the start', () async {
      await s.start(const [rest20]);
      await s.advance(20);
      expect(s.run.isFinished, isTrue);
      // AGAIN waits out the end screen's first 700ms (retest fix 12).
      s.later();
      await s.controller.again();
      expect(s.run.isFinished, isFalse);
      expect(s.run.index, 0);
      expect(s.run.outcomes, isEmpty);
      expect(s.eventsNamed('session_started'), hasLength(2));
    });
  });

  group('the app suspended (one large tick)', () {
    test(
      'through a Rest block into the Sets get-ready and on to the set',
      () async {
        await s.start(const [rest20, sets2]);
        await s.advance(5);
        // 15s left in the rest, then the 10s get-ready: 40s away lands on
        // set 1, which has no clock.
        await s.jump(40000);
        expect(s.run.index, 1);
        expect(s.run.phase, WodPhase.setWork);
        expect(s.run.totalMs, 45000);
        // One voice line for the whole catch-up.
        expect(s.h.played.skip(1), ['get ready']);
      },
    );

    test("through a timer block's end: the session moves on, the time "
        'after the end charged to the Rest', () async {
      await s.start(const [amrap, rest20]);
      await s.advance(30);
      // 40s of the AMRAP left, then 260s after its end: the Rest is over.
      await s.jump(300000);
      expect(s.run.isFinished, isTrue);
      expect(s.run.outcomes.map((o) => o.block), [amrap, rest20]);
    });

    test("through a set's rest to the next set", () async {
      await s.start(const [sets2]);
      await s.advance(10);
      s.later();
      s.controller.setDone();
      await s.jump(90000);
      expect(s.run.phase, WodPhase.setWork);
      expect(s.run.set, 2);
    });
  });
}

/// "12s low 3" -> "low 3".
String _cue(String heard) => heard.substring(heard.indexOf(' ') + 1);
