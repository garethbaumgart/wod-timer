// Today's WOD (2.6.1): what she changes in the builder is what Home's card
// shows when she goes back, and what the app opens with next time, START
// or no START. Gareth's report: repeat a session from Home, delete a few
// blocks, go back, and the card still showed every block.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/features/session/application/session_draft.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/widgets/session_widgets.dart';
import 'package:wod_timer/features/session/presentation/widgets/todays_wod_card.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/screen_harness.dart';

final _mock = WodSession(const [
  SetsBlock(sets: 5, restSeconds: 120),
  RestBlock(seconds: 180),
  EmomBlock(intervalSeconds: 60, rounds: 10),
  RestBlock(seconds: 120),
  AmrapBlock(durationSeconds: 720),
]);

void main() {
  setUpAll(loadOutfit);

  late AppHarness app;
  setUp(() => app = AppHarness());

  /// What the app would open with after a relaunch.
  WodSession? stored() =>
      SessionCodec.decode(app.prefs.getString(SessionStore.lastSessionKey));

  /// Everything Home's card says, its repeat line included.
  String cardLine(WidgetTester tester) => [
    for (final text in tester.widgetList<RichText>(
      find.descendant(
        of: find.byType(TodaysWodCard),
        matching: find.byType(RichText),
      ),
    ))
      text.text.toPlainText(),
  ].join(' | ');

  String aboutMinutes(WodSession session) =>
      'about ${session.aboutMinutes(getReadySeconds: TodaysWodController.getReadySeconds)} min';

  Future<void> homeWithMock(WidgetTester tester) => app.pump(
    tester,
    device: Device.phone,
    stored: {SessionStore.lastSessionKey: SessionCodec.encode(_mock)},
  );

  Future<void> openFromCard(WidgetTester tester) async {
    await tester.tap(find.byType(SessionStrip));
    await tester.pumpAndSettle();
    expect(app.router.state.uri.path, AppRoutes.todaysWod);
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
  }

  Future<void> swipeAway(WidgetTester tester, String detail) async {
    await tester.drag(find.text(detail), const Offset(-500, 0));
    await tester.pumpAndSettle();
  }

  group("Gareth's report", () {
    testWidgets('repeat from Home, swipe two blocks away, back: the card '
        'shows the three left, and so does the next launch', (tester) async {
      await homeWithMock(tester);
      expect(cardLine(tester), contains('EMOM 10'));
      await openFromCard(tester);
      await swipeAway(tester, '10 × 1:00');
      await swipeAway(tester, '12:00');
      await back(tester);

      expect(app.router.state.uri.path, AppRoutes.home);
      expect(cardLine(tester), isNot(contains('EMOM')));
      expect(cardLine(tester), isNot(contains('AMRAP')));
      expect(cardLine(tester), contains(aboutMinutes(stored()!)));
      expect(stored()?.blocks, const [
        SetsBlock(sets: 5, restSeconds: 120),
        RestBlock(seconds: 180),
        RestBlock(seconds: 120),
      ]);

      // And the card opens the builder on what is left.
      await openFromCard(tester);
      expect(
        app.container.read(sessionDraftProvider.notifier).blocks,
        stored()!.blocks,
      );
    });

    testWidgets('REMOVE BLOCK on its edit screen, back to Home', (
      tester,
    ) async {
      await homeWithMock(tester);
      await openFromCard(tester);
      await tester.tap(find.text('12:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('REMOVE BLOCK'));
      await tester.pumpAndSettle();
      await back(tester);
      expect(stored()?.blocks, _mock.blocks.take(4));
      expect(cardLine(tester), isNot(contains('AMRAP')));
    });
  });

  group('every builder change is kept', () {
    testWidgets('DONE on an edit screen', (tester) async {
      await homeWithMock(tester);
      await openFromCard(tester);
      await tester.tap(find.text('10 × 1:00'));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(ListWheelScrollView).last,
        const Offset(0, -96),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      await back(tester);
      expect(
        stored()?.blocks[2],
        const EmomBlock(intervalSeconds: 60, rounds: 11),
      );
      expect(cardLine(tester), contains('EMOM 11'));
    });

    testWidgets('back from an edit screen changes nothing', (tester) async {
      await homeWithMock(tester);
      await openFromCard(tester);
      await tester.tap(find.text('10 × 1:00'));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(ListWheelScrollView).last,
        const Offset(0, -96),
      );
      await tester.pumpAndSettle();
      await back(tester);
      await back(tester);
      expect(stored(), _mock);
    });

    testWidgets('UNDO puts the block back in what Home shows', (tester) async {
      await homeWithMock(tester);
      await openFromCard(tester);
      await swipeAway(tester, '10 × 1:00');
      expect(stored()?.blocks, hasLength(4));
      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();
      expect(stored(), _mock);
      await back(tester);
      expect(cardLine(tester), contains('EMOM 10'));
    });

    testWidgets('UNDO of REMOVE BLOCK puts it back too', (tester) async {
      await homeWithMock(tester);
      await openFromCard(tester);
      await tester.tap(find.text('12:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('REMOVE BLOCK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();
      expect(stored(), _mock);
    });

    testWidgets('a reorder', (tester) async {
      await homeWithMock(tester);
      await openFromCard(tester);
      final handle = find.byIcon(Icons.drag_handle).first;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 50));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 14));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      final now = app.container.read(sessionDraftProvider.notifier).blocks;
      expect(now.first, isNot(_mock.blocks.first));
      expect(stored()?.blocks, now);
    });

    testWidgets('a block added from + NEW becomes the card', (tester) async {
      await homeWithMock(tester);
      await tester.tap(find.text('+ NEW'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TABATA'));
      await tester.pumpAndSettle();
      await back(tester);
      expect(stored()?.blocks.single.kind, BlockKind.tabata);
      expect(cardLine(tester), contains('Tabata'));
    });

    testWidgets('removing every block leaves the empty card', (tester) async {
      await app.pump(
        tester,
        device: Device.phone,
        stored: {
          SessionStore.lastSessionKey: SessionCodec.encode(
            WodSession(const [RestBlock(seconds: 60)]),
          ),
        },
      );
      await tester.tap(find.byType(SessionStrip));
      await tester.pumpAndSettle();
      await swipeAway(tester, '1:00');
      await back(tester);
      expect(find.text('CHAIN TIMERS INTO ONE SESSION'), findsOneWidget);
      expect(app.prefs.containsKey(SessionStore.lastSessionKey), isFalse);
    });
  });

  group('looking is not changing', () {
    testWidgets('+ NEW, then back with nothing added, keeps the card', (
      tester,
    ) async {
      await homeWithMock(tester);
      await tester.tap(find.text('+ NEW'));
      await tester.pumpAndSettle();
      // The add sheet down, then back out of the empty builder.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await back(tester);
      expect(stored(), _mock);
      expect(cardLine(tester), contains('EMOM 10'));
    });

    testWidgets('+ THEN, then back with nothing added, keeps the card', (
      tester,
    ) async {
      await app.pump(
        tester,
        device: Device.phone,
        location: AppRoutes.timerSetupPath(TimerTypes.amrap),
        stored: {SessionStore.lastSessionKey: SessionCodec.encode(_mock)},
      );
      await tester.tap(find.text('+ THEN'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await back(tester);
      expect(stored(), _mock);
    });

    testWidgets('an unreadable session is kept until she changes one', (
      tester,
    ) async {
      await app.pump(
        tester,
        device: Device.phone,
        stored: {SessionStore.lastSessionKey: '{"v":9}'},
      );
      await tester.tap(find.text('+ NEW'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await back(tester);
      expect(app.prefs.getString(SessionStore.lastSessionKey), '{"v":9}');
    });
  });

  test('saving an edited session leaves every setup key alone', () async {
    const setupKeys = <String, Object>{
      'setup_amrap_duration_s': 720,
      'setup_fortime_cap_s': 900,
      'setup_emom_interval_s': 90,
    };
    SharedPreferences.setMockInitialValues(Map.of(setupKeys));
    final prefs = await SharedPreferences.getInstance();
    final store = SessionStore(prefs, SetupMemory(prefs));
    await store.saveBuilt(_mock);
    await store.saveBuilt(WodSession(_mock.blocks.take(2).toList()));
    await store.saveBuilt(WodSession(const []));
    for (final MapEntry(:key, :value) in setupKeys.entries) {
      expect(prefs.get(key), value, reason: key);
    }
    expect(prefs.getKeys(), setupKeys.keys.toSet());
  });
}
