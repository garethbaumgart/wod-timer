import 'package:fpdart/fpdart.dart';
import 'package:wod_timer/core/domain/failures/storage_failure.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';

/// Repository interface for workout persistence.
///
/// This is a domain layer contract that defines how workouts
/// are stored and retrieved. The infrastructure layer provides
/// the implementation.
abstract class IWorkoutRepository {
  /// Get all saved workouts.
  Future<Either<StorageFailure, List<Workout>>> getAll();

  /// Get a workout by its ID.
  Future<Either<StorageFailure, Workout?>> getById(UniqueId id);

  /// Save a workout (creates new or updates existing).
  Future<Either<StorageFailure, Unit>> save(Workout workout);

  /// Delete a workout by its ID.
  Future<Either<StorageFailure, Unit>> delete(UniqueId id);

  /// Watch all workouts for changes.
  ///
  /// Returns a stream that emits the current list of workouts
  /// whenever it changes.
  Stream<Either<StorageFailure, List<Workout>>> watchAll();
}
