// Screenshot tour for App Store / Play captures. NOT part of the normal
// suite — run on a marketing-size simulator/emulator with a watcher script
// that greps MARK_<name> lines and screenshots at each mark.
//
// Updated for the 1.1.0 UI (UX review round 1): hold-to-stop, FINISH,
// phase-coloured actives, tap-to-count AMRAP rounds.
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wod_timer/main.dart' as app;

Future<void> pumpSeconds(WidgetTester tester, double seconds) async {
  final ticks = (seconds * 10).round();
  for (var i = 0; i < ticks; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Let the UI catch up, print the mark, hold ~4s so the watcher can grab.
Future<void> hold(WidgetTester tester, String mark, {int tenths = 40}) async {
  await pumpSeconds(tester, 0.5);
  print('MARK_$mark');
  for (var i = 0; i < tenths; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
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

Future<void> goBack(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
  await tester.pumpAndSettle();
}

/// Stop is hold-to-confirm: press, hold past recognition + the 800ms fill.
Future<void> holdStop(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byIcon(Icons.stop)),
  );
  await pumpSeconds(tester, 1.8);
  await gesture.up();
}

Future<void> dismissCompletion(WidgetTester tester) async {
  expect(
    await pumpUntil(
      tester,
      find.text('DONE'),
      timeout: const Duration(seconds: 10),
    ),
    isTrue,
  );
  await tester.tap(find.text('DONE'));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'screenshot tour',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await hold(tester, 'home');

      // ---- AMRAP: setup, then mid-workout with counted rounds ----
      await tester.tap(find.text('AMRAP'));
      await tester.pumpAndSettle();
      await hold(tester, 'amrap_setup');
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();
      expect(
        await pumpUntil(
          tester,
          find.text('REMAINING'),
          timeout: const Duration(seconds: 15),
        ),
        isTrue,
      );
      await pumpSeconds(tester, 8);
      // Count a few rounds (tap-anywhere) so the shot shows the feature.
      for (var i = 0; i < 3; i++) {
        await tester.tapAt(tester.getCenter(find.text('REMAINING')));
        await pumpSeconds(tester, 0.4);
      }
      await pumpSeconds(tester, 4);
      await hold(tester, 'active_work');
      await holdStop(tester);
      await dismissCompletion(tester);

      // ---- Tabata: setup, then the blue REST phase (classic 20/10 x 8) ----
      await tester.tap(find.text('TABATA'));
      await tester.pumpAndSettle();
      await hold(tester, 'tabata_setup');
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();
      expect(
        await pumpUntil(
          tester,
          find.textContaining('·  REST'),
          timeout: const Duration(seconds: 45),
        ),
        isTrue,
      );
      await pumpSeconds(tester, 2);
      await hold(tester, 'tabata_rest', tenths: 25);
      await holdStop(tester);
      await dismissCompletion(tester);

      // ---- For Time: running with FINISH in view, then Finished! ----
      await tester.tap(find.text('FOR TIME'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();
      expect(
        await pumpUntil(
          tester,
          find.text('FINISH'),
          timeout: const Duration(seconds: 15),
        ),
        isTrue,
      );
      await pumpSeconds(tester, 30);
      await hold(tester, 'fortime_finish');
      await tester.tap(find.text('FINISH'));
      expect(
        await pumpUntil(
          tester,
          find.text('Finished!'),
          timeout: const Duration(seconds: 10),
        ),
        isTrue,
      );
      await hold(tester, 'complete');
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      print('MARK_TOUR_DONE');
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
