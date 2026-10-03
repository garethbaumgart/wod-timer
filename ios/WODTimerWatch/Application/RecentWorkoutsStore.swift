import Foundation

/// Persists recent workouts to UserDefaults for quick re-launch.
final class RecentWorkoutsStore {
    private let defaults = UserDefaults.standard
    private let key = "recent_workouts"
    private let maxRecents = 3

    func load() -> [Workout] {
        guard let data = defaults.data(forKey: key),
              let workouts = try? JSONDecoder().decode([Workout].self, from: data)
        else { return [] }
        return workouts
    }

    func save(_ workout: Workout) {
        var recents = load()

        // Remove duplicate (same timer type config)
        recents.removeAll { $0.timerType == workout.timerType }

        // Insert at front
        recents.insert(workout, at: 0)

        // Trim to max
        if recents.count > maxRecents {
            recents = Array(recents.prefix(maxRecents))
        }

        if let data = try? JSONEncoder().encode(recents) {
            defaults.set(data, forKey: key)
        }
    }
}


/// Remembers the last workout started in each mode, so setup opens on what
/// the athlete ran last time and Home can show it (1.3.0, matching the
/// phone). One additive key per mode; until a mode has been started on
/// 1.3.0 it falls back to that mode's newest recent workout, then the
/// default. Nothing here deletes or rewrites the recents list.
struct SetupMemory {
    private let defaults = UserDefaults.standard
    private let recents = RecentWorkoutsStore()

    private func key(_ code: String) -> String { "watch_setup_\(code)" }

    func last(_ code: String) -> TimerType? {
        if let data = defaults.data(forKey: key(code)),
           let type = try? JSONDecoder().decode(TimerType.self, from: data),
           type.typeCode == code {
            return type
        }
        return recents.load().first { $0.timerType.typeCode == code }?.timerType
    }

    func save(_ type: TimerType) {
        if let data = try? JSONEncoder().encode(type) {
            defaults.set(data, forKey: key(type.typeCode))
        }
    }

    var amrap: TimerDuration {
        if case let .amrap(d) = last("amrap") { return d }
        return TimerDuration(seconds: 600)
    }

    var forTime: (cap: TimerDuration, countUp: Bool) {
        if case let .forTime(cap, up) = last("fortime") { return (cap, up) }
        return (TimerDuration(seconds: 1200), true)
    }

    var emom: (interval: TimerDuration, rounds: Int) {
        if case let .emom(i, r) = last("emom") { return (i, r.value) }
        return (TimerDuration(seconds: 60), 10)
    }

    var tabata: (work: TimerDuration, rest: TimerDuration, rounds: Int) {
        if case let .tabata(w, r, n) = last("tabata") { return (w, r, n.value) }
        return (TimerDuration(seconds: 20), TimerDuration(seconds: 10), 8)
    }

    /// Preview only: the workout's parts for the Home timeline.
    func shape(_ code: String) -> [(Int, Bool)] {
        switch code {
        case "amrap": return [(amrap.seconds, false)]
        case "fortime": return [(forTime.cap.seconds, false)]
        case "emom":
            let e = emom
            return Array(repeating: (e.interval.seconds, false), count: e.rounds)
        default:
            let t = tabata
            return (0 ..< t.rounds).flatMap { _ in [(t.work.seconds, false), (t.rest.seconds, true)] }
        }
    }

    /// One-line summary for Home: "10:00", "CAP 20:00 · UP", "10 × 1:00",
    /// "8 × 20s / 10s".
    func summary(_ code: String) -> String {
        switch code {
        case "amrap": return amrap.clock
        case "fortime":
            let f = forTime
            return "CAP \(f.cap.clock) · \(f.countUp ? "UP" : "DOWN")"
        case "emom":
            let e = emom
            return "\(e.rounds) × \(e.interval.clock)"
        default:
            let t = tabata
            return "\(t.rounds) × \(t.work.phase) / \(t.rest.phase)"
        }
    }
}
