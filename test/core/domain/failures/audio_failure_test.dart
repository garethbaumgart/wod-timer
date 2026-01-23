import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/domain/failures/audio_failure.dart';

void main() {
  group('AudioFailure', () {
    group('loadError', () {
      test('should have default message when fileName is null', () {
        const failure = AudioFailure.loadError();

        expect(failure.message, 'Failed to load audio');
      });

      test('should include fileName in message', () {
        const failure = AudioFailure.loadError(fileName: 'beep.mp3');

        expect(failure.message, 'Failed to load audio: beep.mp3');
      });
    });

    group('playbackError', () {
      test('should have default message when message is null', () {
        const failure = AudioFailure.playbackError();

        expect(failure.message, 'Audio playback failed');
      });

      test('should use provided message', () {
        const failure = AudioFailure.playbackError(message: 'Device busy');

        expect(failure.message, 'Device busy');
      });
    });

    group('fileNotFound', () {
      test('should include fileName in message', () {
        const failure = AudioFailure.fileNotFound(fileName: 'countdown.wav');

        expect(failure.message, 'Audio file not found: countdown.wav');
      });
    });

    group('unsupportedFormat', () {
      test('should have default message when format is null', () {
        const failure = AudioFailure.unsupportedFormat();

        expect(failure.message, 'Unsupported audio format');
      });

      test('should include format in message', () {
        const failure = AudioFailure.unsupportedFormat(format: 'ogg');

        expect(failure.message, 'Unsupported audio format: ogg');
      });
    });

    group('permissionDenied', () {
      test('should have correct message', () {
        const failure = AudioFailure.permissionDenied();

        expect(failure.message, 'Audio permission denied');
      });
    });

    group('deviceUnavailable', () {
      test('should have correct message', () {
        const failure = AudioFailure.deviceUnavailable();

        expect(failure.message, 'Audio device is unavailable');
      });
    });

    group('unexpected', () {
      test('should have default message when message is null', () {
        const failure = AudioFailure.unexpected();

        expect(failure.message, 'An unexpected audio error occurred');
      });

      test('should use provided message', () {
        const failure = AudioFailure.unexpected(message: 'Hardware error');

        expect(failure.message, 'Hardware error');
      });
    });

    group('equality', () {
      test('same failures should be equal', () {
        const failure1 = AudioFailure.fileNotFound(fileName: 'test.mp3');
        const failure2 = AudioFailure.fileNotFound(fileName: 'test.mp3');

        expect(failure1, equals(failure2));
      });

      test('different failures should not be equal', () {
        const failure1 = AudioFailure.loadError();
        const failure2 = AudioFailure.playbackError();

        expect(failure1, isNot(equals(failure2)));
      });

      test('same type but different values should not be equal', () {
        const failure1 = AudioFailure.fileNotFound(fileName: 'a.mp3');
        const failure2 = AudioFailure.fileNotFound(fileName: 'b.mp3');

        expect(failure1, isNot(equals(failure2)));
      });
    });

    group('when pattern matching', () {
      test('should match loadError', () {
        const failure = AudioFailure.loadError();

        final result = failure.when(
          loadError: (_) => 'load',
          playbackError: (_) => 'playback',
          fileNotFound: (_) => 'notFound',
          unsupportedFormat: (_) => 'unsupported',
          permissionDenied: () => 'permission',
          deviceUnavailable: () => 'device',
          unexpected: (_) => 'unexpected',
        );

        expect(result, 'load');
      });

      test('should match all failure types', () {
        final failures = <AudioFailure>[
          const AudioFailure.loadError(),
          const AudioFailure.playbackError(),
          const AudioFailure.fileNotFound(fileName: 'test.mp3'),
          const AudioFailure.unsupportedFormat(),
          const AudioFailure.permissionDenied(),
          const AudioFailure.deviceUnavailable(),
          const AudioFailure.unexpected(),
        ];

        for (final failure in failures) {
          expect(failure.message, isNotEmpty);
        }
      });
    });
  });
}
