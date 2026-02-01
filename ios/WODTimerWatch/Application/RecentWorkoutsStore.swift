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
