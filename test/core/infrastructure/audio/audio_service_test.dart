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
    'interval': audio.playIntervalStart,
    'get_ready': audio.playGetReady,
    'ten_seconds': audio.playTenSeconds,
    'last_round': audio.playLastRound,
    'keep_going': audio.playKeepGoing,
    'good_job': audio.playGoodJob,
    'next_round': audio.playNextRound,
    'final_countdown': audio.playFinalCountdown,
    'lets_go': audio.playLetsGo,
    'come_on': audio.playComeOn,
    'almost_there': audio.playAlmostThere,
    'thats_it': audio.playThatsIt,
    'no_rep': audio.playNoRep,
  };

  /// The clip each cue plays inside a voice pack.
  const clips = {
    'go': 'countdown_go.mp3',
    'rest': 'rest.mp3',
    'complete': 'complete.mp3',
    'halfway': 'halfway.mp3',
    'interval': 'interval.mp3',
    'get_ready': 'get_ready.mp3',
    'ten_seconds': 'ten_seconds.mp3',
    'last_round': 'last_round.mp3',
    'keep_going': 'keep_going.mp3',
    'good_job': 'good_job.mp3',
    'next_round': 'next_round.mp3',
    'final_countdown': 'final_countdown.mp3',
    'lets_go': 'lets_go.mp3',
    'come_on': 'come_on.mp3',
    'almost_there': 'almost_there.mp3',
    'thats_it': 'thats_it.mp3',
    'no_rep': 'no_rep.mp3',
  };

  /// The cues that must stay audible with the voice off: the ones that
  /// mark time (countdown, GO, phase and round changes, the end).
  const timingCues = {
    'go',
    'rest',
    'complete',
    'interval',
    'get_ready',
    'ten_seconds',
    'last_round',
    'next_round',
    'final_countdown',
    'lets_go',
  };

  const beep = 'audio/major/beep.m4a';

  group('voice on', () {
    test('every cue plays its clip from the Major pack by default', () async {
      for (final entry in cues().entries) {
        played.clear();
        expect(await entry.value(), right<AudioFailure, Unit>(unit));
        expect(played, ['audio/major/${clips[entry.key]}'], reason: entry.key);
      }
    });

    test('3, 2, 1 are spoken; any other number is a beep', () async {
      await audio.playCountdown(3);
      await audio.playCountdown(2);
      await audio.playCountdown(1);
      await audio.playCountdown(4);
      await audio.playCountdown(0);
      expect(played, [
        'audio/major/countdown_3.mp3',
        'audio/major/countdown_2.mp3',
        'audio/major/countdown_1.mp3',
        beep,
        beep,
      ]);
    });

    test('the beep is the same file in every pack', () async {
      await audio.playBeep();
      audio.setVoicePack('holly');
      await audio.playBeep();
      expect(played, [beep, beep]);
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

    test('the timing cues fall back to a beep', () async {
      for (final name in timingCues) {
        played.clear();
        expect(await cues()[name]!(), right<AudioFailure, Unit>(unit));
        expect(played, [beep], reason: name);
      }
      played.clear();
      await audio.playCountdown(3);
      await audio.playCountdown(1);
      expect(played, [beep, beep]);
    });

    test('the encouragement cues go quiet but still succeed', () async {
      for (final name in clips.keys.where((n) => !timingCues.contains(n))) {
        played.clear();
        expect(await cues()[name]!(), right<AudioFailure, Unit>(unit));
        expect(played, isEmpty, reason: name);
      }
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
      await audio.playCountdown(3);
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
