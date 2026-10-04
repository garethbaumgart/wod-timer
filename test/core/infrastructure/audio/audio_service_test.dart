// The real AudioService's cue-to-asset rules, with the player pool
// replaced by a recording sink: which file each cue plays, the voice pack
// and Random, Beeps only (timing cues beep, encouragement goes quiet),
// Silent (nothing at all) and the picker preview that ignores both.
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:wod_timer/core/domain/failures/audio_failure.dart';
import 'package:wod_timer/core/infrastructure/audio/audio_service.dart';

void main() {
  late List<String> played;
  late AudioService audio;

  setUp(() {
    played = [];
    audio = AudioService.withSink((path) async => played.add(path));
  });

  /// Every voice cue by name, as the service plays it.
  Map<String, Future<Either<AudioFailure, Unit>> Function()> cues() => {
    'go': audio.playGo,
    'rest': audio.playRest,
    'complete': audio.playComplete,
    'halfway': audio.playHalfway,
    'get_ready': audio.playGetReady,
    'ten_seconds': audio.playTenSeconds,
    'last_round': audio.playLastRound,
    'keep_going': audio.playKeepGoing,
    'good_job': audio.playGoodJob,
    'next_round': audio.playNextRound,
    'lets_go': audio.playLetsGo,
    'come_on': audio.playComeOn,
    'almost_there': audio.playAlmostThere,
    'thats_it': audio.playThatsIt,
  };

  /// The clip each cue plays inside a voice pack.
  const clips = {
    'go': 'countdown_go.mp3',
    'rest': 'rest.mp3',
    'complete': 'complete.mp3',
    'halfway': 'halfway.mp3',
    'get_ready': 'get_ready.mp3',
    'ten_seconds': 'ten_seconds.mp3',
    'last_round': 'last_round.mp3',
    'keep_going': 'keep_going.mp3',
    'good_job': 'good_job.mp3',
    'next_round': 'next_round.mp3',
    'lets_go': 'lets_go.mp3',
    'come_on': 'come_on.mp3',
    'almost_there': 'almost_there.mp3',
    'thats_it': 'thats_it.mp3',
  };

  // The gym-timer beeps (2.1.0), shared by every pack.
  const beep = 'audio/beeps/high.wav';
  String low(int n) => 'audio/beeps/low_$n.wav';

  group('voice on', () {
    test('every cue plays its clip from the Major pack by default', () async {
      for (final entry in cues().entries) {
        played.clear();
        expect(await entry.value(), right<AudioFailure, Unit>(unit));
        expect(played, ['audio/major/${clips[entry.key]}'], reason: entry.key);
      }
    });

    test('the beeps are the same files in every pack', () async {
      await audio.playBeep();
      await audio.playHighBeep();
      await audio.playLowBeep(3);
      audio.setVoicePack('holly');
      await audio.playHighBeep();
      await audio.playLowBeep(3);
      expect(played, [beep, beep, low(3), beep, low(3)]);
    });

    test('each of 3, 2, 1 has its own low beep; out of range clamps', () async {
      for (final n in [3, 2, 1, 5, 0]) {
        await audio.playLowBeep(n);
      }
      expect(played, [low(3), low(2), low(1), low(3), low(1)]);
    });

    test(
      'a chosen pack moves every cue; an unknown pack means Major',
      () async {
        for (final pack in ['liam', 'holly', 'major']) {
          audio.setVoicePack(pack);
          played.clear();
          await audio.playGo();
          await audio.playGoodJob();
          expect(played, [
            'audio/$pack/countdown_go.mp3',
            'audio/$pack/good_job.mp3',
          ]);
        }
        audio.setVoicePack('siri');
        played.clear();
        await audio.playRest();
        expect(played, ['audio/major/rest.mp3']);
      },
    );

    test('Random picks a different real pack per cue', () async {
      audio
        ..setVoicePack('liam')
        ..setRandomizePerCue(enabled: true);
      for (var i = 0; i < 60; i++) {
        await audio.playGo();
      }
      final packs = played.map((p) => p.split('/')[1]).toSet();
      expect(packs, {'major', 'liam', 'holly'});
      expect(played.every((p) => p.endsWith('countdown_go.mp3')), isTrue);

      audio.setRandomizePerCue(enabled: false);
      played.clear();
      await audio.playGo();
      expect(played, ['audio/liam/countdown_go.mp3'], reason: 'pack kept');
    });
  });

  group('Beeps only (voice muted)', () {
    setUp(() => audio.setVoiceMuted(muted: true));

    test('every voice cue goes quiet but still succeeds', () async {
      for (final name in clips.keys) {
        played.clear();
        expect(await cues()[name]!(), right<AudioFailure, Unit>(unit));
        expect(played, isEmpty, reason: name);
      }
      expect(played, isEmpty);
    });

    test('the beeps keep playing: they carry the timing', () async {
      await audio.playLowBeep(3);
      await audio.playLowBeep(2);
      await audio.playLowBeep(1);
      await audio.playHighBeep();
      expect(played, [low(3), low(2), low(1), beep]);
    });

    test('turning the voice back on restores the clips', () async {
      audio.setVoiceMuted(muted: false);
      await audio.playHalfway();
      expect(played, ['audio/major/halfway.mp3']);
    });
  });

  group('Silent (muted)', () {
    test('nothing plays, not even the beep, and every call succeeds', () async {
      await audio.setMuted(muted: true);
      expect(audio.isMuted, isTrue);
      for (final cue in cues().values) {
        expect(await cue(), right<AudioFailure, Unit>(unit));
      }
      await audio.playBeep();
      await audio.playLowBeep(3);
      await audio.playHighBeep();
      expect(played, isEmpty);

      await audio.setMuted(muted: false);
      expect(audio.isMuted, isFalse);
      await audio.playBeep();
      expect(played, [beep]);
    });

    test('Silent on top of Beeps only is still silent', () async {
      audio.setVoiceMuted(muted: true);
      await audio.setMuted(muted: true);
      await audio.playGo();
      expect(played, isEmpty);
    });
  });

  group('voice preview', () {
    test('plays GO from the asked-for pack whatever the current one', () async {
      audio.setVoicePack('holly');
      await audio.playVoicePreview('liam');
      await audio.playVoicePreview('major');
      expect(played, [
        'audio/liam/countdown_go.mp3',
        'audio/major/countdown_go.mp3',
      ]);
    });

    test('is a deliberate tap, so it ignores Silent and Beeps only', () async {
      audio.setVoiceMuted(muted: true);
      await audio.setMuted(muted: true);
      await audio.playVoicePreview('holly');
      expect(played, ['audio/holly/countdown_go.mp3']);
    });

    test('an unknown pack (Random) previews one of the real three', () async {
      for (var i = 0; i < 30; i++) {
        await audio.playVoicePreview('random');
      }
      final packs = played.map((p) => p.split('/')[1]).toSet();
      expect(packs.difference({'major', 'liam', 'holly'}), isEmpty);
      expect(packs.length, greaterThan(1));
    });
  });

  test('the volume setter clamps to 0..1 without complaint', () async {
    await audio.setVolume(5);
    await audio.setVolume(-1);
    await audio.playBeep();
    expect(played, [beep]);
  });
}
