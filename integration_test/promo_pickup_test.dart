// Promo pickup: a believable For Time finish (~0:47). Scratch.
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'promo pickup',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('FOR TIME'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();
      await holdRealtime(tester, 12);
      await tester.tapAt(tester.getCenter(find.text('STARTS IN')));
      expect(await pumpUntil(tester, find.text('FINISH'),
          timeout: const Duration(seconds: 10)), isTrue);
      print('MARK_pickup_working');
      await holdRealtime(tester, 470); // run to ~0:47
      await tester.tap(find.text('FINISH'));
      expect(await pumpUntil(tester, find.text('Finished!'),
          timeout: const Duration(seconds: 10)), isTrue);
      print('MARK_pickup_finished');
      await holdRealtime(tester, 45);
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
      print('MARK_TOUR_DONE');
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
