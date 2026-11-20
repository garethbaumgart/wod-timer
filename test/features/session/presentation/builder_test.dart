// Today's WOD's builder (2.6.0): rows, the add sheet with each kind's last
// values, editing a block on its setup screen (DONE, REMOVE BLOCK), swipe
// to remove with UNDO, drag to reorder, the strip and START.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/features/session/application/session_draft.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/widgets/session_widgets.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_wheel.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/screen_harness.dart';

const _blocks = [
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

  SessionDraft draft() => app.container.read(sessionDraftProvider.notifier);

  Future<void> pumpBuilder(
    WidgetTester tester, {
    List<SessionBlock> blocks = _blocks,
    Device device = Device.phone,
  }) async {
    await app.pump(tester, device: device, location: AppRoutes.todaysWod);
    draft().open(blocks, BuilderSource.home);
    await tester.pumpAndSettle();
  }

  testWidgets('the mock session: rows, strip, START with about 41 min', (
    tester,
  ) async {
    await pumpBuilder(tester);
    expect(find.byType(BlockRow), findsNWidgets(5));
    expect(find.text('5 · REST 2:00'), findsOneWidget);
    expect(find.text('10 × 1:00'), findsOneWidget);
    expect(find.text('REST'), findsNWidgets(2));
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(5));
    expect(find.byType(SessionStrip), findsOneWidget);
    expect(find.text('About 41 min'), findsOneWidget);
    expect(find.text('+ ADD BLOCK'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('START is disabled with no blocks', (tester) async {
    await pumpBuilder(tester, blocks: const []);
    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();
    expect(app.container.read(todaysWodProvider), isNull);
    expect(app.prefs.getString(SessionStore.lastSessionKey), isNull);
    expect(find.byType(SessionStrip), findsNothing);
  });

  testWidgets('START saves the session as the last one and starts it', (
    tester,
  ) async {
    await pumpBuilder(tester);
    // SetupScaffold's guard against a double tap carried over from DONE.
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.pump();
    expect(
      app.container.read(sessionStoreProvider).lastSession?.blocks,
      _blocks,
    );
    expect(app.container.read(todaysWodProvider)?.phase, WodPhase.getReady);
    expect(app.eventsNamed('session_started').single['blocks'], 5);
    app.container.read(todaysWodProvider.notifier).exit();
  });

  testWidgets('the add sheet: six kinds with their last values; one tap adds', (
    tester,
  ) async {
    await pumpBuilder(tester, blocks: const [AmrapBlock(durationSeconds: 60)]);
    await app.container
        .read(sessionStoreProvider)
        .rememberBlock(const SetsBlock(sets: 3, restSeconds: 90));
    await tester.tap(find.text('+ ADD BLOCK'));
    await tester.pumpAndSettle();
    expect(find.text('Add block'), findsOneWidget);
    for (final label in ['FOR TIME', 'EMOM', 'TABATA', 'SETS']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.text('3 · REST 1:30'), findsOneWidget);
    expect(find.text('CAP 20:00 · UP'), findsOneWidget);
    expect(find.text('8 × 20s / 10s'), findsOneWidget);
    await tester.tap(find.text('3 · REST 1:30'));
    await tester.pumpAndSettle();
    expect(find.text('Add block'), findsNothing);
    expect(draft().blocks.last, const SetsBlock(sets: 3, restSeconds: 90));
  });

  testWidgets('twelve blocks: no more to add, nothing overflows', (
    tester,
  ) async {
    await pumpBuilder(
      tester,
      blocks: List.filled(12, const RestBlock(seconds: 60)),
    );
    expect(find.text('+ ADD BLOCK'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(find.text('About 12 min'), findsOneWidget);
  });

  group('editing a block', () {
    testWidgets('tap a row: its setup screen with its values, DONE keeps a '
        'change', (tester) async {
      await pumpBuilder(tester);
      await tester.tap(find.text('10 × 1:00'));
      await tester.pumpAndSettle();
      expect(app.router.state.uri.path, AppRoutes.todaysWodBlockPath(2));
      expect(find.text('EMOM'), findsOneWidget);
      expect(find.text('DONE'), findsOneWidget);
      expect(find.text('REMOVE BLOCK'), findsOneWidget);
      expect(find.text('+ THEN'), findsNothing);
      expect(find.byType(SetupWheel), findsNWidgets(2));
      // One round more on the ROUNDS wheel.
      final rounds = find.byType(ListWheelScrollView).last;
      await tester.drag(rounds, const Offset(0, -96));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      expect(app.router.state.uri.path, AppRoutes.todaysWod);
      expect(
        draft().blocks[2],
        const EmomBlock(intervalSeconds: 60, rounds: 11),
      );
    });

    testWidgets('a Rest: one duration wheel', (tester) async {
      await pumpBuilder(tester);
      await tester.tap(find.text('3:00'));
      await tester.pumpAndSettle();
      expect(find.byType(SetupWheel), findsOneWidget);
      expect(find.text('REST'), findsWidgets);
      // Back leaves it as it was.
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();
      expect(draft().blocks, _blocks);
    });

    testWidgets('Sets: a count wheel and a rest wheel', (tester) async {
      await pumpBuilder(tester);
      await tester.tap(find.text('5 · REST 2:00'));
      await tester.pumpAndSettle();
      expect(find.text('SETS'), findsWidgets);
      expect(find.byType(SetupWheel), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('REMOVE BLOCK, then UNDO puts it back', (tester) async {
      await pumpBuilder(tester);
      await tester.tap(find.text('12:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('REMOVE BLOCK'));
      await tester.pumpAndSettle();
      expect(draft().blocks, _blocks.take(4));
      expect(find.text('AMRAP REMOVED'), findsOneWidget);
      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();
      expect(draft().blocks, _blocks);
    });
  });

  testWidgets('swipe a row away, then UNDO', (tester) async {
    await pumpBuilder(tester);
    await tester.drag(find.text('10 × 1:00'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(draft().blocks.map((b) => b.kind), [
      BlockKind.sets,
      BlockKind.rest,
      BlockKind.rest,
      BlockKind.amrap,
    ]);
    expect(find.text('EMOM REMOVED'), findsOneWidget);
    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();
    expect(draft().blocks, _blocks);
  });

  testWidgets('drag a handle to reorder', (tester) async {
    await pumpBuilder(tester);
    final handle = find.byIcon(Icons.drag_handle).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 50));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, 14));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(draft().blocks.first, isNot(_blocks.first));
    expect(draft().blocks.toSet(), _blocks.toSet());
  });
}
