// The audio and haptic providers hand out the get_it singletons (so the
// mute and Haptics settings reach the same instances that play cues), and
// the engine provider owns a real engine it disposes with its scope.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/application/usecases/create_workout.dart';
import 'package:wod_timer/features/timer/application/usecases/pause_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/resume_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/start_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/stop_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/tick_timer.dart';
import 'package:wod_timer/features/timer/infrastructure/services/timer_engine.dart';
import 'package:wod_timer/injection.dart';

class _MockAudioService extends Mock implements IAudioService {}

class _MockHapticService extends Mock implements IHapticService {}

void main() {
  late _MockAudioService audio;
  late _MockHapticService haptic;
  late ProviderContainer container;

  setUp(() {
    audio = _MockAudioService();
    haptic = _MockHapticService();
    getIt
      ..registerSingleton<IAudioService>(audio)
      ..registerSingleton<IHapticService>(haptic);
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await getIt.reset();
  });

  test('audio and haptics are the app-wide singletons', () {
    expect(container.read(audioServiceProvider), same(audio));
    expect(container.read(hapticServiceProvider), same(haptic));
    // keepAlive: the same instance on every read.
    expect(container.read(audioServiceProvider), same(audio));
  });

  test('the engine is a real TimerEngine, stopped when the scope goes', () {
    final engine = container.read(timerEngineProvider);
    expect(engine, isA<TimerEngine>());
    engine.start();
    expect(engine.isRunning, isTrue);
    container.dispose();
    expect(engine.isRunning, isFalse);
  });

  test('each use case is built once per scope', () {
    expect(container.read(createWorkoutProvider), isA<CreateWorkout>());
    expect(container.read(startTimerProvider), isA<StartTimer>());
    expect(container.read(pauseTimerProvider), isA<PauseTimer>());
    expect(container.read(resumeTimerProvider), isA<ResumeTimer>());
    expect(container.read(stopTimerProvider), isA<StopTimer>());
    expect(container.read(tickTimerProvider), isA<TickTimer>());
    expect(
      container.read(startTimerProvider),
      same(container.read(startTimerProvider)),
    );
  });
}
