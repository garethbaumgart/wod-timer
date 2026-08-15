// Drives the real app on a device/emulator; prints are the progress log
// that shows up in the flutter test output.
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/injection.dart';
import 'package:wod_timer/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Timer Integration Tests', () {
    testWidgets('AMRAP timer counts down and transitions to WORK',
        (tester) async {
      unawaited(app.main());
      await tester.pumpAndSettle();

      // Verify home page is shown (hero renders "WOD." as a RichText)
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText && widget.text.toPlainText() == 'WOD.',
        ),
        findsOneWidget,
      );
      expect(find.text('AMRAP'), findsOneWidget);
      print('✓ Home page loaded');

      // Tap on AMRAP card
      await tester.tap(find.text('AMRAP'));
      await tester.pumpAndSettle();
      print('✓ Tapped on AMRAP');

      // Should be on setup page (button label is "START" since the UX-review
      // redesign)
      expect(find.text('START'), findsOneWidget);
      print('✓ Setup page shown');

      // Start workout. The active page animates every frame, so
      // pumpAndSettle never settles here — pump fixed durations instead.
      await tester.tap(find.text('START'));
      await tester.pump(const Duration(milliseconds: 600));

      // Should see the prep countdown ("STARTS IN" + bare-digit seconds)
      expect(
        find.text('STARTS IN'),
        findsOneWidget,
        reason: 'Should show the STARTS IN prep phase',
      );
      print('✓ STARTS IN prep phase shown');

      String? findBareDigits() {
        for (final element in find.byType(Text).evaluate()) {
          final widget = element.widget as Text;
          final data = widget.data;
          if (data != null && RegExp(r'^\d{1,2}$').hasMatch(data)) {
            return data;
          }
        }
        return null;
      }

      // Capture initial prep countdown value
      final initialPrep = findBareDigits();
      print('  Initial prep countdown: $initialPrep');

      // Wait and verify countdown is progressing
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 200));
      final newPrep = findBareDigits();
      print('  Prep countdown after 1.2s: $newPrep');

      // CRITICAL TEST: prep countdown must be counting down
      expect(initialPrep, isNotNull, reason: 'Should find prep countdown');
      expect(newPrep, isNotNull, reason: 'Should find prep countdown later');
      expect(
        initialPrep,
        isNot(equals(newPrep)),
        reason: 'Prep should have counted down from $initialPrep to $newPrep',
      );
      print('✓ Prep countdown is counting down! ($initialPrep -> $newPrep)');

      // Wait for the prep countdown to complete (10s default prep). The work
      // phase shows the big MM:SS display over a "REMAINING" caption.
      print('Waiting for prep countdown to complete...');
      var transitionedToWork = false;
      for (var i = 0; i < 150; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('REMAINING').evaluate().isNotEmpty) {
          print('✓ Transitioned to WORK phase after ${(i + 1) * 100}ms');
          transitionedToWork = true;
          break;
        }
      }

      // CRITICAL TEST: Must transition to the work phase
      expect(
        transitionedToWork,
        isTrue,
        reason: 'Should transition from STARTS IN to the REMAINING display',
      );

      String? findClockText() {
        for (final element in find.byType(Text).evaluate()) {
          final widget = element.widget as Text;
          final data = widget.data;
          if (data != null && RegExp(r'^\d{2}:\d{2}$').hasMatch(data)) {
            return data;
          }
        }
        return null;
      }

      // And the workout clock itself must be ticking
      final initialClock = findClockText();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 200));
      final newClock = findClockText();
      expect(initialClock, isNotNull, reason: 'Should find workout clock');
      expect(newClock, isNotNull, reason: 'Should find workout clock later');
      expect(
        initialClock,
        isNot(equals(newClock)),
        reason: 'Clock should have ticked from $initialClock to $newClock',
      );
      print('✓ Workout clock is ticking! ($initialClock -> $newClock)');

      // Stop the workout so audio players are released before teardown
      // (a still-running session leaves audioplayers frame callbacks
      // pending). Ending is hold-to-confirm: long-press (500ms) arms it,
      // then an 800ms ring fill confirms.
      final stopButton = find.byIcon(Icons.stop);
      expect(stopButton, findsOneWidget, reason: 'Should find stop button');
      final gesture = await tester.startGesture(tester.getCenter(stopButton));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 900));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 500));
      // Release the pooled audio players. Their frame-based position
      // updaters run for the service's lifetime (fine in the app, which
      // never disposes the pool), but the harness fails the test if any
      // frame callback is still scheduled when the tree is disposed.
      await getIt<IAudioService>().dispose();
      await tester.pump(const Duration(milliseconds: 300));
      print('✓ Workout stopped cleanly');

      print('\n=== TIMER INTEGRATION TEST PASSED ===');
      print('The timer:');
      print('  - Counts down during the STARTS IN prep phase ✓');
      print('  - Transitions to the work phase and ticks ✓');
    });
  });
}
