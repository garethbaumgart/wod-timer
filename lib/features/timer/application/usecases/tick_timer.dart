import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wod_timer/features/timer/domain/entities/timer_session.dart';
import 'package:wod_timer/features/timer/domain/failures/timer_failure.dart';

/// Use case for processing a timer tick.
///
/// This use case is called on each tick from the timer engine
/// to update the session's elapsed time and handle state transitions.
@injectable
class TickTimer {
  /// Updates the timer session with the elapsed duration since last tick.
  ///
  /// Returns [Either<TimerFailure, TimerSession>]:
  /// - Right(TimerSession) with updated elapsed time
  /// - Left(TimerFailure) if the tick cannot be processed
  Either<TimerFailure, TimerSession> call(
    TimerSession session,
    Duration delta,
  ) {
    return session.tick(delta);
  }
}
