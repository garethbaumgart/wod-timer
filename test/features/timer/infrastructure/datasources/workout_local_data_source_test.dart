import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wod_timer/core/infrastructure/storage/local_storage_service.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/infrastructure/datasources/workout_local_data_source.dart';
import 'package:wod_timer/features/timer/infrastructure/dto/workout_dto.dart';

void main() {
  late WorkoutLocalDataSourceImpl dataSource;
  late FileLocalStorageService storageService;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wod_timer_datasource_');
    storageService = FileLocalStorageService(baseDirectory: tempDir);
    dataSource = WorkoutLocalDataSourceImpl(storageService);
  });

  tearDown(() async {
    await storageService.dispose();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('WorkoutLocalDataSourceImpl', () {
    group('getAll', () {
      test('should return empty list when no workouts exist', () async {
        final result = await dataSource.getAll();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (workouts) => expect(workouts, isEmpty),
        );
      });

      test('should return all saved workouts', () async {
        final workout1 = WorkoutDto.fromDomain(Workout.defaultAmrap());
        final workout2 = WorkoutDto.fromDomain(Workout.defaultTabata());

        await dataSource.save(workout1);
        await dataSource.save(workout2);

        final result = await dataSource.getAll();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (workouts) => expect(workouts.length, 2),
        );
      });
    });

    group('getById', () {
      test('should return null for non-existent ID', () async {
        final result = await dataSource.getById('non-existent-id');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (workout) => expect(workout, isNull),
        );
      });

      test('should return workout by ID', () async {
        final workout = WorkoutDto.fromDomain(Workout.defaultAmrap());
        await dataSource.save(workout);

        final result = await dataSource.getById(workout.id);

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (found) {
          expect(found, isNotNull);
          expect(found!.id, workout.id);
          expect(found.name, workout.name);
        });
      });
    });

    group('save', () {
      test('should save new workout', () async {
        final workout = WorkoutDto.fromDomain(Workout.defaultEmom());

        final saveResult = await dataSource.save(workout);
        expect(saveResult.isRight(), true);

        final getResult = await dataSource.getById(workout.id);
        getResult.fold(
          (failure) => fail('Should not fail'),
          (found) => expect(found?.id, workout.id),
        );
      });

      test('should update existing workout', () async {
        final original = Workout.defaultAmrap();
        final originalDto = WorkoutDto.fromDomain(original);
        await dataSource.save(originalDto);

        // Update the workout (same ID, different name)
        final updated = WorkoutDto(
          id: originalDto.id,
          name: 'Updated AMRAP',
          timerType: originalDto.timerType,
          prepCountdownSeconds: 20,
          createdAt: originalDto.createdAt,
        );
        await dataSource.save(updated);

        final result = await dataSource.getAll();
        result.fold((failure) => fail('Should not fail'), (workouts) {
          expect(workouts.length, 1);
          expect(workouts.first.name, 'Updated AMRAP');
          expect(workouts.first.prepCountdownSeconds, 20);
        });
      });

      test('should sort workouts by creation date (newest first)', () async {
        final older = WorkoutDto(
          id: 'older-id',
          name: 'Older Workout',
          timerType: WorkoutDto.fromDomain(Workout.defaultAmrap()).timerType,
          prepCountdownSeconds: 10,
          createdAt: '2024-01-01T10:00:00.000',
        );

        final newer = WorkoutDto(
          id: 'newer-id',
          name: 'Newer Workout',
          timerType: WorkoutDto.fromDomain(Workout.defaultAmrap()).timerType,
          prepCountdownSeconds: 10,
          createdAt: '2024-06-15T10:00:00.000',
        );

        await dataSource.save(older);
        await dataSource.save(newer);

        final result = await dataSource.getAll();
        result.fold((failure) => fail('Should not fail'), (workouts) {
          expect(workouts.first.id, 'newer-id');
          expect(workouts.last.id, 'older-id');
        });
      });
    });

    group('delete', () {
      test('should delete existing workout', () async {
        final workout = WorkoutDto.fromDomain(Workout.defaultForTime());
        await dataSource.save(workout);

        final deleteResult = await dataSource.delete(workout.id);
        expect(deleteResult.isRight(), true);

        final getResult = await dataSource.getById(workout.id);
        getResult.fold(
          (failure) => fail('Should not fail'),
          (found) => expect(found, isNull),
        );
      });

      test('should not fail when deleting non-existent workout', () async {
        final result = await dataSource.delete('non-existent-id');
        expect(result.isRight(), true);
      });

      test('should only delete specified workout', () async {
        final workout1 = WorkoutDto.fromDomain(Workout.defaultAmrap());
        final workout2 = WorkoutDto.fromDomain(Workout.defaultTabata());
        await dataSource.save(workout1);
        await dataSource.save(workout2);

        await dataSource.delete(workout1.id);

        final result = await dataSource.getAll();
        result.fold((failure) => fail('Should not fail'), (workouts) {
          expect(workouts.length, 1);
          expect(workouts.first.id, workout2.id);
        });
      });
    });

    group('watchAll', () {
      test('should emit current workouts on subscription', () async {
        final workout = WorkoutDto.fromDomain(Workout.defaultAmrap());
        await dataSource.save(workout);

        final stream = dataSource.watchAll();

        await expectLater(
          stream,
          emits(isA<dynamic>().having((r) => r.isRight(), 'is right', true)),
        );
      });
    });

    group('data persistence', () {
      test('should persist workouts across data source instances', () async {
        // Save with first instance
        final workout = WorkoutDto.fromDomain(Workout.defaultAmrap());
        await dataSource.save(workout);

        // Create new instance with same storage
        final newDataSource = WorkoutLocalDataSourceImpl(storageService);

        // Should find the workout
        final result = await newDataSource.getById(workout.id);
        result.fold((failure) => fail('Should not fail'), (found) {
          expect(found, isNotNull);
          expect(found!.id, workout.id);
        });
      });

      test('should correctly serialize all timer types', () async {
        final amrap = WorkoutDto.fromDomain(Workout.defaultAmrap());
        final forTime = WorkoutDto.fromDomain(Workout.defaultForTime());
        final emom = WorkoutDto.fromDomain(Workout.defaultEmom());
        final tabata = WorkoutDto.fromDomain(Workout.defaultTabata());

        await dataSource.save(amrap);
        await dataSource.save(forTime);
        await dataSource.save(emom);
        await dataSource.save(tabata);

        final result = await dataSource.getAll();
        result.fold((failure) => fail('Should not fail'), (workouts) {
          expect(workouts.length, 4);

          final types = workouts.map((w) => w.timerType.type).toSet();
          expect(types, containsAll(['amrap', 'fortime', 'emom', 'tabata']));
        });
      });
    });
  });
}
