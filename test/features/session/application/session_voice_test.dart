// Retest fix 1 (2.6.0): Today's WOD's own cues (a Sets get-ready and its
// GO, a set's rest, a Rest block) speak in the voice the athlete chose,
// from the very first cue of the launch, as a timer does. The real audio
// service, sink-backed, shows which files actually play.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/core/infrastructure/audio/audio_service.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';

import '../../../helpers/session_harness.dart';

void main() {
  /// The voice lines a session played, by pack ("major/get_ready.mp3").
  Future<List<String>> voiceLines(
    VoiceOption voice,
    List<SessionBlock> blocks,
  ) async {
    final assets = <String>[];
    final s = SessionHarness(
      settings: AppSettings(voice: voice),
      audioService: AudioService.withSink((asset) async => assets.add(asset)),
    );
    addTearDown(s.dispose);
    await s.start(blocks);
    await s.advance(10);
    s.later();
    s.controller.setDone();
    await s.advance(20);
    return [
      for (final a in assets)
        if (!a.startsWith('audio/beeps/')) a.substring('audio/'.length),
    ];
  }

  const setsFirst = [
    SetsBlock(sets: 2, restSeconds: 15),
    RestBlock(seconds: 30),
  ];
  const restFirst = [
    RestBlock(seconds: 15),
    SetsBlock(sets: 2, restSeconds: 15),
  ];

  for (final (name, blocks) in [
    ('starting on Sets', setsFirst),
    ('starting on a Rest', restFirst),
  ]) {
    group(name, () {
      for (final voice in [VoiceOption.off, VoiceOption.silent]) {
        test('${voice.name}: no line is spoken', () async {
          expect(await voiceLines(voice, blocks), isEmpty);
        });
      }
      for (final voice in [
        VoiceOption.major,
        VoiceOption.liam,
        VoiceOption.holly,
      ]) {
        test('${voice.name}: every line in that voice', () async {
          final lines = await voiceLines(voice, blocks);
          expect(lines, isNotEmpty);
          expect(
            lines.every((l) => l.startsWith('${voice.name}/')),
            isTrue,
            reason: '$lines',
          );
        });
      }
      test('random: lines are spoken', () async {
        expect(await voiceLines(VoiceOption.random, blocks), isNotEmpty);
      });
    });
  }

  test('the setting is applied before the first cue (Beeps only)', () async {
    // Beeps only is the default setting.
    final s = SessionHarness(settings: const AppSettings());
    addTearDown(s.dispose);
    await s.start(const [SetsBlock(sets: 2, restSeconds: 30)]);
    verifyInOrder([
      () => s.h.audio.setVoiceMuted(muted: true),
      () => s.h.audio.playGetReady(),
    ]);
  });
}
