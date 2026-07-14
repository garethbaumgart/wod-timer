import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/domain/value_objects/unique_id.dart';
import 'package:wod_timer/core/domain/value_objects/workout_name.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    audio = MockAudioService();
    haptic = MockHapticService();
    engine = FakeTimerEngine();

    when(() => audio.setVoicePack(any())).thenReturn(null);
    when(
      () => audio.setRandomizePerCue(enabled: any(named: 'enabled')),
    ).thenReturn(null);
    when(
      () => audio.setVoiceMuted(muted: any(named: 'muted')),
    ).thenReturn(null);
    when(() => audio.playGo()).thenAnswer((_) async => right(unit));
    when(() => audio.playLetsGo()).thenAnswer((_) async => right(unit));
    when(() => audio.playGoodJob()).thenAnswer((_) async => right(unit));
    when(() => audio.playThatsIt()).thenAnswer((_) async => right(unit));
    when(() => haptic.heavyImpact()).thenAnswer((_) async => right(unit));
    when(() => haptic.mediumImpact()).thenAnswer((_) async => right(unit));
    when(() => haptic.success()).thenAnswer((_) async => right(unit));
  });

  Workout forTimeWorkout({required bool countUp}) => Workout(
    id: UniqueId(),
    name: WorkoutName.defaultForTime,
    timerType: ForTimeTimer(
      timeCap: TimerDuration.fromSeconds(1200), // 20:00 cap
      countUp: countUp,
    ),
    prepCountdown: TimerDuration.zero,
    createdAt: DateTime.now(),
  );

  Future<ProviderContainer> pumpActivePage(
    WidgetTester tester, {
    required bool countUp,
  }) async {
    final container = ProviderContainer(
      overrides: [
        audioServiceProvider.overrideWithValue(audio),
        hapticServiceProvider.overrideWithValue(haptic),
        timerEngineProvider.overrideWithValue(engine),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(timerNotifierProvider.notifier)
        .start(forTimeWorkout(countUp: countUp));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: TimerActivePage(timerType: TimerTypes.forTime),
        ),
      ),
    );

    // 65 seconds into the workout.
    engine.emit(const Duration(seconds: 65));
    await tester.pump();
    return container;
  }

  group('For Time display direction', () {
    // Regression: the count-up toggle used to be dropped at construction,
    // and the display always counted down under an 'Elapsed' label.
    testWidgets('count-up shows elapsed time under "Elapsed"', (tester) async {
      await pumpActivePage(tester, countUp: true);

      expect(find.text('01:05'), findsOneWidget); // elapsed, counting up
      expect(find.text('ELAPSED'), findsOneWidget);
      expect(find.text('REMAINING'), findsNothing);
      expect(find.text('CAP 20:00'), findsOneWidget);
    });

    testWidgets('count-down shows remaining time under "Remaining"', (
      tester,
    ) async {
      await pumpActivePage(tester, countUp: false);

      expect(find.text('18:55'), findsOneWidget); // 20:00 cap - 1:05
      expect(find.text('REMAINING'), findsOneWidget);
      expect(find.text('ELAPSED'), findsNothing);
    });
  });

  group('End-of-workout honesty (UX review round 1)', () {
    // Regression: Stop used to land on "Finished!" with a full green bar
    // even when aborting at 0:19 of a 10:00 workout.
    testWidgets('Stop reports an honest Stopped state', (tester) async {
      final container = await pumpActivePage(tester, countUp: true);

      container.read(timerNotifierProvider.notifier).stop();
      await tester.pump();

      final state = container.read(timerNotifierProvider);
      expect(state, isA<TimerCompleted>());
      expect((state as TimerCompleted).endedEarly, isTrue);
      expect(find.text('Stopped'), findsOneWidget);
      expect(find.text('Finished!'), findsNothing);
      // The honest elapsed-of-planned line: 1:05 of the 20:00 cap.
      expect(find.text('1:05 of 20:00'), findsOneWidget);
    });

    testWidgets('FINISH is offered and completes as an achievement', (
      tester,
    ) async {
      final container = await pumpActivePage(tester, countUp: true);

      // The success action is a labelled, first-class button.
      expect(find.text('FINISH'), findsOneWidget);

      container.read(timerNotifierProvider.notifier).finish();
      await tester.pump();

      final state = container.read(timerNotifierProvider);
      expect(state, isA<TimerCompleted>());
      expect((state as TimerCompleted).endedEarly, isFalse);
      expect(find.text('Finished!'), findsOneWidget);
      expect(find.text('Stopped'), findsNothing);

      // Flush the delayed encouragement cue so no timer is left pending.
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('AMRAP round counting (UX review round 1)', () {
    Workout amrapWorkout() => Workout(
      id: UniqueId(),
      name: WorkoutName.defaultAmrap,
      timerType: AmrapTimer(duration: TimerDuration.fromSeconds(600)),
      prepCountdown: TimerDuration.zero,
      createdAt: DateTime.now(),
    );

    Future<ProviderContainer> pumpAmrapPage(WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          audioServiceProvider.overrideWithValue(audio),
          hapticServiceProvider.overrideWithValue(haptic),
          timerEngineProvider.overrideWithValue(engine),
        ],
      );
      addTearDown(container.dispose);

      await container.read(timerNotifierProvider.notifier).start(
        amrapWorkout(),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: TimerActivePage(timerType: TimerTypes.amrap),
          ),
        ),
      );
      engine.emit(const Duration(seconds: 30));
      await tester.pump();
      return container;
    }

    testWidgets('tap-to-count tallies rounds and survives to completion', (
      tester,
    ) async {
      final container = await pumpAmrapPage(tester);

      expect(find.text('ROUNDS 0'), findsOneWidget);

      container.read(timerNotifierProvider.notifier)
        ..countRound()
        ..countRound();
      await tester.pump();

      expect(find.text('ROUNDS 2'), findsOneWidget);

      // Rounds become the hero stat on the completion screen.
      container.read(timerNotifierProvider.notifier).stop();
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('ROUNDS'), findsOneWidget);
    });
  });

  group('Prep skip (UX review round 1)', () {
    testWidgets('skipPrep jumps straight to the work phase', (tester) async {
      when(() => audio.playGetReady()).thenAnswer((_) async => right(unit));
      when(
        () => audio.playCountdown(any()),
      ).thenAnswer((_) async => right(unit));

      final container = ProviderContainer(
        overrides: [
          audioServiceProvider.overrideWithValue(audio),
          hapticServiceProvider.overrideWithValue(haptic),
          timerEngineProvider.overrideWithValue(engine),
        ],
      );
      addTearDown(container.dispose);

      final workout = Workout(
        id: UniqueId(),
        name: WorkoutName.defaultAmrap,
        timerType: AmrapTimer(duration: TimerDuration.fromSeconds(600)),
        prepCountdown: TimerDuration.fromSeconds(10),
        createdAt: DateTime.now(),
      );

      await container.read(timerNotifierProvider.notifier).start(workout);
      expect(
        container.read(timerNotifierProvider),
        isA<TimerPreparing>(),
      );

      container.read(timerNotifierProvider.notifier).skipPrep();
      expect(container.read(timerNotifierProvider), isA<TimerRunning>());
    });
  });
}
