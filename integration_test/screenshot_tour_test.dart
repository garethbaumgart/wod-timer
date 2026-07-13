// Screenshot tour for App Store captures. NOT part of the normal suite —
// run on a marketing-size simulator with the watcher script:
//   scripts/capture-screenshots.sh
//
// Prints MARK_<name> lines and holds each screen ~4s so the watcher can
// `simctl io screenshot` at every mark.
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wod_timer/main.dart' as app;

Future<void> hold(WidgetTester tester, String mark) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
  print('MARK_$mark');
  // Real-time hold so the watcher can grab the frame.
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await hold(tester, 'home');

    // AMRAP setup
    await tester.tap(find.text('AMRAP'));
    await tester.pumpAndSettle();
    await hold(tester, 'amrap_setup');

    // Active timer: start and let it reach WORK (10s prep + margin)
    await tester.tap(find.text('START WORKOUT'));
    await tester.pumpAndSettle();
    var reachedWork = false;
    for (var i = 0; i < 150; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.textContaining('WORK').evaluate().isNotEmpty) {
        reachedWork = true;
        break;
      }
    }
    expect(reachedWork, isTrue);
    // Let a few seconds tick so the clock looks mid-workout.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await hold(tester, 'active_work');

    // Stop cleanly (releases audio players) -> completion screen
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();
    await hold(tester, 'complete');

    // Done -> home, then Tabata setup
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TABATA'));
    await tester.pumpAndSettle();
    await hold(tester, 'tabata_setup');
  });
}
