import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wod_timer/core/domain/failures/storage_failure.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/repositories/i_workout_repository.dart';

/// Use case for fetching all saved workout presets.
@injectable
class GetPresets {
  GetPresets(this._repository);

  final IWorkoutRepository _repository;

  /// Fetches all saved workout presets.
  ///
  /// Returns [Either<StorageFailure, List<Workout>>]:
  /// - Right(List<Workout>) with all saved presets
  /// - Left(StorageFailure) if fetching fails
  Future<Either<StorageFailure, List<Workout>>> call() {
    return _repository.getAll();
  }
}
