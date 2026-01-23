import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';
import 'package:wod_timer/features/timer/domain/failures/timer_failure.dart';

/// Use case for stopping (completing) a timer session early.
@injectable
class StopTimer {
  /// Stops the given timer session and marks it as completed.
  ///
  /// Returns [Either<TimerFailure, TimerSession>]:
  /// - Right(TimerSession) with the session in completed state
  /// - Left(TimerFailure) if the session cannot be stopped
  Either<TimerFailure, TimerSession> call(TimerSession session) {
    return session.complete();
  }
}
