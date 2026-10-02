import 'dart:async';

import 'package:flutter/material.dart';
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
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/application/setup/live_hints.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/infrastructure/services/i_timer_engine.dart';
import 'package:wod_timer/features/timer/presentation/pages/timer_active_page.dart';

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
        child: MaterialApp.router(routerConfig: router),
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
      final clock = tester.getRect(find.text('9:45'));
      expect(clock.width, greaterThan(390 * 0.9));
      expect(tester.takeException(), isNull);
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

    testWidgets('a 1:00 EMOM interval opens on 60, never 1:00', (
      tester,
    ) async {
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
      expect(tester.getRect(find.text('2/10')).height, greaterThan(70));
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
      final slot = tester.getRect(find.text('TAP TO COUNT')).top;

      later();
      await tester.tapAt(const Offset(195, 300)); // on the clock
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('ROUNDS'), findsOneWidget);
      expect(find.text('TAP TO COUNT'), findsNothing);
      // Same slot: the count sits where the hint was.
      expect(
        (tester.getRect(find.text('1')).top - slot).abs(),
        lessThan(30),
      );
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

    testWidgets('a near miss on the control row does not count a round', (
      tester,
    ) async {
      phone(tester);
      final c = await pumpPage(
        tester,
        workout: amrap(),
        type: TimerTypes.amrap,
        elapsed: const Duration(seconds: 30),
      );
      final pause = tester.getRect(find.bySemanticsLabel('Pause button'));

      later();
      await tester.tapAt(Offset(pause.left - 40, pause.center.dy));
      await tester.pump();

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
      final digits = tester.getRect(find.text('7'));

      engine.emit(const Duration(seconds: 27));
      await tester.pump();

      expect(find.text('NEXT · WORK'), findsOneWidget);
      expect(find.textContaining(' in '), findsNothing);
      final after = tester.getRect(find.text('3'));
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

  group('controls', () {
    testWidgets('running shows one Pause and no Stop', (tester) async {
      await pumpPage(
        tester,
        workout: emom(),
        type: TimerTypes.emom,
        elapsed: const Duration(seconds: 5),
      );
      expect(find.bySemanticsLabel('Pause button'), findsOneWidget);
      expect(
        find.bySemanticsLabel('End workout. Hold to confirm.'),
        findsNothing,
      );
    });

    testWidgets('paused shows Stop beside Resume; tap anywhere resumes', (
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

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.bySemanticsLabel('Resume button'), findsOneWidget);
      expect(
        find.bySemanticsLabel('End workout. Hold to confirm.'),
        findsOneWidget,
      );

      await tester.tapAt(const Offset(195, 300));
      await tester.pump();
      expect(c.read(timerNotifierProvider), isA<TimerRunning>());
    });

    testWidgets('a short press on Stop shows HOLD inside it and moves nothing', (
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
      final clock = tester.getRect(find.text('55'));

      final press = await tester.startGesture(tester.getCenter(stop));
      await tester.pump(const Duration(milliseconds: 200));
      await press.up();
      await tester.pump();

      expect(find.text('HOLD'), findsOneWidget);
      expect(c.read(timerNotifierProvider), isA<TimerPaused>());
      expect(tester.getRect(find.bySemanticsLabel('Resume button')), resume);
      expect(tester.getRect(find.text('55')), clock);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('HOLD'), findsNothing);
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
      // 0.8s of hold plus a frame for the ring to report complete.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await press.up();
      await tester.pump();

      final state = c.read(timerNotifierProvider);
      expect(state, isA<TimerCompleted>());
      expect((state as TimerCompleted).endedEarly, isTrue);
    });

    testWidgets('For Time: FINISH left of Pause, no Stop while running', (
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
      final pause = tester.getRect(find.bySemanticsLabel('Pause button'));
      expect(finish.right, lessThan(pause.left));
      expect((finish.center.dy - pause.center.dy).abs(), lessThan(4));
      expect(
        find.bySemanticsLabel('End workout. Hold to confirm.'),
        findsNothing,
      );
    });

    testWidgets('get ready: one Stop, no Pause, skip hint, phase word', (
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
      expect(
        find.bySemanticsLabel('End workout. Hold to confirm.'),
        findsOneWidget,
      );

      await tester.tapAt(const Offset(200, 200));
      await tester.pump();
      expect(c.read(timerNotifierProvider), isA<TimerRunning>());
      // The skip tap did not also count a round.
      expect(c.read(timerNotifierProvider).sessionOrNull!.currentRound, 1);
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

    testWidgets('a back while paused flashes HOLD on Stop', (tester) async {
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
      expect(find.text('HOLD'), findsOneWidget);
      expect(c.read(timerNotifierProvider), isA<TimerPaused>());
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('completion', () {
    testWidgets('Stopped For Time: one word, one line, one number', (
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
      expect(find.text('TIME'), findsOneWidget);
      expect(find.text('1:05 of 20:00'), findsNothing);
      expect(find.text('Finished!'), findsNothing);
      expect(find.byIcon(Icons.stop_circle_outlined), findsNothing);
    });

    testWidgets('a natural Tabata finish is the word, not 8/8', (
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
      expect(find.text('2/2'), findsNothing);
      expect(find.text('ROUNDS'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
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
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('AMRAP end screen: rounds hero with a working minus / plus', (
      tester,
    ) async {
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
      expect(find.text('1'), findsOneWidget);
      expect(find.text('ROUNDS'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('One round more'));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('One round fewer'));
      await tester.tap(find.bySemanticsLabel('One round fewer'));
      await tester.pump();
      expect(find.text('0'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
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
    });
  });

  group('landscape live screen', () {
    testWidgets('the clock takes the full width and the row holds the rest', (
      tester,
    ) async {
      phone(tester, landscape: true);
      await pumpPage(
        tester,
        workout: emom(),
        type: TimerTypes.emom,
        elapsed: const Duration(seconds: 65),
      );
      expect(tester.takeException(), isNull);

      final clock = tester.getRect(find.text('55'));
      final round = tester.getRect(find.text('2/10'));
      final pause = tester.getRect(find.bySemanticsLabel('Pause button'));
      expect(clock.height, greaterThan(200));
      expect(round.top, greaterThan(clock.bottom - 20));
      expect(pause.left, greaterThan(round.right));
      expect(pause.bottom, lessThan(390));
    });

    testWidgets('MM:SS clock is far taller than the 1.2 123pt', (
      tester,
    ) async {
      phone(tester, landscape: true);
      await pumpPage(
        tester,
        workout: amrap(),
        type: TimerTypes.amrap,
        elapsed: const Duration(seconds: 8),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.text('9:52')).height, greaterThan(180));
    });
  });
}
