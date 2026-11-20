// Today's WOD's ways in (2.6.0): Home's card in both states, and "+ THEN"
// on the four setup screens, upright and held sideways.
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/features/session/application/session_draft.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/widgets/session_widgets.dart';
import 'package:wod_timer/features/session/presentation/widgets/todays_wod_card.dart';

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

  List<SessionBlock> draft() =>
      app.container.read(sessionDraftProvider.notifier).blocks;

  group("Home's card", () {
    testWidgets('empty: one slim line and + NEW', (tester) async {
      await app.pump(tester, device: Device.phone);
      expect(find.text("TODAY'S WOD"), findsOneWidget);
      expect(find.text('chain timers, hands free'), findsOneWidget);
      expect(find.text('+ NEW'), findsOneWidget);
      expect(find.byType(SessionStrip), findsNothing);
      final card = tester.getRect(find.byType(TodaysWodCard));
      expect(card.height, lessThan(60));
      // The four modes keep their order under it.
      final names = ['FOR TIME', 'EMOM', 'AMRAP', 'TABATA'];
      final tops = [for (final n in names) tester.getRect(find.text(n)).top];
      expect(tops, [...tops]..sort());
      expect(tops.first, greaterThan(card.bottom));
    });

    testWidgets('+ NEW opens an empty builder with the add sheet up', (
      tester,
    ) async {
      await app.pump(tester, device: Device.phone);
      await tester.tap(find.text('+ NEW'));
      await tester.pumpAndSettle();
      expect(app.router.state.uri.path, AppRoutes.todaysWod);
      expect(find.text('Add block'), findsOneWidget);
      expect(draft(), isEmpty);
      expect(
        app.eventsNamed('session_builder_opened').single['source'],
        'home',
      );
    });

    testWidgets('with a last session: its blocks, strip and length; tapping '
        'repeats it', (tester) async {
      await app.pump(
        tester,
        device: Device.phone,
        stored: {SessionStore.lastSessionKey: SessionCodec.encode(_mock)},
      );
      expect(find.text('about 41 min'), findsOneWidget);
      expect(find.byType(SessionStrip), findsOneWidget);
      expect(find.textContaining('Sets 5', findRichText: true), findsOneWidget);
      await tester.tap(find.byType(SessionStrip));
      await tester.pumpAndSettle();
      expect(app.router.state.uri.path, AppRoutes.todaysWod);
      expect(find.text('Add block'), findsNothing);
      expect(draft(), _mock.blocks);
      expect(
        app.eventsNamed('session_builder_opened').single['source'],
        'repeat',
      );
    });

    testWidgets('an unreadable session shows the empty card, and is kept', (
      tester,
    ) async {
      await app.pump(
        tester,
        device: Device.phone,
        stored: {SessionStore.lastSessionKey: '{"v":9}'},
      );
      expect(find.text('chain timers, hands free'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(app.prefs.getString(SessionStore.lastSessionKey), '{"v":9}');
    });
  });

  group('+ THEN', () {
    for (final (route, title, kind) in [
      (TimerTypes.forTime, 'FOR TIME', BlockKind.forTime),
      (TimerTypes.emom, 'EMOM', BlockKind.emom),
      (TimerTypes.amrap, 'AMRAP', BlockKind.amrap),
      (TimerTypes.tabata, 'TABATA', BlockKind.tabata),
    ]) {
      for (final device in [Device.phone, Device.phoneLandscape]) {
        testWidgets('$title (${device.name}): starts a session with the '
            'values on screen first', (tester) async {
          await app.pump(
            tester,
            device: device,
            location: AppRoutes.timerSetupPath(route),
          );
          expect(find.text(title), findsOneWidget);
          await tester.tap(find.text('+ THEN'));
          await tester.pumpAndSettle();
          expect(app.router.state.uri.path, AppRoutes.todaysWod);
          expect(find.text('Add block'), findsOneWidget);
          expect(draft().single.kind, kind);
          expect(
            draft().single,
            app.container.read(sessionStoreProvider).lastBlockOf(kind),
          );
          expect(
            app.eventsNamed('session_builder_opened').single['source'],
            'then',
          );
        });
      }
    }

    testWidgets('sits above START, clear of the timeline', (tester) async {
      await app.pump(
        tester,
        device: Device.phone,
        location: AppRoutes.timerSetupPath(TimerTypes.emom),
      );
      final capsule = tester.getRect(find.byType(SessionCapsule));
      final start = tester.getRect(find.text('START'));
      expect(capsule.bottom, lessThan(start.top));
      expect(tester.takeException(), isNull);
    });
  });
}
