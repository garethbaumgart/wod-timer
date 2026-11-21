// Retest fix 4 (2.6.0): back (Android's button or gesture, the iOS edge
// swipe) never ends a session. It behaves as it does mid-timer; only on
// the very first get-ready does it go back to the builder, as HOLD TO STOP
// does there.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/screen_harness.dart';

void main() {
  setUpAll(loadOutfit);

  late AppHarness app;
  setUp(() => app = AppHarness());

  WodRun? run() => app.container.read(todaysWodProvider);
  TimerNotifierState timer() => app.container.read(timerNotifierProvider);

  Future<void> startSession(
    WidgetTester tester,
    List<SessionBlock> blocks,
  ) async {
    await app.pump(tester, device: Device.phone, location: AppRoutes.todaysWod);
    await app.container
        .read(todaysWodProvider.notifier)
        .start(WodSession(blocks));
    app.router.go(AppRoutes.todaysWodActive);
    await tester.pumpAndSettle();
  }

  /// Android back, and the iOS edge swipe.
  Future<void> goBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.dragFrom(const Offset(2, 400), const Offset(300, 0));
      await tester.pumpAndSettle();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  void expectStillRunning() {
    expect(run(), isNotNull);
    expect(run()!.isFinished, isFalse);
    expect(app.router.state.uri.path, AppRoutes.todaysWodActive);
  }

  testWidgets("a later timer block's get-ready: back does nothing", (
    tester,
  ) async {
    await startSession(tester, const [
      SetsBlock(sets: 1, restSeconds: 60),
      AmrapBlock(durationSeconds: 600),
      RestBlock(seconds: 60),
    ]);
    await app.advance(tester, 10);
    app.later();
    await tester.tap(find.text('SET DONE'));
    await tester.pumpAndSettle();
    expect(timer(), isA<TimerPreparing>());
    await goBack(tester);
    expectStillRunning();
    expect(run()!.index, 1);
  });

  testWidgets("a later Sets block's get-ready: back does nothing", (
    tester,
  ) async {
    await startSession(tester, const [
      RestBlock(seconds: 15),
      SetsBlock(sets: 3, restSeconds: 60),
    ]);
    await app.advance(tester, 15);
    expect(run()!.phase, WodPhase.getReady);
    await goBack(tester);
    expectStillRunning();
  });

  testWidgets('mid-block, running and in a Rest: back does nothing', (
    tester,
  ) async {
    await startSession(tester, const [
      AmrapBlock(durationSeconds: 60),
      RestBlock(seconds: 60),
    ]);
    await app.advance(tester, 20);
    expect(timer(), isA<TimerRunning>());
    await goBack(tester);
    expectStillRunning();
    await app.advance(tester, 55);
    expect(run()!.phase, WodPhase.rest);
    await goBack(tester);
    expectStillRunning();
  });

  testWidgets('the very first get-ready: back returns to the builder', (
    tester,
  ) async {
    await startSession(tester, const [AmrapBlock(durationSeconds: 60)]);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(app.router.state.uri.path, AppRoutes.todaysWod);
    expect(run(), isNull);
  });
}
