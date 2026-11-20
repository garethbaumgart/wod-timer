// What a cue does to the music (5 Oct 2026): lower it and hand it back.
// Both audio plugins default to Android's permanent focus, which stops
// Spotify at the first beep and never restarts it; these pin the policy
// that replaced it on both platforms.
import 'package:audio_session/audio_session.dart' as audio_session;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/infrastructure/audio/audio_service.dart';

void main() {
  group('the audio session, which owns focus', () {
    final config = AudioService.sessionConfiguration;

    test('iOS ducks music and mixes with it, never interrupts it', () {
      expect(
        config.avAudioSessionCategory,
        audio_session.AVAudioSessionCategory.playback,
      );
      final options = config.avAudioSessionCategoryOptions!;
      expect(
        options.contains(
          audio_session.AVAudioSessionCategoryOptions.duckOthers,
        ),
        isTrue,
      );
      expect(
        options.contains(
          audio_session.AVAudioSessionCategoryOptions.mixWithOthers,
        ),
        isTrue,
      );
    });

    test('Android takes transient focus that may duck, on the media stream',
        () {
      expect(
        config.androidAudioFocusGainType,
        audio_session.AndroidAudioFocusGainType.gainTransientMayDuck,
        reason: 'permanent focus stops the music for good',
      );
      expect(config.androidWillPauseWhenDucked, isFalse);
      expect(
        config.androidAudioAttributes?.usage,
        audio_session.AndroidAudioUsage.media,
      );
    });
  });

  group('the players', () {
    final context = AudioService.cueContext;

    test('on Android request no focus of their own and use the media stream',
        () {
      expect(context.android.audioFocus, AndroidAudioFocus.none);
      expect(context.android.usageType, AndroidUsageType.media);
      expect(context.android.stayAwake, isFalse);
      expect(context.android.isSpeakerphoneOn, isFalse);
    });

    test('on iOS agree with the session', () {
      expect(context.iOS.category, AVAudioSessionCategory.playback);
      expect(
        context.iOS.options,
        containsAll([
          AVAudioSessionOptions.duckOthers,
          AVAudioSessionOptions.mixWithOthers,
        ]),
      );
    });
  });
}
