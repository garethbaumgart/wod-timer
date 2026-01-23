import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';
import 'package:wod_timer/features/timer/domain/failures/timer_failure.dart';

/// Use case for resuming a paused timer session.
@injectable
class ResumeTimer {
  /// Resumes the given paused timer session.
  ///
  /// Returns [Either<TimerFailure, TimerSession>]:
  /// - Right(TimerSession) with the session in its previous active state
  /// - Left(TimerFailure) if the session cannot be resumed
  Either<TimerFailure, TimerSession> call(TimerSession session) {
    return session.resume();
  }
}
