// Retest round 2 (2.6.0), kept as regression tests: the tester's probes for the session engine (adopted
// branch): voice, suspension by the coordinator's rule, tap cooldowns.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wod_timer/core/application/providers/app_settings_provider.dart';
import 'package:wod_timer/features/session/application/todays_wod_controller.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/timer/application/blocs/timer_state.dart';

import '../../helpers/notifier_harness.dart';
import '../../helpers/session_harness.dart';

const amrap60 = AmrapBlock(durationSeconds: 60);
const rest120 = RestBlock(seconds: 120);
const emom = EmomBlock(intervalSeconds: 15, rounds: 2);
const tabata = TabataBlock(workSeconds: 10, restSeconds: 5, rounds: 2);
const sets2 = SetsBlock(sets: 2, restSeconds: 30);
const ftCap60 = ForTimeBlock(capSeconds: 60, countUp: true);

/// One tick on [e] of [ms], without moving the tap clock.
void emit(FakeTimerEngine e, int ms) =>
    e.emit(e.elapsed + Duration(milliseconds: ms));

void setVoice(SessionHarness s, VoiceOption v) {
  final n = s.h.container.read(appSettingsNotifierProvider.notifier);
  // The test sets the voice as the settings screen would, directly.
  // ignore: invalid_use_of_protected_member
  n.state = n.state.copyWith(voice: v);
}

void main() {
  group('voice: applied before the first spoken cue', () {
    for (final voice in VoiceOption.values) {
      for (final (name, first) in <(String, SessionBlock)>[
        ('Sets', sets2),
        ('Rest', rest120),
        ('a timer', amrap60),
      ]) {
        test('${voice.name}, session starting on $name', () async {
          final s = SessionHarness(settings: AppSettings(voice: voice));
          addTearDown(s.dispose);
          await s.start([first, rest120, sets2]);
          await s.advance(1);
          final muted = voice == VoiceOption.off || voice == VoiceOption.silent;
          final audio = s.h.audio;
          verifyInOrder([
            () => audio.setVoiceMuted(muted: muted),
            if (first is RestBlock) audio.playRest else audio.playGetReady,
          ]);
          verifyNever(() => audio.setVoiceMuted(muted: !muted));
          switch (voice) {
            case VoiceOption.major || VoiceOption.liam || VoiceOption.holly:
              verify(
                () => audio.setVoicePack(voice.name),
              ).called(greaterThanOrEqualTo(1));
              verifyNever(() => audio.setRandomizePerCue(enabled: true));
            case VoiceOption.random:
              verify(
                () => audio.setRandomizePerCue(enabled: true),
              ).called(greaterThanOrEqualTo(1));
            case VoiceOption.off || VoiceOption.silent:
              break;
          }
        });
      }
    }

    test('changed mid-session it applies at once, in a rest and in a set; '
        'after the end it waits for the next start', () async {
      // Major is the harness default.
      final s = SessionHarness();
      addTearDown(s.dispose);
      final audio = s.h.audio;
      await s.start(const [rest120, sets2]);
      await s.advance(5);
      clearInteractions(audio);
      setVoice(s, VoiceOption.off);
      await s.flush();
      verify(() => audio.setVoiceMuted(muted: true)).called(1);
      setVoice(s, VoiceOption.holly);
      await s.flush();
      verifyInOrder([
        () => audio.setVoiceMuted(muted: false),
        () => audio.setVoicePack('holly'),
      ]);
      await s.advance(130); // into set 1
      expect(s.run.phase, WodPhase.setWork);
      clearInteractions(audio);
      setVoice(s, VoiceOption.random);
      await s.flush();
      verify(() => audio.setRandomizePerCue(enabled: true)).called(1);
      s.controller.pause();
      await s.flush();
      s.controller.stop();
      await s.flush();
      expect(s.run.isFinished, isTrue);
      clearInteractions(audio);
      setVoice(s, VoiceOption.silent);
      await s.flush();
      verifyNever(() => audio.setVoiceMuted(muted: any(named: 'muted')));
      // AGAIN waits out the end screen's first 700ms (fix 12).
      s.later();
      await s.controller.again();
      await s.flush();
      verifyInOrder([() => audio.setVoiceMuted(muted: true), audio.playRest]);
    });
  });

  group(
    'suspension: a Rest is charged only with time after the timer ended',
    () {
      late SessionHarness s;
      setUp(() => s = SessionHarness());
      tearDown(() => s.dispose());

      Future<void> away(int ms, {required bool timerFirst}) async {
        if (timerFirst) {
          emit(s.h.engine, ms);
          await s.flush();
          emit(s.sessionEngine, ms);
        } else {
          emit(s.sessionEngine, ms);
          await s.flush();
          emit(s.h.engine, ms);
        }
        await s.flush();
        // Settle one more ordinary tick on both.
        emit(s.sessionEngine, 100);
        emit(s.h.engine, 100);
        await s.flush();
      }

      for (final timerFirst in [true, false]) {
        final order = timerFirst ? 'timer clock first' : 'session clock first';
        for (final (name, block, into) in <(String, SessionBlock, int)>[
          ('AMRAP', amrap60, 40),
          ('For Time by cap', ftCap60, 40),
          ('EMOM', emom, 20), // 10 + 10 of 30
          ('Tabata', tabata, 20), // 10 + 10 of 30
        ]) {
          test('$name, away 60s across its end ($order)', () async {
            await s.start([block, rest120, emom]);
            await s.advance(into);
            final left = block.estimatedSeconds - (into - 10);
            await away(60000, timerFirst: timerFirst);
            expect(s.run.index, 1);
            expect(s.run.phase, WodPhase.rest);
            // 60s away, [left] of them still in the timer block.
            expect(s.run.remainingSeconds, closeTo(120 - (60 - left), 1));
          });
        }

        test('get-ready skipped earlier, then away 60s across the AMRAP end '
            '($order)', () async {
          await s.start(const [amrap60, rest120, emom]);
          await s.advance(2);
          s.h.notifier.skipPrep();
          await s.flush();
          await s.advance(30);
          expect(s.timer.sessionOrNull!.elapsed.seconds, 30);
          await away(60000, timerFirst: timerFirst);
          expect(s.run.phase, WodPhase.rest);
          // 30s of AMRAP were left: 30s of rest gone.
          expect(s.run.remainingSeconds, closeTo(90, 1));
        });

        test('paused in the AMRAP, resumed, then away 60s ($order)', () async {
          await s.start(const [amrap60, rest120, emom]);
          await s.advance(40);
          s.later();
          s.controller.pause();
          await s.flush();
          s.later();
          s.controller.resume();
          await s.flush();
          await away(60000, timerFirst: timerFirst);
          expect(s.run.phase, WodPhase.rest);
          expect(s.run.remainingSeconds, closeTo(90, 1));
        });

        test('away 5 min across the AMRAP end: through the Rest and the Sets '
            'get-ready, stops on set 1 ($order)', () async {
          await s.start(const [amrap60, rest120, sets2, emom]);
          await s.advance(40);
          await away(300000, timerFirst: timerFirst);
          expect(s.run.index, 2);
          expect(s.run.phase, WodPhase.setWork);
          expect(s.run.set, 1);
        });

        test('away 5 min across the AMRAP end: never into the next timer '
            '($order)', () async {
          await s.start(const [amrap60, rest120, emom]);
          await s.advance(40);
          await away(300000, timerFirst: timerFirst);
          expect(s.run.index, 2);
          expect(s.run.phase, WodPhase.timer);
          expect(s.timer, isA<TimerPreparing>());
          expect(s.timer.sessionOrNull!.timeRemaining.seconds, 10);
        });

        test(
          'away in the get-ready past the whole AMRAP and Rest ($order)',
          () async {
            await s.start(const [amrap60, rest120, sets2]);
            await s.advance(5);
            await away(400000, timerFirst: timerFirst);
            // A probe's record of what it saw, in the test output.
            // ignore: avoid_print
            print(
              'idx ${s.run.index} ${s.run.phase} set ${s.run.set} '
              'timer ${s.timer.runtimeType}',
            );
            expect(s.run.index, 2);
            expect(s.run.phase, WodPhase.setWork);
          },
        );

        test('timer to timer, away 5 min: the next starts its get-ready '
            '($order)', () async {
          await s.start(const [amrap60, emom, rest120]);
          await s.advance(40);
          await away(300000, timerFirst: timerFirst);
          expect(s.run.index, 1);
          expect(s.timer, isA<TimerPreparing>());
        });
      }

      test('no suspension, get-ready skipped: the Rest after is not shortened '
          'or stretched', () async {
        await s.start(const [amrap60, rest120, emom]);
        await s.advance(2);
        s.h.notifier.skipPrep();
        await s.flush();
        await s.advance(60);
        expect(s.run.phase, WodPhase.rest);
        await s.advance(10);
        expect(s.run.remainingSeconds, closeTo(110, 1));
        await s.advance(109);
        expect(s.run.phase, WodPhase.rest, reason: 'one second of rest left');
        await s.advance(2);
        expect(s.run.index, 2);
      });

      test(
        'session time and drift over three timer blocks, 100ms ticks',
        () async {
          await s.start(const [
            emom,
            rest120,
            tabata,
            RestBlock(seconds: 15),
            amrap60,
          ]);
          await s.advance(
            10 + 30 + 120 + 10 + 30 + 15 + 10 + 60 + 1,
            stepMs: 100,
          );
          expect(s.run.isFinished, isTrue);
          // A probe's record of what it saw, in the test output.
          // ignore: avoid_print
          print('total ${s.run.totalMs}');
          expect(s.run.totalMs, closeTo(285000, 1100));
        },
      );
    },
  );

  group('taps around a phase change', () {
    late SessionHarness s;
    setUp(() => s = SessionHarness());
    tearDown(() => s.dispose());

    test('a late skip after the Rest ran out does not skip the Sets '
        'get-ready; after the cooldown it does', () async {
      await s.start(const [RestBlock(seconds: 15), sets2]);
      for (var i = 0; i < 15; i++) {
        emit(s.sessionEngine, 1000);
        await s.flush();
      }
      expect(s.run.phase, WodPhase.getReady);
      s.controller.skip();
      expect(s.run.phase, WodPhase.getReady);
      s.later();
      s.controller.skip();
      expect(s.run.phase, WodPhase.setWork);
    });

    test(
      'SET DONE right as the rest runs out is not taken for the next set',
      () async {
        await s.start(const [sets2, rest120]);
        await s.advance(10);
        s.later();
        s.controller.setDone();
        for (var i = 0; i < 30; i++) {
          emit(s.sessionEngine, 1000);
          await s.flush();
        }
        expect(s.run.phase, WodPhase.setWork);
        expect(s.run.set, 2);
        s.controller.setDone(); // aimed at PAUSE of the rest, lands on SET DONE
        expect(s.run.phase, WodPhase.setWork, reason: 'set 2 not done yet');
      },
    );

    test('FINISH then a second tap where PAUSE now is: the Rest keeps '
        'counting', () async {
      await s.start(const [
        ForTimeBlock(capSeconds: 600, countUp: true),
        rest120,
      ]);
      await s.advance(30);
      s.h.notifier.finish();
      await s.flush();
      expect(s.run.phase, WodPhase.rest);
      s.controller.pause(); // the second tap of a double tap on FINISH
      await s.flush();
      expect(
        s.run.paused,
        isFalse,
        reason: 'a double tap on FINISH paused the rest',
      );
    });

    test('the last SET DONE then a second tap where AGAIN now is: the end '
        'screen stays', () async {
      await s.start(const [SetsBlock(sets: 1, restSeconds: 30)]);
      await s.advance(10);
      s.later();
      s.controller.setDone();
      await s.flush();
      expect(s.run.isFinished, isTrue);
      await s.controller.again(); // the second tap lands on AGAIN
      await s.flush();
      expect(
        s.run.isFinished,
        isTrue,
        reason: 'a double tap on the last SET DONE restarted the session',
      );
    });
  });
}
