// Retest fix 15 (2.6.0): the builder's title fits at the largest text
// size, and on a phone held sideways Home's "about N min" keeps a readable
// size or is left out.
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/widgets/glyph_ink.dart';
import 'package:wod_timer/features/session/application/session_draft.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/widgets/todays_wod_card.dart';

import '../helpers/app_harness.dart';
import '../helpers/screen_harness.dart';

const blocks = [
  SetsBlock(sets: 5, restSeconds: 120),
  RestBlock(seconds: 180),
  EmomBlock(intervalSeconds: 60, rounds: 10),
];

void main() {
  setUpAll(loadOutfit);

  for (final device in [
    const Device('iPhone SE 375x667', Size(375, 667), dpr: 2),
    const Device('iPhone 16 Pro 402x874', Size(402, 874)),
  ]) {
    testWidgets("the builder's title shows whole at 3.1x (${device.name})", (
      tester,
    ) async {
      final app = AppHarness();
      await app.pump(
        tester,
        device: device,
        location: AppRoutes.todaysWod,
        textScale: 3.1,
      );
      app.container
          .read(sessionDraftProvider.notifier)
          .open(blocks, BuilderSource.home);
      await tester.pumpAndSettle();
      final title = find.text("TODAY'S WOD");
      final element = title.evaluate().single;
      final text = element.widget as Text;
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: title, matching: find.byType(RichText)),
      );
      final natural = GlyphInk.boxWidth(
        text.data!,
        GlyphInk.resolve(element, text.style!),
        textScaler: MediaQuery.textScalerOf(element),
      );
      expect(paragraph.size.width, greaterThanOrEqualTo(natural - 0.5));
      expect(tester.takeException(), isNull);
    });
  }

  for (final device in [
    Device.phoneLandscape,
    const Device('iPhone 16 Pro 874x402', Size(874, 402)),
    const Device('iPhone SE 667x375', Size(667, 375), dpr: 2),
  ]) {
    for (final scale in [1.0, 1.4]) {
      testWidgets('held sideways, "about N min" is readable or left out '
          '(${device.name}, ${scale}x)', (tester) async {
        final app = AppHarness();
        await app.pump(
          tester,
          device: device,
          textScale: scale,
          stored: {
            SessionStore.lastSessionKey: SessionCodec.encode(
              WodSession(blocks),
            ),
          },
        );
        final note = find.descendant(
          of: find.byType(TodaysWodCard),
          matching: find.textContaining('min'),
        );
        if (note.evaluate().isEmpty) return;
        final shown = tester.getRect(note).height;
        final laidOut = tester.getSize(note).height;
        final size =
            (tester.widget<Text>(note).style!.fontSize!) *
            MediaQuery.textScalerOf(note.evaluate().single).scale(1) *
            shown /
            laidOut;
        expect(size, greaterThanOrEqualTo(11));
      });
    }
  }
}
