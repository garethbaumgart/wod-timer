// Hard rule 3 of 2.6.0 on a device: each of the four timers started the
// way it is today (Home, its setup, START) runs and ends as before. Setup,
// live and end are captured for each (single-<mode>-<screen>), the live
// EMOM at 56 in round 2, the moment origin/main's capture shows, so the
// two can be compared pixel for pixel.
//
//   tool/capture_todays_wod.sh single
//
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/features/session/presentation/widgets/todays_wod_card.dart';

import 'todays_wod_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the four timers on their own', (tester) async {
    await launchApp(tester);
    CaptureClock.speed = 10;
    await pumpSeconds(tester, 1);
    await capture(tester, 'single-home');

    for (final (mode, slug, live) in [
      ('FOR TIME', 'fortime', '0:04'),
      ('EMOM', 'emom', '56'),
      ('AMRAP', 'amrap', '9:56'),
      ('TABATA', 'tabata', '16'),
    ]) {
      await tapText(tester, mode);
      await capture(tester, 'single-$slug-setup');
      await tapText(tester, 'START');
      expect(
        await pumpUntil(
          tester,
          () => shows(live) && (slug != 'emom' || shows('2/10')),
        ),
        isTrue,
        reason: '$mode live',
      );
      await capture(tester, 'single-$slug-live');
      if (slug == 'fortime') {
        await tapText(tester, 'FINISH');
      }
      expect(
        await pumpUntil(tester, () => shows('AGAIN')),
        isTrue,
        reason: '$mode end',
      );
      await capture(tester, 'single-$slug-end');
      await tapText(tester, 'DONE');
      // DONE lands on the mode's setup, as before; back Home.
      expect(shows('START'), isTrue);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await pumpSeconds(tester, 1);
      expect(find.byType(TodaysWodCard), findsOneWidget);
    }
    await releaseAudio(tester);
  });
}
