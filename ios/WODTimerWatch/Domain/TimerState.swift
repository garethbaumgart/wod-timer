import Foundation

/// The current state of a timer session.
enum TimerState: Equatable, Codable {
    case ready
    case preparing
    case running
    case resting
    case paused
    case completed

    var isActive: Bool {
        self == .preparing || self == .running || self == .resting
    }

    var canStart: Bool { self == .ready }

    var canPause: Bool {
        self == .running || self == .resting || self == .preparing
    }

    var canResume: Bool { self == .paused }

    var isFinished: Bool { self == .completed }

    var displayLabel: String {
        switch self {
        case .ready: "Ready"
        case .preparing: "Get Ready"
        case .running: "Work"
        case .resting: "Rest"
        case .paused: "Paused"
        case .completed: "Complete"
        }
    }
}
