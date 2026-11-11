// Helpers for the App Store preview footage tour (preview_video_tour_test.dart).
// Test-only: nothing here is imported by lib/.
//
// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tap_dots.dart';

int nowMs() => DateTime.now().millisecondsSinceEpoch;

/// A cut point in the drive log: `MARK <name> <epoch ms>`.
void mark(String name) => print('MARK $name ${nowMs()}');

/// The app under [TapDots], with a full-screen white flash the tour fires
/// once at the start and once at the end. The cut script finds the flash in
/// the recording (mean luma) and so ties the log's wall clock to video time.
class RecordingRoot extends StatelessWidget {
  const RecordingRoot({required this.child, super.key});

  final Widget child;

  static final ValueNotifier<bool> flash = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          TapDots(child: child),
          ValueListenableBuilder<bool>(
            valueListenable: flash,
            builder: (context, on, _) => on
                ? const IgnorePointer(child: ColoredBox(color: Colors.white))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Pump ~60 fps frames against the wall clock for [ms]. Never
/// pumpAndSettle: a live timer or the paused pulse never settles.
Future<void> hold(WidgetTester tester, int ms) async {
  final sw = Stopwatch()..start();
  while (sw.elapsedMilliseconds < ms) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Pump real time until [finder] matches. Fails the tour on timeout.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  int timeoutMs = 20000,
  String? reason,
}) async {
  final sw = Stopwatch()..start();
  while (sw.elapsedMilliseconds < timeoutMs) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 16));
  }
  fail('waitFor timed out after $timeoutMs ms: ${reason ?? finder}');
}

/// White flash for the cut script: `MARK <name> <ms>` is printed once the
/// first white frame has been built.
Future<void> syncFlash(WidgetTester tester, String name) async {
  RecordingRoot.flash.value = true;
  await tester.pump();
  mark(name);
  await hold(tester, 260);
  RecordingRoot.flash.value = false;
  await tester.pump();
  await hold(tester, 500);
}

/// A finger down at [at]. Sent as a device event, not a test event: the
/// live test binding paints a coloured crosshair over every test pointer,
/// which must not be in the footage. Needs
/// `binding.shouldPropagateDevicePointerEvents = true` (set in main()).
Future<TestGesture> fingerDown(WidgetTester tester, Offset at) async {
  final gesture = TestGesture(
    dispatcher: (event) async =>
        tester.binding.handlePointerEventForSource(event),
    pointer: tester.nextPointer,
  );
  await gesture.down(at);
  return gesture;
}

/// A human tap: finger down for [ms], then up.
Future<void> pressAt(WidgetTester tester, Offset at, {int ms = 70}) async {
  final gesture = await fingerDown(tester, at);
  await hold(tester, ms);
  await gesture.up();
  await tester.pump();
}

Future<void> press(WidgetTester tester, Finder finder, {int ms = 70}) async {
  await waitFor(tester, finder, timeoutMs: 8000);
  await pressAt(tester, tester.getCenter(finder.first), ms: ms);
}

/// Drag a finger along [path] (t from 0 to 1) over [ms] with an eased
/// speed, rest for [restMs] and lift: the finger is still when it lifts,
/// so a snapping wheel settles on the nearest row and never flings on.
Future<void> pathDrag(
  WidgetTester tester,
  Offset Function(double t) path, {
  required int ms,
  int restMs = 140,
}) async {
  final gesture = await fingerDown(tester, path(0));
  await hold(tester, 90);
  final sw = Stopwatch()..start();
  while (sw.elapsedMilliseconds < ms) {
    final t = Curves.easeInOut.transform(
      (sw.elapsedMilliseconds / ms).clamp(0.0, 1.0),
    );
    await gesture.moveTo(path(t));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.moveTo(path(1));
  await hold(tester, restMs);
  await gesture.up();
  await tester.pump();
}

/// A point on a circle about [centre], [minutes] round a 60-minute dial
/// from 12 o'clock.
Offset dialPoint(Offset centre, double radius, double minutes) {
  final radians = minutes / 60 * 2 * math.pi;
  return centre +
      Offset(radius * math.sin(radians), -radius * math.cos(radians));
}
