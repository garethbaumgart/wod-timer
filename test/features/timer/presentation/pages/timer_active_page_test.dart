import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/application/providers/shared_preferences_provider.dart';
import 'package:wod_timer/core/domain/failures/audio_failure.dart';
import 'package:wod_timer/core/domain/value_objects/round_count.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/domain/value_objects/unique_id.dart';
import 'package:wod_timer/core/domain/value_objects/workout_name.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/theme/app_colors.dart';
import 'package:wod_timer/core/presentation/widgets/bottom_slab.dart';
import 'package:wod_timer/core/presentation/widgets/tablet_scale.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/application/setup/live_hints.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/infrastructure/services/i_timer_engine.dart';
import 'package:wod_timer/features/timer/presentation/pages/timer_active_page.dart';
import 'package:wod_timer/features/timer/presentation/widgets/hold_to_stop_cell.dart';
import 'package:wod_timer/features/timer/presentation/widgets/rounds_wheel.dart';
import 'package:wod_timer/features/timer/presentation/widgets/workout_timeline.dart';

class MockAudioService extends Mock implements IAudioService {}

class MockHapticService extends Mock implements IHapticService {}

class FakeTimerEngine implements ITimerEngine {
  final _controller = StreamController<Duration>.broadcast(sync: true);
  Duration _elapsed = Duration.zero;

  @override
  Stream<Duration> get tickStream => _controller.stream;

  void emit(Duration elapsed) {
    _elapsed = elapsed;
    _controller.add(elapsed);
  }

  @override
  Duration get elapsed => _elapsed;
  @override
  bool get isRunning => true;
  @override
  bool get isPaused => false;
  @override
  void start() {}
  @override
  void pause() {}
  @override
  void resume() {}
  @override
  void stop() {}
  @override
  void reset() => _elapsed = Duration.zero;
  @override
  void dispose() => _controller.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAudioService audio;
  late MockHapticService haptic;
  late FakeTimerEngine engine;
  late DateTime now;

  setUp(() {
    audio = MockAudioService();
    haptic = MockHapticService();
    engine = FakeTimerEngine();
    now = DateTime(2026, 10, 3, 6);
    TimerNotifier.clock = () => now;

    when(() => audio.setVoicePack(any())).thenReturn(null);
    when(
      () => audio.setRandomizePerCue(enabled: any(named: 'enabled')),
    ).thenReturn(null);
    when(
      () => audio.setVoiceMuted(muted: any(named: 'muted')),
    ).thenReturn(null);
    for (final cue in <Future<Either<AudioFailure, Unit>> Function()>[
      () => audio.playGo(),
      () => audio.playLetsGo(),
      () => audio.playGoodJob(),
      () => audio.playThatsIt(),
      () => audio.playComplete(),
      () => audio.playGetReady(),
      () => audio.playRest(),
      () => audio.playNextRound(),
      () => audio.playLastRound(),
      () => audio.playHalfway(),
      () => audio.playKeepGoing(),
      () => audio.playComeOn(),
      () => audio.playAlmostThere(),
      () => audio.playTenSeconds(),
      () => audio.playFinalCountdown(),
    ]) {
      when(cue).thenAnswer((_) async => right(unit));
    }
    when(() => audio.playCountdown(any())).thenAnswer((_) async => right(unit));
    when(() => audio.playLowBeep(any())).thenAnswer((_) async => right(unit));
    when(audio.playHighBeep).thenAnswer((_) async => right(unit));
    when(() => haptic.heavyImpact()).thenAnswer((_) async => right(unit));
    when(() => haptic.mediumImpact()).thenAnswer((_) async => right(unit));
    when(() => haptic.success()).thenAnswer((_) async => right(unit));
    when(() => haptic.warning()).thenAnswer((_) async => right(unit));
    when(() => haptic.selectionClick()).thenAnswer((_) async => right(unit));
  });

  tearDown(() => TimerNotifier.clock = DateTime.now);

  Workout amrap({int seconds = 600, int prep = 0}) => Workout(
    id: UniqueId(),
    name: WorkoutName.defaultAmrap,
    timerType: AmrapTimer(duration: TimerDuration.fromSeconds(seconds)),
    prepCountdown: TimerDuration.fromSeconds(prep),
    createdAt: DateTime.now(),
  );

  Workout forTime({required bool countUp, int cap = 1200}) => Workout(
    id: UniqueId(),
    name: WorkoutName.defaultForTime,
    timerType: ForTimeTimer(
      timeCap: TimerDuration.fromSeconds(cap),
      countUp: countUp,
    ),
    prepCountdown: TimerDuration.zero,
    createdAt: DateTime.now(),
  );

  Workout emom({int interval = 60, int rounds = 10}) => Workout(
    id: UniqueId(),
    name: WorkoutName.defaultEmom,
    timerType: EmomTimer(
      intervalDuration: TimerDuration.fromSeconds(interval),
      rounds: RoundCount.fromInt(rounds),
    ),
    prepCountdown: TimerDuration.zero,
    createdAt: DateTime.now(),
  );

  Workout tabata({int rounds = 8}) => Workout(
    id: UniqueId(),
    name: WorkoutName.defaultTabata,
    timerType: TabataTimer(
      workDuration: TimerDuration.fromSeconds(20),
      restDuration: TimerDuration.fromSeconds(10),
      rounds: RoundCount.fromInt(rounds),
    ),
    prepCountdown: TimerDuration.zero,
    createdAt: DateTime.now(),
  );

  void phone(WidgetTester tester, {bool landscape = false}) {
    tester.view
      ..physicalSize = landscape
          ? const Size(2532, 1170)
          : const Size(1170, 2532) // iPhone 16e
      ..devicePixelRatio = 3;
    if (landscape) {
      tester.view.padding = const FakeViewPadding(
        left: 141,
        right: 141,
        bottom: 63,
      );
    }
    addTearDown(tester.view.reset);
  }

  /// Pumps the live page inside a router whose setup route is a marker, so
  /// DONE and the back gesture can be observed.
  Future<ProviderContainer> pumpPage(
    WidgetTester tester, {
    required Workout workout,
    required String type,
    Duration elapsed = Duration.zero,
    Map<String, Object> prefs = const {},
    bool tablet = false,
    double textScale = 1,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sharedPrefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        audioServiceProvider.overrideWithValue(audio),
        hapticServiceProvider.overrideWithValue(haptic),
        timerEngineProvider.overrideWithValue(engine),
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
    );
    addTearDown(container.dispose);

    await container.read(timerNotifierProvider.notifier).start(workout);

    final router = GoRouter(
      initialLocation: AppRoutes.timerActivePath(type),
      routes: [
        GoRoute(
          path: AppRoutes.timerSetup,
          builder: (context, state) =>
              Text('SETUP ${state.pathParameters['timerType']}'),
          routes: [
            GoRoute(
              path: 'active',
              builder: (context, state) => TimerActivePage(timerType: type),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          // As in the app: tablets get the phone layout scaled up.
          builder: (context, child) {
            final scaled = MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            );
            return tablet ? TabletScale(child: scaled) : scaled;
          },
        ),
      ),
    );
    if (elapsed > Duration.zero) engine.emit(elapsed);
    await tester.pump();
    return container;
  }

  TimerNotifier notifierOf(ProviderContainer c) =>
      c.read(timerNotifierProvider.notifier);

  /// Advance the fake clock past the round-count cooldown.
  void later() => now = now.add(const Duration(seconds: 1));

  Finder clockText(String text) => find.byWidgetPredicate(
    (w) => w is Text && w.data == text && w.textScaler == TextScaler.noScaling,
  );

  Color cellColor(WidgetTester tester, String semanticsLabel) {
    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.bySemanticsLabel(semanticsLabel),
            matching: find.byType(Material),
          )
          .first,
    );
    return material.color!;
  }

  group('the clock', () {
    testWidgets('minutes are never zero-padded and fill the width', (
      tester,
    ) async {
      phone(tester);
      await pumpPage(
        tester,
        workout: amrap(),
        type: TimerTypes.amrap,
        elapsed: const Duration(seconds: 15),
      );

      expect(find.text('9:45'), findsOneWidget);
      expect(find.text('09:45'), findsNothing);
      // Sized for the workout's longest value, 10:00, which fills the
      // width; 9:45 is one glyph narrower at the same size.
      final clock = tester.getRect(find.text('9:45'));
      expect(clock.width, greaterThan(390 * 0.6));
      expect(tester.takeException(), isNull);

      await pumpPage(tester, workout: amrap(), type: TimerTypes.amrap);
      expect(tester.getRect(find.text('10:00')).width, greaterThan(390 * 0.85));
    });

    testWidgets('count-up For Time reads 1:05, count-down 18:55', (
      tester,
    ) async {
      await pumpPage(
        tester,
        workout: forTime(countUp: true),
        type: TimerTypes.forTime,
        elapsed: const Duration(seconds: 65),
      );
      expect(find.text('1:05'), findsOneWidget);
    });

    testWidgets('count-down For Time has no cap line under the clock', (
      tester,
    ) async {
      await pumpPage(
        tester,
        workout: forTime(countUp: false),
        type: TimerTypes.forTime,
        elapsed: const Duration(seconds: 65),
      );
      expect(find.text('18:55'), findsOneWidget);
      expect(find.textContaining('CAP'), findsNothing);
    });

    testWidgets('a 1:00 EMOM interval opens on 60, never 1:00', (tester) async {
      await pumpPage(tester, workout: emom(), type: TimerTypes.emom);

      expect(find.text('60'), findsOneWidget);
      expect(find.text('1:00'), findsNothing);
      expect(find.text('01:00'), findsNothing);
    });

    testWidgets('no direction label, no mode pill', (tester) async {
      final c = await pumpPage(
        tester,
        workout: tabata(),
        type: TimerTypes.tabata,
        elapsed: const Duration(seconds: 23),
      );
      expect(find.text('REMAINING'), findsNothing);
      expect(find.text('ELAPSED'), findsNothing);
      expect(find.textContaining('TABATA  ·'), findsNothing);

      notifierOf(c).pause();
      await tester.pump();
      expect(find.textContaining('AMRAP  ·'), findsNothing);
      expect(find.text('REMAINING'), findsNothing);
    });

    // Layout rule 1: the size is set once per workout from its longest
    // value, so going from two digits to one changes nothing but the text.
    testWidgets('keeps one size per workout as the digits shrink', (
      tester,
    ) async {
      phone(tester);
      await pumpPage(
        tester,
        workout: emom(),
        type: TimerTypes.emom,
        elapsed: const Duration(seconds: 5),
      );
      final two = tester.widget<Text>(clockText('55'));
      final twoRect = tester.getRect(clockText('55'));
      final timeline = tester.getRect(find.byType(WorkoutTimeline));
      final round = tester.getRect(find.text('1/10'));

      engine.emit(const Duration(seconds: 51));
      await tester.pump();

      final one = tester.widget<Text>(clockText('9'));
      expect(one.style!.fontSize, two.style!.fontSize);
      final oneRect = tester.getRect(clockText('9'));
      expect(oneRect.top, twoRect.top);
      expect(oneRect.height, twoRect.height);
      expect(oneRect.center.dx, closeTo(twoRect.center.dx, 0.5));
      expect(tester.getRect(find.byType(WorkoutTimeline)), timeline);
      expect(tester.getRect(find.text('1/10')), round);
    });

    testWidgets('wears the workout colour: orange, pink, blue, green / pink', (
      tester,
    ) async {
      await pumpPage(
        tester,
        workout: forTime(countUp: true),
        type: TimerTypes.forTime,
        elapsed: const Duration(seconds: 65),
      );
      expect(
        tester.widget<Text>(clockText('1:05')).style!.color,
        AppColors.forTimeAccent,
      );

      await pumpPage(
        tester,
        workout: emom(),
        type: TimerTypes.emom,
        elapsed: const Duration(seconds: 5),
      );
      expect(
        tester.widget<Text>(clockText('55')).style!.color,
        AppColors.emomAccent,
      );

      await pumpPage(
        tester,
        workout: amrap(),
        type: TimerTypes.amrap,
        elapsed: const Duration(seconds: 15),
      );
      expect(
        tester.widget<Text>(clockText('9:45')).style!.color,
        AppColors.amrapAccent,
      );

      await pumpPage(
        tester,
        workout: tabata(),
        type: TimerTypes.tabata,
        elapsed: const Duration(seconds: 12),
      );
      expect(tester.widget<Text>(clockText('8')).style!.color, AppColors.work);
      engine.emit(const Duration(seconds: 23));
      await tester.pump();
      expect(tester.widget<Text>(clockText('7')).style!.color, AppColors.rest);
    });

    testWidgets('the get-ready countdown is white, GET READY too', (
      tester,
    ) async {
      await pumpPage(tester, workout: amrap(prep: 10), type: TimerTypes.amrap);
      expect(tester.widget<Text>(clockText('10')).style!.color, Colors.white);
      expect(
        tester.widget<Text>(find.text('GET READY')).style!.color,
        Colors.white,
      );
    });
  });

  group('the second number', () {
    testWidgets('EMOM shows the round as a big bare fraction', (tester) async {
      phone(tester);
      await pumpPage(
        tester,
        workout: emom(),
        type: TimerTypes.emom,
        elapsed: const Duration(seconds: 65),
      );

      expect(find.text('2/10'), findsOneWidget);
      expect(find.textContaining('ROUND '), findsNothing);
      expect(tester.getRect(find.text('2/10')).height, greaterThan(60));
      expect(find.text('55'), findsOneWidget);
    });

    testWidgets('AMRAP teaches TAP TO COUNT once, then shows the count', (
      tester,
    ) async {
      phone(tester);
      final c = await pumpPage(
        tester,
        workout: amrap(),
        type: TimerTypes.amrap,
        elapsed: const Duration(seconds: 30),
      );
      expect(find.text('TAP TO COUNT'), findsOneWidget);
      final hint = tester.getRect(find.text('TAP TO COUNT'));
      final timeline = tester.getRect(find.byType(WorkoutTimeline));
      final clock = tester.getRect(clockText('9:30'));

      later();
      await tester.tapAt(const Offset(195, 300)); // on the clock
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('ROUNDS'), findsOneWidget);
      expect(find.text('TAP TO COUNT'), findsNothing);
      // Same slot and baseline: the count sits where the hint was, and
      // nothing around it moved.
      final count = tester.getRect(find.text('1'));
      expect(count.top, lessThanOrEqualTo(hint.top));
      expect((count.bottom - hint.bottom).abs(), lessThan(14));
      expect(tester.getRect(find.byType(WorkoutTimeline)), timeline);
      expect(tester.getRect(clockText('9:30')), clock);
      expect(c.read(liveHintsProvider).hasCountedRound, isTrue);
    });

    testWidgets('after the first ever count, zero reads 0 ROUNDS', (
      tester,
    ) async {
      await pumpPage(
        tester,
        workout: amrap(),
        type: TimerTypes.amrap,
        elapsed: const Duration(seconds: 30),
        prefs: {LiveHints.countedRoundKey: true},
      );
      expect(find.text('TAP TO COUNT'), findsNothing);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('ROUNDS'), findsOneWidget);
    });

    testWidgets('a tap on the slab never counts a round', (tester) async {
      phone(tester);
      final c = await pumpPage(
        tester,
        workout: amrap(),
        type: TimerTypes.amrap,
        elapsed: const Duration(seconds: 30),
      );

      later();
      // The slab's bottom corner, under PAUSE's label.
      await tester.tapAt(const Offset(12, 844 - 6));
      await tester.pump();

      expect(c.read(timerNotifierProvider), isA<TimerPaused>());
      expect(c.read(timerNotifierProvider).sessionOrNull!.currentRound, 1);
    });

    testWidgets('For Time count-up carries the cap as the second line', (
      tester,
    ) async {
      await pumpPage(
        tester,
        workout: forTime(countUp: true),
        type: TimerTypes.forTime,
        elapsed: const Duration(seconds: 65),
      );
      expect(find.text('CAP 20:00'), findsOneWidget);
    });
  });

  group('phase word', () {
    testWidgets('Tabata names the next phase in its last five seconds, '
        'and the digits do not move', (tester) async {
      phone(tester);
      await pumpPage(
        tester,
        workout: tabata(),
        type: TimerTypes.tabata,
        elapsed: const Duration(seconds: 23),
      );
      expect(find.text('REST'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('REST')).style!.color,
        AppColors.rest,
      );
      final digits = tester.getRect(clockText('7'));

      engine.emit(const Duration(seconds: 27));
      await tester.pump();

      expect(find.text('NEXT · WORK'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('NEXT · WORK')).style!.color,
        AppColors.work,
      );
      expect(find.textContaining(' in '), findsNothing);
      final after = tester.getRect(clockText('3'));
      expect(after.top, digits.top);
      expect(after.height, digits.height);

      engine.emit(const Duration(seconds: 47));
      await tester.pump();
      expect(find.text('NEXT · REST'), findsOneWidget);
    });

    testWidgets('the final rest reads LAST REST', (tester) async {
      await pumpPage(
        tester,
        workout: tabata(rounds: 2),
        type: TimerTypes.tabata,
        elapsed: const Duration(seconds: 52),
      );
      expect(find.text('LAST REST'), findsOneWidget);
    });

    testWidgets('a paused Tabata says which phase resumes', (tester) async {
      final c = await pumpPage(
        tester,
        workout: tabata(),
        type: TimerTypes.tabata,
        elapsed: const Duration(seconds: 12),
      );
      notifierOf(c).pause();
      await tester.pump();

      expect(find.text('PAUSED · WORK'), findsOneWidget);
      expect(find.text('8'), findsOneWidget); // not 0: the 1.2 bug
    });
  });

  group('the slab', () {
    testWidgets('running shows one PAUSE, white on soft, no Stop', (
      tester,
    ) async {
      phone(tester);
      await pumpPage(
        tester,
        workout: emom(),
        type: TimerTypes.emom,
        elapsed: const Duration(seconds: 5),
      );
      expect(find.bySemanticsLabel('Pause button'), findsOneWidget);
      expect(find.text('PAUSE'), findsOneWidget);
      expect(
        find.bySemanticsLabel('End workout. Hold to confirm.'),
        findsNothing,
      );
      expect(cellColor(tester, 'Pause button'), AppColors.soft);
      final slab = tester.getRect(find.byType(BottomSlab));
      expect(slab, const Rect.fromLTWH(0, 844 - 132, 390, 132));
      expect(tester.getRect(find.bySemanticsLabel('Pause button')).width, 390);
    });

    testWidgets('paused shows HOLD TO STOP beside RESUME; tap anywhere '
        'resumes', (tester) async {
      phone(tester);
      final c = await pumpPage(
        tester,
        workout: emom(),
        type: TimerTypes.emom,
        elapsed: const Duration(seconds: 5),
      );
      notifierOf(c).pause();
      await tester.pump();

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('HOLD TO STOP'), findsOneWidget);
      expect(find.text('RESUME'), findsOneWidget);
      expect(find.bySemanticsLabel('Resume button'), findsOneWidget);
      expect(
        find.bySemanticsLabel('End workout. Hold to confirm.'),
        findsOneWidget,
      );
      final stop = tester.getRect(
        find.bySemanticsLabel('End workout. Hold to confirm.'),
      );
      final resume = tester.getRect(find.bySemanticsLabel('Resume button'));
      expect(stop.right, resume.left);
      expect(stop.width, resume.width);
      expect(cellColor(tester, 'Resume button'), AppColors.emomAccent);
      expect(
        tester.widget<Text>(find.text('HOLD TO STOP')).style!.color,
        AppColors.stopRed,
      );

      await tester.tapAt(const Offset(195, 300));
      await tester.pump();
      expect(c.read(timerNotifierProvider), isA<TimerRunning>());
    });

    testWidgets('a short press on HOLD TO STOP hints and moves nothing', (
      tester,
    ) async {
      phone(tester);
      final c = await pumpPage(
        tester,
        workout: emom(),
        type: TimerTypes.emom,
        elapsed: const Duration(seconds: 5),
      );
      notifierOf(c).pause();
      await tester.pump();
      final stop = find.bySemanticsLabel('End workout. Hold to confirm.');
      final resume = tester.getRect(find.bySemanticsLabel('Resume button'));
      final clock = tester.getRect(clockText('55'));

      final press = await tester.startGesture(tester.getCenter(stop));
      await tester.pump(const Duration(milliseconds: 200));
      await press.up();
      await tester.pump();

      expect(
        tester.widget<HoldToStopCell>(find.byType(HoldToStopCell)).showHint,
        isTrue,
      );
      expect(c.read(timerNotifierProvider), isA<TimerPaused>());
      expect(tester.getRect(find.bySemanticsLabel('Resume button')), resume);
      expect(tester.getRect(clockText('55')), clock);
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester.widget<HoldToStopCell>(find.byType(HoldToStopCell)).showHint,
        isFalse,
      );
    });

    testWidgets('holding Stop for 0.8s ends the workout honestly', (
      tester,
    ) async {
      final c = await pumpPage(
        tester,
        workout: emom(),
        type: TimerTypes.emom,
        elapsed: const Duration(seconds: 5),
      );
      notifierOf(c).pause();
      await tester.pump();
      final stop = find.bySemanticsLabel('End workout. Hold to confirm.');

      final press = await tester.startGesture(tester.getCenter(stop));
      // 0.8s of hold plus a frame for the fill to report complete.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await press.up();
      await tester.pump();

      final state = c.read(timerNotifierProvider);
      expect(state, isA<TimerCompleted>());
      expect((state as TimerCompleted).endedEarly, isTrue);
    });

    testWidgets('For Time: FINISH (white) left of PAUSE, no Stop running', (
      tester,
    ) async {
      phone(tester);
      await pumpPage(
        tester,
        workout: forTime(countUp: true),
        type: TimerTypes.forTime,
        elapsed: const Duration(seconds: 65),
      );
      final finish = tester.getRect(find.text('FINISH'));
      final pause = tester.getRect(find.text('PAUSE'));
      expect(finish.right, lessThan(pause.left));
      expect((finish.center.dy - pause.center.dy).abs(), lessThan(1));
      expect(
        cellColor(tester, 'Finish workout and log your time'),
        Colors.white,
      );
      expect(
        find.bySemanticsLabel('End workout. Hold to confirm.'),
        findsNothing,
      );
    });

    testWidgets('get ready: HOLD TO STOP alone, skip hint, GET READY', (
      tester,
    ) async {
      final c = await pumpPage(
        tester,
        workout: amrap(prep: 10),
        type: TimerTypes.amrap,
      );
      expect(c.read(timerNotifierProvider), isA<TimerPreparing>());
      expect(find.text('GET READY'), findsOneWidget);
      expect(find.text('TAP TO SKIP'), findsOneWidget);
      expect(find.text('STARTS IN'), findsNothing);
      expect(find.bySemanticsLabel('Pause button'), findsNothing);
      expect(find.text('PAUSE'), findsNothing);
      expect(
        find.bySemanticsLabel('End workout. Hold to confirm.'),
        findsOneWidget,
      );
      // The timeline shows the track, unfilled.
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(WorkoutTimeline),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as TimelinePainter;
      expect(painter.elapsedSeconds, 0);

      await tester.tapAt(const Offset(200, 200));
      await tester.pump();
      expect(c.read(timerNotifierProvider), isA<TimerRunning>());
      // The skip tap did not also count a round.
      expect(c.read(timerNotifierProvider).sessionOrNull!.currentRound, 1);
    });
  });

  group('the timeline', () {
    testWidgets('fills as the workout runs, parts in their colours', (
      tester,
    ) async {
      phone(tester);
      await pumpPage(
        tester,
        workout: tabata(),
        type: TimerTypes.tabata,
        elapsed: const Duration(seconds: 23),
      );
      TimelinePainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(WorkoutTimeline),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as TimelinePainter;
      expect(painter().shape.parts, hasLength(16));
      expect(painter().elapsedSeconds, 23);
      expect(painter().shape.colorOf(painter().shape.parts[1]), AppColors.rest);
      expect(tester.getSize(find.byType(WorkoutTimeline)).height, 14);

      engine.emit(const Duration(seconds: 40));
      await tester.pump();
      expect(painter().elapsedSeconds, 40);
      // Between the second line and the slab.
      final timeline = tester.getRect(find.byType(WorkoutTimeline));
      expect(
        timeline.top,
        greaterThan(tester.getRect(find.text('2/8')).bottom),
      );
      expect(
        timeline.bottom,
        lessThan(tester.getRect(find.byType(BottomSlab)).top),
      );
    });
  });

  group('back gesture', () {
    testWidgets('a back while running does nothing', (tester) async {
      final c = await pumpPage(
        tester,
        workout: emom(),
        type: TimerTypes.emom,
        elapsed: const Duration(seconds: 5),
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(c.read(timerNotifierProvider), isA<TimerRunning>());
      expect(find.text('SETUP emom'), findsNothing);
    });

    testWidgets('a back while paused hints on HOLD TO STOP', (tester) async {
      final c = await pumpPage(
        tester,
        workout: emom(),
        type: TimerTypes.emom,
        elapsed: const Duration(seconds: 5),
      );
      notifierOf(c).pause();
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(
        tester.widget<HoldToStopCell>(find.byType(HoldToStopCell)).showHint,
        isTrue,
      );
      expect(c.read(timerNotifierProvider), isA<TimerPaused>());
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('completion', () {
    testWidgets('Stopped For Time: word, config, the time in orange', (
      tester,
    ) async {
      final c = await pumpPage(
        tester,
        workout: forTime(countUp: true),
        type: TimerTypes.forTime,
        elapsed: const Duration(seconds: 65),
      );
      notifierOf(c).stop();
      await tester.pump();

      expect(find.text('Stopped'), findsOneWidget);
      expect(find.text('FOR TIME  ·  CAP 20:00'), findsOneWidget);
      expect(find.text('1:05'), findsOneWidget); // the hero, once
      expect(
        tester.widget<Text>(find.text('1:05')).style!.color,
        AppColors.forTimeAccent,
      );
      expect(find.text('TIME'), findsOneWidget);
      expect(find.text('1:05 of 20:00'), findsNothing);
      expect(find.text('Finished!'), findsNothing);
      expect(
        tester.widget<Text>(find.text('Stopped')).style!.color,
        Colors.white,
      );
      expect(tester.widget<Text>(find.text('Stopped')).style!.fontSize, 30);
    });

    testWidgets('a natural Tabata finish shows 2/2 ROUNDS and the total', (
      tester,
    ) async {
      final c = await pumpPage(
        tester,
        workout: tabata(rounds: 2),
        type: TimerTypes.tabata,
      );
      engine.emit(const Duration(seconds: 60));
      await tester.pump();
      expect(c.read(timerNotifierProvider), isA<TimerCompleted>());

      expect(find.text('Finished'), findsOneWidget);
      expect(find.text('TABATA  ·  2 × 20s / 10s'), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('2/2')).style!.color,
        AppColors.tabataAccent,
      );
      expect(find.text('ROUNDS'), findsOneWidget);
      expect(find.text('1:00 total'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('a stopped EMOM shows 3/10 ROUNDS and the elapsed total', (
      tester,
    ) async {
      final c = await pumpPage(
        tester,
        workout: emom(),
        type: TimerTypes.emom,
        elapsed: const Duration(seconds: 125),
      );
      notifierOf(c).stop();
      await tester.pump();

      expect(find.text('Stopped'), findsOneWidget);
      expect(find.text('3/10'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('3/10')).style!.color,
        AppColors.emomAccent,
      );
      expect(find.text('ROUNDS'), findsOneWidget);
      expect(find.text('2:05 total'), findsOneWidget);
      // The timeline is filled to where it stopped.
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(WorkoutTimeline),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as TimelinePainter;
      expect(painter.elapsedSeconds, 125);
    });

    testWidgets('reaching the For Time cap reads Time cap, no score', (
      tester,
    ) async {
      final c = await pumpPage(
        tester,
        workout: forTime(countUp: true, cap: 60),
        type: TimerTypes.forTime,
      );
      for (var s = 2; s <= 60; s += 2) {
        engine.emit(Duration(seconds: s));
      }
      await tester.pump();
      expect(c.read(timerNotifierProvider).endedAtTimeCap, isTrue);

      expect(find.text('Time cap'), findsOneWidget);
      expect(find.text('Finished'), findsNothing);
      expect(find.text('TIME'), findsNothing);
      expect(find.text('1:00'), findsNothing);
      // The timeline is full.
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(WorkoutTimeline),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as TimelinePainter;
      expect(painter.elapsedSeconds, 60);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('AMRAP end screen: a rounds wheel to fix the count', (
      tester,
    ) async {
      phone(tester);
      final c = await pumpPage(
        tester,
        workout: amrap(seconds: 60),
        type: TimerTypes.amrap,
        elapsed: const Duration(seconds: 5),
      );
      later();
      notifierOf(c).countRound();
      engine.emit(const Duration(seconds: 60));
      await tester.pump();

      expect(find.text('Finished'), findsOneWidget);
      expect(find.byType(RoundsWheel), findsOneWidget);
      expect(tester.widget<RoundsWheel>(find.byType(RoundsWheel)).rounds, 1);
      expect(
        tester.widget<Text>(find.text('1')).style!.color,
        AppColors.amrapAccent,
      );
      expect(
        tester.widget<Text>(find.text('2')).style!.color,
        AppColors.wheelDim,
      );
      expect(find.text('ROUNDS'), findsOneWidget);
      expect(find.text('Scroll to fix the count'), findsOneWidget);
      expect(find.bySemanticsLabel('One round more'), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);

      // Scroll the wheel one row up: one more round.
      final itemHeight = RoundsWheel.itemHeightFor(
        tester.widget<RoundsWheel>(find.byType(RoundsWheel)).fontSize,
      );
      await tester.drag(find.byType(RoundsWheel), Offset(0, -itemHeight));
      await tester.pumpAndSettle();
      expect(c.read(timerNotifierProvider).sessionOrNull!.currentRound, 3);
      expect(tester.widget<RoundsWheel>(find.byType(RoundsWheel)).rounds, 2);

      // And it is adjustable without a drag.
      final handle = tester.ensureSemantics();
      await tester.pump();
      final node = tester.getSemantics(find.bySemanticsLabel('Rounds'));
      expect(node, containsSemantics(value: '2', hasDecreaseAction: true));
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.decrease,
      );
      await tester.pumpAndSettle();
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.decrease,
      );
      await tester.pumpAndSettle();
      handle.dispose();
      expect(c.read(timerNotifierProvider).sessionOrNull!.currentRound, 1);
      expect(tester.widget<RoundsWheel>(find.byType(RoundsWheel)).rounds, 0);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('AGAIN wears the workout colour, DONE the soft fill', (
      tester,
    ) async {
      phone(tester);
      final c = await pumpPage(
        tester,
        workout: tabata(),
        type: TimerTypes.tabata,
        elapsed: const Duration(seconds: 5),
      );
      notifierOf(c).stop();
      await tester.pump();

      expect(
        cellColor(tester, 'Run the same workout again'),
        AppColors.tabataAccent,
      );
      expect(cellColor(tester, 'Done, back to setup'), AppColors.soft);
      final again = tester.getRect(
        find.bySemanticsLabel('Run the same workout again'),
      );
      final done = tester.getRect(find.bySemanticsLabel('Done, back to setup'));
      expect(again.right, done.left);
      expect(done.bottom, 844);
      expect(tester.getRect(find.byType(BottomSlab)).height, 132);
    });

    testWidgets("DONE lands on this mode's setup", (tester) async {
      final c = await pumpPage(
        tester,
        workout: emom(),
        type: TimerTypes.emom,
        elapsed: const Duration(seconds: 5),
      );
      notifierOf(c).stop();
      await tester.pump();

      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();

      expect(find.text('SETUP emom'), findsOneWidget);
      expect(c.read(timerNotifierProvider), isA<TimerInitial>());
    });

    testWidgets('the AMRAP wheel fits a phone sideways and large text', (
      tester,
    ) async {
      for (final (landscape, scale) in [(true, 1.0), (false, 1.6)]) {
        phone(tester, landscape: landscape);
        final c = await pumpPage(
          tester,
          workout: amrap(seconds: 60),
          type: TimerTypes.amrap,
          elapsed: const Duration(seconds: 5),
          textScale: scale,
        );
        later();
        notifierOf(c).countRound();
        engine.emit(const Duration(seconds: 60));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'landscape $landscape');
        final wheel = tester.getRect(find.byType(RoundsWheel));
        final hint = tester.getRect(find.text('Scroll to fix the count'));
        final timeline = tester.getRect(find.byType(WorkoutTimeline));
        final slab = tester.getRect(find.byType(BottomSlab));
        expect(hint.top, greaterThanOrEqualTo(wheel.bottom - 0.01));
        expect(timeline.top, greaterThan(hint.bottom));
        expect(timeline.bottom, lessThan(slab.top));
        await tester.pump(const Duration(seconds: 1));
      }
    });

    testWidgets('portrait and landscape completion lay out cleanly', (
      tester,
    ) async {
      phone(tester, landscape: true);
      final c = await pumpPage(
        tester,
        workout: amrap(),
        type: TimerTypes.amrap,
        elapsed: const Duration(seconds: 19),
      );
      notifierOf(c).stop();
      await tester.pump();
      expect(tester.takeException(), isNull);
      final again = tester.getRect(find.text('AGAIN'));
      expect(again.bottom, lessThan(390));
      expect(tester.getRect(find.byType(BottomSlab)).height, 96);
    });
  });

  group('landscape live screen', () {
    testWidgets('the clock on top, the round under it, the slab along the '
        'bottom', (tester) async {
      phone(tester, landscape: true);
      await pumpPage(
        tester,
        workout: emom(),
        type: TimerTypes.emom,
        elapsed: const Duration(seconds: 65),
      );
      expect(tester.takeException(), isNull);

      final clock = tester.getRect(clockText('55'));
      final round = tester.getRect(find.text('2/10'));
      final pause = tester.getRect(find.bySemanticsLabel('Pause button'));
      final slab = tester.getRect(find.byType(BottomSlab));
      expect(clock.height, greaterThan(100));
      expect(round.top, greaterThanOrEqualTo(clock.bottom - 1));
      expect(pause.top, greaterThan(round.bottom));
      // Along the bottom, inside the notch's side insets.
      expect(slab, const Rect.fromLTWH(47, 390 - 96, 844 - 94, 96));
      final timeline = tester.getRect(find.byType(WorkoutTimeline));
      expect(timeline.top, greaterThan(round.bottom));
      expect(timeline.bottom, lessThan(slab.top));
    });

    testWidgets('MM:SS clock stays big in the shorter slot', (tester) async {
      phone(tester, landscape: true);
      await pumpPage(
        tester,
        workout: amrap(),
        type: TimerTypes.amrap,
        elapsed: const Duration(seconds: 8),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getRect(clockText('9:52')).height, greaterThan(120));
    });
  });

  // 1.3.1: an iPad lays the live screen out at a 600pt shortest side and
  // scales it to fill, so every slot grows with the screen.
  group('iPad', () {
    void ipad(WidgetTester tester, {bool landscape = false}) {
      tester.view
        ..physicalSize = landscape
            ? const Size(2752, 2064)
            : const Size(2064, 2752) // iPad Pro 13in
        ..devicePixelRatio = 2;
      addTearDown(tester.view.reset);
    }

    testWidgets('portrait: the round hint is bigger than on a phone', (
      tester,
    ) async {
      phone(tester);
      await pumpPage(tester, workout: amrap(), type: TimerTypes.amrap);
      final onPhone = tester.getRect(find.text('TAP TO COUNT')).height;

      ipad(tester);
      await pumpPage(
        tester,
        workout: amrap(),
        type: TimerTypes.amrap,
        tablet: true,
      );
      expect(tester.takeException(), isNull);
      final onIpad = tester.getRect(find.text('TAP TO COUNT'));
      expect(onIpad.height, greaterThan(onPhone * 1.5));
      final pause = tester.getRect(find.bySemanticsLabel('Pause button'));
      expect(pause.bottom, closeTo(1376, 1));
      expect(pause.width, closeTo(1032, 1));
    });

    testWidgets('landscape live, paused and end screens fit', (tester) async {
      ipad(tester, landscape: true);
      final c = await pumpPage(
        tester,
        workout: emom(),
        type: TimerTypes.emom,
        elapsed: const Duration(seconds: 65),
        tablet: true,
      );
      expect(tester.takeException(), isNull);
      final pause = tester.getRect(find.bySemanticsLabel('Pause button'));
      expect(pause.bottom, lessThanOrEqualTo(1032 + 1));
      expect(pause.right, lessThanOrEqualTo(1376 + 1));

      notifierOf(c).pause();
      await tester.pump();
      expect(tester.takeException(), isNull);

      notifierOf(c).stop();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.text('AGAIN')).bottom, lessThan(1032));
    });
  });
}
