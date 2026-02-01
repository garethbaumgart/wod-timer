import Foundation

/// A validated duration in seconds for timer operations.
/// Maximum duration is 2 hours (7200 seconds).
struct TimerDuration: Equatable, Comparable, Codable, Hashable {
    let seconds: Int

    static let zero = TimerDuration(seconds: 0)
    static let maxSeconds = 7200

    init(seconds: Int) {
        self.seconds = max(0, min(seconds, Self.maxSeconds))
    }

    static func fromMinutesAndSeconds(_ minutes: Int, _ seconds: Int) -> TimerDuration {
        TimerDuration(seconds: (minutes * 60) + seconds)
    }

    var minutes: Int { seconds / 60 }
    var remainingSeconds: Int { seconds % 60 }

    var formatted: String {
        String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    var timeInterval: TimeInterval { TimeInterval(seconds) }

    // MARK: - Operators

    static func + (lhs: TimerDuration, rhs: TimerDuration) -> TimerDuration {
        TimerDuration(seconds: lhs.seconds + rhs.seconds)
    }

    static func - (lhs: TimerDuration, rhs: TimerDuration) -> TimerDuration {
        TimerDuration(seconds: max(0, lhs.seconds - rhs.seconds))
    }

    static func < (lhs: TimerDuration, rhs: TimerDuration) -> Bool {
        lhs.seconds < rhs.seconds
    }
}
