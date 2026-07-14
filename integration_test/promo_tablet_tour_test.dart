// Promo tablet footage: landscape iPad, giant wall-clock digits. Scratch
// tour for promo_video capture — run on an iPad simulator while
// `simctl io recordVideo` rolls. Restores orientation at the end.
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'promo tablet tour',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Lock landscape so the propped-tablet framing is guaranteed.
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Orientation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Landscape only'));
      await tester.pumpAndSettle();
      await holdRealtime(tester, 20);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      print('MARK_home_landscape');
      await holdRealtime(tester, 20);

      await tester.tap(find.text('AMRAP'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();
      await holdRealtime(tester, 12);
      // skip the rest of the prep — the money shot is the giant clock
      await tester.tapAt(tester.getCenter(find.text('STARTS IN')));
      expect(await pumpUntil(tester, find.text('REMAINING'),
          timeout: const Duration(seconds: 10)), isTrue);
      print('MARK_tablet_working');
      await holdRealtime(tester, 140);
      print('MARK_tablet_done');
      await holdStop(tester);
      expect(await pumpUntil(tester, find.text('DONE'),
          timeout: const Duration(seconds: 10)), isTrue);
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      // Restore orientation for whoever uses the sim next.
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Orientation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Auto (follow device)'));
      await tester.pumpAndSettle();
      await holdRealtime(tester, 15);
      print('MARK_TOUR_DONE');
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
