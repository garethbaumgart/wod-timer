// Retest fix 5 (2.6.0): a tap acts on the phase it was made in. TAP TO
// SKIP and SET DONE are ignored for 700ms after any phase change (the
// AMRAP round tap's cooldown), so a double tap that skips a Rest never
// also skips the next get-ready, and a rest running out under a finger
// never turns its tap into a skip of what follows.
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/screen_harness.dart';
import '../../../helpers/session_harness.dart';

const sets2 = SetsBlock(sets: 2, restSeconds: 30);

void main() {
  group('the engine', () {
    late SessionHarness s;
    setUp(() => s = SessionHarness());
    tearDown(() => s.dispose());

    test(
      'a late skip after a Rest ran out does not skip the get-ready',
      () async {
        await s.start(const [RestBlock(seconds: 15), sets2]);
        await s.advance(15);
        expect(s.run.phase, WodPhase.getReady);
        s.controller.skip();
        expect(s.run.phase, WodPhase.getReady);
        await s.advance(1);
        s.controller.skip();
        expect(s.run.phase, WodPhase.setWork, reason: 'a deliberate skip');
      },
    );

    test(
      "a late skip after a set's rest ran out does not skip the set",
      () async {
        await s.start(const [sets2]);
        await s.advance(10);
        s.later();
        s.controller.setDone();
        await s.advance(30);
        expect(s.run.phase, WodPhase.setWork);
        s.controller.setDone();
        expect(s.run.set, 2);
        expect(s.run.isFinished, isFalse, reason: 'SET DONE too soon');
      },
    );

    test('SET DONE is ignored right after the get-ready ends', () async {
      await s.start(const [sets2]);
      await s.advance(10);
      expect(s.run.phase, WodPhase.setWork);
      s.controller.setDone();
      expect(s.run.phase, WodPhase.setWork);
    });
  });

  testWidgets('a double tap on a Rest skips the rest only, not the next '
      "timer's get-ready", (tester) async {
    final app = AppHarness();
    await app.pump(tester, device: Device.phone, location: AppRoutes.todaysWod);
    await app.container
        .read(todaysWodProvider.notifier)
        .start(
          WodSession(const [
            RestBlock(seconds: 120),
            AmrapBlock(durationSeconds: 600),
          ]),
        );
    app.router.go(AppRoutes.todaysWodActive);
    await tester.pumpAndSettle();
    await app.advance(tester, 5);
    final spot = tester.getCenter(find.text('1:55'));
    await tester.tapAt(spot);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    TimerNotifierState timer() => app.container.read(timerNotifierProvider);
    expect(timer(), isA<TimerPreparing>(), reason: 'the first tap skipped');
    await tester.tapAt(spot);
    await tester.pump();
    await tester.pump();
    expect(
      timer(),
      isA<TimerPreparing>(),
      reason: 'the second tap must not start the AMRAP',
    );
  });
}
