import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wod_timer/core/domain/value_objects/round_count.dart';
import 'package:wod_timer/core/domain/value_objects/timer_duration.dart';
import 'package:wod_timer/core/domain/value_objects/unique_id.dart';
import 'package:wod_timer/core/domain/value_objects/workout_name.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_notifier.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/value_objects/timer_type.dart';
import 'package:wod_timer/features/timer/infrastructure/services/i_timer_engine.dart';

class MockAudioService extends Mock implements IAudioService {}

class MockHapticService extends Mock implements IHapticService {}

/// A timer engine the test drives by hand via [emit].
class FakeTimerEngine implements ITimerEngine {
  final _controller = StreamController<Duration>.broadcast(sync: true);

  /// Number of currently-active tick subscriptions (leak detector).
  int activeListeners = 0;

  Duration _elapsed = Duration.zero;
  bool _running = false;
  bool _paused = false;

  @override
  Stream<Duration> get tickStream => Stream<Duration>.multi((listener) {
    activeListeners++;
    final sub = _controller.stream.listen(listener.addSync);
    listener.onCancel = () {
      activeListeners--;
      sub.cancel();
    };
  });

  void emit(Duration elapsed) {
    _elapsed = elapsed;
    _controller.add(elapsed);
  }

  @override
  Duration get elapsed => _elapsed;

  @override
  bool get isRunning => _running;

  @override
  bool get isPaused => _paused;

  @override
  void start() {
    _running = true;
    _paused = false;
  }

  @override
  void pause() => _paused = true;

  @override
  void resume() => _paused = false;

  @override
  void stop() {
    _running = false;
    _paused = false;
  }

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
  late ProviderContainer container;

  Workout emomWorkout({
    int intervalSeconds = 60,
    int rounds = 3,
    int prepSeconds = 0,
  }) => Workout(
    id: UniqueId(),
    name: WorkoutName.defaultEmom,
    timerType: EmomTimer(
      intervalDuration: TimerDuration.fromSeconds(intervalSeconds),
      rounds: RoundCount.fromInt(rounds),
    ),
    prepCountdown: TimerDuration.fromSeconds(prepSeconds),
    createdAt: DateTime.now(),
  );

  Workout amrapWorkout({int seconds = 600, int prepSeconds = 0}) => Workout(
    id: UniqueId(),
    name: WorkoutName.defaultAmrap,
    timerType: AmrapTimer(duration: TimerDuration.fromSeconds(seconds)),
    prepCountdown: TimerDuration.fromSeconds(prepSeconds),
    createdAt: DateTime.now(),
  );

  setUp(() {
    audio = MockAudioService();
    haptic = MockHapticService();
    engine = FakeTimerEngine();

    when(() => audio.preloadSounds()).thenAnswer((_) async {});
    when(() => audio.setVoicePack(any())).thenReturn(null);
    when(
      () => audio.setRandomizePerCue(enabled: any(named: 'enabled')),
    ).thenReturn(null);
    when(() => audio.playGo()).thenAnswer((_) async => right(unit));
    when(() => audio.playLetsGo()).thenAnswer((_) async => right(unit));
    when(() => audio.playGetReady()).thenAnswer((_) async => right(unit));
    when(() => audio.playCountdown(any())).thenAnswer((_) async => right(unit));
    when(() => audio.playRest()).thenAnswer((_) async => right(unit));
    when(() => audio.playNextRound()).thenAnswer((_) async => right(unit));
    when(() => audio.playLastRound()).thenAnswer((_) async => right(unit));
    when(() => audio.playHalfway()).thenAnswer((_) async => right(unit));
    when(() => audio.playKeepGoing()).thenAnswer((_) async => right(unit));
    when(() => audio.playComeOn()).thenAnswer((_) async => right(unit));
    when(() => audio.playAlmostThere()).thenAnswer((_) async => right(unit));
    when(() => audio.playTenSeconds()).thenAnswer((_) async => right(unit));
    when(
      () => audio.playFinalCountdown(),
    ).thenAnswer((_) async => right(unit));
    when(() => audio.playGoodJob()).thenAnswer((_) async => right(unit));
    when(() => audio.playThatsIt()).thenAnswer((_) async => right(unit));
    when(() => haptic.mediumImpact()).thenAnswer((_) async => right(unit));
    when(() => haptic.heavyImpact()).thenAnswer((_) async => right(unit));
    when(() => haptic.warning()).thenAnswer((_) async => right(unit));
    when(() => haptic.success()).thenAnswer((_) async => right(unit));

    container = ProviderContainer(
      overrides: [
        audioServiceProvider.overrideWithValue(audio),
        hapticServiceProvider.overrideWithValue(haptic),
        timerEngineProvider.overrideWithValue(engine),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TimerNotifier cue timing (whole-workout scale)', () {
    test(
      'EMOM: final countdown does NOT fire at the end of round 1',
      () async {
        final notifier = container.read(timerNotifierProvider.notifier);
        await notifier.start(emomWorkout()); // 3 x 60s

        // 55s in: round 1 has 5s left, but the WORKOUT has 125s left.
        engine.emit(const Duration(seconds: 55));

        verifyNever(() => audio.playFinalCountdown());
        verifyNever(() => audio.playTenSeconds());
      },
    );

    test('EMOM: final countdown fires near the end of the workout', () async {
      final notifier = container.read(timerNotifierProvider.notifier);
      await notifier.start(emomWorkout()); // 3 x 60s = 180s

      // Realistic tick cadence so the one-shot progress cues (keep going,
      // halfway, almost there) fire on their own ticks and don't occupy
      // the per-tick voice slot when the countdown threshold is crossed.
      for (var s = 10; s <= 176; s += 2) {
        engine.emit(Duration(seconds: s));
      }

      verify(() => audio.playFinalCountdown()).called(1);
    });

    test('EMOM: ten-seconds warning fires near the workout end', () async {
      final notifier = container.read(timerNotifierProvider.notifier);
      await notifier.start(emomWorkout()); // 3 x 60s = 180s

      for (var s = 10; s <= 171; s += 2) {
        engine.emit(Duration(seconds: s));
      }

      verify(() => audio.playTenSeconds()).called(1);
    });
  });

  group('TimerNotifier race guards', () {
    test('a tick in flight when paused does not flip to error', () async {
      final notifier = container.read(timerNotifierProvider.notifier);
      await notifier.start(amrapWorkout());

      engine.emit(const Duration(seconds: 5));
      notifier.pause();
      expect(container.read(timerNotifierProvider), isA<TimerPaused>());

      // The stale tick that was already queued when the user paused.
      engine.emit(const Duration(seconds: 5, milliseconds: 100));

      expect(container.read(timerNotifierProvider), isA<TimerPaused>());
    });

    test('double pause is a no-op, not an error', () async {
      final notifier = container.read(timerNotifierProvider.notifier);
      await notifier.start(amrapWorkout());
      engine.emit(const Duration(seconds: 1));

      notifier.pause();
      notifier.pause();

      expect(container.read(timerNotifierProvider), isA<TimerPaused>());
    });

    test('resume after completion is a no-op, not an error', () async {
      final notifier = container.read(timerNotifierProvider.notifier);
      await notifier.start(amrapWorkout());
      engine.emit(const Duration(seconds: 1));

      notifier.stop();
      expect(container.read(timerNotifierProvider), isA<TimerCompleted>());

      notifier.resume();

      expect(container.read(timerNotifierProvider), isA<TimerCompleted>());
    });

    test('double start never leaks a tick subscription', () async {
      final notifier = container.read(timerNotifierProvider.notifier);

      await notifier.start(amrapWorkout());
      await notifier.start(amrapWorkout());

      expect(engine.activeListeners, 1);
    });
  });

  group('TimerNotifier start cue', () {
    test('GO cue plays when there is no prep countdown', () async {
      var goCues = 0;
      when(() => audio.playGo()).thenAnswer((_) async {
        goCues++;
        return right(unit);
      });
      when(() => audio.playLetsGo()).thenAnswer((_) async {
        goCues++;
        return right(unit);
      });

      final notifier = container.read(timerNotifierProvider.notifier);
      await notifier.start(amrapWorkout());

      expect(goCues, 1);
    });
  });
}
