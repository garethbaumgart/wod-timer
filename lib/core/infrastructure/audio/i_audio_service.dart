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

  /// Play the "Get ready" cue before countdown starts.
  Future<Either<AudioFailure, Unit>> playGetReady();

  /// Play the "Ten seconds" warning.
  Future<Either<AudioFailure, Unit>> playTenSeconds();

  /// Play the "Last round" alert.
  Future<Either<AudioFailure, Unit>> playLastRound();

  /// Play the "Keep going" motivational cue.
  Future<Either<AudioFailure, Unit>> playKeepGoing();

  /// Play the "Good job" encouragement cue.
  Future<Either<AudioFailure, Unit>> playGoodJob();

  /// Play the "Next round" transition cue.
  Future<Either<AudioFailure, Unit>> playNextRound();

  /// Play the spoken "5, 4, 3, 2, 1" final countdown.
  Future<Either<AudioFailure, Unit>> playFinalCountdown();

  /// Play the "Let's go" alternative start cue.
  Future<Either<AudioFailure, Unit>> playLetsGo();

  /// Play the "Come on, push it" motivation cue.
  Future<Either<AudioFailure, Unit>> playComeOn();

  /// Play the "Almost there" near-end encouragement.
  Future<Either<AudioFailure, Unit>> playAlmostThere();

  /// Play the "That's it, you're done" completion cue.
  Future<Either<AudioFailure, Unit>> playThatsIt();

  /// Play the "No rep" fun cue.
  Future<Either<AudioFailure, Unit>> playNoRep();

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

  /// Set the voice pack directory name (e.g. 'major', 'liam').
  void setVoicePack(String voicePack);
}
