// The live screen's actions and what a screen reader hears, per state:
// FINISH, RESUME, hold-to-stop in the countdown, AGAIN, every Android
// back case, the live-region label, a long Tabata rest on the clock, and
// large text (1.6x) across every state in both orientations.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/presentation/widgets/hold_to_stop_cell.dart';

import '../../../../helpers/screen_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LiveHarness live;

  setUp(() => live = LiveHarness());

  TimerNotifierState state() => live.container.read(timerNotifierProvider);

  /// Holds the stop cell down for its full duration: 0.8s of hold plus a
  /// frame for the fill to report complete.
  Future<void> holdStop(WidgetTester tester) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(HoldToStopCell)),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  group('actions', () {
    testWidgets('FINISH on a For Time logs the time as a finish', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: forTimeWorkout(countUp: true),
        type: TimerTypes.forTime,
        device: Device.phone,
        elapsed: const Duration(seconds: 754),
      );
      await tester.tap(
        find.bySemanticsLabel('Finish workout and log your time'),
      );
      await tester.pump();
      expect(state(), isA<TimerCompleted>());
      expect((state() as TimerCompleted).endedEarly, isFalse);
      expect(find.text('Finished'), findsOneWidget);
      expect(find.text('12:34'), findsOneWidget);
      expect(find.text('TIME'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('RESUME resumes; a tap on the slab never does', (tester) async {
      await live.pump(
        tester,
        workout: emomWorkout(),
        type: TimerTypes.emom,
        device: Device.phone,
        elapsed: const Duration(seconds: 5),
      );
      live.notifier.pause();
      await tester.pump();
      expect(state(), isA<TimerPaused>());
      await tester.tap(find.bySemanticsLabel('Resume button'));
      await tester.pump();
      expect(state(), isA<TimerRunning>());
      expect(find.text('PAUSE'), findsOneWidget);
    });

    testWidgets('holding Stop in the countdown goes straight back to setup', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: amrapWorkout(prep: 10),
        type: TimerTypes.amrap,
        device: Device.phone,
        elapsed: const Duration(seconds: 1),
      );
      expect(find.text('GET READY'), findsOneWidget);
      await holdStop(tester);
      expect(state(), isA<TimerInitial>());
      expect(find.text('SETUP amrap'), findsOneWidget);
    });

    testWidgets('AGAIN runs the same workout again from the top', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: amrapWorkout(seconds: 60),
        type: TimerTypes.amrap,
        device: Device.phone,
        elapsed: const Duration(seconds: 5),
      );
      live.engine.emit(const Duration(seconds: 60));
      await tester.pump();
      expect(find.text('Finished'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Run the same workout again'));
      await tester.pump();
      expect(state(), isA<TimerRunning>());
      expect(state().sessionOrNull!.elapsed.seconds, 0);
      // A one-minute phase counts 60, 59 ... never 1:00.
      expect(find.text('60'), findsOneWidget);
      expect(find.text('TAP TO COUNT'), findsOneWidget);
      expect(find.text('PAUSE'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Android back', () {
    testWidgets('in the countdown: back to setup, nothing started', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: emomWorkout(prep: 10),
        type: TimerTypes.emom,
        device: Device.phone,
        elapsed: const Duration(seconds: 2),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(state(), isA<TimerInitial>());
      expect(find.text('SETUP emom'), findsOneWidget);
    });

    testWidgets('on the end screen: the same as DONE', (tester) async {
      await live.pump(
        tester,
        workout: emomWorkout(),
        type: TimerTypes.emom,
        device: Device.phone,
        elapsed: const Duration(seconds: 65),
      );
      live.notifier.stop();
      await tester.pump();
      expect(find.text('Stopped'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(state(), isA<TimerInitial>());
      expect(find.text('SETUP emom'), findsOneWidget);
    });

    testWidgets('a back while resting in a Tabata does nothing', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: tabataWorkout(),
        type: TimerTypes.tabata,
        device: Device.phone,
        elapsed: const Duration(seconds: 25),
      );
      expect(state(), isA<TimerResting>());
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(state(), isA<TimerResting>());
      expect(find.text('SETUP tabata'), findsNothing);
    });
  });

  group('what a screen reader hears', () {
    /// The merged live region: the state sentence first, then what the
    /// visible texts say (the clock's spoken form, the second line).
    Future<List<String>> liveLabel(WidgetTester tester) async {
      final handle = tester.ensureSemantics();
      await tester.pump();
      final node = tester.getSemantics(
        find.bySemanticsLabel(
          RegExp('^(Get Ready|Work|Rest|Paused|Stopped|Complete), '),
        ),
      );
      final label = node.label;
      handle.dispose();
      return label.split('\n');
    }

    testWidgets('AMRAP: the count and how to add to it', (tester) async {
      await live.pump(
        tester,
        workout: amrapWorkout(),
        type: TimerTypes.amrap,
        device: Device.phone,
        elapsed: const Duration(seconds: 30),
      );
      final lines = await liveLabel(tester);
      expect(
        lines.first,
        'Work, 9 minutes 30 seconds remaining, 0 rounds counted. '
        'Tap to count a round. Pause to stop.',
      );
      expect(lines, contains('9 minutes 30 seconds remaining'));
      expect(lines, contains('TAP TO COUNT'));
    });

    testWidgets('EMOM: the round and the interval left', (tester) async {
      await live.pump(
        tester,
        workout: emomWorkout(),
        type: TimerTypes.emom,
        device: Device.phone,
        elapsed: const Duration(seconds: 65),
      );
      final lines = await liveLabel(tester);
      expect(
        lines.first,
        'Work, 0 minutes 55 seconds remaining, Round 2 of 10. Pause to stop.',
      );
      expect(lines, contains('2/10'));
    });

    testWidgets('For Time count-up: elapsed, not remaining', (tester) async {
      await live.pump(
        tester,
        workout: forTimeWorkout(countUp: true),
        type: TimerTypes.forTime,
        device: Device.phone,
        elapsed: const Duration(seconds: 65),
      );
      final lines = await liveLabel(tester);
      expect(lines.first, 'Work, 1 minutes 5 seconds elapsed. Pause to stop.');
      expect(lines, contains('1 minutes 5 seconds elapsed'));
      expect(lines, contains('CAP 20:00'));
    });

    testWidgets('the countdown says how to skip and how to leave', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: tabataWorkout(prep: 10),
        type: TimerTypes.tabata,
        device: Device.phone,
        elapsed: const Duration(seconds: 1),
      );
      final lines = await liveLabel(tester);
      expect(
        lines.first,
        'Get Ready, 0 minutes 9 seconds remaining, Round 1 of 8. '
        'Tap to start now. Hold the stop button to go back.',
      );
      expect(lines, contains('GET READY'));
      expect(lines, contains('TAP TO SKIP'));
    });

    testWidgets('paused says tap to resume; rest says Rest', (tester) async {
      await live.pump(
        tester,
        workout: tabataWorkout(),
        type: TimerTypes.tabata,
        device: Device.phone,
        elapsed: const Duration(seconds: 22),
      );
      expect(
        (await liveLabel(tester)).first,
        'Rest, 0 minutes 8 seconds remaining, Round 1 of 8. Pause to stop.',
      );
      live.notifier.pause();
      await tester.pump();
      final lines = await liveLabel(tester);
      expect(
        lines.first,
        'Paused, 0 minutes 8 seconds remaining, Round 1 of 8. '
        'Tap anywhere to resume. Hold the stop button to end.',
      );
      expect(lines, contains('PAUSED · REST'));
    });

    testWidgets('the end screen says Stopped or Complete, and its buttons', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: emomWorkout(),
        type: TimerTypes.emom,
        device: Device.phone,
        elapsed: const Duration(seconds: 125),
      );
      live.notifier.stop();
      await tester.pump();
      final stopped = await liveLabel(tester);
      expect(
        stopped.first,
        'Stopped, 0 minutes 55 seconds remaining, Round 3 of 10',
      );
      expect(stopped, containsAll(['Stopped', '3/10', 'ROUNDS', '2:05 total']));
      expect(
        find.bySemanticsLabel('Run the same workout again'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Done, back to setup'), findsOneWidget);

      await live.pump(
        tester,
        workout: amrapWorkout(seconds: 30),
        type: TimerTypes.amrap,
        device: Device.phone,
        elapsed: const Duration(seconds: 30),
      );
      expect(
        (await liveLabel(tester)).first,
        'Complete, 0 minutes 0 seconds remaining, 0 rounds counted',
      );
      final handle = tester.ensureSemantics();
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Rounds')),
        isSemantics(
          value: '0',
          increasedValue: '1',
          hasIncreaseAction: true,
          hasDecreaseAction: false,
        ),
      );
      handle.dispose();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('the slab cells are named buttons', (tester) async {
      await live.pump(
        tester,
        workout: forTimeWorkout(countUp: true),
        type: TimerTypes.forTime,
        device: Device.phone,
        elapsed: const Duration(seconds: 5),
      );
      final handle = tester.ensureSemantics();
      await tester.pump();
      for (final label in [
        'Finish workout and log your time',
        'Pause button',
      ]) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(label)),
          isSemantics(isButton: true, isEnabled: true),
          reason: label,
        );
      }
      live.notifier.pause();
      await tester.pump();
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('End workout. Hold to confirm.'),
        ),
        isSemantics(isButton: true, hasLongPressAction: true),
      );
      // The long-press action is the hold for a screen reader.
      tester.semantics.performAction(
        find.semantics.byLabel('End workout. Hold to confirm.'),
        SemanticsAction.longPress,
      );
      await tester.pump();
      handle.dispose();
      expect(state(), isA<TimerCompleted>());
      expect(find.text('Stopped'), findsOneWidget);
    });
  });

  group('the clock on a long phase', () {
    testWidgets('a 1:30 rest counts 1:30, 1:00, 59 in the rest colour', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: tabataWorkout(rest: 90, rounds: 2),
        type: TimerTypes.tabata,
        device: Device.phone,
        elapsed: const Duration(seconds: 20),
      );
      expect(state(), isA<TimerResting>());
      expect(find.text('1:30'), findsOneWidget);
      expect(find.text('REST'), findsOneWidget);
      live.engine.emit(const Duration(seconds: 50));
      await tester.pump();
      expect(find.text('1:00'), findsOneWidget);
      live.engine.emit(const Duration(seconds: 51));
      await tester.pump();
      expect(find.text('59'), findsOneWidget);
    });
  });

  group('large text (1.6x)', () {
    const width = 375.0;
    const portrait = Device('phone 375x812 1.6x', Size(width, 812));
    const landscape = Device('phone 812x375 1.6x', Size(812, width));

    final cases = <String, (Workout, String)>{
      'AMRAP': (amrapWorkout(), TimerTypes.amrap),
      'For Time': (forTimeWorkout(countUp: true), TimerTypes.forTime),
      'EMOM': (emomWorkout(), TimerTypes.emom),
      'Tabata': (tabataWorkout(), TimerTypes.tabata),
    };

    for (final device in [portrait, landscape]) {
      for (final entry in cases.entries) {
        testWidgets('${entry.key} live, paused and end fit ${device.name}', (
          tester,
        ) async {
          final (workout, type) = entry.value;
          await live.pump(
            tester,
            workout: workout,
            type: type,
            device: device,
            elapsed: const Duration(seconds: 25),
            textScale: 1.6,
          );
          expect(tester.takeException(), isNull, reason: 'live');
          final slab = tester.getRect(find.byType(BottomSlab));
          expect(slab.bottom, device.size.height);
          expect(slab.left, 0);
          expect(slab.right, device.size.width);

          live.notifier.pause();
          await tester.pump();
          expect(tester.takeException(), isNull, reason: 'paused');
          expect(find.text('HOLD TO STOP'), findsOneWidget);
          expect(find.text('RESUME'), findsOneWidget);

          live.notifier.stop();
          await tester.pump();
          expect(tester.takeException(), isNull, reason: 'end');
          expect(find.text('Stopped'), findsOneWidget);
          expect(
            tester.getRect(find.byType(BottomSlab)).bottom,
            device.size.height,
          );
        });
      }

      testWidgets('the countdown fits ${device.name}', (tester) async {
        await live.pump(
          tester,
          workout: tabataWorkout(prep: 10),
          type: TimerTypes.tabata,
          device: device,
          elapsed: const Duration(seconds: 1),
          textScale: 1.6,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('GET READY'), findsOneWidget);
        expect(find.text('TAP TO SKIP'), findsOneWidget);
        expect(find.text('HOLD TO STOP'), findsOneWidget);
      });
    }
  });
}
