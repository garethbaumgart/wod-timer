// Today's WOD's layout rules (2.6.0): the live clock in a session is the
// single-timer clock (same size, the strip's height lower), the timeline
// sits midway between the second line's glyphs and the slab, nothing moves
// across a tick, and every screen lays out on a small phone, a phone held
// sideways, an iPad either way and at large text without overflowing.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/features/session/application/session_draft.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/widgets/session_widgets.dart';
import 'package:wod_timer/features/session/presentation/widgets/todays_wod_card.dart';
import 'package:wod_timer/features/timer/presentation/widgets/workout_timeline.dart';

import '../helpers/app_harness.dart';
import '../helpers/screen_harness.dart';

const se = Device('iPhone SE 375x667', Size(375, 667), dpr: 2);
const ipadLandscape = Device(
  'tablet 1366x1024',
  Size(1366, 1024),
  dpr: 2,
  tablet: true,
);
const devices = [
  Device.phone,
  se,
  Device.phoneLandscape,
  Device.tablet13,
  ipadLandscape,
];

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

  Future<void> startSession(
    WidgetTester tester,
    Device device, {
    List<SessionBlock> blocks = mockBlocks,
    double textScale = 1,
  }) async {
    await app.pump(
      tester,
      device: device,
      location: AppRoutes.todaysWod,
      textScale: textScale,
    );
    await controller().start(WodSession(blocks));
    app.router.go(AppRoutes.todaysWodActive);
    await tester.pumpAndSettle();
  }

  Future<void> setDone(WidgetTester tester) async {
    app.later();
    await tester.tap(find.text('SET DONE'));
    await tester.pump();
  }

  /// The live clock: the Text drawn with the clock's line height.
  Finder clockText() => find.byWidgetPredicate(
    (w) => w is Text && w.style?.height == 0.76 && w.style!.fontSize! > 60,
  );

  group('the clock in a session is the single-timer clock', () {
    for (final device in [Device.phone, se, Device.phoneLandscape]) {
      testWidgets('EMOM block vs an EMOM on its own (${device.name})', (
        tester,
      ) async {
        final live = LiveHarness();
        await live.pump(
          tester,
          workout: emomWorkout(),
          type: TimerTypes.emom,
          device: device,
          elapsed: const Duration(seconds: 4),
        );
        final alone = tester.widget<Text>(clockText());
        final aloneRect = tester.getRect(clockText());
        await tester.pumpWidget(const SizedBox());

        await startSession(
          tester,
          device,
          blocks: const [EmomBlock(intervalSeconds: 60, rounds: 10)],
        );
        await app.advance(tester, 14);
        final inSession = tester.widget<Text>(clockText());
        final sessionRect = tester.getRect(clockText());
        expect(inSession.style!.fontSize, alone.style!.fontSize);
        expect(sessionRect.height, closeTo(aloneRect.height, 0.01));
        final lower = sessionRect.top - aloneRect.top;
        if (device.size.width < device.size.height) {
          // The strip and its line in place of the 30pt above the phase
          // word: about 14pt lower, as mocked.
          expect(lower, inInclusiveRange(12, 16));
        } else {
          expect(lower, greaterThanOrEqualTo(0));
        }
      });
    }

    testWidgets('a Rest block and Sets keep one clock size across the set '
        'and its rest', (tester) async {
      await startSession(tester, Device.phone);
      await app.advance(tester, 10);
      final work = tester.widget<Text>(clockText()).style!.fontSize;
      final workRect = tester.getRect(clockText());
      await setDone(tester);
      await app.advance(tester, 1);
      expect(tester.widget<Text>(clockText()).style!.fontSize, work);
      expect(tester.getRect(clockText()).center, workRect.center);
    });
  });

  group('the timeline is centred and nothing moves across a tick', () {
    Future<void> expectCentred(WidgetTester tester, String reason) async {
      final timeline = tester.getRect(find.byType(WorkoutTimeline));
      final slab = tester.getRect(find.byType(BottomSlab));
      final shot = await paintedScreen(tester);
      final ink = lowestInkIn(
        shot,
        Rect.fromLTRB(
          timeline.left,
          tester.getRect(clockText()).bottom + 1,
          timeline.right,
          timeline.top - 1,
        ),
        tester.view.devicePixelRatio,
      );
      expect(ink, isNotNull, reason: reason);
      final above = timeline.top - ink!;
      final below = slab.top - timeline.bottom;
      expect(
        (above - below).abs(),
        lessThanOrEqualTo(1.0 + 1 / tester.view.devicePixelRatio),
        reason: '$reason: above $above below $below',
      );
    }

    Map<String, Rect> rects(WidgetTester tester) => {
      for (final (i, e) in find.byType(Text).evaluate().indexed)
        'text$i': tester.getRect(find.byWidget(e.widget)),
      'timeline': tester.getRect(find.byType(WorkoutTimeline)),
      'slab': tester.getRect(find.byType(BottomSlab)),
      'strip': tester.getRect(find.byType(SessionStrip)),
    };

    /// Layout rule 1: a tick changes only a counting text's width (it stays
    /// centred); every other box stays put.
    void expectUnmoved(Map<String, Rect> a, Map<String, Rect> b) {
      expect(b.keys, a.keys);
      for (final key in a.keys) {
        expect(b[key]!.top, closeTo(a[key]!.top, 0.01), reason: key);
        expect(b[key]!.height, closeTo(a[key]!.height, 0.01), reason: key);
        expect(b[key]!.center.dx, closeTo(a[key]!.center.dx, 0.5), reason: key);
      }
    }

    for (final device in [Device.phone, Device.phoneLandscape]) {
      testWidgets('a Rest block (${device.name})', (tester) async {
        await startSession(
          tester,
          device,
          blocks: const [
            RestBlock(seconds: 180),
            AmrapBlock(durationSeconds: 60),
          ],
        );
        await expectCentred(tester, 'rest ${device.name}');
        final before = rects(tester);
        await app.advance(tester, 1);
        expectUnmoved(before, rects(tester));
      });

      testWidgets("a set, and a set's rest (${device.name})", (tester) async {
        await startSession(tester, device);
        await app.advance(tester, 10);
        await expectCentred(tester, 'set ${device.name}');
        await setDone(tester);
        await app.advance(tester, 1);
        await expectCentred(tester, 'set rest ${device.name}');
        final before = rects(tester);
        await app.advance(tester, 1);
        expectUnmoved(before, rects(tester));
      });

      testWidgets('a timer block (${device.name})', (tester) async {
        await startSession(
          tester,
          device,
          blocks: const [
            EmomBlock(intervalSeconds: 60, rounds: 10),
            RestBlock(seconds: 60),
          ],
        );
        await app.advance(tester, 15);
        await expectCentred(tester, 'emom ${device.name}');
        final before = rects(tester);
        await app.advance(tester, 1);
        expectUnmoved(before, rects(tester));
      });
    }
  });

  group('no overflow anywhere', () {
    for (final device in devices) {
      for (final textScale in [1.0, if (device == se) 1.6]) {
        final name = '${device.name}${textScale > 1 ? ' at 1.6x' : ''}';

        testWidgets('Home, both card states ($name)', (tester) async {
          await app.pump(tester, device: device, textScale: textScale);
          expect(tester.takeException(), isNull);
          expect(find.byType(TodaysWodCard), findsOneWidget);
          await app.prefs.setString(
            SessionStore.lastSessionKey,
            SessionCodec.encode(WodSession(mockBlocks)),
          );
          app.router.go(AppRoutes.settings);
          await tester.pumpAndSettle();
          app.router.go(AppRoutes.home);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(SessionStrip), findsOneWidget);
          final card = tester.getRect(find.byType(TodaysWodCard));
          expect(card.top, greaterThanOrEqualTo(0));
        });

        for (final count in [1, 12]) {
          testWidgets('the builder with $count blocks ($name)', (tester) async {
            await app.pump(
              tester,
              device: device,
              location: AppRoutes.todaysWod,
              textScale: textScale,
            );
            app.container.read(sessionDraftProvider.notifier).open([
              for (var i = 0; i < count; i++) mockBlocks[i % mockBlocks.length],
            ], BuilderSource.home);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.text('START'), findsOneWidget);
          });
        }

        testWidgets('every live screen and the end screen ($name)', (
          tester,
        ) async {
          await startSession(
            tester,
            device,
            textScale: textScale,
            blocks: const [
              SetsBlock(sets: 2, restSeconds: 30),
              RestBlock(seconds: 15),
              TabataBlock(workSeconds: 20, restSeconds: 10, rounds: 1),
              ForTimeBlock(capSeconds: 60, countUp: false),
              EmomBlock(intervalSeconds: 15, rounds: 1),
              AmrapBlock(durationSeconds: 60),
            ],
          );
          expect(tester.takeException(), isNull, reason: 'sets get-ready');
          await app.advance(tester, 10);
          expect(tester.takeException(), isNull, reason: 'set');
          await setDone(tester);
          expect(tester.takeException(), isNull, reason: 'set rest');
          await app.advance(tester, 30);
          await setDone(tester);
          await app.advance(tester, 5);
          expect(tester.takeException(), isNull, reason: 'rest block');
          // Every screen of every block, a second at a time.
          final seen = <String>{};
          for (var i = 0; i < 400; i++) {
            final run = app.container.read(todaysWodProvider)!;
            if (run.isFinished) break;
            seen.add('${run.index} ${run.phase.name}');
            await app.advance(tester, 1);
            expect(tester.takeException(), isNull, reason: '${run.phase}');
          }
          expect(
            seen,
            containsAll(['2 timer', '3 timer', '4 timer', '5 timer']),
          );
          await tester.pumpAndSettle();
          expect(find.text('Finished'), findsOneWidget);
          expect(tester.takeException(), isNull, reason: 'end');
          final slab = tester.getRect(find.byType(BottomSlab));
          final strip = tester.getRect(find.byType(SessionStrip));
          expect(strip.bottom, lessThanOrEqualTo(slab.top));
          expect(math.max(0, strip.top), greaterThan(0));
        });
      }
    }
  });
}
