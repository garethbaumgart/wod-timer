import 'package:fpdart/fpdart.dart';
import 'package:wod_timer/core/domain/failures/audio_failure.dart';

/// Interface for audio playback services.
///
/// This service handles playing timer-related sounds like beeps,
/// countdown numbers, and completion sounds.
abstract class IAudioService {
  /// Play a short beep sound (used for interval alerts).
  Future<Either<AudioFailure, Unit>> playBeep();

  /// Play a countdown number (3, 2, 1).
  Future<Either<AudioFailure, Unit>> playCountdown(int number);

  /// Play the "Go" sound at workout start.
  Future<Either<AudioFailure, Unit>> playGo();

  /// Play the rest period start sound.
  Future<Either<AudioFailure, Unit>> playRest();

  /// Play the workout complete sound.
  Future<Either<AudioFailure, Unit>> playComplete();

  /// Play the halfway alert sound.
  Future<Either<AudioFailure, Unit>> playHalfway();

  /// Play the interval start sound (for EMOM).
  Future<Either<AudioFailure, Unit>> playIntervalStart();

  /// Preload all sounds for faster playback.
  Future<void> preloadSounds();

  /// Dispose of audio resources.
  Future<void> dispose();

  /// Set the volume (0.0 to 1.0).
  Future<void> setVolume(double volume);

  /// Whether audio is currently muted.
  bool get isMuted;

  /// Mute or unmute audio.
  Future<void> setMuted({required bool muted});
}
