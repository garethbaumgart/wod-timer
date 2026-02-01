import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wod_timer/core/domain/failures/storage_failure.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/repositories/i_workout_repository.dart';
import 'package:wod_timer/features/timer/infrastructure/datasources/workout_local_data_source.dart';
import 'package:wod_timer/features/timer/infrastructure/dto/workout_dto.dart';

/// Implementation of [IWorkoutRepository] using local storage.
@LazySingleton(as: IWorkoutRepository)
class WorkoutRepository implements IWorkoutRepository {
  WorkoutRepository(this._localDataSource);

  final WorkoutLocalDataSource _localDataSource;

  @override
  Future<Either<StorageFailure, List<Workout>>> getAll() async {
    final result = await _localDataSource.getAll();
    return result.map((dtos) => dtos.map((dto) => dto.toDomain()).toList());
  }

  @override
  Future<Either<StorageFailure, Workout?>> getById(UniqueId id) async {
    final result = await _localDataSource.getById(id.value);
    return result.map((dto) => dto?.toDomain());
  }

  @override
  Future<Either<StorageFailure, Unit>> save(Workout workout) async {
    final dto = WorkoutDto.fromDomain(workout);
    return _localDataSource.save(dto);
  }

  @override
  Future<Either<StorageFailure, Unit>> delete(UniqueId id) async {
    return _localDataSource.delete(id.value);
  }

  @override
  Stream<Either<StorageFailure, List<Workout>>> watchAll() {
    return _localDataSource.watchAll().map(
      (result) =>
          result.map((dtos) => dtos.map((dto) => dto.toDomain()).toList()),
    );
  }
}
