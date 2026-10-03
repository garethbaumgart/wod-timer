// The 1.3.1 layout rules, checked on every screen that has a timeline, on
// a phone in both orientations and on a 13in iPad under TabletScale, with
// the real Outfit font:
//
// 1. No jumping: when a number changes or counts, nothing else moves.
// 2. Centring: every timeline sits exactly midway between the visible
//    bottom of the content above it (its painted glyphs, read back from
//    the pixels) and the top of the bottom slab, within 1pt.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_theme.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/setup/live_hints.dart';
import 'package:wod_timer/features/timer/presentation/pages/pages.dart';
import 'package:wod_timer/core/presentation/widgets/glyph_ink.dart';
import 'package:wod_timer/features/timer/presentation/widgets/rounds_wheel.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_wheel.dart';
import 'package:wod_timer/features/timer/presentation/widgets/workout_timeline.dart';

import '../helpers/screen_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadOutfit);

  /// Layout rule 2, measured: the gap from the lowest painted pixel above
  /// the timeline to its top equals the gap from its bottom to the slab.
  /// [above] bounds where that content can be (the timeline's column from
  /// [aboveTop] down, so the clock's glow and the header are excluded).
  Future<void> expectCentred(
    WidgetTester tester, {
    required double aboveTop,
    String reason = '',
  }) async {
    final timeline = tester.getRect(find.byType(WorkoutTimeline));
    final slab = tester.getRect(find.byType(BottomSlab));
    final shot = await paintedScreen(tester);
    final dpr = tester.view.devicePixelRatio;
    final inkBottom = lowestInkIn(
      shot,
      Rect.fromLTRB(timeline.left, aboveTop, timeline.right, timeline.top - 1),
      dpr,
    );
    expect(inkBottom, isNotNull, reason: 'no content above the timeline');
    final gapAbove = timeline.top - inkBottom!;
    final gapBelow = slab.top - timeline.bottom;
    expect(gapAbove, greaterThan(4), reason: '$reason: ink touches timeline');
    // Within a point, plus the one device pixel a small glyph's painted
    // edge can land past its outline (calibrated: the outline metrics are
    // exact at 64pt and above; 13pt text snaps to the pixel grid).
    expect(
      (gapAbove - gapBelow).abs(),
      lessThanOrEqualTo(1.0 + 1 / dpr),
      reason:
          '$reason: gap above ${gapAbove.toStringAsFixed(2)} vs below '
          '${gapBelow.toStringAsFixed(2)}',
    );
  }

  /// Every Text's rect (by position in the tree) plus the timeline and
  /// slab, for the no-jump comparisons.
  Map<String, Rect> snapshot(WidgetTester tester) {
    final rects = <String, Rect>{};
    final texts = find.byType(Text).evaluate().toList();
    for (final (i, element) in texts.indexed) {
      rects['text$i'] = tester.getRect(find.byWidget(element.widget));
    }
    rects['timeline'] = tester.getRect(find.byType(WorkoutTimeline));
    rects['slab'] = tester.getRect(find.byType(BottomSlab));
    return rects;
  }

  /// Rule 1: between [before] and [after] only [changed] (the ticking
  /// text, compared by index) may differ, and only in width.
  void expectNothingMoved(
    Map<String, Rect> before,
    Map<String, Rect> after, {
    required Set<String> changedTexts,
    required WidgetTester tester,
  }) {
    expect(after.keys, before.keys);
    for (final key in before.keys) {
      final a = before[key]!;
      final b = after[key]!;
      final data = key.startsWith('text')
          ? (find
                        .byType(Text)
                        .evaluate()
                        .toList()[int.parse(key.substring(4))]
                        .widget
                    as Text)
                .data
          : null;
      if (data != null && changedTexts.contains(data)) {
        expect(b.top, closeTo(a.top, 0.01), reason: '$key top');
        expect(b.height, closeTo(a.height, 0.01), reason: '$key height');
        expect(b.center.dx, closeTo(a.center.dx, 0.5), reason: '$key centre');
      } else {
        expect(b, a, reason: '$key ($data)');
      }
    }
  }

  group('setup screens', () {
    Future<void> pumpSetup(
      WidgetTester tester,
      Widget page,
      Device device,
    ) async {
      device.apply(tester);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final router = GoRouter(
        initialLocation: '/setup',
        routes: [GoRoute(path: '/setup', builder: (_, _) => page)],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.dark,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.dark,
            builder: (context, child) => appShell(child!, device: device),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final device in Device.all) {
      testWidgets(
        'EMOM timeline is centred under the wheels (${device.name})',
        (tester) async {
          await pumpSetup(tester, const EmomSetupPage(), device);
          // The lower visible row's glyphs, not the wheel box.
          final wheels = tester.getRect(find.byType(SetupWheel).first);
          await expectCentred(
            tester,
            aboveTop: wheels.bottom - wheels.height / 3,
            reason: 'EMOM setup ${device.name}',
          );
        },
      );

      testWidgets('Tabata timeline is centred under the wheels '
          '(${device.name})', (tester) async {
        await pumpSetup(tester, const TabataSetupPage(), device);
        final wheels = tester.getRect(find.byType(SetupWheel).first);
        await expectCentred(
          tester,
          aboveTop: wheels.bottom - wheels.height / 3,
          reason: 'Tabata setup ${device.name}',
        );
      });
    }
  });

  group('live screens', () {
    late LiveHarness live;

    setUp(() => live = LiveHarness());

    /// Where the content above the timeline starts: just under the clock.
    double underClock(WidgetTester tester, String clock) =>
        tester.getRect(find.text(clock)).bottom + 1;

    for (final device in Device.all) {
      testWidgets('For Time count-up: timeline centred under CAP '
          '(${device.name})', (tester) async {
        await live.pump(
          tester,
          workout: forTimeWorkout(countUp: true),
          type: TimerTypes.forTime,
          device: device,
          elapsed: const Duration(seconds: 65),
        );
        await expectCentred(
          tester,
          aboveTop: underClock(tester, '1:05'),
          reason: 'For Time up ${device.name}',
        );
      });

      testWidgets('For Time count-down: timeline centred under the clock '
          '(${device.name})', (tester) async {
        await live.pump(
          tester,
          workout: forTimeWorkout(countUp: false),
          type: TimerTypes.forTime,
          device: device,
          elapsed: const Duration(seconds: 65),
        );
        final clock = tester.getRect(find.text('18:55'));
        await expectCentred(
          tester,
          aboveTop: clock.top + clock.height / 2,
          reason: 'For Time down ${device.name}',
        );
      });

      testWidgets('EMOM: timeline centred under the round (${device.name})', (
        tester,
      ) async {
        await live.pump(
          tester,
          workout: emomWorkout(),
          type: TimerTypes.emom,
          device: device,
          elapsed: const Duration(seconds: 65),
        );
        await expectCentred(
          tester,
          aboveTop: underClock(tester, '55'),
          reason: 'EMOM ${device.name}',
        );
      });

      testWidgets('Tabata: timeline centred under the round '
          '(${device.name})', (tester) async {
        await live.pump(
          tester,
          workout: tabataWorkout(),
          type: TimerTypes.tabata,
          device: device,
          elapsed: const Duration(seconds: 12),
        );
        await expectCentred(
          tester,
          aboveTop: underClock(tester, '8'),
          reason: 'Tabata ${device.name}',
        );
      });

      testWidgets('AMRAP: timeline centred under the hint, then the count '
          '(${device.name})', (tester) async {
        await live.pump(
          tester,
          workout: amrapWorkout(),
          type: TimerTypes.amrap,
          device: device,
          elapsed: const Duration(seconds: 30),
        );
        await expectCentred(
          tester,
          aboveTop: underClock(tester, '9:30'),
          reason: 'AMRAP hint ${device.name}',
        );
        await live.pump(
          tester,
          workout: amrapWorkout(),
          type: TimerTypes.amrap,
          device: device,
          elapsed: const Duration(seconds: 30),
          prefs: {LiveHints.countedRoundKey: true},
        );
        await expectCentred(
          tester,
          aboveTop: underClock(tester, '9:30'),
          reason: 'AMRAP count ${device.name}',
        );
      });
    }

    // Rule 1 across the digit-count changes the spec names.
    testWidgets('For Time count-up 9:59 -> 10:00 moves nothing', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: forTimeWorkout(countUp: true),
        type: TimerTypes.forTime,
        device: Device.phone,
        elapsed: const Duration(seconds: 599),
      );
      expect(find.text('9:59'), findsOneWidget);
      final before = snapshot(tester);
      live.engine.emit(const Duration(seconds: 600));
      await tester.pump();
      expect(find.text('10:00'), findsOneWidget);
      expectNothingMoved(
        before,
        snapshot(tester),
        changedTexts: {'10:00'},
        tester: tester,
      );
    });

    testWidgets('EMOM countdown 10 -> 9 moves nothing', (tester) async {
      await live.pump(
        tester,
        workout: emomWorkout(),
        type: TimerTypes.emom,
        device: Device.phone,
        elapsed: const Duration(seconds: 50),
      );
      expect(find.text('10'), findsOneWidget);
      final before = snapshot(tester);
      live.engine.emit(const Duration(seconds: 51));
      await tester.pump();
      expect(find.text('9'), findsOneWidget);
      expectNothingMoved(
        before,
        snapshot(tester),
        changedTexts: {'9'},
        tester: tester,
      );
    });

    testWidgets('AMRAP TAP TO COUNT -> 1 ROUNDS moves nothing else', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: amrapWorkout(),
        type: TimerTypes.amrap,
        device: Device.phone,
        elapsed: const Duration(seconds: 30),
      );
      expect(find.text('TAP TO COUNT'), findsOneWidget);
      final before = snapshot(tester);
      final clock = tester.getRect(find.text('9:30'));

      live.later();
      live.notifier.countRound();
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('ROUNDS'), findsOneWidget);
      final after = snapshot(tester);
      // The hint became two texts, so compare the fixed things by name.
      expect(after['timeline'], before['timeline']);
      expect(after['slab'], before['slab']);
      expect(tester.getRect(find.text('9:30')), clock);
      // And the count shares the hint's baseline: its bottom edge is the
      // big digits' descender below the same line.
      final hintBottom = before['text1']!.bottom;
      final countBottom = tester.getRect(find.text('1')).bottom;
      expect(countBottom, greaterThan(hintBottom));
      expect(countBottom - hintBottom, lessThan(14));
    });

    testWidgets('Tabata 2/8 -> 3/8 and WORK -> REST move nothing', (
      tester,
    ) async {
      await live.pump(
        tester,
        workout: tabataWorkout(),
        type: TimerTypes.tabata,
        device: Device.phone,
        elapsed: const Duration(seconds: 52),
      );
      expect(find.text('2/8'), findsOneWidget);
      expect(find.text('REST'), findsOneWidget);
      final before = snapshot(tester);
      live.engine.emit(const Duration(seconds: 61));
      await tester.pump();
      expect(find.text('3/8'), findsOneWidget);
      expect(find.text('WORK'), findsOneWidget);
      expectNothingMoved(
        before,
        snapshot(tester),
        changedTexts: {'3/8', 'WORK', '19'},
        tester: tester,
      );
    });
  });

  group('end screens', () {
    late LiveHarness live;

    setUp(() => live = LiveHarness());

    /// The content above the end timeline starts under the status word.
    double underWord(WidgetTester tester, String word) =>
        tester.getRect(find.text(word)).bottom + 1;

    for (final device in Device.all) {
      testWidgets('For Time finished (${device.name})', (tester) async {
        await live.pump(
          tester,
          workout: forTimeWorkout(countUp: true),
          type: TimerTypes.forTime,
          device: device,
          elapsed: const Duration(seconds: 754),
        );
        live.notifier.finish();
        await tester.pump();
        expect(find.text('TIME'), findsOneWidget);
        await expectCentred(
          tester,
          aboveTop: underWord(tester, 'Finished'),
          reason: 'For Time end ${device.name}',
        );
        // The finish cue is scheduled a beat later.
        await tester.pump(const Duration(seconds: 1));
      });

      testWidgets('EMOM stopped (${device.name})', (tester) async {
        await live.pump(
          tester,
          workout: emomWorkout(),
          type: TimerTypes.emom,
          device: device,
          elapsed: const Duration(seconds: 125),
        );
        live.notifier.stop();
        await tester.pump();
        expect(find.text('2:05 total'), findsOneWidget);
        await expectCentred(
          tester,
          aboveTop: underWord(tester, 'Stopped'),
          reason: 'EMOM end ${device.name}',
        );
      });

      testWidgets('Tabata finished (${device.name})', (tester) async {
        await live.pump(
          tester,
          workout: tabataWorkout(rounds: 2),
          type: TimerTypes.tabata,
          device: device,
        );
        live.engine.emit(const Duration(seconds: 60));
        await tester.pump();
        expect(
          live.container.read(timerNotifierProvider),
          isA<TimerCompleted>(),
        );
        expect(find.text('2/2'), findsOneWidget);
        await expectCentred(
          tester,
          aboveTop: underWord(tester, 'Finished'),
          reason: 'Tabata end ${device.name}',
        );
        await tester.pump(const Duration(seconds: 1));
      });

      testWidgets('AMRAP finished, rounds wheel (${device.name})', (
        tester,
      ) async {
        await live.pump(
          tester,
          workout: amrapWorkout(seconds: 60),
          type: TimerTypes.amrap,
          device: device,
          elapsed: const Duration(seconds: 5),
        );
        live.engine.emit(const Duration(seconds: 60));
        await tester.pump();
        expect(find.text('Scroll to fix the count'), findsOneWidget);
        await expectCentred(
          tester,
          aboveTop: underWord(tester, 'Finished'),
          reason: 'AMRAP end ${device.name}',
        );
        await tester.pump(const Duration(seconds: 1));
      });

      // The selected count reads as big as an EMOM "2/10": same hero rule.
      testWidgets('AMRAP hero is as big as the EMOM hero (${device.name})', (
        tester,
      ) async {
        await live.pump(
          tester,
          workout: emomWorkout(),
          type: TimerTypes.emom,
          device: device,
          elapsed: const Duration(seconds: 65),
        );
        live.notifier.stop();
        await tester.pump();
        final emom = tester.widget<Text>(find.text('2/10')).style!;
        final emomGlyphs =
            emom.fontSize! * GlyphInk.capHeightEm(emom.fontWeight!);

        await live.pump(
          tester,
          workout: amrapWorkout(seconds: 60),
          type: TimerTypes.amrap,
          device: device,
          elapsed: const Duration(seconds: 5),
        );
        live.later();
        live.notifier.countRound();
        live.engine.emit(const Duration(seconds: 60));
        await tester.pump();
        final count = tester.widget<Text>(find.text('1')).style!;
        final countGlyphs =
            count.fontSize! * GlyphInk.capHeightEm(count.fontWeight!);
        // A phone held sideways has no room for three rows at hero size:
        // there the wheel shrinks to fit and the layout checks still hold.
        if (device.size.height > device.size.width) {
          expect(
            countGlyphs,
            closeTo(emomGlyphs, emomGlyphs * 0.1),
            reason: 'AMRAP ${count.fontSize} vs EMOM ${emom.fontSize}',
          );
        }
        expect(tester.takeException(), isNull);
        final wheel = tester.getRect(find.byType(RoundsWheel));
        final hint = tester.getRect(find.text('Scroll to fix the count'));
        expect(hint.top, greaterThanOrEqualTo(wheel.bottom));
        expect(
          tester.getRect(find.byType(WorkoutTimeline)).top,
          greaterThan(hint.bottom),
        );
        await tester.pump(const Duration(seconds: 1));
      });

      testWidgets('For Time at the cap (${device.name})', (tester) async {
        await live.pump(
          tester,
          workout: forTimeWorkout(countUp: true, cap: 60),
          type: TimerTypes.forTime,
          device: device,
        );
        for (var s = 2; s <= 60; s += 2) {
          live.engine.emit(Duration(seconds: s));
        }
        await tester.pump();
        expect(find.text('Time cap'), findsOneWidget);
        await expectCentred(
          tester,
          aboveTop: underWord(tester, 'Time cap'),
          reason: 'Time cap end ${device.name}',
        );
        await tester.pump(const Duration(seconds: 1));
      });
    }
  });
}
