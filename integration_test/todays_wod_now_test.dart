// PROTOTYPE ONLY ("Today's WOD", 20 Nov 2026). NOT part of the normal suite.
// The "now" half of the preview captures: the app exactly as it ships, on a
// clean install, at Home, EMOM setup and a live EMOM. Prints MARK_<file>
// lines; tool/preview/capture_todays_wod.sh screenshots the simulator at
// each one.
//
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wod_timer/main.dart' as app;

import 'todays_wod_capture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("today's wod: the app as it is now", (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    await hold(tester, 'now-01-home');

    await tester.tap(find.text('EMOM'));
    await tester.pumpAndSettle();
    await hold(tester, 'now-02-emom-setup');

    // The capture machine's speakers stay quiet: the voice chip to Silent
    // (the live screen does not show the voice).
    await tester.tap(find.text('Beeps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Silent'));
    await tester.pumpAndSettle();
    await pumpSeconds(tester, 0.8);

    await tester.tap(find.text('START'));
    await tester.pump();
    expect(
      await pumpUntil(tester, find.text('2/10')),
      isTrue,
      reason: 'round 2 of the EMOM',
    );
    await pumpSeconds(tester, 2);
    await hold(tester, 'now-03-live-emom');
  });
}
