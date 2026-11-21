// Retest fix 10 (2.6.0): a phone held sideways. On every session screen
// the phase word, the clock and the second line keep clear space between
// their glyphs (measured from the painted ink), and the timeline keeps its
// zone; the builder shows at least three rows. A timer on its own is laid
// out exactly as before (the existing layout suites).
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/features/session/application/session_draft.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/widgets/session_widgets.dart';
import 'package:wod_timer/features/timer/presentation/widgets/workout_timeline.dart';

import '../helpers/app_harness.dart';
import '../helpers/screen_harness.dart';

const iphone16Pro = Device('iPhone 16 Pro 874x402', Size(874, 402));
const android = Device('Android 851x393', Size(851, 393), dpr: 2.75);

/// The least clear space between two lines' glyphs.
const minGap = 6.0;

void main() {
  setUpAll(loadOutfit);

  late AppHarness app;
  setUp(() => app = AppHarness());

  /// The rows of the screen (logical px, top to bottom) between [top] and
  /// [bottom] that carry ink across the middle half of the width.
  Future<List<bool>> inkRows(
    WidgetTester tester,
    double top,
    double bottom,
  ) async {
    final shot = await paintedScreen(tester);
    final dpr = tester.view.devicePixelRatio;
    const bg = AppColors.backgroundDark;
    final ref = [
      (bg.r * 255).round(),
      (bg.g * 255).round(),
      (bg.b * 255).round(),
    ];
    final px = shot.rgba;
    final x0 = (shot.width * 0.25).round();
    final x1 = (shot.width * 0.75).round();
    return [
      for (var y = (top * dpr).round(); y < (bottom * dpr).round(); y++)
        () {
          for (var x = x0; x < x1; x++) {
            final i = (y * shot.width + x) * 4;
            final d = math.max(
              (px[i] - ref[0]).abs(),
              math.max((px[i + 1] - ref[1]).abs(), (px[i + 2] - ref[2]).abs()),
            );
            // The clock's radial wash is faint; glyphs are not.
            if (d > 90) return true;
          }
          return false;
        }(),
    ];
  }

  /// Ink bands (start, end) in logical px from [top].
  Future<List<(double, double)>> bands(
    WidgetTester tester,
    double top,
    double bottom,
  ) async {
    final dpr = tester.view.devicePixelRatio;
    final rows = await inkRows(tester, top, bottom);
    final out = <(double, double)>[];
    int? start;
    for (var i = 0; i <= rows.length; i++) {
      final ink = i < rows.length && rows[i];
      if (ink && start == null) start = i;
      if (!ink && start != null) {
        out.add((top + start / dpr, top + i / dpr));
        start = null;
      }
    }
    return out;
  }

  Future<void> expectClear(WidgetTester tester, String what) async {
    final strip = tester.getRect(find.byType(SessionStrip));
    final timeline = tester.getRect(find.byType(WorkoutTimeline));
    final slab = tester.getRect(find.byType(BottomSlab));
    final found = await bands(tester, strip.bottom + 14, timeline.top);
    // Merge ink closer than a pixel (one glyph line's own gaps).
    for (var i = 1; i < found.length; i++) {
      final gap = found[i].$1 - found[i - 1].$2;
      expect(
        gap,
        greaterThanOrEqualTo(minGap),
        reason: '$what: $gap between lines at ${found[i].$1}',
      );
    }
    expect(found.isNotEmpty, isTrue);
    final above = timeline.top - found.last.$2;
    final below = slab.top - timeline.bottom;
    expect(above, greaterThanOrEqualTo(minGap), reason: '$what: timeline');
    expect(below, greaterThanOrEqualTo(minGap), reason: '$what: slab');
  }

  Future<void> start(
    WidgetTester tester,
    Device device,
    List<SessionBlock> blocks,
  ) async {
    await app.pump(tester, device: device, location: AppRoutes.todaysWod);
    await app.container
        .read(todaysWodProvider.notifier)
        .start(WodSession(blocks));
    app.router.go(AppRoutes.todaysWodActive);
    await tester.pumpAndSettle();
  }

  for (final device in [iphone16Pro, android]) {
    testWidgets('Sets, its rest, a Rest, a timer (${device.name})', (
      tester,
    ) async {
      await start(tester, device, const [
        SetsBlock(sets: 5, restSeconds: 120),
        RestBlock(seconds: 120),
        EmomBlock(intervalSeconds: 60, rounds: 10),
      ]);
      await expectClear(tester, 'sets get-ready');
      await app.advance(tester, 10);
      // Set 3 of 5, as mocked.
      for (var i = 0; i < 2; i++) {
        app.later();
        await tester.tap(find.text('SET DONE'));
        await tester.pump();
        await app.advance(tester, 1);
        app.later();
        await tester.tapAt(tester.getCenter(find.text('TAP TO SKIP')));
        await tester.pump();
        await app.advance(tester, 1);
      }
      expect(find.text('3/5'), findsOneWidget);
      await expectClear(tester, 'set');
      app.later();
      await tester.tap(find.text('SET DONE'));
      await tester.pump();
      await app.advance(tester, 36);
      await expectClear(tester, 'set rest');
      app.container.read(todaysWodProvider.notifier).skip();
      await tester.pump();
      for (var i = 0; i < 2; i++) {
        await app.advance(tester, 1);
        app.later();
        await tester.tap(find.text('SET DONE'));
        await tester.pump();
        if (i == 0) {
          await app.advance(tester, 1);
          app.later();
          await tester.tapAt(tester.getCenter(find.text('TAP TO SKIP')));
          await tester.pump();
        }
      }
      await app.advance(tester, 2);
      expect(app.container.read(todaysWodProvider)!.phase, WodPhase.rest);
      await expectClear(tester, 'rest block');
      await app.advance(tester, 118 + 14);
      expect(find.text('2/10'), findsNothing);
      await app.advance(tester, 60);
      expect(find.text('2/10'), findsOneWidget);
      await expectClear(tester, 'emom');
    });

    testWidgets('the builder shows at least three rows (${device.name})', (
      tester,
    ) async {
      await app.pump(tester, device: device, location: AppRoutes.todaysWod);
      app.container.read(sessionDraftProvider.notifier).open(const [
        SetsBlock(sets: 5, restSeconds: 120),
        RestBlock(seconds: 180),
        EmomBlock(intervalSeconds: 60, rounds: 10),
        RestBlock(seconds: 120),
        AmrapBlock(durationSeconds: 720),
      ], BuilderSource.home);
      await tester.pumpAndSettle();
      final list = tester.getRect(find.byType(ReorderableListView));
      final whole = find.byType(BlockRow).evaluate().where((e) {
        final r = tester.getRect(find.byWidget(e.widget));
        return r.top >= list.top - 0.5 && r.bottom <= list.bottom + 0.5;
      });
      expect(whole.length, greaterThanOrEqualTo(3));
      expect(find.text('START'), findsOneWidget);
      expect(find.byType(SessionStrip), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
