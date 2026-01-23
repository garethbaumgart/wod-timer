import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wod_timer/core/domain/failures/storage_failure.dart';
import 'package:wod_timer/core/domain/value_objects/value_objects.dart';
import 'package:wod_timer/features/timer/domain/repositories/i_workout_repository.dart';

/// Use case for deleting a workout preset.
@injectable
class DeletePreset {
  DeletePreset(this._repository);

  final IWorkoutRepository _repository;

  /// Deletes the preset with the given ID.
  ///
  /// Returns [Either<StorageFailure, Unit>]:
  /// - Right(unit) on success
  /// - Left(StorageFailure) if deletion fails
  Future<Either<StorageFailure, Unit>> call(UniqueId id) {
    return _repository.delete(id);
  }
}
