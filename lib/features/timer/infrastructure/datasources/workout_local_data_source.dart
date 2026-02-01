import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wod_timer/core/domain/failures/storage_failure.dart';
import 'package:wod_timer/core/infrastructure/storage/local_storage_service.dart';
import 'package:wod_timer/features/timer/infrastructure/dto/workout_dto.dart';

/// Interface for local workout data operations.
abstract class WorkoutLocalDataSource {
  /// Get all saved workouts.
  Future<Either<StorageFailure, List<WorkoutDto>>> getAll();

  /// Get a workout by ID.
  Future<Either<StorageFailure, WorkoutDto?>> getById(String id);

  /// Save a workout.
  Future<Either<StorageFailure, Unit>> save(WorkoutDto workout);

  /// Delete a workout by ID.
  Future<Either<StorageFailure, Unit>> delete(String id);

  /// Watch all workouts for changes.
  Stream<Either<StorageFailure, List<WorkoutDto>>> watchAll();
}

/// Implementation of [WorkoutLocalDataSource] using [LocalStorageService].
@LazySingleton(as: WorkoutLocalDataSource)
class WorkoutLocalDataSourceImpl implements WorkoutLocalDataSource {
  WorkoutLocalDataSourceImpl(this._storageService);

  final LocalStorageService _storageService;

  /// The key used to store workouts.
  static const String _storageKey = 'workouts';

  @override
  Future<Either<StorageFailure, List<WorkoutDto>>> getAll() async {
    final result = await _storageService.readJsonList(_storageKey);
    return result.map((list) => list.map(WorkoutDto.fromJson).toList());
  }

  @override
  Future<Either<StorageFailure, WorkoutDto?>> getById(String id) async {
    final result = await getAll();
    return result.map((workouts) {
      for (final workout in workouts) {
        if (workout.id == id) return workout;
      }
      return null;
    });
  }

  @override
  Future<Either<StorageFailure, Unit>> save(WorkoutDto workout) async {
    final result = await getAll();
    if (result.isLeft()) {
      return result.map((_) => unit);
    }

    final workouts = result.getRight().toNullable()!;
    // Remove existing workout with same ID if present
    final updated = workouts.where((w) => w.id != workout.id).toList()
      ..add(workout)
      // Sort by creation date (newest first)
      ..sort(
        (a, b) =>
            DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)),
      );

    final jsonList = updated.map((w) => w.toJson()).toList();
    return _storageService.writeJsonList(_storageKey, jsonList);
  }

  @override
  Future<Either<StorageFailure, Unit>> delete(String id) async {
    final result = await getAll();
    if (result.isLeft()) {
      return result.map((_) => unit);
    }

    final workouts = result.getRight().toNullable()!;
    final updated = workouts.where((w) => w.id != id).toList();
    final jsonList = updated.map((w) => w.toJson()).toList();
    return _storageService.writeJsonList(_storageKey, jsonList);
  }

  @override
  Stream<Either<StorageFailure, List<WorkoutDto>>> watchAll() {
    return _storageService
        .watchJsonList(_storageKey)
        .map(
          (result) =>
              result.map((list) => list.map(WorkoutDto.fromJson).toList()),
        );
  }
}
