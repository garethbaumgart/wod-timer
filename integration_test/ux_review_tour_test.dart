// UX-review and store-screenshot capture tour. NOT part of the normal suite:
// it drives the real app through every screen and state, printing
// MARK_<name> lines; a watcher script screenshots the simulator / emulator at
// each mark (`xcrun simctl io <udid> screenshot` or `adb exec-out screencap`).
//
// Updated for 1.3.1: setup values live on the stopwatch bezel (AMRAP, For
// Time) and the snapping wheels (EMOM, Tabata), every screen's actions are
// in the bottom slab (START; PAUSE; FINISH | PAUSE; HOLD TO STOP | RESUME;
// AGAIN | DONE), the AMRAP end screen fixes the count on a wheel, and the
// For Time direction is a COUNT UP | COUNT DOWN switch.
//
// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/features/timer/application/setup/setup_memory.dart';
import 'package:wod_timer/features/timer/presentation/widgets/rounds_wheel.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_wheel.dart';
import 'package:wod_timer/features/timer/presentation/widgets/stopwatch_bezel.dart';
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

/// Print the mark immediately (no settle) and hold briefly, for states that
/// only exist for a second or two (countdown pulse, phase previews).
Future<void> quickMark(
  WidgetTester tester,
  String mark, {
  int tenths = 18,
}) async {
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

/// Open a mode from Home and tap START once the 500ms guard has passed.
Future<void> openAndStart(WidgetTester tester, String mode) async {
  await tester.tap(find.text(mode));
  await tester.pumpAndSettle();
  await pumpSeconds(tester, 0.8);
  await tester.tap(find.text('START'));
  await tester.pump();
}

/// Spin a setup wheel by [steps] rows (positive = higher values).
Future<void> spin(WidgetTester tester, String label, int steps) async {
  final wheel = find.ancestor(
    of: find.text(label),
    matching: find.byType(SetupWheel),
  );
  // Measured as painted, so it is one row on a tablet too (TabletScale
  // paints a 56pt row at 1.7x and drags are in painted points).
  final rows = find.descendant(
    of: wheel,
    matching: find.byType(ListWheelScrollView),
  );
  final rowHeight = tester.getRect(rows).height / 3;
  await tester.drag(rows, Offset(0, -steps * rowHeight));
  await tester.pumpAndSettle();
}

/// Turn the bezel to [minutes] by touching the ring at that angle.
Future<void> turnBezel(WidgetTester tester, int minutes) async {
  final rect = tester.getRect(find.byType(StopwatchBezel));
  final radians = minutes / 60 * 2 * math.pi;
  final radius = rect.width / 2 * 0.83;
  final point =
      rect.center +
      Offset(radius * math.sin(radians), -radius * math.cos(radians));
  await tester.tapAt(point);
  await tester.pumpAndSettle();
}

/// Running → paused. HOLD TO STOP only exists on the paused screen.
Future<void> pause(WidgetTester tester) async {
  await tester.tap(find.text('PAUSE'));
  expect(
    await pumpUntil(
      tester,
      find.text('RESUME'),
      timeout: const Duration(seconds: 10),
    ),
    isTrue,
    reason: 'paused screen',
  );
}

/// Hold HOLD TO STOP (0.8s fill) until the end screen shows.
Future<void> holdStop(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.text('HOLD TO STOP')),
  );
  await pumpSeconds(tester, 1.4);
  await gesture.up();
  expect(
    await pumpUntil(
      tester,
      find.text('DONE'),
      timeout: const Duration(seconds: 10),
    ),
    isTrue,
    reason: 'end screen after HOLD TO STOP',
  );
}

/// From an end screen: DONE lands on the mode's setup; back to Home.
Future<void> doneToHome(WidgetTester tester) async {
  await tester.tap(find.text('DONE'));
  await tester.pumpAndSettle();
  await goBack(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ux review tour', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // ---------- Home ----------
    await hold(tester, 'home');

    // ---------- Setup screens ----------
    await tester.tap(find.text('AMRAP'));
    await tester.pumpAndSettle();
    await hold(tester, 'amrap_setup');
    await turnBezel(tester, 12);
    await hold(tester, 'amrap_setup_turned', tenths: 20);
    await turnBezel(tester, 10);
    await goBack(tester);

    await tester.tap(find.text('FOR TIME'));
    await tester.pumpAndSettle();
    await hold(tester, 'fortime_setup');
    await tester.tap(find.text('COUNT DOWN'));
    await tester.pumpAndSettle();
    await hold(tester, 'fortime_setup_countdown');
    await tester.tap(find.text('COUNT UP'));
    await tester.pumpAndSettle();
    await goBack(tester);

    await tester.tap(find.text('EMOM'));
    await tester.pumpAndSettle();
    await hold(tester, 'emom_setup');
    await goBack(tester);

    await tester.tap(find.text('TABATA'));
    await tester.pumpAndSettle();
    await hold(tester, 'tabata_setup');
    await spin(tester, 'ROUNDS', 1);
    await hold(tester, 'tabata_setup_drifted');
    await tester.tap(find.text('RESET TO CLASSIC'));
    await tester.pumpAndSettle();
    await goBack(tester);

    // ---------- Settings + pickers ----------
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
    await goBack(tester);

    // ---------- AMRAP live: prep, work, counted, paused, stopped ----------
    await openAndStart(tester, 'AMRAP');
    expect(
      await pumpUntil(
        tester,
        find.text('3'),
        timeout: const Duration(seconds: 15),
      ),
      isTrue,
    );
    await quickMark(tester, 'active_prep_countdown');
    expect(
      await pumpUntil(
        tester,
        find.text('TAP TO COUNT'),
        timeout: const Duration(seconds: 15),
      ),
      isTrue,
    );
    await pumpSeconds(tester, 12);
    await hold(tester, 'active_amrap_work');
    for (var i = 0; i < 3; i++) {
      await tester.tapAt(tester.getCenter(find.byType(Scaffold)) / 1.6);
      await pumpSeconds(tester, 1.2);
    }
    await hold(tester, 'active_amrap_counted');
    await pause(tester);
    await hold(tester, 'active_amrap_paused');
    // A short press brightens HOLD TO STOP as the hint.
    final press = await tester.startGesture(
      tester.getCenter(find.text('HOLD TO STOP')),
    );
    await pumpSeconds(tester, 0.2);
    await press.up();
    await quickMark(tester, 'active_amrap_hold_hint', tenths: 10);
    await pumpSeconds(tester, 1.2);
    await holdStop(tester);
    await hold(tester, 'active_amrap_complete');
    // Fix the count on the wheel: one row up is one round more.
    final wheel = find.byType(RoundsWheel);
    final itemHeight = tester.getRect(wheel).height / 1.9;
    await tester.drag(wheel, Offset(0, -itemHeight));
    await tester.pumpAndSettle();
    await hold(tester, 'active_amrap_complete_fixed', tenths: 20);
    await doneToHome(tester);

    // ---------- For Time live (count up), paused, finished ----------
    await openAndStart(tester, 'FOR TIME');
    expect(
      await pumpUntil(
        tester,
        find.text('FINISH'),
        timeout: const Duration(seconds: 15),
      ),
      isTrue,
    );
    await pumpSeconds(tester, 8);
    await hold(tester, 'active_fortime_countup');
    await pause(tester);
    await hold(tester, 'active_fortime_paused');
    await tester.tap(find.text('RESUME'));
    await pumpSeconds(tester, 2);
    await tester.tap(find.text('FINISH'));
    expect(
      await pumpUntil(
        tester,
        find.text('DONE'),
        timeout: const Duration(seconds: 10),
      ),
      isTrue,
    );
    await hold(tester, 'active_fortime_finished');
    await doneToHome(tester);

    // ---------- EMOM live (round 2 of 10, 1:00 intervals) ----------
    await openAndStart(tester, 'EMOM');
    expect(
      await pumpUntil(
        tester,
        find.text('2/10'),
        timeout: const Duration(seconds: 100),
      ),
      isTrue,
    );
    await pumpSeconds(tester, 3);
    await hold(tester, 'active_emom_round2');
    await pause(tester);
    await holdStop(tester);
    await hold(tester, 'active_emom_stopped');
    await doneToHome(tester);

    // ---------- Tabata live: work, rest, next, last rest, finished -------
    await tester.tap(find.text('TABATA'));
    await tester.pumpAndSettle();
    // 2 rounds keeps the run short: prep 10 + (20+10)*2 = 70s.
    await spin(tester, 'ROUNDS', -6);
    await pumpSeconds(tester, 0.8);
    await tester.tap(find.text('START'));
    await tester.pump();
    expect(
      await pumpUntil(
        tester,
        find.text('1/2'),
        timeout: const Duration(seconds: 20),
      ),
      isTrue,
    );
    await pumpSeconds(tester, 4);
    await quickMark(tester, 'active_tabata_work', tenths: 20);
    expect(
      await pumpUntil(
        tester,
        find.text('REST'),
        timeout: const Duration(seconds: 30),
      ),
      isTrue,
    );
    await quickMark(tester, 'active_tabata_rest', tenths: 20);
    expect(
      await pumpUntil(
        tester,
        find.text('NEXT · WORK'),
        timeout: const Duration(seconds: 15),
      ),
      isTrue,
    );
    await quickMark(tester, 'active_tabata_phase_preview', tenths: 12);
    expect(
      await pumpUntil(
        tester,
        find.text('LAST REST'),
        timeout: const Duration(seconds: 40),
      ),
      isTrue,
    );
    await quickMark(tester, 'active_tabata_last_rest', tenths: 12);
    expect(
      await pumpUntil(
        tester,
        find.text('Finished'),
        timeout: const Duration(seconds: 30),
      ),
      isTrue,
    );
    await hold(tester, 'active_tabata_complete');
    // Put Tabata back on classic for the later captures: setup only
    // remembers on START, so write the pref directly.
    await (await SharedPreferences.getInstance()).setInt(
      SetupMemory.tabataRoundsKey,
      8,
    );
    await doneToHome(tester);

    // ---------- Landscape: home, setups, active, paused, end ---------
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orientation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Landscape only'));
    await tester.pumpAndSettle();
    await pumpSeconds(tester, 2); // let the rotation finish
    await goBack(tester);
    await hold(tester, 'home_landscape');
    await tester.tap(find.text('TABATA'));
    await tester.pumpAndSettle();
    await hold(tester, 'tabata_setup_landscape');
    await goBack(tester);
    await tester.tap(find.text('FOR TIME'));
    await tester.pumpAndSettle();
    await hold(tester, 'fortime_setup_landscape');
    await goBack(tester);
    await openAndStart(tester, 'AMRAP');
    // Rounds were counted earlier in the run, so TAP TO COUNT is gone.
    expect(
      await pumpUntil(
        tester,
        find.text('PAUSE'),
        timeout: const Duration(seconds: 15),
      ),
      isTrue,
    );
    await pumpSeconds(tester, 6);
    await tester.tapAt(tester.getCenter(find.byType(Scaffold)) / 1.6);
    await pumpSeconds(tester, 1.2);
    await tester.tapAt(tester.getCenter(find.byType(Scaffold)) / 1.6);
    await pumpSeconds(tester, 1);
    await hold(tester, 'active_work_landscape');
    await pause(tester);
    await hold(tester, 'active_paused_landscape');
    await holdStop(tester);
    await hold(tester, 'complete_landscape');
    await doneToHome(tester);

    // ---------- Restore orientation ----------
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orientation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto (follow device)'));
    await tester.pumpAndSettle();
    await pumpSeconds(tester, 2);
    await goBack(tester);
    print('MARK_TOUR_DONE');
  }, timeout: const Timeout(Duration(minutes: 15)));
}
