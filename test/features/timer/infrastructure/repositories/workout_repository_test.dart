import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wod_timer/core/domain/failures/storage_failure.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/infrastructure/datasources/workout_local_data_source.dart';
import 'package:wod_timer/features/timer/infrastructure/dto/workout_dto.dart';
import 'package:wod_timer/features/timer/infrastructure/repositories/workout_repository.dart';

class MockWorkoutLocalDataSource extends Mock
    implements WorkoutLocalDataSource {}

class FakeWorkoutDto extends Fake implements WorkoutDto {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeWorkoutDto());
  });

  late WorkoutRepository repository;
  late MockWorkoutLocalDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockWorkoutLocalDataSource();
    repository = WorkoutRepository(mockDataSource);
  });

  group('WorkoutRepository', () {
    group('getAll', () {
      test('should return list of workouts from data source', () async {
        final workouts = [
          Workout.defaultAmrap(),
          Workout.defaultTabata(),
        ];
        final dtos = workouts.map(WorkoutDto.fromDomain).toList();

        when(() => mockDataSource.getAll())
            .thenAnswer((_) async => right(dtos));

        final result = await repository.getAll();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (list) => expect(list.length, 2),
        );
        verify(() => mockDataSource.getAll()).called(1);
      });

      test('should return failure when data source fails', () async {
        when(() => mockDataSource.getAll()).thenAnswer(
          (_) async => left(const StorageFailure.readError()),
        );

        final result = await repository.getAll();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<StorageFailure>()),
          (_) => fail('Should fail'),
        );
      });
    });

    group('getById', () {
      test('should return workout when found', () async {
        final workout = Workout.defaultEmom();
        final dto = WorkoutDto.fromDomain(workout);

        when(() => mockDataSource.getById(workout.id.value))
            .thenAnswer((_) async => right(dto));

        final result = await repository.getById(workout.id);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (found) {
            expect(found, isNotNull);
            expect(found!.id.value, workout.id.value);
          },
        );
      });

      test('should return null when not found', () async {
        final id = UniqueId();

        when(() => mockDataSource.getById(id.value))
            .thenAnswer((_) async => right(null));

        final result = await repository.getById(id);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (found) => expect(found, isNull),
        );
      });

      test('should return failure when data source fails', () async {
        final id = UniqueId();

        when(() => mockDataSource.getById(id.value)).thenAnswer(
          (_) async => left(const StorageFailure.readError()),
        );

        final result = await repository.getById(id);

        expect(result.isLeft(), true);
      });
    });

    group('save', () {
      test('should save workout through data source', () async {
        final workout = Workout.defaultForTime();

        when(() => mockDataSource.save(any()))
            .thenAnswer((_) async => right(unit));

        final result = await repository.save(workout);

        expect(result.isRight(), true);
        verify(() => mockDataSource.save(any())).called(1);
      });

      test('should return failure when data source fails', () async {
        final workout = Workout.defaultAmrap();

        when(() => mockDataSource.save(any())).thenAnswer(
          (_) async => left(const StorageFailure.writeError()),
        );

        final result = await repository.save(workout);

        expect(result.isLeft(), true);
      });
    });

    group('delete', () {
      test('should delete workout through data source', () async {
        final id = UniqueId();

        when(() => mockDataSource.delete(id.value))
            .thenAnswer((_) async => right(unit));

        final result = await repository.delete(id);

        expect(result.isRight(), true);
        verify(() => mockDataSource.delete(id.value)).called(1);
      });

      test('should return failure when data source fails', () async {
        final id = UniqueId();

        when(() => mockDataSource.delete(id.value)).thenAnswer(
          (_) async => left(const StorageFailure.deleteError()),
        );

        final result = await repository.delete(id);

        expect(result.isLeft(), true);
      });
    });

    group('watchAll', () {
      test('should stream workouts from data source', () async {
        final workouts = [Workout.defaultAmrap()];
        final dtos = workouts.map(WorkoutDto.fromDomain).toList();

        when(() => mockDataSource.watchAll()).thenAnswer(
          (_) => Stream.value(right(dtos)),
        );

        final stream = repository.watchAll();

        await expectLater(
          stream,
          emits(isA<Right<StorageFailure, List<Workout>>>()),
        );
      });

      test('should propagate failures from data source', () async {
        when(() => mockDataSource.watchAll()).thenAnswer(
          (_) => Stream.value(left(const StorageFailure.readError())),
        );

        final stream = repository.watchAll();

        await expectLater(
          stream,
          emits(isA<Left<StorageFailure, List<Workout>>>()),
        );
      });
    });

    group('mapping', () {
      test('should correctly map DTO to domain and back', () async {
        final originalWorkout = Workout.defaultTabata();
        final dto = WorkoutDto.fromDomain(originalWorkout);

        when(() => mockDataSource.getById(originalWorkout.id.value))
            .thenAnswer((_) async => right(dto));

        final result = await repository.getById(originalWorkout.id);

        result.fold(
          (failure) => fail('Should not fail'),
          (found) {
            expect(found, isNotNull);
            expect(found!.id.value, originalWorkout.id.value);
            expect(found.name.value, originalWorkout.name.value);
            expect(
              found.timerType.typeCode,
              originalWorkout.timerType.typeCode,
            );
          },
        );
      });
    });
  });
}
