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
    when(() => audio.playGo()).thenAnswer((_) async => right(unit));
    when(() => audio.playLetsGo()).thenAnswer((_) async => right(unit));
    when(() => haptic.heavyImpact()).thenAnswer((_) async => right(unit));
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
      expect(find.text('Elapsed'), findsOneWidget);
      expect(find.text('Remaining'), findsNothing);
    });

    testWidgets('count-down shows remaining time under "Remaining"', (
      tester,
    ) async {
      await pumpActivePage(tester, countUp: false);

      expect(find.text('18:55'), findsOneWidget); // 20:00 cap - 1:05
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('Elapsed'), findsNothing);
    });
  });
}
