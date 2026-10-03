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

/// One block of the Home / live / end timeline: a stretch of seconds that
/// is either work (the mode colour) or rest (pink).
struct TimelinePart: Equatable {
    let seconds: Int
    let isRest: Bool
}

extension TimerType {
    /// The workout drawn as blocks (1.3.1): For Time one bar (the cap),
    /// AMRAP one bar, EMOM one block per round, Tabata work / rest pairs.
    var timelineParts: [TimelinePart] {
        switch self {
        case let .amrap(duration):
            return [TimelinePart(seconds: duration.seconds, isRest: false)]
        case let .forTime(timeCap, _):
            return [TimelinePart(seconds: timeCap.seconds, isRest: false)]
        case let .emom(interval, rounds):
            return Array(repeating: TimelinePart(seconds: interval.seconds, isRest: false), count: rounds.value)
        case let .tabata(work, rest, rounds):
            return (0 ..< rounds.value).flatMap { _ in
                [TimelinePart(seconds: work.seconds, isRest: false),
                 TimelinePart(seconds: rest.seconds, isRest: true)]
            }
        }
    }

    /// How far each block is filled after `elapsed` seconds of the workout,
    /// 0...1 per part: finished parts 1, the current part partial, the rest 0.
    static func fillFractions(_ parts: [TimelinePart], elapsed: Double) -> [Double] {
        var start = 0.0
        return parts.map { part in
            let length = Double(max(1, part.seconds))
            let fraction = min(1, max(0, (elapsed - start) / length))
            start += Double(part.seconds)
            return fraction
        }
    }
}
