// The cue schedule: which beep, voice cue and haptic fire at which second
// of a workout, and what happens at the end (encouragement, the time-cap
// tone, the review payoff). Since 2.1.0 every phase change is the gym-timer
// pattern: low beeps with 3, 2 and 1 seconds left, then the high beep with
// the voice line on it.
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

  /// What was heard, second by second, with the random picks folded to one
  /// name each ('lets go' -> 'go', 'come on' -> 'keep going',
  /// 'thats it' -> 'good job').
  List<String> heard() => [
    for (final line in h.heard)
      line
          .replaceAll('lets go', 'go')
          .replaceAll('come on', 'keep going')
          .replaceAll('thats it', 'good job'),
  ];

  /// Low beeps 3 seconds before [second], then the high beep on it.
  List<String> countIn(int second) => [
    '${second - 3}s low 3',
    '${second - 2}s low 2',
    '${second - 1}s low 1',
    '${second}s high',
  ];

  final go = anyOf('go', 'lets go');
  final motivation = anyOf('keep going', 'come on');
  final encouragement = anyOf('good job', 'thats it');

  group('get ready and GO', () {
    test('Get ready, low beeps at 3 2 1 with a tap each, then the high '
        'beep and GO with a thump', () async {
      await h.notifier.start(amrapWorkout(seconds: 60, prep: 10));
      expect(h.played, isEmpty);

      h.tick(1);
      expect(h.played, ['get ready']);
      h.run(2, 6);
      expect(h.beeped, isEmpty, reason: 'nothing until 3s left');

      h
        ..tick(7)
        ..tick(8)
        ..tick(9);
      expect(h.beeped, ['low 3', 'low 2', 'low 1']);
      expect(h.played, ['get ready'], reason: 'the numbers are beeps now');
      expect(h.felt, ['medium', 'medium', 'medium']);

      h.tick(10);
      expect(h.state, isA<TimerRunning>());
      expect(h.beeped.last, 'high');
      expect(h.played.last, go);
      expect(h.felt.last, 'heavy');
    });

    test('each beep plays once even with 100ms ticks', () async {
      await h.notifier.start(amrapWorkout(seconds: 60, prep: 5));
      for (var ms = 100; ms <= 5000; ms += 100) {
        h.tick(ms ~/ 1000, ms % 1000);
      }
      expect(h.played, ['get ready', go]);
      expect(h.beeped, ['low 3', 'low 2', 'low 1', 'high']);
    });

    test('a prep of exactly 3s says Get ready, then beeps 2 and 1', () async {
      await h.notifier.start(amrapWorkout(seconds: 60, prep: 3));
      h.tick(0, 100);
      expect(h.played, ['get ready']);
      expect(h.beeped, isEmpty);
      h
        ..tick(1)
        ..tick(2);
      expect(h.beeped, ['low 2', 'low 1']);
    });

    test('skipping the countdown plays GO on the high beep and starts the '
        'clock at zero', () async {
      await h.notifier.start(amrapWorkout(seconds: 60, prep: 10));
      h.tick(1);
      h.notifier.skipPrep();
      expect(h.state, isA<TimerRunning>());
      expect(h.state.sessionOrNull!.elapsed.seconds, 0);
      expect(h.played, ['get ready', go]);
      expect(h.beeped, ['high']);
      expect(h.felt, ['heavy']);
      // The GO cooldown: a tap that skipped the countdown cannot count.
      h.notifier.countRound();
      expect(h.state.sessionOrNull!.currentRound, 1);
    });

    test('skipPrep outside the countdown is a no-op', () async {
      await h.notifier.start(amrapWorkout(seconds: 60));
      h.tick(5);
      h.notifier.skipPrep();
      expect(h.state.sessionOrNull!.elapsed.seconds, 5);
    });
  });

  group('AMRAP schedule (60s)', () {
    test('GO on the high beep; motivation, halfway and ten seconds; the '
        'count-in to the end with the payoff on the high beep', () async {
      await h.notifier.start(amrapWorkout(seconds: 60));
      expect(heard(), ['0s high', '0s go']);
      expect(h.felt, ['heavy']);

      h.run(1, 60);
      expect(heard(), [
        '0s high',
        '0s go',
        '20s keep going',
        '30s halfway',
        '50s ten seconds',
        // Almost there (51s) would talk over Ten seconds, so it sits out.
        ...countIn(60),
        '60s good job',
      ]);
      expect(h.state, isA<TimerCompleted>());
      expect(h.state.endedAtTimeCap, isFalse);
      expect(h.felt.last, 'success');
      expect(h.engine.calls.last, 'stop');
    });

    test('a natural finish records the review payoff moment', () async {
      await h.notifier.start(amrapWorkout(seconds: 10));
      h.run(1, 10);
      expect(h.state, isA<TimerCompleted>());
      await settle();
      expect(h.valueMoments, 1);
      expect(h.requester.requests, 1);
    });

    test('a finish the app slept through still ends on the high beep and '
        'the encouragement', () async {
      await h.notifier.start(amrapWorkout(seconds: 60));
      h
        ..tick(1)
        ..tick(60);
      expect(h.state, isA<TimerCompleted>());
      expect(h.beeped, ['high', 'high'], reason: 'no count-in was due');
      expect(h.played.last, encouragement);
    });

    test('no optional voice cue lands inside the count-in', () async {
      // 85% of 12s is 10.2s: Almost there would land on the low 2 beep.
      await h.notifier.start(amrapWorkout(seconds: 12));
      h.run(1, 12);
      expect(heard(), [
        '0s high',
        '0s go',
        '4s keep going',
        '6s halfway',
        ...countIn(12),
        '12s good job',
      ]);
    });
  });

  group('EMOM schedule (3 x 60s)', () {
    test('a count-in to every minute: Next round, then Last round, then '
        'the end; the round cue beats halfway on the same tick', () async {
      await h.notifier.start(emomWorkout(rounds: 3));
      h.run(1, 59);
      expect(heard(), [
        '0s high',
        '0s go',
        '57s low 3',
        '58s low 2',
        '59s low 1',
      ]);

      h.tick(60);
      expect(h.state.sessionOrNull!.currentRound, 2);
      expect(h.felt.last, 'heavy');

      h.run(61, 180);
      expect(heard(), [
        '0s high',
        '0s go',
        ...countIn(60),
        // 60s is also 33% of the workout: the round cue took the slot.
        '60s next round',
        '90s halfway',
        ...countIn(120),
        '120s last round',
        '153s almost there',
        '170s ten seconds',
        ...countIn(180),
        '180s good job',
      ]);
      expect(h.state, isA<TimerCompleted>());
      expect(h.state.sessionOrNull!.currentRound, 3);
    });

    test(
      'a catch-up tick across several rounds cues once and lands right',
      () async {
        await h.notifier.start(emomWorkout(rounds: 5));
        // One tick, then the app was suspended for three minutes.
        h
          ..tick(1)
          ..tick(181);
        final session = h.state.sessionOrNull!;
        expect(session.currentRound, 4);
        expect(session.currentIntervalElapsed.seconds, 1);
        expect(h.played, [go, 'next round']);
        expect(h.beeped, ['high', 'high']);
      },
    );

    test('the Last round cue never repeats', () async {
      await h.notifier.start(emomWorkout(interval: 10, rounds: 2));
      h.run(1, 19);
      expect(h.played.where((c) => c == 'last round'), hasLength(1));
    });
  });

  group('Tabata schedule (20s / 10s x 2)', () {
    test('a count-in to every change: Rest with a warning buzz, Last round '
        'as work resumes, the final rest, then done', () async {
      await h.notifier.start(tabataWorkout(rounds: 2));
      h.run(1, 20);
      expect(h.state, isA<TimerResting>());
      expect(h.felt.last, 'warning');

      h.run(21, 30);
      expect(h.state, isA<TimerRunning>());
      expect(h.state.sessionOrNull!.currentRound, 2);
      // Back to work thumps, and the new round thumps.
      expect(h.felt.sublist(h.felt.length - 2), ['heavy', 'heavy']);

      h.run(31, 60);
      expect(heard(), [
        '0s high',
        '0s go',
        ...countIn(20),
        '20s rest',
        ...countIn(30),
        '30s last round',
        ...countIn(50),
        '50s rest',
        // Almost there and Ten seconds would talk over Rest: they sit out.
        ...countIn(60),
        '60s good job',
      ]);
      expect(h.state, isA<TimerCompleted>());
      expect(h.state.sessionOrNull!.currentRound, 2);
      expect(h.felt.last, 'success');
    });

    test(
      'no Rest cue when the rest ends in the same tick as the round',
      () async {
        await h.notifier.start(tabataWorkout(rounds: 3));
        // Suspended through the end of round 1's rest, into round 2's work.
        h
          ..tick(1)
          ..tick(32);
        expect(h.state, isA<TimerRunning>());
        expect(h.state.sessionOrNull!.currentRound, 2);
        expect(h.played, [go, 'next round']);
        expect(h.beeped, ['high', 'high'], reason: 'one beep per change');
      },
    );

    test('phases of 3s or less skip the beeps they start on', () async {
      await h.notifier.start(tabataWorkout(work: 3, rest: 2, rounds: 1));
      h.run(1, 5);
      expect(h.beeped, ['high', 'low 2', 'low 1', 'high', 'low 1', 'high']);
    });
  });

  group('For Time', () {
    test('reaching the cap: the count-in, then the end tone on the high '
        'beep; no Good job, no review', () async {
      await h.notifier.start(forTimeWorkout(cap: 60));
      h.run(1, 60);
      expect(h.state, isA<TimerCompleted>());
      expect(h.state.endedAtTimeCap, isTrue);
      expect(h.felt.last, 'heavy');
      expect(heard(), [
        '0s high',
        '0s go',
        '20s keep going',
        '30s halfway',
        '50s ten seconds',
        ...countIn(60),
        '60s complete',
      ]);
      await settle();
      expect(h.valueMoments, 0);
    });

    test('FINISH celebrates: the high beep, a success buzz and the '
        'encouragement', () async {
      await h.notifier.start(forTimeWorkout(cap: 600));
      h.run(1, 30);
      h.notifier.finish();
      expect(h.state, isA<TimerCompleted>());
      expect((h.state as TimerCompleted).endedEarly, isFalse);
      expect(h.felt.last, 'success');
      expect(h.engine.calls.last, 'stop');
      expect(heard().sublist(heard().length - 2), ['30s high', '30s good job']);
    });

    test('FINISH during the count-in cuts it short at once', () async {
      await h.notifier.start(forTimeWorkout(cap: 60));
      h.run(1, 58);
      expect(h.beeped.last, 'low 2');
      h.notifier.finish();
      expect(h.beeped.last, 'high');
      expect(h.played.last, encouragement);
      h.tick(59);
      expect(h.beeped.last, 'high', reason: 'no beeps after the end');
    });

    test('a count-down For Time cues on the same schedule', () async {
      await h.notifier.start(forTimeWorkout(cap: 60, countUp: false));
      h.run(1, 59);
      expect(heard(), [
        '0s high',
        '0s go',
        '20s keep going',
        '30s halfway',
        '50s ten seconds',
        '57s low 3',
        '58s low 2',
        '59s low 1',
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
      expect(h.played.last, motivation, reason: 'one-shot cues re-armed');
      expect(h.beeped.where((b) => b == 'high'), hasLength(3));
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
        h
          ..tick(5)
          ..later()
          ..notifier.countRound();
        expect(h.state.sessionOrNull!.currentRound, 1);

        await h.notifier.start(amrapWorkout(seconds: 60, prep: 10));
        h
          ..tick(1)
          ..later()
          ..notifier.countRound();
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
      h
        ..tick(5)
        ..later()
        ..felt.clear()
        ..notifier.countRound();
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
