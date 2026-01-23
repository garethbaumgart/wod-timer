import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';
import 'package:wod_timer/features/timer/domain/failures/timer_failure.dart';

/// Use case for pausing an active timer session.
@injectable
class PauseTimer {
  /// Pauses the given timer session.
  ///
  /// Returns [Either<TimerFailure, TimerSession>]:
  /// - Right(TimerSession) with the session in paused state
  /// - Left(TimerFailure) if the session cannot be paused
  Either<TimerFailure, TimerSession> call(TimerSession session) {
    return session.pause();
  }
}
