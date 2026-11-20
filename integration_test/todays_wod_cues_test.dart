// Today's WOD's cues on a device (2.6.0), in real time with the Major
// voice: one short session with every kind of hand-over (a Sets get-ready,
// a set's rest, the last set into a Rest block, a Rest block into a
// timer's get-ready, a timer into a Rest block, the last block's end).
// The debug build's cue log ("[wharfwod] cue ...") is the record; the
// MARK lines split it by transition.
//
//   fvm flutter test integration_test/todays_wod_cues_test.dart -d <device>
//
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/session/presentation/widgets/session_widgets.dart';

import 'todays_wod_support.dart';

final shortSession = WodSession(const [
  SetsBlock(sets: 2, restSeconds: 15),
  RestBlock(seconds: 15),
  EmomBlock(intervalSeconds: 15, rounds: 2),
  RestBlock(seconds: 15),
  AmrapBlock(durationSeconds: 60),
]);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("today's wod: every hand-over's cues", (tester) async {
    await launchApp(
      tester,
      prefs: {
        SessionStore.lastSessionKey: SessionCodec.encode(shortSession),
        'app_voice': 0,
      },
    );
    await tester.tap(find.byType(SessionStrip));
    await pumpSeconds(tester, 1);
    print('MARK_cues-start');
    await tapText(tester, 'START');
    expect(await pumpUntil(tester, () => shows('SET DONE')), isTrue);
    print('MARK_cues-set-1');
    await pumpSeconds(tester, 3);
    await tapText(tester, 'SET DONE');
    print('MARK_cues-set-rest');
    expect(await pumpUntil(tester, () => shows('2/2')), isTrue);
    print('MARK_cues-set-2');
    await pumpSeconds(tester, 3);
    await tapText(tester, 'SET DONE');
    print('MARK_cues-rest-block');
    expect(await pumpUntil(tester, () => shows('GET READY')), isTrue);
    print('MARK_cues-emom-get-ready');
    expect(await pumpUntil(tester, () => shows('NEXT · AMRAP 1:00')), isTrue);
    print('MARK_cues-rest-block-2');
    expect(await pumpUntil(tester, () => shows('GET READY')), isTrue);
    print('MARK_cues-amrap-get-ready');
    expect(await pumpUntil(tester, () => shows('Finished')), isTrue);
    await pumpSeconds(tester, 3);
    print('MARK_cues-end');
    await releaseAudio(tester);
  });
}
