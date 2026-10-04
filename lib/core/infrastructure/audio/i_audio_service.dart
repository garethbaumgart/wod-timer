import 'package:fpdart/fpdart.dart';
import 'package:wod_timer/core/domain/failures/audio_failure.dart';

/// Interface for audio playback services.
///
/// This service handles playing timer-related sounds like beeps,
/// countdown numbers, and completion sounds.
abstract class IAudioService {
  /// Play the high change beep (same sound as [playHighBeep]).
  Future<Either<AudioFailure, Unit>> playBeep();

  /// Play the low countdown beep for [secondsLeft] (3, 2 or 1) before a
  /// phase change. The gym-timer pattern (2.1.0, matched to the SmartWOD
  /// recording Gareth chose): three low beeps in the last three seconds of
  /// every phase, then [playHighBeep] on the change with the voice line on
  /// top. Beeps play in Beeps only too; only Silent mutes them.
  Future<Either<AudioFailure, Unit>> playLowBeep(int secondsLeft);

  /// Play the high beep that marks every phase change: start, round, rest,
  /// work and end. The voice line for the change starts with it.
  Future<Either<AudioFailure, Unit>> playHighBeep();

  /// Play the "Go" sound at workout start.
  Future<Either<AudioFailure, Unit>> playGo();

  /// Play the rest period start sound.
  Future<Either<AudioFailure, Unit>> playRest();

  /// Play the workout complete sound.
  Future<Either<AudioFailure, Unit>> playComplete();

  /// Play the halfway alert sound.
  Future<Either<AudioFailure, Unit>> playHalfway();

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

  /// Play the "Let's go" alternative start cue.
  Future<Either<AudioFailure, Unit>> playLetsGo();

  /// Play the "Come on, push it" motivation cue.
  Future<Either<AudioFailure, Unit>> playComeOn();

  /// Play the "Almost there" near-end encouragement.
  Future<Either<AudioFailure, Unit>> playAlmostThere();

  /// Play the "That's it, you're done" completion cue.
  Future<Either<AudioFailure, Unit>> playThatsIt();

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

  /// Enable or disable per-cue voice randomization.
  ///
  /// When enabled, each voice cue randomly picks between available
  /// voice packs instead of using the fixed [setVoicePack] value.
  void setRandomizePerCue({required bool enabled});

  /// Mute only the spoken voice cues (Beeps only). The low and high beeps
  /// keep playing, so every countdown and change stays audible.
  void setVoiceMuted({required bool muted});

  /// Play a short preview sample ("GO!") for the given voice pack,
  /// regardless of the currently selected pack. Used by the voice picker.
  Future<Either<AudioFailure, Unit>> playVoicePreview(String voicePack);
}
