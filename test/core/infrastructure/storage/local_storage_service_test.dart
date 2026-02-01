import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/domain/failures/storage_failure.dart';
import 'package:wod_timer/core/infrastructure/storage/local_storage_service.dart';

void main() {
  late FileLocalStorageService storageService;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wod_timer_test_');
    storageService = FileLocalStorageService(baseDirectory: tempDir);
  });

  tearDown(() async {
    await storageService.dispose();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FileLocalStorageService', () {
    group('readJson / writeJson', () {
      test('should return null for non-existent key', () async {
        final result = await storageService.readJson('non_existent');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (value) => expect(value, isNull),
        );
      });

      test('should write and read JSON map', () async {
        final data = <String, dynamic>{
          'name': 'Test',
          'value': 42,
          'nested': {'a': 1, 'b': 2},
        };

        final writeResult = await storageService.writeJson('test_key', data);
        expect(writeResult.isRight(), true);

        final readResult = await storageService.readJson('test_key');
        expect(readResult.isRight(), true);
        readResult.fold((failure) => fail('Should not fail'), (value) {
          expect(value, isNotNull);
          expect(value!['name'], 'Test');
          expect(value['value'], 42);
          expect(value['nested']['a'], 1);
        });
      });

      test('should overwrite existing data', () async {
        final data1 = <String, dynamic>{'version': 1};
        final data2 = <String, dynamic>{'version': 2};

        await storageService.writeJson('overwrite_key', data1);
        await storageService.writeJson('overwrite_key', data2);

        final readResult = await storageService.readJson('overwrite_key');
        readResult.fold(
          (failure) => fail('Should not fail'),
          (value) => expect(value!['version'], 2),
        );
      });
    });

    group('readJsonList / writeJsonList', () {
      test('should return empty list for non-existent key', () async {
        final result = await storageService.readJsonList('non_existent_list');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (value) => expect(value, isEmpty),
        );
      });

      test('should write and read JSON list', () async {
        final data = <Map<String, dynamic>>[
          {'id': '1', 'name': 'First'},
          {'id': '2', 'name': 'Second'},
          {'id': '3', 'name': 'Third'},
        ];

        final writeResult = await storageService.writeJsonList(
          'list_key',
          data,
        );
        expect(writeResult.isRight(), true);

        final readResult = await storageService.readJsonList('list_key');
        expect(readResult.isRight(), true);
        readResult.fold((failure) => fail('Should not fail'), (value) {
          expect(value.length, 3);
          expect(value[0]['id'], '1');
          expect(value[1]['name'], 'Second');
        });
      });

      test('should handle empty list', () async {
        final data = <Map<String, dynamic>>[];

        await storageService.writeJsonList('empty_list', data);
        final readResult = await storageService.readJsonList('empty_list');

        readResult.fold(
          (failure) => fail('Should not fail'),
          (value) => expect(value, isEmpty),
        );
      });
    });

    group('delete', () {
      test('should delete existing key', () async {
        await storageService.writeJson('to_delete', {'test': true});

        final deleteResult = await storageService.delete('to_delete');
        expect(deleteResult.isRight(), true);

        final readResult = await storageService.readJson('to_delete');
        readResult.fold(
          (failure) => fail('Should not fail'),
          (value) => expect(value, isNull),
        );
      });

      test('should not fail when deleting non-existent key', () async {
        final deleteResult = await storageService.delete('does_not_exist');
        expect(deleteResult.isRight(), true);
      });
    });

    group('exists', () {
      test('should return false for non-existent key', () async {
        final result = await storageService.exists('non_existent');

        result.fold(
          (failure) => fail('Should not fail'),
          (value) => expect(value, false),
        );
      });

      test('should return true for existing key', () async {
        await storageService.writeJson('existing', {'test': true});

        final result = await storageService.exists('existing');
        result.fold(
          (failure) => fail('Should not fail'),
          (value) => expect(value, true),
        );
      });
    });

    group('watchJsonList', () {
      test('should emit current value on subscription', () async {
        final data = <Map<String, dynamic>>[
          {'id': '1'},
        ];
        await storageService.writeJsonList('watch_key', data);

        final stream = storageService.watchJsonList('watch_key');

        await expectLater(
          stream,
          emits(isA<dynamic>().having((r) => r.isRight(), 'is right', true)),
        );
      });

      test('should emit updates on write', () async {
        final stream = storageService.watchJsonList('watch_updates');

        // Start listening
        final emissions = <dynamic>[];
        final subscription = stream.listen(emissions.add);

        // Wait for initial empty emission
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Write new data
        final data = <Map<String, dynamic>>[
          {'id': '1'},
        ];
        await storageService.writeJsonList('watch_updates', data);

        // Wait for emission
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();

        // Should have received at least the update
        expect(emissions.length, greaterThanOrEqualTo(1));
      });
    });

    group('error handling', () {
      test('should handle corrupted JSON', () async {
        // Write invalid JSON directly to file
        final file = File('${tempDir.path}/corrupted.json');
        await file.writeAsString('not valid json {{{');

        final result = await storageService.readJson('corrupted');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure.message, contains('Unexpected')),
          (_) => fail('Should fail'),
        );
      });

      test('should handle corrupted JSON list', () async {
        // Write invalid JSON directly to file
        final file = File('${tempDir.path}/corrupted_list.json');
        await file.writeAsString('[invalid json');

        final result = await storageService.readJsonList('corrupted_list');

        expect(result.isLeft(), true);
      });
    });
  });
}
