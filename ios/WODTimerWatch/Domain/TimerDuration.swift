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

    /// Clock format used everywhere since 1.3.0: "9:45", "0:11", "12:30".
    /// Minutes are never zero-padded.
    var clock: String {
        "\(minutes):" + String(format: "%02d", remainingSeconds)
    }

    /// A phase length the way athletes say it: "20s" under a minute,
    /// "2:00" from a minute up (Tabata values, config lines, Home).
    var phase: String {
        seconds < 60 ? "\(seconds)s" : clock
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
