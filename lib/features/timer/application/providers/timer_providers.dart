import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wod_timer/core/infrastructure/audio/audio_service.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart';
import 'package:wod_timer/features/timer/application/usecases/create_workout.dart';
import 'package:wod_timer/features/timer/application/usecases/pause_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/resume_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/start_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/stop_timer.dart';
import 'package:wod_timer/features/timer/application/usecases/tick_timer.dart';
import 'package:wod_timer/features/timer/infrastructure/services/i_timer_engine.dart';
import 'package:wod_timer/features/timer/infrastructure/services/timer_engine.dart';
import 'package:wod_timer/injection.dart';

part 'timer_providers.g.dart';

/// Provider for the audio service.
@riverpod
IAudioService audioService(AudioServiceRef ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
}

/// Provider for the haptic feedback service.
///
/// Uses the singleton from get_it to ensure the enabled state is shared
/// across the app when toggled from settings.
@Riverpod(keepAlive: true)
IHapticService hapticService(HapticServiceRef ref) {
  return getIt<IHapticService>();
}

/// Provider for the timer engine.
@riverpod
ITimerEngine timerEngine(TimerEngineRef ref) {
  final engine = TimerEngine();
  ref.onDispose(engine.dispose);
  return engine;
}

/// Provider for the CreateWorkout use case.
@riverpod
CreateWorkout createWorkout(CreateWorkoutRef ref) {
  return CreateWorkout();
}

/// Provider for the StartTimer use case.
@riverpod
StartTimer startTimer(StartTimerRef ref) {
  return StartTimer(ref.watch(audioServiceProvider));
}

/// Provider for the PauseTimer use case.
@riverpod
PauseTimer pauseTimer(PauseTimerRef ref) {
  return PauseTimer();
}

/// Provider for the ResumeTimer use case.
@riverpod
ResumeTimer resumeTimer(ResumeTimerRef ref) {
  return ResumeTimer();
}

/// Provider for the StopTimer use case.
@riverpod
StopTimer stopTimer(StopTimerRef ref) {
  return StopTimer();
}

/// Provider for the TickTimer use case.
@riverpod
TickTimer tickTimer(TickTimerRef ref) {
  return TickTimer();
}
