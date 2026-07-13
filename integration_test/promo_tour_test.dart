// Promo-video footage tour. NOT part of the normal suite — run on a
// marketing-size simulator while `xcrun simctl io <udid> recordVideo` rolls
// (see promo_video/capture.sh). Prints MARK_<name> lines for cut-finding.
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wod_timer/main.dart' as app;

Future<void> holdRealtime(WidgetTester tester, int deciseconds) async {
  for (var i = 0; i < deciseconds; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> mark(WidgetTester tester, String name) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 250));
  print('MARK_$name');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('promo tour', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await mark(tester, 'home');
    await holdRealtime(tester, 30); // linger on the hero home

    // ---- AMRAP: setup with a little picker life ----
    await tester.tap(find.text('AMRAP'));
    await tester.pumpAndSettle();
    await mark(tester, 'amrap_setup');
    await holdRealtime(tester, 12);
    // nudge the duration a couple of times so the UI feels alive
    final plus = find.byIcon(Icons.add).first;
    await tester.tap(plus);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(plus);
    await tester.pump(const Duration(milliseconds: 350));
    await holdRealtime(tester, 8);

    // ---- start: full prep countdown, GO, work ----
    await tester.tap(find.text('START WORKOUT'));
    await tester.pumpAndSettle();
    await mark(tester, 'prep');
    await holdRealtime(tester, 115); // 10s prep + 1.5s of WORK
    await mark(tester, 'working');
    await holdRealtime(tester, 80); // 8s of the big clock ticking

    // stop -> Finished!
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();
    await mark(tester, 'finished');
    await holdRealtime(tester, 30);

    // ---- Tabata: classic preset, catch a WORK->REST flip ----
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await holdRealtime(tester, 8);
    await tester.tap(find.text('TABATA'));
    await tester.pumpAndSettle();
    await mark(tester, 'tabata_setup');
    await holdRealtime(tester, 15);
    await tester.tap(find.text('START WORKOUT'));
    await tester.pumpAndSettle();
    await mark(tester, 'tabata_prep');
    // 10s prep + 20s work + a few seconds of REST on screen
    await holdRealtime(tester, 360);
    await mark(tester, 'tabata_rest_done');

    // stop cleanly (releases audio players before teardown)
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();
    await mark(tester, 'end');
  });
}
