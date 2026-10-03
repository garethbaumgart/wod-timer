import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/core/presentation/widgets/centred_timeline.dart';
import 'package:wod_timer/core/presentation/widgets/glyph_ink.dart';

void main() {
  group('GlyphInk', () {
    test('knows which Outfit glyphs paint below the baseline', () {
      expect(GlyphInk.belowBaselineEm('1247', FontWeight.w900), 0);
      expect(GlyphInk.belowBaselineEm('TIME', FontWeight.w800), 0);
      expect(GlyphInk.belowBaselineEm('20:00', FontWeight.w900), 0.012);
      expect(GlyphInk.belowBaselineEm('2/10', FontWeight.w900), 0.07);
      expect(GlyphInk.belowBaselineEm('2/10', FontWeight.w700), 0.055);
      // Weights outside the table snap to the nearest bundled one.
      expect(GlyphInk.belowBaselineEm('g', FontWeight.w500), 0.214);
      expect(GlyphInk.belowBaselineEm('s', FontWeight.w400), 0.011);
    });

    test('the inset is the box below the baseline, less the overshoot', () {
      const style = TextStyle(
        fontSize: 100,
        fontWeight: FontWeight.w900,
        height: 1,
      );
      final box = GlyphInk.boxHeight('2', style);
      final inset = GlyphInk.bottomInset('2', style);
      final slashInset = GlyphInk.bottomInset('2/10', style);
      expect(box, 100);
      expect(inset, greaterThan(0));
      expect(inset, lessThan(box));
      expect(slashInset, closeTo(inset - 7, 0.01));
      // Large text scales the overshoot with the glyphs.
      final large = GlyphInk.bottomInset(
        '2/10',
        style,
        textScaler: const TextScaler.linear(2),
      );
      expect(large, closeTo(2 * slashInset, 0.01));
    });
  });

  group('CentredTimeline', () {
    test('puts the child midway between the glyphs above and the slab', () {
      // Glyphs end 10 above the zone; the zone is 110 tall; a 14 child.
      // Midpoint between -10 and 110 is 50, so the child spans 43..57:
      // 53 from the glyphs to its top, 53 from its bottom to the slab.
      expect(
        CentredTimeline.topFor(zoneHeight: 110, aboveInkInset: 10, height: 14),
        43,
      );
      expect(
        CentredTimeline.topFor(zoneHeight: 20, aboveInkInset: 30, height: 14),
        0,
      );
      expect(
        CentredTimeline.topFor(zoneHeight: 10, aboveInkInset: 0, height: 14),
        0,
      );
    });

    testWidgets('lays the child out at that top, full width', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              const SizedBox(height: 100),
              const Expanded(
                child: CentredTimeline(
                  aboveInkInset: 10,
                  height: 14,
                  child: ColoredBox(color: AppColors.track),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      );
      final zone = tester.getRect(find.byType(CentredTimeline));
      final child = tester.getRect(find.byType(ColoredBox));
      final above = zone.top - 10;
      expect(child.width, zone.width);
      expect(child.height, 14);
      expect(child.top - above, closeTo(zone.bottom - child.bottom, 0.01));
    });
  });

  group('BottomSlab', () {
    Future<void> pump(
      WidgetTester tester, {
      required Size size,
      double bottomInset = 0,
      List<Widget>? cells,
    }) async {
      tester.view
        ..physicalSize = size * 3
        ..devicePixelRatio = 3
        ..viewPadding = FakeViewPadding(bottom: bottomInset * 3)
        ..padding = FakeViewPadding(bottom: bottomInset * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Spacer(),
                BottomSlab(
                  cells:
                      cells ??
                      [
                        SlabCell(
                          label: 'AGAIN',
                          background: AppColors.amrapAccent,
                          foreground: Colors.black,
                          onTap: () {},
                          semanticsLabel: 'Again',
                        ),
                        SlabCell(
                          label: 'DONE',
                          background: AppColors.soft,
                          foreground: Colors.white,
                          onTap: () {},
                          semanticsLabel: 'Done',
                        ),
                      ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('is 132 tall on a phone, 96 held sideways, edge to edge', (
      tester,
    ) async {
      await pump(tester, size: const Size(390, 844));
      expect(tester.getSize(find.byType(BottomSlab)), const Size(390, 132));
      await pump(tester, size: const Size(844, 390));
      expect(tester.getSize(find.byType(BottomSlab)), const Size(844, 96));
      // A tablet lays out at 600pt shortest side: tall either way.
      await pump(tester, size: const Size(800, 600));
      expect(tester.getSize(find.byType(BottomSlab)).height, 132);
    });

    testWidgets('two cells split the width; text clears the home indicator', (
      tester,
    ) async {
      await pump(tester, size: const Size(390, 844), bottomInset: 34);
      final again = tester.getRect(find.bySemanticsLabel('Again'));
      final done = tester.getRect(find.bySemanticsLabel('Done'));
      expect(again.width, 195);
      expect(done.left, 195);
      expect(again.bottom, 844);
      final label = tester.getRect(find.text('AGAIN'));
      expect(label.bottom, lessThan(844 - 34));
      expect(label.center.dy, closeTo(844 - 34 - (132 - 34) / 2, 1));
      expect(tester.widget<Text>(find.text('AGAIN')).style!.fontSize, 26);
      expect(
        tester.widget<Text>(find.text('AGAIN')).style!.fontWeight,
        FontWeight.w900,
      );
    });
  });
}
