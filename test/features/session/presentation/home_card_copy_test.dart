// Retest fix 9 (2.6.0): the empty Home card's words fit on one line at
// their size on an iPhone SE, an iPhone 16 Pro and a 393dp Android phone:
// nothing ellipsized, nothing shrunk.
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/widgets/glyph_ink.dart';
import 'package:wod_timer/features/session/presentation/widgets/todays_wod_card.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/screen_harness.dart';

void main() {
  setUpAll(loadOutfit);

  for (final device in [
    const Device('iPhone SE 375x667', Size(375, 667), dpr: 2),
    const Device('Android 393x851', Size(393, 851), dpr: 2.75),
    const Device('iPhone 16 Pro 402x874', Size(402, 874)),
  ]) {
    testWidgets('every word of the empty card shows (${device.name})', (
      tester,
    ) async {
      final app = AppHarness();
      await app.pump(tester, device: device);
      final texts = find.descendant(
        of: find.byType(TodaysWodCard),
        matching: find.byType(Text),
      );
      expect(texts, findsWidgets);
      for (final element in texts.evaluate()) {
        final text = element.widget as Text;
        final data = text.data;
        if (data == null || data.isEmpty) continue;
        final paragraph = element.renderObject! as RenderParagraph;
        final natural = GlyphInk.boxWidth(
          data,
          GlyphInk.resolve(element, text.style!),
          textScaler: MediaQuery.textScalerOf(element),
        );
        expect(
          paragraph.size.width,
          greaterThanOrEqualTo(natural - 0.5),
          reason: '"$data" is cut short on ${device.name}',
        );
        expect(
          find.ancestor(
            of: find.byWidget(text),
            matching: find.byType(FittedBox),
          ),
          findsNothing,
          reason: '"$data" must not shrink',
        );
      }
      expect(find.text('CHAIN TIMERS INTO ONE SESSION'), findsOneWidget);
    });
  }
}
