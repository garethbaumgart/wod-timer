// The cue schedule: which voice cue and which haptic fire at which second
// of a workout, one voice cue per tick, and what happens at the end
// (encouragement, the time-cap tone, the review payoff).
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_state.dart'
    as domain;

import '../../../../helpers/notifier_harness.dart';

void main() {
  late NotifierHarness h;

  setUp(() => h = NotifierHarness());
  tearDown(() => h.dispose());

  /// Lets the unawaited review booking and any pending microtasks settle.
  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  final go = anyOf('go', 'lets go');
  final motivation = anyOf('keep going', 'come on');
  final encouragement = anyOf('good job', 'thats it');

  group('get ready and GO', () {
    test(
      'Get ready, then 3 2 1 with a tap each, then GO with a thump',
      () async {
        await h.notifier.start(amrapWorkout(seconds: 60, prep: 10));
        expect(h.played, isEmpty);

        h.tick(1);
        expect(h.played, ['get ready']);
        h.run(2, 6);
        expect(h.played, ['get ready'], reason: 'nothing until 3s left');

        h.tick(7);
        h.tick(8);
        h.tick(9);
        expect(h.played, [
          'get ready',
          'countdown 3',
          'countdown 2',
          'countdown 1',
        ]);
        expect(h.felt, ['medium', 'medium', 'medium']);

        h.tick(10);
        expect(h.state, isA<TimerRunning>());
        expect(h.played.last, go);
        expect(h.felt.last, 'heavy');
      },
    );

    test('each countdown number plays once even with 100ms ticks', () async {
      await h.notifier.start(amrapWorkout(seconds: 60, prep: 5));
      for (var ms = 100; ms <= 5000; ms += 100) {
        h.tick(ms ~/ 1000, ms % 1000);
      }
      expect(h.played, [
        'get ready',
        'countdown 3',
        'countdown 2',
        'countdown 1',
        go,
      ]);
    });

    test('a prep of exactly 3s says Get ready, not 3', () async {
      await h.notifier.start(amrapWorkout(seconds: 60, prep: 3));
      h.tick(0, 100);
      expect(h.played, ['get ready']);
      h.tick(1);
      h.tick(2);
      expect(h.played, ['get ready', 'countdown 2', 'countdown 1']);
    });

    test(
      'skipping the countdown plays GO and starts the clock at zero',
      () async {
        await h.notifier.start(amrapWorkout(seconds: 60, prep: 10));
        h.tick(1);
        h.notifier.skipPrep();
        expect(h.state, isA<TimerRunning>());
        expect(h.state.sessionOrNull!.elapsed.seconds, 0);
        expect(h.played, ['get ready', go]);
        expect(h.felt, ['heavy']);
        // The GO cooldown: a tap that skipped the countdown cannot count.
        h.notifier.countRound();
        expect(h.state.sessionOrNull!.currentRound, 1);
      },
    );

    test('skipPrep outside the countdown is a no-op', () async {
      await h.notifier.start(amrapWorkout(seconds: 60));
      h.tick(5);
      h.notifier.skipPrep();
      expect(h.state.sessionOrNull!.elapsed.seconds, 5);
    });
  });

  group('AMRAP schedule (60s)', () {
    test('motivation at a third, halfway, ten seconds, almost there, '
        'the final five, then the payoff', () async {
      await h.notifier.start(amrapWorkout(seconds: 60));
      expect(h.played, [go]);
      expect(h.felt, ['heavy']);

      h.run(1, 19);
      expect(h.played, hasLength(1));
      h.tick(20);
      expect(h.played.last, motivation, reason: '33% in');
      h.run(21, 29);
      expect(h.played, hasLength(2));
      h.tick(30);
      expect(h.played.last, 'halfway');
      expect(h.felt.last, 'medium');
      h.run(31, 49);
      expect(h.played, hasLength(3));
      h.tick(50);
      expect(h.played.last, 'ten seconds');
      h.tick(51);
      expect(h.played.last, 'almost there');
      h.run(52, 54);
      expect(h.played, hasLength(5));
      h.tick(55);
      expect(h.played.last, 'final countdown');
      h.run(56, 59);
      expect(h.state, isA<TimerRunning>());

      h.tick(60);
      expect(h.state, isA<TimerCompleted>());
      expect(h.state.endedAtTimeCap, isFalse);
      expect(h.felt.last, 'success');
      expect(h.engine.calls.last, 'stop');
      // The encouragement waits for the final countdown clip to finish.
      expect(h.played, hasLength(6));
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(h.played.last, encouragement);
      expect(h.played, hasLength(7));
    });

    test('a natural finish records the review payoff moment', () async {
      await h.notifier.start(amrapWorkout(seconds: 10));
      h.run(1, 10);
      expect(h.state, isA<TimerCompleted>());
      await settle();
      expect(h.valueMoments, 1);
      expect(h.requester.requests, 1);
    });

    test('a finish the final-countdown clip never preceded celebrates at '
        'once (the app slept through the end)', () async {
      await h.notifier.start(amrapWorkout(seconds: 60));
      h.tick(1);
      h.tick(60);
      expect(h.state, isA<TimerCompleted>());
      expect(h.played, isNot(contains('final countdown')));
      await settle();
      expect(h.played.last, encouragement);
    });
  });

  group('EMOM schedule (3 x 60s)', () {
    test('Next round on each minute, Last round on the final one, '
        'the round cue beats halfway on the same tick', () async {
      await h.notifier.start(emomWorkout(rounds: 3));
      h.run(1, 59);
      expect(h.played, [go]);

      h.tick(60);
      expect(h.state.sessionOrNull!.currentRound, 2);
      expect(h.played.last, 'next round');
      expect(h.felt.last, 'heavy');
      // 60s is also 33% of the workout: the round cue took the slot.
      h.run(61, 89);
      expect(h.played, hasLength(2));
      h.tick(90);
      expect(h.played.last, 'halfway');

      h.run(91, 119);
      h.tick(120);
      expect(h.state.sessionOrNull!.currentRound, 3);
      expect(h.played.last, 'last round');

      h.run(121, 152);
      h.tick(153);
      expect(h.played.last, 'almost there');
      h.run(154, 169);
      h.tick(170);
      expect(h.played.last, 'ten seconds');
      h.run(171, 174);
      h.tick(175);
      expect(h.played.last, 'final countdown');
      h.run(176, 179);
      expect(h.state, isA<TimerRunning>());
      h.tick(180);
      expect(h.state, isA<TimerCompleted>());
      expect(h.state.sessionOrNull!.currentRound, 3);
    });

    test(
      'a catch-up tick across several rounds cues once and lands right',
      () async {
        await h.notifier.start(emomWorkout(rounds: 5));
        h.tick(1);
        // The app was suspended for three minutes.
        h.tick(181);
        final session = h.state.sessionOrNull!;
        expect(session.currentRound, 4);
        expect(session.currentIntervalElapsed.seconds, 1);
        expect(h.played, [go, 'next round']);
      },
    );

    test('the Last round cue never repeats', () async {
      await h.notifier.start(emomWorkout(interval: 10, rounds: 2));
      h.run(1, 19);
      expect(h.played.where((c) => c == 'last round'), hasLength(1));
    });
  });

  group('Tabata schedule (20s / 10s x 2)', () {
    test('Rest with a warning buzz, Last round as work resumes, '
        'the final rest, then done', () async {
      await h.notifier.start(tabataWorkout(rounds: 2));
      h.run(1, 19);
      expect(h.played, [go]);

      h.tick(20);
      expect(h.state, isA<TimerResting>());
      expect(h.played.last, 'rest');
      expect(h.felt.last, 'warning');

      h.run(21, 29);
      h.tick(30);
      expect(h.state, isA<TimerRunning>());
      expect(h.state.sessionOrNull!.currentRound, 2);
      expect(h.played.last, 'last round');
      // Back to work thumps, and the new round thumps.
      expect(h.felt.sublist(h.felt.length - 2), ['heavy', 'heavy']);

      h.run(31, 49);
      h.tick(50);
      expect(h.state, isA<TimerResting>());
      expect(h.played.last, 'rest');
      h.tick(51);
      expect(h.played.last, 'almost there');
      h.tick(52);
      expect(h.played.last, 'ten seconds');
      h.run(53, 54);
      h.tick(55);
      expect(h.played.last, 'final countdown', reason: 'resting counts');
      h.run(56, 59);
      h.tick(60);
      expect(h.state, isA<TimerCompleted>());
      expect(h.state.sessionOrNull!.currentRound, 2);
      expect(h.felt.last, 'success');
    });

    test(
      'no Rest cue when the rest ends in the same tick as the round',
      () async {
        await h.notifier.start(tabataWorkout(rounds: 3));
        h.tick(1);
        // Suspended through the end of round 1's rest, into round 2's work.
        h.tick(32);
        expect(h.state, isA<TimerRunning>());
        expect(h.state.sessionOrNull!.currentRound, 2);
        expect(h.played, [go, 'next round']);
      },
    );
  });

  group('For Time', () {
    test(
      'reaching the cap plays the end tone, no Good job, no review',
      () async {
        await h.notifier.start(forTimeWorkout(cap: 60));
        h.run(1, 60);
        expect(h.state, isA<TimerCompleted>());
        expect(h.state.endedAtTimeCap, isTrue);
        expect(h.felt.last, 'heavy');
        expect(h.played.last, 'final countdown');
        await Future<void>.delayed(const Duration(milliseconds: 700));
        expect(h.played.last, 'complete');
        expect(h.played, isNot(contains(encouragement)));
        await settle();
        expect(h.valueMoments, 0);
      },
    );

    test('FINISH celebrates with a success buzz and encouragement', () async {
      await h.notifier.start(forTimeWorkout(cap: 600));
      h.run(1, 30);
      h.notifier.finish();
      expect(h.state, isA<TimerCompleted>());
      expect((h.state as TimerCompleted).endedEarly, isFalse);
      expect(h.felt.last, 'success');
      expect(h.engine.calls.last, 'stop');
      await settle();
      expect(h.played.last, encouragement);
    });

    test('FINISH right after the final countdown waits for the clip', () async {
      await h.notifier.start(forTimeWorkout(cap: 60));
      h.run(1, 56);
      expect(h.played.last, 'final countdown');
      h.notifier.finish();
      await settle();
      expect(h.played.last, 'final countdown');
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(h.played.last, encouragement);
    });

    test('a count-down For Time cues on the same schedule', () async {
      await h.notifier.start(forTimeWorkout(cap: 60, countUp: false));
      h.run(1, 55);
      expect(h.played, [
        go,
        motivation,
        'halfway',
        'ten seconds',
        'almost there',
        'final countdown',
      ]);
    });
  });

  group('stop, pause, resume, restart', () {
    test('Stop is honest: a medium tap, no cue, no review moment', () async {
      await h.notifier.start(emomWorkout());
      h.run(1, 30);
      h.notifier.stop();
      expect(h.state, isA<TimerCompleted>());
      expect((h.state as TimerCompleted).endedEarly, isTrue);
      expect(h.felt.last, 'medium');
      expect(h.engine.calls.last, 'stop');
      await settle();
      expect(h.played, [go]);
      expect(h.valueMoments, 0);
    });

    test('pause and resume drive the engine and tap once each', () async {
      await h.notifier.start(emomWorkout());
      h.tick(5);
      h.notifier.pause();
      expect(h.state, isA<TimerPaused>());
      expect(h.engine.calls.last, 'pause');
      expect(h.felt.last, 'medium');
      h.notifier.resume();
      expect(h.state, isA<TimerRunning>());
      expect(h.engine.calls.last, 'resume');
      expect(h.felt, ['heavy', 'medium', 'medium']);
    });

    test('resume keeps the phase a Tabata paused in', () async {
      await h.notifier.start(tabataWorkout());
      h.run(1, 25);
      expect(h.state, isA<TimerResting>());
      h.notifier.pause();
      expect(
        h.state.sessionOrNull!.stateBeforePause,
        domain.TimerState.resting,
      );
      h.notifier.resume();
      expect(h.state, isA<TimerResting>());
    });

    test('AGAIN restarts the same workout with the cues reset', () async {
      await h.notifier.start(amrapWorkout(seconds: 10));
      h.run(1, 10);
      expect(h.state, isA<TimerCompleted>());
      h.engine.calls.clear();
      await h.notifier.restart();
      expect(h.state, isA<TimerRunning>());
      expect(h.state.sessionOrNull!.elapsed.seconds, 0);
      expect(h.engine.calls, ['stop', 'stop', 'reset', 'start']);
      expect(h.played.where((c) => c == 'go' || c == 'lets go'), hasLength(2));
      h.run(1, 5);
      expect(h.played.last, 'halfway', reason: 'one-shot cues re-armed');
    });

    test('restart is a no-op while running and after a reset', () async {
      await h.notifier.start(amrapWorkout(seconds: 10));
      h.run(1, 3);
      await h.notifier.restart();
      expect(h.state.sessionOrNull!.elapsed.seconds, 3);

      h.notifier.reset();
      expect(h.state, isA<TimerInitial>());
      await h.notifier.restart();
      expect(h.state, isA<TimerInitial>());
    });
  });

  group('AMRAP tally guards', () {
    test(
      'only a running AMRAP counts; the end screen only corrects AMRAP',
      () async {
        await h.notifier.start(emomWorkout());
        h.tick(5);
        h.later();
        h.notifier.countRound();
        expect(h.state.sessionOrNull!.currentRound, 1);

        await h.notifier.start(amrapWorkout(seconds: 60, prep: 10));
        h.tick(1);
        h.later();
        h.notifier.countRound();
        expect(h.state.sessionOrNull!.currentRound, 1, reason: 'preparing');

        h.notifier.adjustRounds(1);
        expect(h.state.sessionOrNull!.currentRound, 1, reason: 'not completed');

        await h.notifier.start(emomWorkout(interval: 5, rounds: 1));
        h.run(1, 5);
        expect(h.state, isA<TimerCompleted>());
        h.notifier.adjustRounds(1);
        expect(h.state.sessionOrNull!.currentRound, 1, reason: 'not AMRAP');
      },
    );

    test('counting a round taps and ignores the cooldown window', () async {
      await h.notifier.start(amrapWorkout(seconds: 60));
      h.tick(5);
      h.later();
      h.felt.clear();
      h.notifier.countRound();
      expect(h.felt, ['medium']);
      h.notifier.countRound();
      expect(h.state.sessionOrNull!.currentRound, 2);
      h.later();
      h.notifier.countRound();
      expect(h.state.sessionOrNull!.currentRound, 3);
    });
  });

  group('voice setting', () {
    Future<NotifierHarness> startWith(VoiceOption voice) async {
      h.dispose();
      h = NotifierHarness(settings: AppSettings(voice: voice));
      await h.notifier.start(amrapWorkout(seconds: 60));
      return h;
    }

    test('a named voice sets its pack and turns randomising off', () async {
      for (final (voice, pack) in [
        (VoiceOption.major, 'major'),
        (VoiceOption.liam, 'liam'),
        (VoiceOption.holly, 'holly'),
      ]) {
        await startWith(voice);
        verify(() => h.audio.setVoiceMuted(muted: false)).called(1);
        verify(() => h.audio.setRandomizePerCue(enabled: false)).called(1);
        verify(() => h.audio.setVoicePack(pack)).called(1);
      }
    });

    test('Random turns randomising on and leaves the pack alone', () async {
      await startWith(VoiceOption.random);
      verify(() => h.audio.setVoiceMuted(muted: false)).called(1);
      verify(() => h.audio.setRandomizePerCue(enabled: true)).called(1);
      verifyNever(() => h.audio.setVoicePack(any()));
    });

    test('Beeps only and Silent mute the spoken cues', () async {
      for (final voice in [VoiceOption.off, VoiceOption.silent]) {
        await startWith(voice);
        verify(() => h.audio.setVoiceMuted(muted: true)).called(1);
        verifyNever(() => h.audio.setVoicePack(any()));
        verifyNever(
          () => h.audio.setRandomizePerCue(enabled: any(named: 'enabled')),
        );
      }
    });
  });
}
