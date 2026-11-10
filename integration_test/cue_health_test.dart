// The cue players on a real device or emulator (WHARFWOD-3, 10 Nov 2026):
// every clip of a workout starts inside its 2.2s hold on a cold cache, and
// the pattern that can strand Android's low-latency player (the same clip
// asked for on both players of a channel, then the first one re-pointed
// while it is still loading) never reaches the app as an error and never
// leaves the channel silent.
//
//   fvm flutter test integration_test/cue_health_test.dart -d <device>
//
// Prints are the progress log that shows up in the flutter test output.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wod_timer/core/infrastructure/audio/audio_service.dart';
import 'package:wod_timer/core/infrastructure/telemetry/telemetry.dart';

/// `--dart-define=CUE_HEALTH_LONG_WAIT=true` waits out the plugin's own
/// 30-second load timeout, to see what an unfixed build reports.
const longWait = bool.fromEnvironment('CUE_HEALTH_LONG_WAIT');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cues start on time, and a stranded player is recovered from', (
    tester,
  ) async {
    final failures = <Map<String, dynamic>>[];
    final unhandled = <Object>[];
    telemetryEnabled = true;
    debugTelemetrySend = (name, props) {
      if (name == 'cue_failed') failures.add(props);
    };
    final platformOnError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      unhandled.add(error);
      return true;
    };
    addTearDown(() {
      PlatformDispatcher.instance.onError = platformOnError;
      telemetryEnabled = false;
      debugTelemetrySend = null;
    });

    Future<void> wait(int milliseconds) => tester.runAsync(
      () => Future<void>.delayed(Duration(milliseconds: milliseconds)),
    );

    final audio = AudioService();
    await audio.preloadSounds();

    // A countdown and a round of lines, each clip for the first time.
    await audio.playGetReady();
    await wait(1200);
    for (final n in [3, 2, 1]) {
      await audio.playLowBeep(n);
      await wait(1000);
    }
    await audio.playHighBeep();
    await audio.playGo();
    await wait(1500);
    await audio.playHalfway();
    await wait(1500);
    await audio.playTenSeconds();
    await wait(1500);
    await audio.playHighBeep();
    await audio.playRest();
    await wait(1500);
    await audio.playHighBeep();
    await audio.playComplete();
    await wait(3000);
    print(
      'workout cues: ${failures.length} failed, ${unhandled.length} unhandled',
    );
    expect(failures, isEmpty, reason: 'a healthy device drops no cue');
    expect(unhandled, isEmpty);

    // The voice picker, tapped the way a thumb taps it.
    for (final pack in ['major', 'major', 'liam', 'liam', 'holly', 'major']) {
      await audio.playVoicePreview(pack);
      await wait(250);
    }
    await wait(3000);
    print(
      'picker taps: ${failures.length} failed, ${unhandled.length} unhandled',
    );
    expect(failures, isEmpty, reason: 'previews a quarter second apart play');
    expect(unhandled, isEmpty);

    // The stranding pattern, far faster than any thumb.
    for (var round = 0; round < 6; round++) {
      await audio.playVoicePreview('major');
      await audio.playVoicePreview('major');
      await audio.playVoicePreview('liam');
      await audio.playVoicePreview('holly');
      await audio.playVoicePreview('holly');
      await audio.playVoicePreview('major');
      await wait(round.isEven ? 0 : 40);
    }
    await wait(4000);
    final stranded = failures.length;
    print(
      'preview burst: $stranded failed '
      '${failures.map((f) => '${f['mode']}/${f['error']}').toList()}, '
      '${unhandled.length} unhandled',
    );
    expect(unhandled, isEmpty, reason: 'a stranded cue is handled, not thrown');

    // A player the burst stranded costs the next cue on it, once: that cue
    // is dropped at 2.2s and the player rebuilt as a standard one. Two
    // voice players, so two rounds at most.
    for (var round = 0; round < 2; round++) {
      await audio.playHighBeep();
      await audio.playGo();
      await wait(3000);
    }
    final recovered = failures.length;
    print(
      'recovery: ${recovered - stranded} failed '
      '${failures.skip(stranded).map((f) => '${f['mode']}/${f['error']}').toList()}, '
      '${unhandled.length} unhandled $unhandled',
    );
    expect(unhandled, isEmpty, reason: 'a stranded cue is handled, not thrown');

    // From here every cue plays, on both players of both channels.
    for (var round = 0; round < 2; round++) {
      await audio.playHighBeep();
      await audio.playGo();
      await wait(longWait ? 35000 : 3000);
    }
    print(
      'after recovery: ${failures.length - recovered} failed, '
      '${unhandled.length} unhandled $unhandled',
    );
    expect(failures.length, recovered, reason: 'no channel is left silent');
    expect(unhandled, isEmpty);

    await audio.dispose();
  });
}
