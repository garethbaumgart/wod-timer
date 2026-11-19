// The cue schedule: which beep, voice cue and haptic fire at which second
// of a workout, and what happens at the end (Good job, the time-cap tone,
// the review payoff). Since 2.1.0 every phase change is the gym-timer
// pattern: low beeps with 3, 2 and 1 seconds left, then the high beep with
// the voice line on it. Since 8 Nov 2026 there are no encouragement lines
// (Keep going / Come on, Almost there) and no coin flips: GO is "Go", the
// end is "Good job".
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

  /// What was heard, second by second. Every cue says one thing, so there
  /// is nothing to fold.
  List<String> heard() => h.heard;

  /// Low beeps 3 seconds before [second], then the high beep on it.
  List<String> countIn(int second) => [
    '${second - 3}s low 3',
    '${second - 2}s low 2',
    '${second - 1}s low 1',
    '${second}s high',
  ];

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
      expect(h.played.last, 'go');
      expect(h.felt.last, 'heavy');
    });

    test('each beep plays once even with 100ms ticks', () async {
      await h.notifier.start(amrapWorkout(seconds: 60, prep: 5));
      for (var ms = 100; ms <= 5000; ms += 100) {
        h.tick(ms ~/ 1000, ms % 1000);
      }
      expect(h.played, ['get ready', 'go']);
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
      expect(h.played, ['get ready', 'go']);
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
    test('GO on the high beep; halfway and ten seconds; the count-in to '
        'the end with Good job on the high beep', () async {
      await h.notifier.start(amrapWorkout(seconds: 60));
      expect(heard(), ['0s high', '0s go']);
      expect(h.felt, ['heavy']);

      h.run(1, 60);
      expect(heard(), [
        '0s high',
        '0s go',
        '30s mid',
        '30s halfway',
        '50s ten seconds',
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
        'Good job', () async {
      await h.notifier.start(amrapWorkout(seconds: 60));
      h
        ..tick(1)
        ..tick(60);
      expect(h.state, isA<TimerCompleted>());
      expect(h.beeped, ['high', 'high'], reason: 'no count-in was due');
      expect(h.played.last, 'good job');
    });

    test('no optional voice cue lands inside the count-in', () async {
      // Halfway of 6s is 3s: it would land on the low 3 beep, so it sits out.
      await h.notifier.start(amrapWorkout(seconds: 6));
      h.run(1, 6);
      expect(heard(), ['0s high', '0s go', ...countIn(6), '6s good job']);
    });

    test('no encouragement lines: a 120s AMRAP hears GO, Halfway, Ten '
        'seconds and Good job, nothing else spoken', () async {
      await h.notifier.start(amrapWorkout(seconds: 120));
      h.run(1, 120);
      expect(h.played, ['go', 'halfway', 'ten seconds', 'good job']);
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
        '30s mid',
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
        '30s mid',
        ...countIn(60),
        '60s next round',
        '90s mid',
        '90s halfway',
        ...countIn(120),
        '120s last round',
        '150s mid',
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
        expect(h.played, ['go', 'next round']);
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
        '10s mid',
        ...countIn(20),
        '20s rest',
        ...countIn(30),
        '30s last round',
        '40s mid',
        ...countIn(50),
        '50s rest',
        // Ten seconds (50s) would talk over Rest, so it sits out.
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
        expect(h.played, ['go', 'next round']);
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
        '30s mid',
        '30s halfway',
        '50s ten seconds',
        ...countIn(60),
        '60s complete',
      ]);
      await settle();
      expect(h.valueMoments, 0);
    });

    test(
      'FINISH celebrates: the high beep, a success buzz and Good job',
      () async {
        await h.notifier.start(forTimeWorkout(cap: 600));
        h.run(1, 30);
        h.notifier.finish();
        expect(h.state, isA<TimerCompleted>());
        expect((h.state as TimerCompleted).endedEarly, isFalse);
        expect(h.felt.last, 'success');
        expect(h.engine.calls.last, 'stop');
        expect(heard().sublist(heard().length - 2), [
          '30s high',
          '30s good job',
        ]);
      },
    );

    test('FINISH during the count-in cuts it short at once', () async {
      await h.notifier.start(forTimeWorkout(cap: 60));
      h.run(1, 58);
      expect(h.beeped.last, 'low 2');
      h.notifier.finish();
      expect(h.beeped.last, 'high');
      expect(h.played.last, 'good job');
      h.tick(59);
      expect(h.beeped.last, 'high', reason: 'no beeps after the end');
    });

    test('a count-down For Time cues on the same schedule', () async {
      await h.notifier.start(forTimeWorkout(cap: 60, countUp: false));
      h.run(1, 59);
      expect(heard(), [
        '0s high',
        '0s go',
        '30s mid',
        '30s halfway',
        '50s ten seconds',
        '57s low 3',
        '58s low 2',
        '59s low 1',
      ]);
    });
  });

  group('mid-round pips (2.5.0, no setting)', () {
    test('every EMOM minute pips once at its halfway, with one tap', () async {
      await h.notifier.start(emomWorkout(rounds: 3));
      h.run(1, 180);
      expect(heard().where((c) => c.endsWith(' mid')), [
        '30s mid',
        '90s mid',
        '150s mid',
      ]);
    });

    test('every tick of 100ms still pips once per round', () async {
      await h.notifier.start(emomWorkout(interval: 20, rounds: 2));
      for (var ms = 100; ms <= 40000; ms += 100) {
        h.tick(ms ~/ 1000, ms % 1000);
      }
      expect(h.beeped.where((b) => b == 'mid'), hasLength(2));
    });

    test('a 15s EMOM pips at 7s left (the half rounds down)', () async {
      await h.notifier.start(emomWorkout(interval: 15, rounds: 1));
      h.run(1, 15);
      expect(heard().where((c) => c.endsWith(' mid')), ['8s mid']);
    });

    test('Tabata pips in every work block, never in rest', () async {
      await h.notifier.start(tabataWorkout(rounds: 2));
      h.run(1, 60);
      expect(heard().where((c) => c.endsWith(' mid')), ['10s mid', '40s mid']);
    });

    test('phases under 10s get no pips', () async {
      await h.notifier.start(tabataWorkout(work: 5, rest: 5, rounds: 2));
      h.run(1, 20);
      expect(h.beeped, isNot(contains('mid')));
    });

    test('AMRAP and For Time pip once at the clock halfway, with one tap '
        'shared with the spoken Halfway', () async {
      await h.notifier.start(amrapWorkout(seconds: 600));
      h.run(1, 299);
      final taps = h.felt.length;
      h.tick(300);
      expect(heard().sublist(heard().length - 2), ['300s mid', '300s halfway']);
      expect(h.felt.length - taps, 1);
      h.run(301, 600);
      expect(h.beeped.where((b) => b == 'mid'), hasLength(1));
    });

    test('tallying AMRAP rounds never re-arms the pips', () async {
      await h.notifier.start(amrapWorkout(seconds: 120));
      h.run(1, 60);
      h.now = h.now.add(const Duration(seconds: 5));
      h.notifier.countRound();
      h.run(61, 61);
      expect(h.beeped.where((b) => b == 'mid'), hasLength(1));
    });

    test('a catch-up tick past the halfway stays quiet', () async {
      await h.notifier.start(emomWorkout(rounds: 2));
      h
        ..tick(1)
        ..tick(40);
      expect(h.beeped, isNot(contains('mid')));
    });

    test(
      'paused at the halfway: no pips while paused, none late on resume',
      () async {
        await h.notifier.start(emomWorkout(rounds: 2));
        h.run(1, 29);
        h.notifier.pause();
        h.tick(30);
        expect(h.beeped, isNot(contains('mid')));
        h.notifier.resume();
        h.tick(45);
        expect(h.beeped, isNot(contains('mid')));
        h.run(46, 120);
        expect(heard().where((c) => c.endsWith(' mid')), ['90s mid']);
      },
    );

    test('AGAIN re-arms the pips for the new run', () async {
      await h.notifier.start(emomWorkout(interval: 20, rounds: 1));
      h.run(1, 20);
      expect(h.beeped.where((b) => b == 'mid'), hasLength(1));
      await h.notifier.restart();
      h.run(1, 20);
      expect(h.beeped.where((b) => b == 'mid'), hasLength(2));
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
      expect(h.played, ['go']);
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
      expect(
        h.played.where((c) => c == 'go'),
        hasLength(2),
        reason: 'GO re-armed',
      );
      h.run(1, 5);
      expect(h.played.last, 'halfway', reason: 'the schedule runs again');
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

    test('an athlete who never chose a voice gets Beeps only', () async {
      h.dispose();
      h = NotifierHarness();
      await h.notifier.start(amrapWorkout(seconds: 60));
      verify(() => h.audio.setVoiceMuted(muted: true)).called(1);
      verifyNever(() => h.audio.setVoicePack(any()));
    });
  });
}
