// UX-review capture tour. NOT part of the normal suite — throwaway harness
// for the multi-model UX review (see <app>/ux-review/). Drives the real app
// through every screen and state, printing MARK_<name> lines; a watcher
// script screenshots the simulator at each mark.
//
//   scripts/capture-ux-review.sh   (scratch, not committed)
//
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wod_timer/main.dart' as app;

/// Let the UI catch up, print the mark, then hold ~4s real time so the
/// watcher can grab. No pumpAndSettle: perpetually-animating states (the
/// paused pulse) would never settle.
Future<void> hold(WidgetTester tester, String mark, {int tenths = 40}) async {
  await pumpSeconds(tester, 0.5);
  print('MARK_$mark');
  for (var i = 0; i < tenths; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Print the mark immediately (no settle) and hold briefly — for states that
/// only exist for a second or two (countdown pulse, phase previews).
Future<void> quickMark(WidgetTester tester, String mark, {int tenths = 18}) async {
  print('MARK_$mark');
  for (var i = 0; i < tenths; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Pump real time until [finder] matches (or timeout). Returns success.
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

/// Pump [seconds] of real time.
Future<void> pumpSeconds(WidgetTester tester, double seconds) async {
  final ticks = (seconds * 10).round();
  for (var i = 0; i < ticks; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> goBack(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
  await tester.pumpAndSettle();
}

/// The active page has an ancestor GestureDetector with onDoubleTap, so a
/// single tap on its buttons only resolves after the double-tap window
/// (~300ms). Always wait for the expected next state instead of settling.
Future<void> holdStop(WidgetTester tester) async {
  final gesture =
      await tester.startGesture(tester.getCenter(find.byIcon(Icons.stop)));
  await pumpSeconds(tester, 1.8);
  await gesture.up();
}

Future<void> stopAndFinish(WidgetTester tester, {String? completeMark}) async {
  await holdStop(tester);
  expect(
    await pumpUntil(tester, find.text('DONE'),
        timeout: const Duration(seconds: 10)),
    isTrue,
    reason: 'completion screen after Stop',
  );
  if (completeMark != null) {
    await hold(tester, completeMark);
  }
  await tester.tap(find.text('DONE'));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'ux review tour',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // ---------- 1. Home ----------
      await hold(tester, 'home');

      // ---------- 2. AMRAP setup ----------
      await tester.tap(find.text('AMRAP'));
      await tester.pumpAndSettle();
      await hold(tester, 'amrap_setup');
      await goBack(tester);

      // ---------- 3+4. For Time setup (count up default, then count down) --
      await tester.tap(find.text('FOR TIME'));
      await tester.pumpAndSettle();
      await hold(tester, 'fortime_setup');
      await tester.tap(find.text('COUNT DOWN'));
      await tester.pumpAndSettle();
      await hold(tester, 'fortime_setup_countdown');
      await tester.tap(find.text('COUNT UP'));
      await tester.pumpAndSettle();
      await goBack(tester);

      // ---------- 5. EMOM setup ----------
      await tester.tap(find.text('EMOM'));
      await tester.pumpAndSettle();
      await hold(tester, 'emom_setup');
      await goBack(tester);

      // ---------- 6. Tabata setup ----------
      await tester.tap(find.text('TABATA'));
      await tester.pumpAndSettle();
      await hold(tester, 'tabata_setup');
      await goBack(tester);

      // ---------- 7-9. Settings + pickers ----------
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await hold(tester, 'settings');

      await tester.tap(find.text('Voice'));
      await tester.pumpAndSettle();
      await hold(tester, 'settings_voice_picker');
      await tester.tap(find.text('Major (CrossFit Coach)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Orientation'));
      await tester.pumpAndSettle();
      await hold(tester, 'settings_orientation_picker');
      await tester.tap(find.text('Auto (follow device)'));
      await tester.pumpAndSettle();

      // Mute voice cues for the rest of the run (Sound Effects = switch #2).
      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();
      await goBack(tester);

      // ---------- 10-13. AMRAP live: prep pulse, work, paused, complete ----
      await tester.tap(find.text('AMRAP'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();
      expect(await pumpUntil(tester, find.text('3'),
          timeout: const Duration(seconds: 15)), isTrue);
      await quickMark(tester, 'active_prep_countdown');
      expect(await pumpUntil(tester, find.text('REMAINING'),
          timeout: const Duration(seconds: 15)), isTrue);
      await pumpSeconds(tester, 12);
      await hold(tester, 'active_amrap_work');
      await tester.tap(find.byIcon(Icons.pause));
      expect(await pumpUntil(tester, find.textContaining('PAUSED'),
          timeout: const Duration(seconds: 10)), isTrue);
      await hold(tester, 'active_amrap_paused');
      await stopAndFinish(tester, completeMark: 'active_amrap_complete');

      // ---------- 14. For Time live (count up) ----------
      await tester.tap(find.text('FOR TIME'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();
      // FINISH only renders once running (ELAPSED would match during prep).
      expect(await pumpUntil(tester, find.text('FINISH'),
          timeout: const Duration(seconds: 15)), isTrue);
      await pumpSeconds(tester, 8);
      await hold(tester, 'active_fortime_countup');
      await stopAndFinish(tester);

      // ---------- 15. EMOM live (round 2 of 10, 1:00 intervals) ----------
      await tester.tap(find.text('EMOM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();
      expect(await pumpUntil(tester, find.text('ROUND 2/10'),
          timeout: const Duration(seconds: 100)), isTrue);
      await pumpSeconds(tester, 3);
      await hold(tester, 'active_emom_round2');
      await stopAndFinish(tester);

      // ---------- 16-18. Tabata live: rest, phase preview, complete --------
      await tester.tap(find.text('TABATA'));
      await tester.pumpAndSettle();
      // 2 rounds keeps the run short: prep 10 + (20+10)*2 = 70s.
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.bySemanticsLabel('Decrease rounds'));
        await tester.pump(const Duration(milliseconds: 150));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();
      // Pill reads 'TABATA  ·  REST' (phase preview says 'REST in Ns').
      expect(await pumpUntil(tester, find.textContaining('·  REST'),
          timeout: const Duration(seconds: 45)), isTrue);
      await quickMark(tester, 'active_tabata_rest', tenths: 25);
      expect(await pumpUntil(tester, find.textContaining('WORK in'),
          timeout: const Duration(seconds: 15)), isTrue);
      await quickMark(tester, 'active_tabata_phase_preview', tenths: 12);
      expect(await pumpUntil(tester, find.text('Finished!'),
          timeout: const Duration(seconds: 60)), isTrue);
      await hold(tester, 'active_tabata_complete');
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      // ---------- 19-22. Landscape: home, setup, active, complete ----------
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Orientation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Landscape only'));
      await tester.pumpAndSettle();
      await pumpSeconds(tester, 2); // let the rotation finish
      await goBack(tester);
      await hold(tester, 'home_landscape');
      await tester.tap(find.text('AMRAP'));
      await tester.pumpAndSettle();
      await hold(tester, 'amrap_setup_landscape');
      await tester.tap(find.text('START'));
      await tester.pumpAndSettle();
      expect(await pumpUntil(tester, find.text('REMAINING'),
          timeout: const Duration(seconds: 15)), isTrue);
      await pumpSeconds(tester, 6);
      await hold(tester, 'active_work_landscape');
      await holdStop(tester);
      expect(await pumpUntil(tester, find.text('DONE'),
          timeout: const Duration(seconds: 10)), isTrue);
      await hold(tester, 'complete_landscape');
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      // ---------- Restore settings (orientation auto, sound on) ----------
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Orientation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Auto (follow device)'));
      await tester.pumpAndSettle();
      await pumpSeconds(tester, 2);
      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();
      await goBack(tester);
      print('MARK_TOUR_DONE');
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
