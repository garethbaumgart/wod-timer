// Store set frame 1 (23 Nov 2026): Home as a returning athlete sees it, the
// four timers under a Today's WOD card that mixes them. One still, held for
// a host-side grab:
//
//   UDID=<iphone> OUT=<dir> tool/capture_store_home.sh
//
// --dart-define=STORE_SESSION=all4 (default) chains all four timers with
// rests between; =classic is the 2.6.0 mock session (Sets, Rest, EMOM, Rest,
// AMRAP).
//
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';

import 'todays_wod_support.dart';

const _which = String.fromEnvironment('STORE_SESSION', defaultValue: 'all4');

final _sessions = {
  'all4': WodSession(const [
    EmomBlock(intervalSeconds: 60, rounds: 8),
    RestBlock(seconds: 60),
    ForTimeBlock(capSeconds: 720, countUp: true),
    RestBlock(seconds: 120),
    AmrapBlock(durationSeconds: 600),
    TabataBlock(workSeconds: 20, restSeconds: 10, rounds: 8),
  ]),
  'classic': WodSession(const [
    SetsBlock(sets: 5, restSeconds: 120),
    RestBlock(seconds: 180),
    EmomBlock(intervalSeconds: 60, rounds: 10),
    RestBlock(seconds: 120),
    AmrapBlock(durationSeconds: 720),
  ]),
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("store frame 1: home with a mixed Today's WOD", (tester) async {
    await launchApp(
      tester,
      prefs: {
        SessionStore.lastSessionKey: SessionCodec.encode(_sessions[_which]!),
      },
    );
    await pumpSeconds(tester, 1);
    await capture(tester, 'store-home-$_which');
  });
}
