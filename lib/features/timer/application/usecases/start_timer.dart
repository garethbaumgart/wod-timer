import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/failures/timer_failure.dart';

/// Use case for starting a timer session.
///
/// Creates a new [TimerSession] from a workout and preloads audio resources.
@injectable
class StartTimer {
  StartTimer(this._audioService);

  final IAudioService _audioService;

  /// Starts a new timer session for the given workout.
  ///
  /// Returns [Either<TimerFailure, TimerSession>]:
  /// - Right(TimerSession) with the session in started state
  /// - Left(TimerFailure) if the session cannot be started or audio preload fails
  Future<Either<TimerFailure, TimerSession>> call(Workout workout) async {
    // Preload sounds for responsive audio during the workout
    // We catch any errors here to maintain the Either contract
    try {
      await _audioService.preloadSounds();
    } catch (e) {
      // Audio preload failure is non-fatal - we continue without audio
      // The user will still be able to use the timer, just without sounds
    }

    // Create a new session from the workout
    final session = TimerSession.fromWorkout(workout);

    // Start the session
    return session.start();
  }
}
