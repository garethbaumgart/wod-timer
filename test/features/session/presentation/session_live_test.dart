// Today's WOD running (2.6.0): the strip and line over every live screen,
// the get-ready naming the block, Sets (SET, 3/5, SET DONE) and its rests,
// a Rest block, the timer blocks as the timer's own screen, and the end
// screen in both forms.
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/widgets/session_widgets.dart';
import 'package:wod_timer/features/timer/presentation/widgets/end_fact_tiles.dart';
import 'package:wod_timer/features/timer/presentation/widgets/hold_to_stop_cell.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/screen_harness.dart';

const mockBlocks = [
  SetsBlock(sets: 5, restSeconds: 120),
  RestBlock(seconds: 180),
  EmomBlock(intervalSeconds: 60, rounds: 10),
  RestBlock(seconds: 120),
  AmrapBlock(durationSeconds: 720),
];

void main() {
  setUpAll(loadOutfit);

  late AppHarness app;
  setUp(() => app = AppHarness());

  TodaysWodController controller() =>
      app.container.read(todaysWodProvider.notifier);
  WodRun run() => app.container.read(todaysWodProvider)!;

  Future<void> startSession(
    WidgetTester tester, {
    List<SessionBlock> blocks = mockBlocks,
    Device device = Device.phone,
  }) async {
    await app.pump(tester, device: device, location: AppRoutes.todaysWod);
    await controller().start(WodSession(blocks));
    app.router.go(AppRoutes.todaysWodActive);
    await tester.pumpAndSettle();
  }

  /// Holds the stop cell down for its full duration.
  Future<void> holdStop(WidgetTester tester) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(HoldToStopCell)),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  /// Taps SET DONE (past the tap cooldown).
  Future<void> setDone(WidgetTester tester) async {
    app.later();
    await tester.tap(find.text('SET DONE'));
    await tester.pump();
  }

  testWidgets("a Sets block's get-ready names it; the line offers the skip", (
    tester,
  ) async {
    await startSession(tester);
    expect(find.byType(SessionStrip), findsOneWidget);
    expect(find.text('BLOCK 1 OF 5 · TAP TO SKIP'), findsOneWidget);
    expect(find.text('GET READY'), findsOneWidget);
    expect(find.text('NEXT · SETS 5'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.byType(HoldToStopCell), findsOneWidget);
    expect(find.text('PAUSE'), findsNothing);
  });

  testWidgets('Sets: SET over 1/5 in amber, THEN REST, SET DONE beside '
      'PAUSE; its rest counts down pink', (tester) async {
    await startSession(tester);
    await app.advance(tester, 10);
    expect(find.text('SET'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('THEN REST 2:00'), findsOneWidget);
    expect(find.text('BLOCK 1 OF 5 · NEXT REST 3:00'), findsOneWidget);
    expect(find.text('SET DONE'), findsOneWidget);
    expect(find.text('PAUSE'), findsOneWidget);

    await setDone(tester);
    await app.advance(tester, 36);
    expect(find.text('REST · SET 2 NEXT'), findsOneWidget);
    expect(find.text('1:24'), findsOneWidget);
    expect(find.text('TAP TO SKIP'), findsOneWidget);
    expect(find.text('SET DONE'), findsNothing);

    // Tap to skip the rest: set 2.
    app.later();
    await tester.tapAt(tester.getCenter(find.text('1:24')));
    await tester.pump();
    expect(find.text('2/5'), findsOneWidget);
  });

  testWidgets('the last set says so', (tester) async {
    await startSession(
      tester,
      blocks: const [
        SetsBlock(sets: 1, restSeconds: 60),
        RestBlock(seconds: 60),
      ],
    );
    await app.advance(tester, 10);
    expect(find.text('LAST SET'), findsOneWidget);
  });

  testWidgets('a Rest block: pink countdown, the next block named, skip', (
    tester,
  ) async {
    await startSession(
      tester,
      blocks: const [
        RestBlock(seconds: 180),
        EmomBlock(intervalSeconds: 60, rounds: 10),
      ],
    );
    expect(find.text('REST'), findsOneWidget);
    expect(find.text('3:00'), findsOneWidget);
    expect(find.text('NEXT · EMOM 10 × 1:00'), findsOneWidget);
    expect(find.text('BLOCK 1 OF 2 · TAP TO SKIP'), findsOneWidget);
    await app.advance(tester, 5);
    expect(find.text('2:55'), findsOneWidget);
    app.later();
    await tester.tapAt(tester.getCenter(find.text('2:55')));
    await tester.pumpAndSettle();
    expect(run().phase, WodPhase.timer);
    expect(find.text('GET READY'), findsOneWidget);
  });

  testWidgets("a timer block: the timer's own screen under the strip; its "
      'get-ready names it', (tester) async {
    await startSession(
      tester,
      blocks: const [
        EmomBlock(intervalSeconds: 60, rounds: 10),
        RestBlock(seconds: 120),
      ],
    );
    expect(find.text('BLOCK 1 OF 2 · TAP TO SKIP'), findsOneWidget);
    expect(find.text('NEXT · EMOM 10 × 1:00'), findsOneWidget);
    expect(find.text('TAP TO SKIP'), findsNothing);
    await app.advance(tester, 14);
    expect(find.text('BLOCK 1 OF 2 · NEXT REST 2:00'), findsOneWidget);
    expect(find.text('56'), findsOneWidget);
    expect(find.text('1/10'), findsOneWidget);
    expect(find.text('PAUSE'), findsOneWidget);
  });

  testWidgets('the last block names no next block', (tester) async {
    await startSession(
      tester,
      blocks: const [AmrapBlock(durationSeconds: 600)],
    );
    await app.advance(tester, 12);
    expect(find.text('BLOCK 1 OF 1'), findsOneWidget);
  });

  testWidgets('pause in a rest: PAUSED, HOLD TO STOP and RESUME; tap resumes', (
    tester,
  ) async {
    await startSession(
      tester,
      blocks: const [RestBlock(seconds: 120), AmrapBlock(durationSeconds: 60)],
    );
    app.later();
    await tester.tap(find.text('PAUSE'));
    await tester.pump();
    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('RESUME'), findsOneWidget);
    expect(find.byType(HoldToStopCell), findsOneWidget);
    await tester.tapAt(tester.getCenter(find.text('2:00')));
    await tester.pump();
    expect(find.text('PAUSED'), findsNothing);
    expect(run().paused, isFalse);
  });

  testWidgets('HOLD TO STOP in the first get-ready goes back to the builder', (
    tester,
  ) async {
    await startSession(tester);
    await holdStop(tester);
    expect(app.router.state.uri.path, AppRoutes.todaysWod);
    expect(app.container.read(todaysWodProvider), isNull);
  });

  group('the end screen', () {
    testWidgets('finished: the time, a tile per scored block, the strip, '
        'AGAIN | DONE', (tester) async {
      await startSession(
        tester,
        blocks: const [
          SetsBlock(sets: 1, restSeconds: 60),
          RestBlock(seconds: 15),
          ForTimeBlock(capSeconds: 120, countUp: true),
          EmomBlock(intervalSeconds: 15, rounds: 2),
          AmrapBlock(durationSeconds: 60),
        ],
      );
      await app.advance(tester, 10);
      await setDone(tester);
      await app.advance(tester, 15);
      await app.advance(tester, 30);
      app.later();
      await tester.tap(find.text('FINISH'));
      await tester.pumpAndSettle();
      await app.advance(tester, 41);
      await app.advance(tester, 71);
      await tester.pumpAndSettle();
      expect(run().isFinished, isTrue);
      expect(find.text('Finished'), findsOneWidget);
      expect(find.text("TODAY'S WOD  ·  5 BLOCKS"), findsOneWidget);
      expect(find.text('TIME'), findsOneWidget);
      expect(find.text('AGAIN'), findsOneWidget);
      expect(find.text('DONE'), findsOneWidget);
      expect(find.text('0:20'), findsOneWidget, reason: 'FOR TIME result');
      expect(find.byType(SessionStrip), findsOneWidget);
      // SETS, FOR TIME, EMOM, AMRAP: two rows, the rest has none.
      expect(find.text('2'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The end screen ignores taps for its first 700ms (retest fix 12).
      await tester.pump(const Duration(milliseconds: 700));
      app.later();
      await tester.tap(find.text('AGAIN'));
      await tester.pumpAndSettle();
      expect(run().isFinished, isFalse);
      expect(find.text('GET READY'), findsOneWidget);
    });

    testWidgets('stopped: says so, shows only what was completed; DONE goes '
        'Home', (tester) async {
      await startSession(
        tester,
        blocks: const [
          SetsBlock(sets: 1, restSeconds: 60),
          AmrapBlock(durationSeconds: 600),
        ],
      );
      await app.advance(tester, 10);
      await setDone(tester);
      await app.advance(tester, 20);
      app.later();
      await tester.tap(find.text('PAUSE'));
      await tester.pump();
      await holdStop(tester);
      expect(find.text('Stopped'), findsOneWidget);
      expect(find.byType(EndFactTiles), findsNothing);
      expect(find.text('SETS'), findsOneWidget);
      expect(find.textContaining('AMRAP', findRichText: true), findsNothing);
      // The end screen ignores taps for its first 700ms (retest fix 12).
      await tester.pump(const Duration(milliseconds: 700));
      app.later();
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(app.router.state.uri.path, AppRoutes.home);
      expect(app.container.read(todaysWodProvider), isNull);
    });
  });
}
