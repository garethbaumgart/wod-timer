import Foundation

/// Timer type with associated configuration.
enum TimerType: Equatable, Codable, Hashable {
    case amrap(duration: TimerDuration)
    case forTime(timeCap: TimerDuration, countUp: Bool = true)
    case emom(intervalDuration: TimerDuration, rounds: RoundCount)
    case tabata(workDuration: TimerDuration, restDuration: TimerDuration, rounds: RoundCount)

    var displayLabel: String {
        switch self {
        case .amrap: "AMRAP"
        case .forTime: "FOR TIME"
        case .emom: "EMOM"
        case .tabata: "TABATA"
        }
    }

    var typeCode: String {
        switch self {
        case .amrap: "amrap"
        case .forTime: "fortime"
        case .emom: "emom"
        case .tabata: "tabata"
        }
    }

    var estimatedDuration: TimerDuration {
        switch self {
        case let .amrap(duration):
            duration
        case let .forTime(timeCap, _):
            timeCap
        case let .emom(intervalDuration, rounds):
            TimerDuration(seconds: intervalDuration.seconds * rounds.value)
        case let .tabata(workDuration, restDuration, rounds):
            TimerDuration(seconds: (workDuration.seconds + restDuration.seconds) * rounds.value)
        }
    }

    /// Standard Tabata: 20s work, 10s rest, 8 rounds.
    static var standardTabata: TimerType {
        .tabata(
            workDuration: TimerDuration(seconds: 20),
            restDuration: TimerDuration(seconds: 10),
            rounds: .tabataDefault
        )
    }
}
