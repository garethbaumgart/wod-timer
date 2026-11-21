// Retest fix 11 (2.6.0): the largest iOS accessibility text size (about
// 3.1x). Nothing on Home's card, the builder, any session screen or the
// end screen overflows, and no line is clipped: each shows whole, at a
// size capped the way the app's other big-type screens cap theirs.
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/widgets/glyph_ink.dart';
import 'package:wod_timer/features/session/application/session_draft.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/pages/session_active_page.dart';
import 'package:wod_timer/features/session/presentation/widgets/session_end_view.dart';
import 'package:wod_timer/features/session/presentation/widgets/todays_wod_card.dart';

import '../helpers/app_harness.dart';
import '../helpers/screen_harness.dart';

const largest = 3.1;
const se = Device('iPhone SE 375x667', Size(375, 667), dpr: 2);
const iphone16Pro = Device('iPhone 16 Pro 402x874', Size(402, 874));

const blocks = [
  SetsBlock(sets: 5, restSeconds: 120),
  RestBlock(seconds: 120),
  TabataBlock(workSeconds: 20, restSeconds: 10, rounds: 1),
];

void main() {
  setUpAll(loadOutfit);

  late AppHarness app;
  setUp(() => app = AppHarness());

  /// No line under [scope] is cut short: each Text's box is as wide as its
  /// words at the size it renders (a FittedBox may scale a whole line).
  void expectWhole(WidgetTester tester, Finder scope, String where) {
    expect(tester.takeException(), isNull, reason: '$where: overflow');
    for (final element
        in find.descendant(of: scope, matching: find.byType(Text)).evaluate()) {
      final text = element.widget as Text;
      final data = text.data;
      if (data == null || data.isEmpty) continue;
      if (element.findAncestorWidgetOfExactType<FittedBox>() != null) continue;
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byWidget(text),
          matching: find.byType(RichText),
        ),
      );
      final natural = GlyphInk.boxWidth(
        data,
        GlyphInk.resolve(element, text.style ?? const TextStyle()),
        textScaler: text.textScaler ?? MediaQuery.textScalerOf(element),
      );
      expect(
        paragraph.size.width,
        greaterThanOrEqualTo(natural - 0.5),
        reason: '$where: "$data" is clipped',
      );
    }
  }

  for (final device in [se, iphone16Pro]) {
    testWidgets("Home's card, both states (${device.name})", (tester) async {
      await app.pump(tester, device: device, textScale: largest);
      expectWhole(tester, find.byType(TodaysWodCard), 'empty card');
      await app.prefs.setString(
        SessionStore.lastSessionKey,
        SessionCodec.encode(WodSession(blocks)),
      );
      // Home rebuilt by going away and back (the builder, not Settings,
      // whose own big-type layout is not this release's).
      app.router.go(AppRoutes.todaysWod);
      await tester.pumpAndSettle();
      app.router.go(AppRoutes.home);
      await tester.pumpAndSettle();
      expectWhole(tester, find.byType(TodaysWodCard), 'card');
    });

    testWidgets('the builder (${device.name})', (tester) async {
      await app.pump(
        tester,
        device: device,
        location: AppRoutes.todaysWod,
        textScale: largest,
      );
      app.container
          .read(sessionDraftProvider.notifier)
          .open(blocks, BuilderSource.home);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('every session screen and the end (${device.name})', (
      tester,
    ) async {
      await app.pump(
        tester,
        device: device,
        location: AppRoutes.todaysWod,
        textScale: largest,
      );
      await app.container
          .read(todaysWodProvider.notifier)
          .start(WodSession(blocks));
      app.router.go(AppRoutes.todaysWodActive);
      await tester.pumpAndSettle();
      final page = find.byType(SessionActivePage);
      expectWhole(tester, page, 'sets get-ready');
      await app.advance(tester, 10);
      expectWhole(tester, page, 'set');
      app.later();
      await tester.tap(find.text('SET DONE'));
      await tester.pump();
      await app.advance(tester, 2);
      expectWhole(tester, page, 'set rest');
      final controller = app.container.read(todaysWodProvider.notifier);
      for (var set = 2; set <= 5; set++) {
        controller.skip();
        await tester.pump();
        await app.advance(tester, 1);
        app.later();
        controller.setDone();
        await tester.pump();
        await app.advance(tester, 1);
      }
      expect(app.container.read(todaysWodProvider)!.phase, WodPhase.rest);
      expectWhole(tester, page, 'rest block');
      app.later();
      controller.skip();
      await tester.pump();
      await app.advance(tester, 1);
      expectWhole(tester, page, 'tabata get-ready');
      await app.advance(tester, 12);
      expectWhole(tester, page, 'tabata work');
      await app.advance(tester, 30);
      await tester.pumpAndSettle();
      expect(find.byType(SessionEndView), findsOneWidget);
      expectWhole(tester, page, 'end');
    });
  }
}
