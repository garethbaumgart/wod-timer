// App Store preview footage tour (Nov 2026). NOT part of the normal suite:
// run with `flutter drive` while `xcrun simctl io <udid> recordVideo` rolls.
//
// Six short tours, each from Home back to Home: amrap, fortime, emom,
// tabata, extras, landscape. No TOUR define runs them all in that order
// (about five minutes); `--dart-define=TOUR=tabata,emom` runs a subset, for
// a retake. (An environment variable does not reach the app through
// `flutter drive`, so the choice is compile time: a retake rebuilds.)
//
// The log carries the cut points and the sound, since a simulator recording
// has no audio:
//   MARK FLASH <ms>      a white frame, to tie the wall clock to video time
//   MARK S:<scene> <ms>  scene start, MARK E:<scene> <ms> scene end
//   MARK T:<event> <ms>  a moment inside a scene (GO, a counted round)
//   CUE <asset> <ms>     every clip the app's own AudioService chose to play
//
// Differences from a real launch, all test-only: preferences start empty
// with the voice set to Major, and the audio service is the production
// class with its test sink (AudioService.withSink), so the cue rules are the
// shipped ones and the Mac stays quiet. Touches are not marked on screen.
// Timers run in real time: nothing here may pumpAndSettle once one is live.
//
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/core/infrastructure/audio/audio_service.dart';
import 'package:wod_timer/core/presentation/theme/app_fonts.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_wheel.dart';
import 'package:wod_timer/features/timer/presentation/widgets/stopwatch_bezel.dart';
import 'package:wod_timer/injection.dart';
import 'package:wod_timer/main.dart' as app;

import 'support/preview_tour_support.dart';

const allTours = ['amrap', 'fortime', 'emom', 'tabata', 'extras', 'landscape'];

// ---------------------------------------------------------------------
// Gestures on this app's controls
// ---------------------------------------------------------------------

/// A spot on the live canvas clear of the digits, the round line and the
/// timeline: just above the slab, right of centre, where a thumb lands.
Offset canvasPoint(WidgetTester tester) {
  final slab = tester.getRect(find.byType(BottomSlab));
  return Offset(slab.width * 0.64, slab.top - 58);
}

/// Turn the stopwatch bezel from [from] to [to] minutes along the ring.
Future<void> turnBezel(
  WidgetTester tester,
  double from,
  double to, {
  required int ms,
}) async {
  final rect = tester.getRect(find.byType(StopwatchBezel));
  final radius = rect.width / 2 * (112 / 135);
  await pathDrag(
    tester,
    (t) => dialPoint(rect.center, radius, from + (to - from) * t),
    ms: ms,
  );
}

/// Spin the setup wheel under [label] by [steps] rows (positive is up the
/// values) with one slow drag, then let it snap.
Future<void> spinWheel(
  WidgetTester tester,
  String label,
  int steps, {
  int ms = 1000,
}) async {
  final wheel = find.ancestor(
    of: find.text(label),
    matching: find.byType(SetupWheel),
  );
  final rows = find.descendant(
    of: wheel,
    matching: find.byType(ListWheelScrollView),
  );
  final rect = tester.getRect(rows);
  final row = rect.height / 3;
  final sign = steps > 0 ? 1 : -1;
  // Right of the digits, where a thumb would drag a wheel.
  final start = rect.center + Offset(rect.width * 0.36, sign * row * 0.8);
  // The first 18 points only arm the scroll (touch slop).
  final travel = -(steps * row + sign * 16);
  await pathDrag(tester, (t) => start + Offset(0, travel * t), ms: ms);
  await hold(tester, 450);
}

/// HOLD TO STOP: finger down through the 0.8 s fill, up on the end screen.
Future<void> holdToStop(WidgetTester tester) async {
  final gesture = await fingerDown(
    tester,
    tester.getCenter(find.text('HOLD TO STOP')),
  );
  await waitFor(tester, find.text('DONE'), timeoutMs: 8000);
  await hold(tester, 60);
  await gesture.up();
  await tester.pump();
}

Future<void> goBack(WidgetTester tester) async {
  await press(tester, find.byIcon(Icons.arrow_back_ios_new));
  await hold(tester, 1000);
}

Future<void> doneToHome(WidgetTester tester) async {
  await press(tester, find.text('DONE'));
  await hold(tester, 1000);
  await goBack(tester);
}

/// Tap START and skip the get-ready count after [prepMs] of it.
Future<void> startAndSkip(WidgetTester tester, {int prepMs = 2400}) async {
  await press(tester, find.text('START'));
  await waitFor(tester, find.text('TAP TO SKIP'));
  await hold(tester, prepMs);
  await pressAt(tester, canvasPoint(tester));
  await waitFor(tester, find.text('PAUSE'));
}

/// A first, uncut pass through a mode so the recorded pass is not the one
/// that compiles every screen (debug builds hitch on first use).
Future<void> warmUp(WidgetTester tester, String mode) async {
  await press(tester, find.text(mode));
  await hold(tester, 1000);
  await startAndSkip(tester, prepMs: 600);
  await hold(tester, 900);
  await press(tester, find.text('PAUSE'));
  await waitFor(tester, find.text('RESUME'));
  await hold(tester, 500);
  await holdToStop(tester);
  await hold(tester, 600);
  await doneToHome(tester);
}

// ---------------------------------------------------------------------
// Tours
// ---------------------------------------------------------------------

Future<void> tourAmrap(WidgetTester tester) async {
  await warmUp(tester, 'AMRAP');

  mark('S:home');
  await hold(tester, 2800);
  mark('E:home');

  mark('S:amrap_setup');
  await hold(tester, 400);
  await press(tester, find.text('AMRAP'));
  await hold(tester, 1100);
  await turnBezel(tester, 10, 18, ms: 1500);
  await hold(tester, 500);
  expect(find.text('18:00'), findsOneWidget);
  await turnBezel(tester, 18, 10, ms: 1400);
  await hold(tester, 900);
  expect(find.text('10:00'), findsOneWidget);
  mark('E:amrap_setup');

  // The opening shot: START, the whole get-ready count, GO, three seconds.
  mark('S:prep_go_amrap');
  await hold(tester, 400);
  await press(tester, find.text('START'));
  mark('T:amrap_start');
  await waitFor(tester, find.text('PAUSE'));
  mark('T:amrap_go');
  await hold(tester, 250);
  mark('S:amrap_live');
  await hold(tester, 3000);
  mark('E:prep_go_amrap');
  for (var i = 1; i <= 3; i++) {
    await pressAt(tester, canvasPoint(tester));
    mark('T:round$i');
    await hold(tester, 1030);
  }
  await hold(tester, 2200);
  mark('E:amrap_live');

  mark('S:pause_stop_amrap');
  await hold(tester, 450);
  await press(tester, find.text('PAUSE'));
  await waitFor(tester, find.text('RESUME'));
  await hold(tester, 1900);
  await press(tester, find.text('RESUME'));
  await waitFor(tester, find.text('PAUSE'));
  await hold(tester, 2200);
  await press(tester, find.text('PAUSE'));
  await waitFor(tester, find.text('RESUME'));
  await hold(tester, 1100);
  mark('T:amrap_hold');
  await holdToStop(tester);
  await hold(tester, 2800);
  mark('E:pause_stop_amrap');
  await doneToHome(tester);
}

Future<void> tourForTime(WidgetTester tester) async {
  await warmUp(tester, 'FOR TIME');

  mark('S:fortime_setup');
  await hold(tester, 400);
  await press(tester, find.text('FOR TIME'));
  await hold(tester, 1400);
  await press(tester, find.text('COUNT DOWN'));
  await hold(tester, 1000);
  await press(tester, find.text('COUNT UP'));
  await hold(tester, 900);
  await turnBezel(tester, 20, 25, ms: 1200);
  await hold(tester, 450);
  await turnBezel(tester, 25, 20, ms: 1200);
  await hold(tester, 900);
  expect(find.text('20:00'), findsOneWidget);
  mark('E:fortime_setup');

  mark('S:fortime_run');
  await hold(tester, 400);
  await startAndSkip(tester);
  mark('T:fortime_go');
  await hold(tester, 5200);
  mark('S:fortime_finish');
  await hold(tester, 1500);
  await press(tester, find.text('FINISH'));
  mark('T:fortime_finish');
  await waitFor(tester, find.text('Finished'));
  await hold(tester, 3400);
  mark('E:fortime_run');
  mark('E:fortime_finish');
  await doneToHome(tester);
}

Future<void> tourEmom(WidgetTester tester) async {
  await warmUp(tester, 'EMOM');

  mark('S:emom_setup');
  await hold(tester, 400);
  await press(tester, find.text('EMOM'));
  await hold(tester, 1100);
  await spinWheel(tester, 'ROUNDS', 2);
  await spinWheel(tester, 'ROUNDS', -2);
  await spinWheel(tester, 'EVERY', 2);
  await spinWheel(tester, 'EVERY', -2);
  await hold(tester, 500);
  expect(find.text('10:00 total'), findsOneWidget);
  mark('E:emom_setup');

  mark('S:emom_start');
  await hold(tester, 400);
  await startAndSkip(tester);
  mark('T:emom_go');
  await hold(tester, 5500);
  mark('E:emom_start');

  // The last seconds of the first minute and the roll into round 2.
  await waitFor(tester, find.text('7'), timeoutMs: 70000);
  mark('S:emom_flip');
  await waitFor(tester, find.text('2/10'));
  mark('T:emom_round2');
  await hold(tester, 3600);
  mark('E:emom_flip');

  mark('S:pause_stop_emom');
  await hold(tester, 450);
  await press(tester, find.text('PAUSE'));
  await waitFor(tester, find.text('RESUME'));
  await hold(tester, 1700);
  mark('T:emom_hold');
  await holdToStop(tester);
  await hold(tester, 2800);
  mark('E:pause_stop_emom');
  await doneToHome(tester);
}

Future<void> tourTabata(WidgetTester tester) async {
  await warmUp(tester, 'TABATA');
  // Warm the voice sheet too: open it and pick the voice already chosen.
  await press(tester, find.text('TABATA'));
  await hold(tester, 1000);
  await press(tester, find.text('Major'));
  await hold(tester, 1000);
  await press(tester, find.text('Major (Drill Sergeant)'));
  await hold(tester, 900);
  await goBack(tester);

  mark('S:tabata_setup');
  await hold(tester, 400);
  await press(tester, find.text('TABATA'));
  await hold(tester, 1100);
  await spinWheel(tester, 'WORK', 2);
  await spinWheel(tester, 'WORK', -2);
  await spinWheel(tester, 'ROUNDS', 2);
  await spinWheel(tester, 'ROUNDS', -2);
  await hold(tester, 400);
  expect(find.text('4:00 total'), findsOneWidget);
  expect(find.text('RESET TO CLASSIC'), findsNothing);
  mark('T:tabata_voice');
  await press(tester, find.text('Major'));
  await hold(tester, 1400);
  await press(tester, find.text('Holly (Female Coach)'));
  await hold(tester, 1300);
  await press(tester, find.text('Holly'));
  await hold(tester, 1300);
  await press(tester, find.text('Major (Drill Sergeant)'));
  await hold(tester, 1200);
  mark('E:tabata_setup');

  // The second take of the opening shot, then the colour flips.
  mark('S:prep_go_tabata');
  mark('S:tabata_full');
  await hold(tester, 400);
  await press(tester, find.text('START'));
  mark('T:tabata_start');
  await waitFor(tester, find.text('PAUSE'));
  mark('T:tabata_go');
  await hold(tester, 3250);
  mark('E:prep_go_tabata');

  await waitFor(tester, find.text('6'), timeoutMs: 25000);
  mark('S:tabata_flip');
  await waitFor(tester, find.text('REST'));
  mark('T:tabata_rest');
  await waitFor(tester, find.text('2/8'));
  mark('T:tabata_work2');
  await hold(tester, 3600);
  mark('E:tabata_flip');
  mark('E:tabata_full');

  mark('S:pause_stop_tabata');
  await hold(tester, 450);
  await press(tester, find.text('PAUSE'));
  await waitFor(tester, find.text('RESUME'));
  await hold(tester, 1900);
  await press(tester, find.text('RESUME'));
  await waitFor(tester, find.text('PAUSE'));
  await hold(tester, 2200);
  await press(tester, find.text('PAUSE'));
  await waitFor(tester, find.text('RESUME'));
  await hold(tester, 1100);
  mark('T:tabata_hold');
  await holdToStop(tester);
  await hold(tester, 2800);
  mark('E:pause_stop_tabata');
  await doneToHome(tester);
}

Future<void> tourExtras(WidgetTester tester) async {
  // Warm: settings and its sheet.
  await press(tester, find.byIcon(Icons.settings_outlined));
  await hold(tester, 1000);
  await press(tester, find.text('Voice'));
  await hold(tester, 1000);
  await press(tester, find.text('Major (Drill Sergeant)'));
  await hold(tester, 900);
  await goBack(tester);

  mark('S:settings');
  await hold(tester, 400);
  await press(tester, find.byIcon(Icons.settings_outlined));
  await hold(tester, 1500);
  await press(tester, find.text('Voice'));
  await hold(tester, 1400);
  await press(tester, find.text('Liam (Male Coach)'));
  await hold(tester, 1200);
  await press(tester, find.byType(Switch));
  await hold(tester, 900);
  await press(tester, find.byType(Switch));
  await hold(tester, 900);
  await press(tester, find.text('Voice'));
  await hold(tester, 1300);
  await press(tester, find.text('Major (Drill Sergeant)'));
  await hold(tester, 1300);
  mark('E:settings');
  await goBack(tester);
}

Future<void> tourLandscape(WidgetTester tester) async {
  Future<void> setOrientation(String label) async {
    await press(tester, find.byIcon(Icons.settings_outlined));
    await hold(tester, 1000);
    await press(tester, find.text('Orientation'));
    await hold(tester, 1100);
    await press(tester, find.text(label));
    await hold(tester, 2600);
    await goBack(tester);
  }

  await setOrientation('Landscape only');
  mark('S:landscape_home');
  await hold(tester, 2200);
  mark('E:landscape_home');

  mark('S:landscape_tabata');
  await hold(tester, 400);
  await press(tester, find.text('TABATA'));
  await hold(tester, 1300);
  await press(tester, find.text('START'));
  await waitFor(tester, find.text('TAP TO SKIP'));
  await hold(tester, 6300);
  await pressAt(tester, canvasPoint(tester));
  await waitFor(tester, find.text('PAUSE'));
  mark('T:landscape_go');
  await hold(tester, 7000);
  mark('E:landscape_tabata');
  await press(tester, find.text('PAUSE'));
  await waitFor(tester, find.text('RESUME'));
  await hold(tester, 600);
  await holdToStop(tester);
  await hold(tester, 600);
  await doneToHome(tester);
  await setOrientation('Auto (follow device)');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Every frame the app schedules is drawn, not only the pumped ones: the
  // footage needs the real 60 fps, the default policy drops unpumped frames.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  // The tour's touches go in as device events (see fingerDown).
  binding.shouldPropagateDevicePointerEvents = true;

  testWidgets('preview video tour', (tester) async {
    final wanted = const String.fromEnvironment(
      'TOUR',
    ).split(',').map((t) => t.trim()).where(allTours.contains).toList();
    final tours = wanted.isEmpty ? allTours : wanted;
    print('TOURS ${tours.join(',')}');

    // main() without runApp, so the root can carry the sync flash and the
    // audio service can be the logging one.
    configureBundledFonts();
    await configureDependencies();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setInt('app_voice', VoiceOption.major.index);
    final audio = AudioService.withSink(
      (asset) async => print('CUE assets/$asset ${nowMs()}'),
    );
    await tester.pumpWidget(
      RecordingRoot(
        child: ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            audioServiceProvider.overrideWithValue(audio),
          ],
          child: const app.WodTimerApp(),
        ),
      ),
    );
    await hold(tester, 2500);
    await syncFlash(tester, 'FLASH');

    for (final tour in tours) {
      mark('TOUR:$tour');
      switch (tour) {
        case 'amrap':
          await tourAmrap(tester);
        case 'fortime':
          await tourForTime(tester);
        case 'emom':
          await tourEmom(tester);
        case 'tabata':
          await tourTabata(tester);
        case 'extras':
          await tourExtras(tester);
        case 'landscape':
          await tourLandscape(tester);
      }
    }

    await syncFlash(tester, 'FLASH_END');
    print('MARK TOUR_DONE ${nowMs()}');
  }, timeout: const Timeout(Duration(minutes: 20)));
}
