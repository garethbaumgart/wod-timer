// Today's WOD, the real build on a device (2.6.0): the approved mock
// session (Sets 5, Rest 3:00, EMOM 10, Rest 2:00, AMRAP 12) actually run,
// on a clock ten times real time held still for each capture, through the
// nine screens of the mocks plus the builder and a live screen held
// sideways.
//
//   tool/capture_todays_wod.sh ios      # or ipad, android
//
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/widgets/session_widgets.dart';
import 'package:wod_timer/features/session/presentation/widgets/todays_wod_card.dart';
import 'package:wod_timer/features/timer/presentation/widgets/hold_to_stop_cell.dart';

import 'todays_wod_support.dart';

final mockSession = WodSession(const [
  SetsBlock(sets: 5, restSeconds: 120),
  RestBlock(seconds: 180),
  EmomBlock(intervalSeconds: 60, rounds: 10),
  RestBlock(seconds: 120),
  AmrapBlock(durationSeconds: 720),
]);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("today's wod: the real screens", (tester) async {
    await launchApp(
      tester,
      prefs: {SessionStore.lastSessionKey: SessionCodec.encode(mockSession)},
    );
    CaptureClock.speed = 10;
    await pumpSeconds(tester, 1);
    await capture(tester, '01-home-repeat');

    await tapText(tester, 'EMOM');
    await capture(tester, '02-setup-then');
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await pumpSeconds(tester, 1);

    // The card repeats the last session: the builder with it loaded.
    await tester.tap(find.byType(SessionStrip));
    await pumpSeconds(tester, 1);
    await capture(tester, '03-builder');

    await tapText(tester, '+ ADD BLOCK');
    await capture(tester, '04-add-block');
    await tester.tapAt(const Offset(20, 60));
    await pumpSeconds(tester, 1);

    await setOrientation(tester, landscape: true);
    await capture(tester, 'landscape-builder');
    await setOrientation(tester, landscape: false);

    await tapText(tester, 'START');
    // Sets: skip the get-ready, sets 1 and 2 and their rests.
    await tapCanvas(tester);
    for (var set = 1; set <= 2; set++) {
      await breath(tester);
      await tapText(tester, 'SET DONE');
      await breath(tester);
      await tapCanvas(tester);
    }
    await breath(tester);
    expect(shows('3/5'), isTrue);
    await capture(tester, '07-sets-work');

    await setOrientation(tester, landscape: true);
    await capture(tester, 'landscape-sets-work');
    await setOrientation(tester, landscape: false);

    await tapText(tester, 'SET DONE');
    expect(await pumpUntil(tester, () => shows('1:24')), isTrue);
    await capture(tester, '08-sets-rest');

    await tapCanvas(tester);
    for (var set = 4; set <= 5; set++) {
      await breath(tester);
      await tapText(tester, 'SET DONE');
      if (set < 5) {
        await breath(tester);
        await tapCanvas(tester);
      }
    }
    // The Rest block, skipped once it is up.
    expect(
      await pumpUntil(tester, () => shows('NEXT · EMOM 10 × 1:00')),
      isTrue,
    );
    await capture(tester, 'rest-block');
    await breath(tester);
    await tapCanvas(tester);

    // The EMOM: its own get-ready, then round 2 at 56.
    expect(await pumpUntil(tester, () => shows('2/10') && shows('56')), isTrue);
    await capture(tester, '05-live-strip');
    await setOrientation(tester, landscape: true);
    await capture(tester, 'landscape-live');
    await setOrientation(tester, landscape: false);

    // The second rest, skipped; the AMRAP's get-ready at 7.
    expect(await pumpUntil(tester, () => shows('NEXT · AMRAP 12:00')), isTrue);
    if (shows('REST')) {
      await breath(tester);
      await tapCanvas(tester);
    }
    expect(await pumpUntil(tester, () => shows('7')), isTrue);
    await capture(tester, '06-get-ready-next');

    // Seven rounds counted, then the AMRAP runs out.
    expect(
      await pumpUntil(tester, () => shows('TAP TO COUNT') || shows('0')),
      isTrue,
    );
    for (var round = 0; round < 7; round++) {
      await breath(tester);
      await tapCanvas(tester);
    }
    expect(await pumpUntil(tester, () => shows('Finished')), isTrue);
    await capture(tester, '09-end');

    // AGAIN, then HOLD TO STOP on a set: the stopped end screen.
    await tapText(tester, 'AGAIN');
    await tapCanvas(tester);
    await breath(tester);
    await tapText(tester, 'SET DONE');
    await breath(tester);
    await tapText(tester, 'PAUSE');
    await holdStop(tester, find.byType(HoldToStopCell));
    expect(shows('Stopped'), isTrue);
    await capture(tester, 'end-stopped');

    await tapText(tester, 'DONE');
    await pumpSeconds(tester, 1);
    expect(find.byType(TodaysWodCard), findsOneWidget);
    await releaseAudio(tester);
  });
}
