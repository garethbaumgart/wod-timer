import Foundation

/// Failures that can occur during timer operations.
enum TimerError: Error, Equatable {
    case invalidStateTransition(from: TimerState, to: TimerState)
    case timerNotActive
    case alreadyCompleted

    var message: String {
        switch self {
        case let .invalidStateTransition(from, to):
            "Cannot transition from \(from.displayLabel) to \(to.displayLabel)"
        case .timerNotActive:
            "Timer is not active"
        case .alreadyCompleted:
            "Workout is already completed"
        }
    }
}
