import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wod_timer/core/domain/failures/storage_failure.dart';
import 'package:wod_timer/features/timer/domain/entities/workout.dart';
import 'package:wod_timer/features/timer/domain/repositories/i_workout_repository.dart';

/// Use case for watching workout presets changes.
@injectable
class WatchPresets {
  WatchPresets(this._repository);

  final IWorkoutRepository _repository;

  /// Returns a stream of preset changes.
  ///
  /// The stream emits the current list of presets whenever changes occur.
  Stream<Either<StorageFailure, List<Workout>>> call() {
    return _repository.watchAll();
  }
}
