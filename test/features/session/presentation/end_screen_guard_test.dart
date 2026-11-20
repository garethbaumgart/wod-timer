// Retest fix 12 (2.6.0): on every end screen, a session's and a timer's on
// its own, AGAIN and DONE ignore taps for the first 700ms after it
// appears, so the second tap of a double tap on the last SET DONE or on
// FINISH never restarts the workout or leaves before the result is seen.
// For a timer on its own this is the release's one deliberate change.
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

  group('a session', () {
    test(
      'AGAIN right after the last SET DONE is ignored (the engine)',
      () async {
        final s = SessionHarness();
        addTearDown(s.dispose);
        await s.start(const [SetsBlock(sets: 1, restSeconds: 30)]);
        await s.advance(10);
        s.later();
        s.controller.setDone();
        await s.flush();
        expect(s.run.isFinished, isTrue);
        await s.controller.again();
        expect(s.run.isFinished, isTrue);
        s.later();
        await s.controller.again();
        expect(s.run.isFinished, isFalse);
      },
    );

    testWidgets('a double tap on the last SET DONE leaves the end screen up', (
      tester,
    ) async {
      final app = AppHarness();
      await app.pump(
        tester,
        device: Device.phone,
        location: AppRoutes.todaysWod,
      );
      await app.container
          .read(todaysWodProvider.notifier)
          .start(WodSession(const [SetsBlock(sets: 1, restSeconds: 60)]));
      app.router.go(AppRoutes.todaysWodActive);
      await tester.pumpAndSettle();
      await app.advance(tester, 10);
      app.later();
      final spot = tester.getCenter(find.text('SET DONE'));
      await tester.tapAt(spot);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      WodRun run() => app.container.read(todaysWodProvider)!;
      expect(run().isFinished, isTrue);
      await tester.tapAt(spot); // AGAIN sits where SET DONE was
      await tester.pump();
      expect(run().isFinished, isTrue);
      // DONE too, in the window.
      await tester.tap(find.text('DONE'));
      await tester.pump();
      expect(app.router.state.uri.path, AppRoutes.todaysWodActive);
      // Then both work.
      await tester.pump(const Duration(milliseconds: 700));
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(app.router.state.uri.path, AppRoutes.home);
    });
  });

  group('a timer on its own', () {
    late LiveHarness live;
    setUp(() => live = LiveHarness());

    testWidgets('a double tap on FINISH: AGAIN and DONE wait 700ms', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: forTimeWorkout(countUp: true),
        type: TimerTypes.forTime,
        device: Device.phone,
        elapsed: const Duration(seconds: 40),
      );
      final spot = tester.getCenter(find.text('FINISH'));
      await tester.tapAt(spot);
      await tester.pump(const Duration(milliseconds: 150));
      expect(live.container.read(timerNotifierProvider), isA<TimerCompleted>());
      final first = live.container.read(timerNotifierProvider);
      await tester.tap(find.text('AGAIN'));
      await tester.pump();
      expect(live.container.read(timerNotifierProvider), same(first));
      await tester.tap(find.text('DONE'));
      await tester.pump();
      expect(find.text('SETUP fortime'), findsNothing);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.tap(find.text('AGAIN'));
      await tester.pump();
      expect(
        live.container.read(timerNotifierProvider),
        isNot(isA<TimerCompleted>()),
      );
    });

    testWidgets('DONE after the window lands on setup, as before', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: emomWorkout(interval: 10, rounds: 1),
        type: TimerTypes.emom,
        device: Device.phone,
        elapsed: const Duration(seconds: 10),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(find.text('SETUP emom'), findsOneWidget);
    });
  });
}
