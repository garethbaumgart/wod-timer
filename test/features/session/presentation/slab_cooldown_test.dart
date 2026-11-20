// Retest fix 13 (2.6.0): in a session every bottom-bar control (PAUSE,
// RESUME, SET DONE, FINISH, the skip tap) ignores taps for 700ms after any
// phase change, so the second tap of a double tap on FINISH never pauses
// the Rest that took its place. A timer on its own keeps today's PAUSE.
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/screen_harness.dart';
import '../../../helpers/session_harness.dart';

void main() {
  setUpAll(loadOutfit);

  group('the engine', () {
    late SessionHarness s;
    setUp(() => s = SessionHarness());
    tearDown(() => s.dispose());

    test('FINISH, then PAUSE at once: the Rest keeps counting', () async {
      await s.start(const [
        ForTimeBlock(capSeconds: 600, countUp: true),
        RestBlock(seconds: 120),
      ]);
      await s.advance(30);
      s.h.notifier.finish();
      await s.flush();
      expect(s.run.phase, WodPhase.rest);
      s.controller.pause();
      expect(s.run.paused, isFalse);
      s.later();
      s.controller.pause();
      expect(s.run.paused, isTrue, reason: 'a deliberate PAUSE');
    });

    test(
      "PAUSE right after a timer block's GO is ignored, then works",
      () async {
        await s.start(const [
          AmrapBlock(durationSeconds: 60),
          RestBlock(seconds: 30),
        ]);
        await s.advance(10);
        expect(s.timer, isA<TimerRunning>());
        s.controller.pause();
        expect(s.timer, isA<TimerRunning>());
        s.later();
        s.controller.pause();
        expect(s.timer, isA<TimerPaused>());
      },
    );
  });

  group('the screens', () {
    late AppHarness app;
    setUp(() => app = AppHarness());

    Future<void> startSession(
      WidgetTester tester,
      List<SessionBlock> blocks,
    ) async {
      await app.pump(
        tester,
        device: Device.phone,
        location: AppRoutes.todaysWod,
      );
      await app.container
          .read(todaysWodProvider.notifier)
          .start(WodSession(blocks));
      app.router.go(AppRoutes.todaysWodActive);
      await tester.pumpAndSettle();
    }

    testWidgets('a double tap on FINISH before a Rest does not pause it', (
      tester,
    ) async {
      await startSession(tester, const [
        ForTimeBlock(capSeconds: 600, countUp: true),
        RestBlock(seconds: 120),
      ]);
      await app.advance(tester, 15);
      app.later();
      final spot = tester.getCenter(find.text('FINISH'));
      await tester.tapAt(spot);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      final run = app.container.read(todaysWodProvider)!;
      expect(run.phase, WodPhase.rest);
      await tester.tapAt(spot); // PAUSE now covers the whole slab
      await tester.pump();
      expect(app.container.read(todaysWodProvider)!.paused, isFalse);
    });

    testWidgets("FINISH right after a For Time block's GO is ignored", (
      tester,
    ) async {
      await startSession(tester, const [
        ForTimeBlock(capSeconds: 600, countUp: true),
        RestBlock(seconds: 120),
      ]);
      await app.advance(tester, 10);
      TimerNotifierState timer() => app.container.read(timerNotifierProvider);
      expect(timer(), isA<TimerRunning>());
      await tester.tap(find.text('FINISH'));
      await tester.pump();
      expect(timer(), isA<TimerRunning>());
      await tester.tap(find.text('PAUSE'));
      await tester.pump();
      expect(timer(), isA<TimerRunning>());
    });

    testWidgets('a timer on its own: PAUSE right after GO pauses, as today', (
      tester,
    ) async {
      final live = LiveHarness();
      await live.pump(
        tester,
        workout: amrapWorkout(prep: 10),
        type: TimerTypes.amrap,
        device: Device.phone,
        elapsed: const Duration(seconds: 10),
      );
      expect(live.container.read(timerNotifierProvider), isA<TimerRunning>());
      await tester.tap(find.text('PAUSE'));
      await tester.pump();
      expect(live.container.read(timerNotifierProvider), isA<TimerPaused>());
    });
  });
}
