// Promo-video footage tour (v3). NOT part of the normal suite — run on a
// marketing-size simulator while `xcrun simctl io <udid> recordVideo` rolls.
// Prints MARK_<name> lines for cut-finding. Updated for the 1.1.0 UI:
// bare-digit prep countdown, tap-to-count AMRAP rounds, hold-to-stop,
// For Time FINISH, phase-coloured Tabata.
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
  print('MARK_$name');
}

Future<bool> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 100),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

Future<void> holdStop(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byIcon(Icons.stop)),
  );
  await holdRealtime(tester, 18);
  await gesture.up();
}

Future<void> tapCanvas(WidgetTester tester) async {
  await tester.tapAt(tester.getCenter(find.text('REMAINING')));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'promo tour',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await mark(tester, 'home');
      await holdRealtime(tester, 30); // linger on the hero home

      // ---- AMRAP: setup with a little picker life ----
      await tester.tap(find.text('AMRAP'));
      await tester.pumpAndSettle();
      await mark(tester, 'amrap_setup');
      await holdRealtime(tester, 12);
      final plus = find.byIcon(Icons.add).first;
      await tester.tap(plus);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(plus);
      await tester.pump(const Duration(milliseconds: 350));
      await holdRealtime(tester, 8);

      // ---- start: full prep countdown (bare orange digits), GO, work ----
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();
      await mark(tester, 'prep');
      expect(await pumpUntil(tester, find.text('REMAINING'),
          timeout: const Duration(seconds: 15)), isTrue);
      await mark(tester, 'working');
      await holdRealtime(tester, 20);
      // tap-to-count: three rounds, spaced so each tick reads on camera
      await tapCanvas(tester);
      await mark(tester, 'round1');
      await holdRealtime(tester, 11);
      await tapCanvas(tester);
      await mark(tester, 'round2');
      await holdRealtime(tester, 11);
      await tapCanvas(tester);
      await mark(tester, 'round3');
      await holdRealtime(tester, 40);
      await holdStop(tester);
      expect(await pumpUntil(tester, find.text('DONE'),
          timeout: const Duration(seconds: 10)), isTrue);
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      // ---- For Time: skip prep with a tap, run, FINISH celebration ----
      await tester.tap(find.text('FOR TIME'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();
      await holdRealtime(tester, 15); // let a couple of prep digits show
      // tap-to-skip the rest of the countdown
      await tester.tapAt(tester.getCenter(find.text('STARTS IN')));
      expect(await pumpUntil(tester, find.text('FINISH'),
          timeout: const Duration(seconds: 10)), isTrue);
      await mark(tester, 'fortime_working');
      await holdRealtime(tester, 62);
      await tester.tap(find.text('FINISH'));
      expect(await pumpUntil(tester, find.text('Finished!'),
          timeout: const Duration(seconds: 10)), isTrue);
      await mark(tester, 'finished');
      await holdRealtime(tester, 40);
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      // ---- Tabata: classic, catch WORK -> preview -> REST flip ----
      await tester.tap(find.text('TABATA'));
      await tester.pumpAndSettle();
      await mark(tester, 'tabata_setup');
      await holdRealtime(tester, 15);
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();
      await mark(tester, 'tabata_prep');
      // 10s prep + 20s work + a few seconds of blue REST on screen
      expect(await pumpUntil(tester, find.textContaining('·  REST'),
          timeout: const Duration(seconds: 45)), isTrue);
      await mark(tester, 'tabata_rest');
      await holdRealtime(tester, 60);
      await mark(tester, 'tabata_done');

      // stop cleanly (releases audio players before teardown)
      await holdStop(tester);
      await mark(tester, 'end');
      await holdRealtime(tester, 10);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
