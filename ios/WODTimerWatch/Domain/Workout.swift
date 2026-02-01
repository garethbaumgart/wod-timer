import Foundation

/// A configured workout ready to be executed.
struct Workout: Equatable, Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let timerType: TimerType
    let prepCountdown: TimerDuration
    let createdAt: Date

    /// The total duration including prep countdown.
    var totalDuration: TimerDuration {
        TimerDuration(seconds: prepCountdown.seconds + timerType.estimatedDuration.seconds)
    }

    /// Whether this workout type has rest periods.
    var hasRestPeriods: Bool {
        switch timerType {
        case .tabata, .emom: true
        default: false
        }
    }

    /// Whether this is an interval-based workout.
    var isIntervalBased: Bool { hasRestPeriods }

    /// The display label for the timer type.
    var timerTypeLabel: String { timerType.displayLabel }

    /// Round count if applicable.
    var roundCount: Int? {
        switch timerType {
        case let .emom(_, rounds): rounds.value
        case let .tabata(_, _, rounds): rounds.value
        default: nil
        }
    }

    // MARK: - Default Workouts

    static func defaultAmrap() -> Workout {
        Workout(
            id: UUID(),
            name: "AMRAP Workout",
            timerType: .amrap(duration: TimerDuration(seconds: 600)),
            prepCountdown: TimerDuration(seconds: 10),
            createdAt: Date()
        )
    }

    static func defaultForTime() -> Workout {
        Workout(
            id: UUID(),
            name: "For Time",
            timerType: .forTime(timeCap: TimerDuration(seconds: 1200)),
            prepCountdown: TimerDuration(seconds: 10),
            createdAt: Date()
        )
    }

    static func defaultEmom() -> Workout {
        Workout(
            id: UUID(),
            name: "EMOM",
            timerType: .emom(
                intervalDuration: TimerDuration(seconds: 60),
                rounds: RoundCount(value: 10)
            ),
            prepCountdown: TimerDuration(seconds: 10),
            createdAt: Date()
        )
    }

    static func defaultTabata() -> Workout {
        Workout(
            id: UUID(),
            name: "Tabata",
            timerType: .standardTabata,
            prepCountdown: TimerDuration(seconds: 10),
            createdAt: Date()
        )
    }
}
