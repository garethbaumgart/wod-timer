import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/domain/failures/storage_failure.dart';

void main() {
  group('StorageFailure', () {
    group('readError', () {
      test('should have default message when message is null', () {
        const failure = StorageFailure.readError();

        expect(failure.message, 'Failed to read data');
      });

      test('should use provided message', () {
        const failure = StorageFailure.readError(message: 'Custom error');

        expect(failure.message, 'Custom error');
      });
    });

    group('writeError', () {
      test('should have default message when message is null', () {
        const failure = StorageFailure.writeError();

        expect(failure.message, 'Failed to save data');
      });

      test('should use provided message', () {
        const failure = StorageFailure.writeError(message: 'Write failed');

        expect(failure.message, 'Write failed');
      });
    });

    group('deleteError', () {
      test('should have default message when message is null', () {
        const failure = StorageFailure.deleteError();

        expect(failure.message, 'Failed to delete data');
      });

      test('should use provided message', () {
        const failure = StorageFailure.deleteError(message: 'Delete failed');

        expect(failure.message, 'Delete failed');
      });
    });

    group('notFound', () {
      test('should have default message when key is null', () {
        const failure = StorageFailure.notFound();

        expect(failure.message, 'Data not found');
      });

      test('should include key in message', () {
        const failure = StorageFailure.notFound(key: 'workout_123');

        expect(failure.message, 'Data not found: workout_123');
      });
    });

    group('corrupted', () {
      test('should have default message when message is null', () {
        const failure = StorageFailure.corrupted();

        expect(failure.message, 'Data is corrupted');
      });

      test('should use provided message', () {
        const failure = StorageFailure.corrupted(message: 'Invalid JSON');

        expect(failure.message, 'Invalid JSON');
      });
    });

    group('permissionDenied', () {
      test('should have correct message', () {
        const failure = StorageFailure.permissionDenied();

        expect(failure.message, 'Storage permission denied');
      });
    });

    group('storageFull', () {
      test('should have correct message', () {
        const failure = StorageFailure.storageFull();

        expect(failure.message, 'Storage is full');
      });
    });

    group('unexpected', () {
      test('should have default message when message is null', () {
        const failure = StorageFailure.unexpected();

        expect(failure.message, 'An unexpected storage error occurred');
      });

      test('should use provided message', () {
        const failure = StorageFailure.unexpected(message: 'Unknown error');

        expect(failure.message, 'Unknown error');
      });
    });

    group('equality', () {
      test('same failures should be equal', () {
        const failure1 = StorageFailure.readError(message: 'test');
        const failure2 = StorageFailure.readError(message: 'test');

        expect(failure1, equals(failure2));
      });

      test('different failures should not be equal', () {
        const failure1 = StorageFailure.readError();
        const failure2 = StorageFailure.writeError();

        expect(failure1, isNot(equals(failure2)));
      });
    });

    group('when pattern matching', () {
      test('should match readError', () {
        const failure = StorageFailure.readError();

        final result = failure.when(
          readError: (_) => 'read',
          writeError: (_) => 'write',
          deleteError: (_) => 'delete',
          notFound: (_) => 'notFound',
          corrupted: (_) => 'corrupted',
          permissionDenied: () => 'permission',
          storageFull: () => 'full',
          unexpected: (_) => 'unexpected',
        );

        expect(result, 'read');
      });

      test('should match all failure types', () {
        final failures = <StorageFailure>[
          const StorageFailure.readError(),
          const StorageFailure.writeError(),
          const StorageFailure.deleteError(),
          const StorageFailure.notFound(),
          const StorageFailure.corrupted(),
          const StorageFailure.permissionDenied(),
          const StorageFailure.storageFull(),
          const StorageFailure.unexpected(),
        ];

        for (final failure in failures) {
          expect(failure.message, isNotEmpty);
        }
      });
    });
  });
}
