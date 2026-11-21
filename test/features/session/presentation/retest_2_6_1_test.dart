// 2.6.1 (independent retest of 2.6.0): a double tap on PAUSE stays
// paused, and a Sets block's edit screen draws no "pip here" ticks.
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/features/session/application/session_draft.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/timer/presentation/widgets/workout_timeline.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/screen_harness.dart';

void main() {
  setUpAll(loadOutfit);

  late AppHarness app;
  setUp(() => app = AppHarness());

  TodaysWodController controller() =>
      app.container.read(todaysWodProvider.notifier);
  WodRun run() => app.container.read(todaysWodProvider)!;

  Future<void> startSession(
    WidgetTester tester,
    List<SessionBlock> blocks,
  ) async {
    await app.pump(tester, device: Device.phone, location: AppRoutes.todaysWod);
    await controller().start(WodSession(blocks));
    app.router.go(AppRoutes.todaysWodActive);
    await tester.pumpAndSettle();
  }

  /// Two taps 120ms apart on the slab's right half: PAUSE, then the
  /// RESUME that replaces it.
  Future<void> doubleTapPause(WidgetTester tester) async {
    final pause = tester.getRect(find.text('PAUSE'));
    final spot = Offset(pause.center.dx + 60, pause.center.dy);
    await tester.tapAt(spot);
    await tester.pump(const Duration(milliseconds: 120));
    app.now = app.now.add(const Duration(milliseconds: 120));
    await tester.tapAt(spot);
    await tester.pump();
  }

  group('a double tap on PAUSE stays paused', () {
    testWidgets('in a Rest block', (tester) async {
      await startSession(tester, const [
        RestBlock(seconds: 120),
        AmrapBlock(durationSeconds: 60),
      ]);
      app.later();
      await doubleTapPause(tester);
      expect(run().paused, isTrue);
      // A deliberate RESUME after the cooldown still resumes.
      app.later();
      controller().resume();
      expect(run().paused, isFalse);
    });

    testWidgets('on a set', (tester) async {
      await startSession(tester, const [SetsBlock(sets: 3, restSeconds: 60)]);
      await app.advance(tester, 11);
      expect(run().phase, WodPhase.setWork);
      app.later();
      await doubleTapPause(tester);
      expect(run().paused, isTrue);
    });

    testWidgets("in a set's rest", (tester) async {
      await startSession(tester, const [SetsBlock(sets: 3, restSeconds: 60)]);
      await app.advance(tester, 11);
      app.later();
      controller().setDone();
      await tester.pump();
      expect(run().phase, WodPhase.setRest);
      app.later();
      await doubleTapPause(tester);
      expect(run().paused, isTrue);
    });
  });

  testWidgets("a Sets block's edit screen draws no pip ticks", (tester) async {
    await app.pump(tester, device: Device.phone, location: AppRoutes.todaysWod);
    final draft = app.container.read(sessionDraftProvider.notifier)
      ..open(const [SetsBlock(sets: 3, restSeconds: 60)], BuilderSource.home);
    await tester.pumpAndSettle();
    app.router.go(AppRoutes.todaysWodBlockPath(draft.state.first.id));
    await tester.pumpAndSettle();
    expect(
      tester.widget<WorkoutTimeline>(find.byType(WorkoutTimeline)).midTicks,
      isFalse,
    );
  });

  testWidgets('EMOM and Tabata setup screens keep their ticks', (tester) async {
    for (final route in [TimerTypes.emom, TimerTypes.tabata]) {
      await app.pump(
        tester,
        device: Device.phone,
        location: AppRoutes.timerSetupPath(route),
      );
      expect(
        tester.widget<WorkoutTimeline>(find.byType(WorkoutTimeline)).midTicks,
        isTrue,
        reason: route,
      );
    }
  });
}
