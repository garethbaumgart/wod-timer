// Retest fix 6 (2.6.0): the app suspended across a timer block's end. The
// Rest after it is charged only with the time after the timer actually
// ended, whichever clock ticks first on the way back; catch-up never runs
// into a timer block (it starts from its own get-ready) and never past a
// set (a set has no clock).
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';

import '../../../helpers/notifier_harness.dart';
import '../../../helpers/session_harness.dart';

const rest120 = RestBlock(seconds: 120);
const sets2 = SetsBlock(sets: 2, restSeconds: 30);

/// Each timer kind, 60s long, so each ends 70s into the session.
const timers = <String, SessionBlock>{
  'AMRAP': AmrapBlock(durationSeconds: 60),
  'For Time (cap)': ForTimeBlock(capSeconds: 60, countUp: false),
  'EMOM': EmomBlock(intervalSeconds: 15, rounds: 4),
  'Tabata': TabataBlock(workSeconds: 20, restSeconds: 10, rounds: 2),
};

void emit(FakeTimerEngine e, int ms) =>
    e.emit(e.elapsed + Duration(milliseconds: ms));

void main() {
  late SessionHarness s;
  setUp(() => s = SessionHarness());
  tearDown(() => s.dispose());

  /// Away [awayMs] with the timer's clock (or the session's) ticking first
  /// on the way back, then one ordinary second.
  Future<void> away(int awayMs, {required bool timerFirst}) async {
    final first = timerFirst ? s.h.engine : s.sessionEngine;
    final second = timerFirst ? s.sessionEngine : s.h.engine;
    // Only a clock that was running while she was away has time to report
    // (a timer started on the way back starts from zero).
    final running = {
      for (final e in [first, second]) e: e.isRunning && !e.isPaused,
    };
    s.h.now = s.h.now.add(Duration(milliseconds: awayMs));
    if (running[first]!) emit(first, awayMs);
    await s.flush();
    if (running[second]!) emit(second, awayMs);
    await s.flush();
  }

  for (final MapEntry(key: name, value: timer) in timers.entries) {
    for (final timerFirst in [true, false]) {
      final order = timerFirst ? 'timer clock first' : 'session clock first';
      group('$name, 5s before its end, $order', () {
        Future<void> startAndRun() async {
          await s.start([timer, rest120, sets2]);
          await s.advance(65);
          expect(s.run.phase, WodPhase.timer);
        }

        test('away 10s: the Rest has 5s gone', () async {
          await startAndRun();
          await away(10000, timerFirst: timerFirst);
          expect(s.run.index, 1);
          expect(s.run.phase, WodPhase.rest);
          expect(s.run.remainingSeconds, 115);
        });

        test('away 60s: the Rest has 55s gone', () async {
          await startAndRun();
          await away(60000, timerFirst: timerFirst);
          expect(s.run.phase, WodPhase.rest);
          expect(s.run.remainingSeconds, 65);
        });

        test('away 5 min: through the Rest and the get-ready, stopping at '
            'the set', () async {
          await startAndRun();
          await away(300000, timerFirst: timerFirst);
          expect(s.run.index, 2);
          expect(s.run.phase, WodPhase.setWork);
          expect(s.run.set, 1);
          expect(s.run.totalMs, 365000);
        });
      });
    }
  }

  group('the large deltas', () {
    test("from a get-ready through a whole timer: the timer's catch-up, "
        'then only the time after its end', () async {
      await s.start(const [AmrapBlock(durationSeconds: 60), rest120]);
      await s.advance(5);
      // 5s into the get-ready, away 100s: the AMRAP ended at 70s.
      await away(100000, timerFirst: true);
      await s.advance(1);
      expect(s.run.phase, WodPhase.rest);
      expect(s.run.remainingSeconds, 120 - 36);
    });

    test(
      'never into a timer block: it starts from its own get-ready',
      () async {
        await s.start(const [
          RestBlock(seconds: 20),
          AmrapBlock(durationSeconds: 60),
        ]);
        await s.advance(5);
        await away(300000, timerFirst: false);
        expect(s.run.index, 1);
        expect(s.timer, isA<TimerPreparing>());
        expect(s.timer.sessionOrNull!.timeRemaining.seconds, 10);
      },
    );

    test(
      'FINISH, then away: the Rest is charged from the moment away began',
      () async {
        await s.start(const [
          ForTimeBlock(capSeconds: 600, countUp: true),
          rest120,
        ]);
        await s.advance(30);
        s.later();
        s.h.notifier.finish();
        await s.flush();
        expect(s.run.phase, WodPhase.rest);
        await away(60000, timerFirst: false);
        expect(s.run.remainingSeconds, 60);
      },
    );

    test('paused, away, resumed: nothing moves while paused', () async {
      await s.start(const [AmrapBlock(durationSeconds: 60), rest120]);
      await s.advance(20);
      s.later();
      s.controller.pause();
      final total = s.run.totalMs;
      await s.jump(600000);
      expect(s.run.totalMs, total);
      s.later();
      s.controller.resume();
      await s.advance(5);
      expect(s.timer.sessionOrNull!.elapsed.seconds, 15);
    });
  });
}
