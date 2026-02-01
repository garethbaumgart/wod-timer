import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wod_timer/core/domain/failures/audio_failure.dart';
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart';

class MockAudioService extends Mock implements IAudioService {}

void main() {
  group('IAudioService', () {
    late MockAudioService mockAudioService;

    setUp(() {
      mockAudioService = MockAudioService();
    });

    group('playBeep', () {
      test('should return success when beep plays', () async {
        when(
          () => mockAudioService.playBeep(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playBeep();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playBeep()).called(1);
      });

      test('should return failure on playback error', () async {
        when(
          () => mockAudioService.playBeep(),
        ).thenAnswer((_) async => left(const AudioFailure.playbackError()));

        final result = await mockAudioService.playBeep();

        expect(result.isLeft(), true);
      });
    });

    group('playCountdown', () {
      test('should play countdown numbers', () async {
        when(
          () => mockAudioService.playCountdown(any()),
        ).thenAnswer((_) async => right(unit));

        for (final num in [3, 2, 1]) {
          final result = await mockAudioService.playCountdown(num);
          expect(result.isRight(), true);
        }

        verify(() => mockAudioService.playCountdown(3)).called(1);
        verify(() => mockAudioService.playCountdown(2)).called(1);
        verify(() => mockAudioService.playCountdown(1)).called(1);
      });
    });

    group('playGo', () {
      test('should return success when go sound plays', () async {
        when(
          () => mockAudioService.playGo(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playGo();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playGo()).called(1);
      });
    });

    group('playRest', () {
      test('should return success when rest sound plays', () async {
        when(
          () => mockAudioService.playRest(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playRest();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playRest()).called(1);
      });
    });

    group('playComplete', () {
      test('should return success when complete sound plays', () async {
        when(
          () => mockAudioService.playComplete(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playComplete();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playComplete()).called(1);
      });
    });

    group('playHalfway', () {
      test('should return success when halfway sound plays', () async {
        when(
          () => mockAudioService.playHalfway(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playHalfway();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playHalfway()).called(1);
      });
    });

    group('playIntervalStart', () {
      test('should return success when interval sound plays', () async {
        when(
          () => mockAudioService.playIntervalStart(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playIntervalStart();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playIntervalStart()).called(1);
      });
    });

    group('playGetReady', () {
      test('should return success when get ready sound plays', () async {
        when(
          () => mockAudioService.playGetReady(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playGetReady();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playGetReady()).called(1);
      });
    });

    group('playTenSeconds', () {
      test('should return success when ten seconds sound plays', () async {
        when(
          () => mockAudioService.playTenSeconds(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playTenSeconds();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playTenSeconds()).called(1);
      });
    });

    group('playLastRound', () {
      test('should return success when last round sound plays', () async {
        when(
          () => mockAudioService.playLastRound(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playLastRound();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playLastRound()).called(1);
      });
    });

    group('playKeepGoing', () {
      test('should return success when keep going sound plays', () async {
        when(
          () => mockAudioService.playKeepGoing(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playKeepGoing();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playKeepGoing()).called(1);
      });
    });

    group('playGoodJob', () {
      test('should return success when good job sound plays', () async {
        when(
          () => mockAudioService.playGoodJob(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playGoodJob();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playGoodJob()).called(1);
      });
    });

    group('playNextRound', () {
      test('should return success when next round sound plays', () async {
        when(
          () => mockAudioService.playNextRound(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playNextRound();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playNextRound()).called(1);
      });
    });

    group('playFinalCountdown', () {
      test('should return success when final countdown sound plays', () async {
        when(
          () => mockAudioService.playFinalCountdown(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playFinalCountdown();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playFinalCountdown()).called(1);
      });
    });

    group('playLetsGo', () {
      test('should return success when lets go sound plays', () async {
        when(
          () => mockAudioService.playLetsGo(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playLetsGo();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playLetsGo()).called(1);
      });
    });

    group('playComeOn', () {
      test('should return success when come on sound plays', () async {
        when(
          () => mockAudioService.playComeOn(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playComeOn();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playComeOn()).called(1);
      });
    });

    group('playAlmostThere', () {
      test('should return success when almost there sound plays', () async {
        when(
          () => mockAudioService.playAlmostThere(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playAlmostThere();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playAlmostThere()).called(1);
      });
    });

    group('playThatsIt', () {
      test('should return success when thats it sound plays', () async {
        when(
          () => mockAudioService.playThatsIt(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playThatsIt();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playThatsIt()).called(1);
      });
    });

    group('playNoRep', () {
      test('should return success when no rep sound plays', () async {
        when(
          () => mockAudioService.playNoRep(),
        ).thenAnswer((_) async => right(unit));

        final result = await mockAudioService.playNoRep();

        expect(result.isRight(), true);
        verify(() => mockAudioService.playNoRep()).called(1);
      });
    });

    group('setVoicePack', () {
      test('should set voice pack without error', () {
        when(() => mockAudioService.setVoicePack(any())).thenReturn(null);

        mockAudioService.setVoicePack('liam');

        verify(() => mockAudioService.setVoicePack('liam')).called(1);
      });
    });

    group('mute control', () {
      test('should return muted state', () {
        when(() => mockAudioService.isMuted).thenReturn(true);
        expect(mockAudioService.isMuted, true);

        when(() => mockAudioService.isMuted).thenReturn(false);
        expect(mockAudioService.isMuted, false);
      });

      test('should call setMuted', () async {
        when(
          () => mockAudioService.setMuted(muted: any(named: 'muted')),
        ).thenAnswer((_) async {});

        await mockAudioService.setMuted(muted: true);

        verify(() => mockAudioService.setMuted(muted: true)).called(1);
      });
    });

    group('volume control', () {
      test('should call setVolume', () async {
        when(() => mockAudioService.setVolume(any())).thenAnswer((_) async {});

        await mockAudioService.setVolume(0.5);

        verify(() => mockAudioService.setVolume(0.5)).called(1);
      });
    });

    group('lifecycle', () {
      test('should call preloadSounds', () async {
        when(() => mockAudioService.preloadSounds()).thenAnswer((_) async {});

        await mockAudioService.preloadSounds();

        verify(() => mockAudioService.preloadSounds()).called(1);
      });

      test('should call dispose', () async {
        when(() => mockAudioService.dispose()).thenAnswer((_) async {});

        await mockAudioService.dispose();

        verify(() => mockAudioService.dispose()).called(1);
      });
    });

    group('error handling', () {
      test('should return file not found failure', () async {
        when(() => mockAudioService.playBeep()).thenAnswer(
          (_) async =>
              left(const AudioFailure.fileNotFound(fileName: 'beep.mp3')),
        );

        final result = await mockAudioService.playBeep();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<AudioFailure>()),
          (_) => fail('Should fail'),
        );
      });

      test('should return device unavailable failure', () async {
        when(
          () => mockAudioService.playComplete(),
        ).thenAnswer((_) async => left(const AudioFailure.deviceUnavailable()));

        final result = await mockAudioService.playComplete();

        expect(result.isLeft(), true);
      });
    });
  });
}
