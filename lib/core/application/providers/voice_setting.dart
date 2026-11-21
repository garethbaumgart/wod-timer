import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';

/// Points [audio]'s spoken cues at [voice]: a pack, a pack picked per cue
/// (Random), or none (Beeps only, Silent). Silent's full mute is synced by
/// [AppSettingsNotifier] on load and on every voice change; here only the
/// spoken cues need switching. Shared by a timer and Today's WOD (2.6.0) so
/// both speak in the voice the athlete chose.
void applyVoiceSetting(IAudioService audio, VoiceOption voice) {
  audio.setVoiceMuted(
    muted: voice == VoiceOption.off || voice == VoiceOption.silent,
  );
  switch (voice) {
    case VoiceOption.major:
      audio
        ..setRandomizePerCue(enabled: false)
        ..setVoicePack('major');
    case VoiceOption.liam:
      audio
        ..setRandomizePerCue(enabled: false)
        ..setVoicePack('liam');
    case VoiceOption.holly:
      audio
        ..setRandomizePerCue(enabled: false)
        ..setVoicePack('holly');
    case VoiceOption.random:
      audio.setRandomizePerCue(enabled: true);
    case VoiceOption.off:
    case VoiceOption.silent:
      break;
  }
}
