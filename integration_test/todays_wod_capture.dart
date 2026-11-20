// PROTOTYPE ONLY ("Today's WOD", 20 Nov 2026). Shared by the two preview
// capture tours: pumping in real time and the MARK lines the capture script
// screenshots on.
//
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';

/// Pump [seconds] of real time.
Future<void> pumpSeconds(WidgetTester tester, double seconds) async {
  final ticks = (seconds * 10).round();
  for (var i = 0; i < ticks; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Pump real time until [finder] matches (or the timeout). Returns success.
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

/// Let the UI catch up, print the mark (the PNG's name), then hold about
/// four seconds of real time so the script can take the screenshot.
Future<void> hold(WidgetTester tester, String file) async {
  await pumpSeconds(tester, 0.8);
  print('MARK_$file');
  await pumpSeconds(tester, 4);
}
