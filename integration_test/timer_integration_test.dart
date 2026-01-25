// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wod_timer/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Timer Integration Tests', () {
    testWidgets('AMRAP timer counts down and transitions to WORK',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify home page is shown
      expect(find.text('WOD Timer'), findsOneWidget);
      expect(find.text('AMRAP'), findsOneWidget);
      print('✓ Home page loaded');

      // Tap on AMRAP card
      await tester.tap(find.text('AMRAP'));
      await tester.pumpAndSettle();
      print('✓ Tapped on AMRAP');

      // Should be on setup page
      expect(find.text('START WORKOUT'), findsOneWidget);
      print('✓ Setup page shown');

      // Start workout
      await tester.tap(find.text('START WORKOUT'));
      await tester.pumpAndSettle();
      print('✓ Started workout');

      // Should see GET READY (prep countdown)
      final getReadyFinder = find.textContaining('GET READY');
      expect(getReadyFinder, findsOneWidget, reason: 'Should show GET READY');
      print('✓ GET READY phase shown');

      // Capture initial countdown time
      final timerTextFinder = find.byType(Text);
      String? initialTime;
      for (final element in timerTextFinder.evaluate()) {
        final widget = element.widget as Text;
        if (widget.data != null &&
            RegExp(r'\d{2}:\d{2}').hasMatch(widget.data!)) {
          initialTime = widget.data;
          print('  Initial countdown time: $initialTime');
          break;
        }
      }

      // Wait and verify countdown is progressing
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 200));

      String? newTime;
      for (final element in timerTextFinder.evaluate()) {
        final widget = element.widget as Text;
        if (widget.data != null &&
            RegExp(r'\d{2}:\d{2}').hasMatch(widget.data!)) {
          newTime = widget.data;
          print('  Time after 1.2s: $newTime');
          break;
        }
      }

      // CRITICAL TEST: Timer must be counting down
      expect(initialTime, isNotNull, reason: 'Should find initial time display');
      expect(newTime, isNotNull, reason: 'Should find time display after waiting');
      expect(initialTime, isNot(equals(newTime)),
          reason: 'Timer should have counted down from $initialTime to $newTime');
      print('✓ Timer is counting down! ($initialTime -> $newTime)');

      // Wait for prep countdown to complete (10s default prep)
      print('Waiting for prep countdown to complete...');
      bool transitionedToWork = false;
      for (int i = 0; i < 150; i++) {
        await tester.pump(const Duration(milliseconds: 100));

        // Check if we've transitioned to WORK phase
        final workFinder = find.text('WORK');
        if (workFinder.evaluate().isNotEmpty) {
          print('✓ Transitioned to WORK phase after ${(i + 1) * 100}ms');
          transitionedToWork = true;
          break;
        }
      }

      // CRITICAL TEST: Must transition to WORK phase
      expect(transitionedToWork, isTrue,
          reason: 'Should transition from GET READY to WORK phase');
      print('✓ WORK phase verified - Timer flow is working correctly!');

      print('\n=== TIMER INTEGRATION TEST PASSED ===');
      print('The timer:');
      print('  - Counts down during GET READY phase ✓');
      print('  - Transitions to WORK phase after countdown ✓');
    });
  });
}
