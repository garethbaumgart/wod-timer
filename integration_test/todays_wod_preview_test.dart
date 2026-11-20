// PROTOTYPE ONLY ("Today's WOD", 20 Nov 2026). NOT part of the normal suite.
// The "proposed" half of the preview captures: the real app with the
// prototype switched on, walked through its nine screens. Everything on
// them is fixed numbers (lib/preview/todays_wod). Prints MARK_<file> lines;
// tool/preview/capture_todays_wod.sh screenshots the simulator at each one.
//
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/main.dart' as app;
import 'package:wod_timer/preview/todays_wod/todays_wod_preview.dart';

import 'todays_wod_capture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("today's wod: the proposed screens", (tester) async {
    TodaysWodPreview.enabled = true;
    await app.main();
    await tester.pumpAndSettle();

    Future<void> open(String screen, String file) async {
      GoRouter.of(
        tester.element(find.byType(Scaffold).first),
      ).go(TodaysWodPreview.path(screen));
      await tester.pumpAndSettle();
      await hold(tester, file);
    }

    await hold(tester, '01-home-repeat');

    await tester.tap(find.text('EMOM'));
    await tester.pumpAndSettle();
    await hold(tester, '02-setup-then');

    await tester.tap(find.text('+ THEN'));
    await tester.pumpAndSettle();
    await hold(tester, '03-builder');

    await tester.tap(find.text('+ ADD BLOCK'));
    await tester.pumpAndSettle();
    await hold(tester, '04-add-block');
    await tester.tap(find.text('TABATA'));
    await tester.pumpAndSettle();

    // The first live screen hides the system UI; give the home indicator
    // time to fade as it has on a running workout.
    GoRouter.of(
      tester.element(find.byType(Scaffold).first),
    ).go(TodaysWodPreview.path('live'));
    await tester.pumpAndSettle();
    await pumpSeconds(tester, 6);
    await hold(tester, '05-live-strip');
    await open('get-ready', '06-get-ready-next');
    await open('sets-work', '07-sets-work');
    await open('sets-rest', '08-sets-rest');
    await open('end', '09-end');
  });
}
