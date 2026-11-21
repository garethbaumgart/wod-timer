// Retest round 2 (2.6.0), kept as regression tests: the tester's probes for Today's WOD's screens (temporary, not part of
// the branch): taps, back, the removed bar and UNDO in every order, and
// what the four setup screens remember.
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/features/session/application/session_draft.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/screen_harness.dart';

const sets5 = SetsBlock(sets: 5, restSeconds: 120);
const rest180 = RestBlock(seconds: 180);
const emom10 = EmomBlock(intervalSeconds: 60, rounds: 10);
const amrap12 = AmrapBlock(durationSeconds: 720);

void main() {
  setUpAll(loadOutfit);

  late AppHarness app;
  setUp(() => app = AppHarness());

  TodaysWodController controller() =>
      app.container.read(todaysWodProvider.notifier);
  WodRun? run() => app.container.read(todaysWodProvider);
  TimerNotifierState timer() => app.container.read(timerNotifierProvider);
  SessionDraft draft() => app.container.read(sessionDraftProvider.notifier);
  String path() => app.router.state.uri.path;

  Future<void> startSession(
    WidgetTester tester,
    List<SessionBlock> blocks,
  ) async {
    await app.pump(tester, device: Device.phone, location: AppRoutes.todaysWod);
    await controller().start(WodSession(blocks));
    app.router.go(AppRoutes.todaysWodActive);
    await tester.pumpAndSettle();
  }

  Future<void> pumpBuilder(
    WidgetTester tester,
    List<SessionBlock> blocks, {
    Map<String, Object> stored = const {},
  }) async {
    await app.pump(
      tester,
      device: Device.phone,
      location: AppRoutes.todaysWod,
      stored: stored,
    );
    draft().open(blocks, BuilderSource.home);
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('taps', () {
    testWidgets('double tap on a Rest: the next timer keeps its get-ready', (
      tester,
    ) async {
      await startSession(tester, const [
        RestBlock(seconds: 120),
        AmrapBlock(durationSeconds: 600),
      ]);
      await app.advance(tester, 5);
      final spot = tester.getCenter(find.text('1:55'));
      await tester.tapAt(spot);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(timer(), isA<TimerPreparing>());
      await tester.tapAt(spot);
      await tester.pump();
      await tester.pump();
      expect(timer(), isA<TimerPreparing>());
      // A deliberate later tap still skips it.
      app.later();
      await tester.tapAt(spot);
      await tester.pump();
      expect(timer(), isA<TimerRunning>());
    });

    testWidgets('double tap on the last SET DONE of the last block does not '
        'restart the session', (tester) async {
      await startSession(tester, const [SetsBlock(sets: 1, restSeconds: 60)]);
      await app.advance(tester, 10);
      app.later();
      final spot = tester.getCenter(find.text('SET DONE'));
      await tester.tapAt(spot);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(run()!.isFinished, isTrue);
      await tester.tapAt(spot); // AGAIN sits where SET DONE was
      await tester.pump();
      await tester.pump();
      expect(
        run()!.isFinished,
        isTrue,
        reason: 'the second tap of a double tap landed on AGAIN',
      );
    });

    testWidgets('double tap on FINISH before a Rest does not pause the rest', (
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
      expect(run()!.phase, WodPhase.rest);
      await tester.tapAt(spot); // PAUSE now covers the whole slab
      await tester.pump();
      await tester.pump();
      expect(
        run()!.paused,
        isFalse,
        reason: 'the second tap of a double tap paused the rest',
      );
    });

    testWidgets('double tap on SET DONE mid-block: rest starts, not paused, '
        'not skipped', (tester) async {
      await startSession(tester, const [SetsBlock(sets: 3, restSeconds: 60)]);
      await app.advance(tester, 10);
      app.later();
      final spot = tester.getCenter(find.text('SET DONE'));
      await tester.tapAt(spot);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tapAt(spot);
      await tester.pump();
      expect(run()!.phase, WodPhase.setRest);
      expect(run()!.paused, isFalse);
    });
  });

  group('back never ends a session', () {
    testWidgets('first get-ready (Sets): back to the builder, nothing kept', (
      tester,
    ) async {
      await startSession(tester, const [sets5, amrap12]);
      await back(tester);
      await tester.pumpAndSettle();
      expect(path(), AppRoutes.todaysWod);
      expect(run(), isNull);
    });

    testWidgets('first get-ready (timer): back to the builder', (tester) async {
      await startSession(tester, const [amrap12, sets5]);
      expect(timer(), isA<TimerPreparing>());
      await back(tester);
      await tester.pumpAndSettle();
      expect(path(), AppRoutes.todaysWod);
      expect(run(), isNull);
      expect(timer(), isA<TimerInitial>());
    });

    testWidgets('every later state: nothing happens', (tester) async {
      await startSession(tester, const [
        SetsBlock(sets: 2, restSeconds: 60),
        RestBlock(seconds: 30),
        AmrapBlock(durationSeconds: 60),
        SetsBlock(sets: 1, restSeconds: 60),
      ]);
      Future<void> check(String where) async {
        final before = run()!;
        await back(tester);
        final after = run();
        expect(after, isNotNull, reason: where);
        expect(after!.isFinished, isFalse, reason: where);
        expect(after.index, before.index, reason: where);
        expect(after.phase, before.phase, reason: where);
        expect(path(), AppRoutes.todaysWodActive, reason: where);
      }

      await app.advance(tester, 10);
      await check('set 1');
      app.later();
      await tester.tap(find.text('SET DONE'));
      await tester.pump();
      await check('set rest');
      app.later();
      await tester.tap(find.text('PAUSE'));
      await tester.pump();
      expect(run()!.paused, isTrue);
      await check('paused in a set rest');
      app.later();
      await tester.tap(find.text('RESUME'));
      await tester.pump();
      await app.advance(tester, 60);
      app.later();
      await tester.tap(find.text('SET DONE'));
      await tester.pump();
      expect(run()!.phase, WodPhase.rest);
      await check('Rest block');
      await app.advance(tester, 30);
      expect(timer(), isA<TimerPreparing>());
      await check('a later timer get-ready');
      await app.advance(tester, 15);
      expect(timer(), isA<TimerRunning>());
      await check('timer running');
      app.later();
      await tester.tap(find.text('PAUSE'));
      await tester.pump();
      await check('timer paused');
      app.later();
      await tester.tap(find.text('RESUME'));
      await tester.pump();
      await app.advance(tester, 60);
      expect(run()!.index, 3);
      expect(run()!.phase, WodPhase.getReady);
      await check('a later Sets get-ready');
      // Let the HOLD TO STOP hint a back gesture flashed while paused run
      // out before the test ends.
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('on the end screen back is DONE', (tester) async {
      await startSession(tester, const [SetsBlock(sets: 1, restSeconds: 60)]);
      await app.advance(tester, 10);
      app.later();
      await tester.tap(find.text('SET DONE'));
      await tester.pumpAndSettle();
      expect(run()!.isFinished, isTrue);
      await back(tester);
      await tester.pumpAndSettle();
      expect(path(), AppRoutes.home);
      expect(run(), isNull);
    });

    testWidgets('a session with a Rest first: back in the Rest does nothing', (
      tester,
    ) async {
      await startSession(tester, const [RestBlock(seconds: 60), amrap12]);
      await back(tester);
      expect(run()!.isFinished, isFalse);
      expect(path(), AppRoutes.todaysWodActive);
    });
  });

  group('the removed bar and UNDO', () {
    testWidgets('goes after four seconds; never on an edit screen, Home or a '
        'live screen', (tester) async {
      await pumpBuilder(tester, const [sets5, emom10, amrap12]);
      await tester.drag(find.text('10 × 1:00'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('EMOM REMOVED'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('EMOM REMOVED'), findsNothing);

      await tester.drag(find.text('12:00'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('AMRAP REMOVED'), findsOneWidget);
      await tester.tap(find.text('5 · REST 2:00'));
      await tester.pumpAndSettle();
      expect(find.text('REMOVE BLOCK'), findsOneWidget);
      expect(find.text('AMRAP REMOVED'), findsNothing);
      expect(find.text('UNDO'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(find.text('UNDO'), findsNothing);
      expect(draft().blocks, [sets5]);

      draft().add(rest180);
      await tester.pumpAndSettle();
      await tester.drag(find.text('3:00'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('REST REMOVED'), findsOneWidget);
      await tester.tap(find.text('START'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(path(), AppRoutes.todaysWodActive);
      expect(find.text('REST REMOVED'), findsNothing);
      expect(find.text('UNDO'), findsNothing);
    });

    testWidgets('UNDO twice never duplicates; remove two, the first is gone '
        'for good', (tester) async {
      await pumpBuilder(tester, const [sets5, emom10, amrap12]);
      await tester.drag(find.text('10 × 1:00'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      final undo = tester.getCenter(find.text('UNDO'));
      await tester.tapAt(undo);
      await tester.pump();
      await tester.tapAt(undo);
      await tester.pumpAndSettle();
      expect(draft().blocks, [sets5, emom10, amrap12]);

      await tester.drag(find.text('5 · REST 2:00'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.text('12:00'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('AMRAP REMOVED'), findsOneWidget);
      expect(find.text('SETS REMOVED'), findsNothing);
      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();
      expect(draft().blocks, [emom10, amrap12]);
    });

    testWidgets('REMOVE BLOCK on the edit screen, then reorder, then UNDO', (
      tester,
    ) async {
      await pumpBuilder(tester, const [sets5, rest180, emom10, amrap12]);
      await tester.tap(find.text('10 × 1:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('REMOVE BLOCK'));
      await tester.pumpAndSettle();
      expect(path(), AppRoutes.todaysWod);
      expect(find.text('EMOM REMOVED'), findsOneWidget);
      expect(draft().blocks, [sets5, rest180, amrap12]);
      draft().move(0, 2);
      await tester.pump();
      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();
      // A probe's record of what it saw, in the test output.
      // ignore: avoid_print
      print(
        'after reorder+undo: ${draft().blocks.map((b) => b.kind.code).toList()}',
      );
      expect(draft().blocks.length, 4);
      expect(draft().blocks.toSet(), {sets5, rest180, emom10, amrap12});
    });

    testWidgets('undo, then edit the restored block and its neighbour: each '
        'DONE lands on its own block', (tester) async {
      await pumpBuilder(tester, const [sets5, emom10, amrap12]);
      await tester.drag(find.text('5 · REST 2:00'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();
      expect(draft().blocks, [sets5, emom10, amrap12]);
      // Edit AMRAP: only the AMRAP row changes kind/values.
      await tester.tap(find.text('12:00'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(draft().blocks, [sets5, emom10, amrap12]);
      // Open EMOM, and while it is open the list changes under it.
      await tester.tap(find.text('10 × 1:00'));
      await tester.pumpAndSettle();
      draft()
        ..move(1, 0)
        ..add(rest180);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(draft().blocks, [emom10, sets5, amrap12, rest180]);
    });

    testWidgets('a block that went while its edit screen was open: DONE '
        'changes nothing, REMOVE BLOCK removes nothing else', (tester) async {
      await pumpBuilder(tester, const [sets5, emom10, amrap12]);
      await tester.tap(find.text('10 × 1:00'));
      await tester.pumpAndSettle();
      draft().removeAt(1);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(draft().blocks, [sets5, amrap12]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an UNDO from one session never lands in a new one', (
      tester,
    ) async {
      await pumpBuilder(tester, const [sets5, emom10]);
      await tester.drag(find.text('10 × 1:00'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      final undo = tester.getCenter(find.text('UNDO'));
      draft().open(const [amrap12], BuilderSource.home);
      await tester.pump();
      await tester.tapAt(undo);
      await tester.pumpAndSettle();
      expect(draft().blocks, [amrap12]);
    });

    testWidgets('twelve blocks: remove one, UNDO brings it back', (
      tester,
    ) async {
      await pumpBuilder(tester, [
        for (var i = 0; i < 12; i++) RestBlock(seconds: 15 * (i + 1)),
      ]);
      await tester.drag(find.text('0:15'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(draft().blocks.length, 11);
      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();
      expect(draft().blocks.length, 12);
      expect(draft().blocks.first, const RestBlock(seconds: 15));
    });

    testWidgets('a stale edit link goes back to the builder', (tester) async {
      await pumpBuilder(tester, const [sets5]);
      app.router.go(AppRoutes.todaysWodBlockPath(999));
      await tester.pumpAndSettle();
      expect(path(), AppRoutes.todaysWod);
    });
  });

  group('what the four setup screens remember', () {
    const setupKeys = {
      SetupMemory.amrapDurationKey: 960,
      SetupMemory.forTimeCapKey: 420,
      SetupMemory.forTimeCountUpKey: false,
      SetupMemory.emomIntervalKey: 90,
      SetupMemory.emomRoundsKey: 7,
      SetupMemory.tabataWorkKey: 30,
      SetupMemory.tabataRestKey: 15,
      SetupMemory.tabataRoundsKey: 6,
      SetupMemory.lastModeKey: 'tabata',
    };

    Map<String, Object?> setupNow() => {
      for (final k in setupKeys.keys) k: app.prefs.get(k),
    };

    testWidgets('editing, adding, + THEN and starting blocks never write a '
        'setup key', (tester) async {
      await pumpBuilder(tester, const [], stored: Map.of(setupKeys));
      final store = app.container.read(sessionStoreProvider);
      // The add sheet offers what the setup screens remember, read only.
      expect(
        store.lastBlockOf(BlockKind.amrap),
        const AmrapBlock(durationSeconds: 960),
      );
      for (final block in const <SessionBlock>[
        AmrapBlock(durationSeconds: 60),
        ForTimeBlock(capSeconds: 60, countUp: true),
        EmomBlock(intervalSeconds: 15, rounds: 2),
        TabataBlock(workSeconds: 5, restSeconds: 5, rounds: 2),
        RestBlock(seconds: 15),
        SetsBlock(sets: 2, restSeconds: 15),
      ]) {
        await store.rememberBlock(block);
        draft().add(block);
      }
      await tester.pumpAndSettle();
      expect(setupNow(), setupKeys);
      // Edit a block on its screen and DONE.
      await tester.tap(find.text('1:00').first);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(setupNow(), setupKeys);
      // START the session.
      await tester.tap(find.text('START'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(path(), AppRoutes.todaysWodActive);
      expect(setupNow(), setupKeys);
      // Run the first block (AMRAP) to its end and stop.
      await app.advance(tester, 75);
      expect(setupNow(), setupKeys);
    });

    testWidgets('+ THEN on a setup screen writes no setup key; START on it '
        'writes no block key', (tester) async {
      await app.pump(
        tester,
        device: Device.phone,
        location: '/timer/emom',
        stored: {
          ...setupKeys,
          SessionStore.emomIntervalKey: 15,
          SessionStore.emomRoundsKey: 2,
        },
      );
      expect(find.text('+ THEN'), findsOneWidget);
      await tester.tap(find.text('+ THEN'));
      await tester.pumpAndSettle();
      expect(path(), AppRoutes.todaysWod);
      expect(setupNow(), setupKeys);
      // + THEN remembered the values on screen as the EMOM block's last.
      expect(app.prefs.get(SessionStore.emomIntervalKey), 90);
      expect(app.prefs.get(SessionStore.emomRoundsKey), 7);

      await app.prefs.setInt(SessionStore.emomIntervalKey, 15);
      app.router.go('/timer/emom');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('START'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(timer(), isA<TimerPreparing>());
      expect(app.prefs.get(SessionStore.emomIntervalKey), 15);
      expect(app.prefs.get(SetupMemory.emomIntervalKey), 90);
      expect(app.prefs.get(SetupMemory.lastModeKey), 'emom');
    });
  });
}
