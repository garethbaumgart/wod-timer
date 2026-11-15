// The upright end screen (2.5.1, option 1 of the 15 Nov 2026 mocks): the
// result lifted under the header and three fact tiles under it, each fact
// from the session itself.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/features/timer/presentation/widgets/end_fact_tiles.dart';
import 'package:wod_timer/features/timer/presentation/widgets/rounds_wheel.dart';
import 'package:wod_timer/features/timer/presentation/widgets/workout_timeline.dart';

import '../../../../helpers/screen_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LiveHarness live;
  setUp(() => live = LiveHarness());

  const se = Device('iPhone SE 375x667', Size(375, 667));

  /// The tiles' facts, left to right.
  List<EndFact> facts(WidgetTester tester) =>
      tester.widget<EndFactTiles>(find.byType(EndFactTiles)).facts;

  final clockTime = RegExp(r'^\d{1,2}:\d\d( am| pm)?$');

  group('EndFact', () {
    test('clock times follow the phone: 12-hour lower case, or 24-hour', () {
      final t = DateTime(2026, 11, 15, 6, 42);
      final evening = DateTime(2026, 11, 15, 18, 5);
      final noon = DateTime(2026, 11, 15, 12, 0);
      final midnight = DateTime(2026, 11, 15, 0, 9);
      expect(EndFact.clockTime(t, use24h: false), '6:42 am');
      expect(EndFact.clockTime(evening, use24h: false), '6:05 pm');
      expect(EndFact.clockTime(noon, use24h: false), '12:00 pm');
      expect(EndFact.clockTime(midnight, use24h: false), '12:09 am');
      expect(EndFact.clockTime(evening, use24h: true), '18:05');
    });

    test('Tabata work counts full rounds and the part of the last one', () {
      int work(int elapsed) =>
          EndFact.tabataWorkSeconds(elapsed, work: 20, rest: 10);
      expect(work(0), 0);
      expect(work(15), 15);
      expect(work(25), 20);
      expect(work(60), 40);
      expect(work(240), 160);
      expect(EndFact.tabataWorkSeconds(30, work: 0, rest: 0), 0);
    });
  });

  group('fact tiles', () {
    testWidgets('AMRAP: time, per round, finished; the count sits above', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: amrapWorkout(seconds: 60),
        type: TimerTypes.amrap,
        device: Device.phone,
        elapsed: const Duration(seconds: 5),
      );
      for (var i = 0; i < 3; i++) {
        live
          ..later()
          ..notifier.countRound();
      }
      live.engine.emit(const Duration(seconds: 60));
      await tester.pump();
      final f = facts(tester);
      expect(f.map((e) => e.label), ['TIME', 'PER ROUND', 'FINISHED']);
      expect(f[0].value, '1:00');
      expect(f[1].value, '0:20');
      expect(f[2].value, matches(clockTime));
      // Lifted: the wheel and its hint sit above the tiles.
      final hint = tester.getRect(find.text('Scroll to fix the count'));
      expect(
        hint.bottom,
        lessThan(tester.getRect(find.byType(EndFactTiles)).top),
      );
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('AMRAP with no rounds counted shows when it started', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: amrapWorkout(seconds: 30),
        type: TimerTypes.amrap,
        device: Device.phone,
        elapsed: const Duration(seconds: 5),
      );
      live.engine.emit(const Duration(seconds: 30));
      await tester.pump();
      expect(facts(tester).map((e) => e.label), [
        'TIME',
        'STARTED',
        'FINISHED',
      ]);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('scrolling the AMRAP count updates the per-round time', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: amrapWorkout(seconds: 60),
        type: TimerTypes.amrap,
        device: Device.phone,
        elapsed: const Duration(seconds: 5),
      );
      live
        ..later()
        ..notifier.countRound();
      live.engine.emit(const Duration(seconds: 60));
      await tester.pump();
      expect(facts(tester)[1], const EndFact('PER ROUND', '1:00'));
      live.notifier.adjustRounds(1);
      await tester.pump();
      expect(facts(tester)[1], const EndFact('PER ROUND', '0:30'));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('For Time finished: cap, time under the cap, finished', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: forTimeWorkout(countUp: true),
        type: TimerTypes.forTime,
        device: Device.phone,
        elapsed: const Duration(seconds: 754),
      );
      live.notifier.finish();
      await tester.pump();
      final f = facts(tester);
      expect(f.sublist(0, 2), const [
        EndFact('CAP', '20:00'),
        EndFact('UNDER CAP', '7:26'),
      ]);
      expect(f[2].label, 'FINISHED');
      expect(find.text('12:34'), findsOneWidget, reason: 'the hero');
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('For Time stopped: no time under the cap, it was not beaten', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: forTimeWorkout(countUp: true),
        type: TimerTypes.forTime,
        device: Device.phone,
        elapsed: const Duration(seconds: 300),
      );
      live.notifier.stop();
      await tester.pump();
      expect(facts(tester).map((e) => e.label), ['CAP', 'STARTED', 'STOPPED']);
    });

    testWidgets('For Time at the cap: no hero, the tiles say it ended', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: forTimeWorkout(countUp: true, cap: 60),
        type: TimerTypes.forTime,
        device: Device.phone,
      );
      for (var s = 2; s <= 60; s += 2) {
        live.engine.emit(Duration(seconds: s));
      }
      await tester.pump();
      expect(find.text('Time cap'), findsOneWidget);
      expect(find.text('TIME'), findsNothing);
      expect(facts(tester).map((e) => e.label), ['CAP', 'STARTED', 'ENDED']);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('EMOM stopped: time, the interval, stopped', (tester) async {
      await live.pump(
        tester,
        workout: emomWorkout(),
        type: TimerTypes.emom,
        device: Device.phone,
        elapsed: const Duration(seconds: 125),
      );
      live.notifier.stop();
      await tester.pump();
      final f = facts(tester);
      expect(f.sublist(0, 2), const [
        EndFact('TIME', '2:05'),
        EndFact('EVERY', '1:00'),
      ]);
      expect(f[2].label, 'STOPPED');
      expect(find.text('2:05 total'), findsNothing);
    });

    testWidgets('Tabata finished: time, the work in it, finished', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: tabataWorkout(rounds: 2),
        type: TimerTypes.tabata,
        device: Device.phone,
      );
      live.engine.emit(const Duration(seconds: 60));
      await tester.pump();
      final f = facts(tester);
      expect(f.sublist(0, 2), const [
        EndFact('TIME', '1:00'),
        EndFact('WORK', '0:40'),
      ]);
      expect(f[2].label, 'FINISHED');
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('held sideways the end screen keeps its 2.5.0 layout', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: emomWorkout(),
        type: TimerTypes.emom,
        device: Device.phoneLandscape,
        elapsed: const Duration(seconds: 125),
      );
      live.notifier.stop();
      await tester.pump();
      expect(find.byType(EndFactTiles), findsNothing);
      expect(find.text('2:05 total'), findsOneWidget);
    });
  });

  group('fits', () {
    for (final (type, name) in [
      (TimerTypes.amrap, 'AMRAP'),
      (TimerTypes.tabata, 'Tabata'),
    ]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('$name on an iPhone SE at text size $scale', (
          tester,
        ) async {
          await live.pump(
            tester,
            workout: type == TimerTypes.amrap
                ? amrapWorkout(seconds: 60)
                : tabataWorkout(rounds: 2),
            type: type,
            device: se,
            elapsed: const Duration(seconds: 5),
            textScale: scale,
          );
          live.engine.emit(const Duration(seconds: 60));
          await tester.pump();
          expect(tester.takeException(), isNull);
          final tiles = tester.getRect(find.byType(EndFactTiles));
          final timeline = tester.getRect(find.byType(WorkoutTimeline));
          final slab = tester.getRect(find.byType(BottomSlab));
          expect(timeline.top, greaterThan(tiles.bottom));
          expect(timeline.bottom, lessThan(slab.top));
          if (type == TimerTypes.amrap) {
            expect(
              tester.getRect(find.byType(RoundsWheel)).bottom,
              lessThan(tiles.top),
            );
          }
          await tester.pump(const Duration(seconds: 1));
        });
      }
    }
  });
}
