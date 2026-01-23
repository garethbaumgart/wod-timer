import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wod_timer/core/domain/failures/storage_failure.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/repositories/i_workout_repository.dart';

/// Use case for saving a workout as a preset.
@injectable
class SavePreset {
  SavePreset(this._repository);

  final IWorkoutRepository _repository;

  /// Saves the given workout as a preset.
  ///
  /// If a workout with the same ID exists, it will be updated.
  ///
  /// Returns [Either<StorageFailure, Unit>]:
  /// - Right(unit) on success
  /// - Left(StorageFailure) if saving fails
  Future<Either<StorageFailure, Unit>> call(Workout workout) {
    return _repository.save(workout);
  }
}
