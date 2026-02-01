import Foundation

/// Factory for creating workout configurations.
/// Matches the default values from the Dart domain.
enum WorkoutFactory {

    static func create(
        timerType: TimerType,
        prepCountdown: TimerDuration = TimerDuration(seconds: 10)
    ) -> Workout {
        Workout(
            id: UUID(),
            name: timerType.displayLabel,
            timerType: timerType,
            prepCountdown: prepCountdown,
            createdAt: Date()
        )
    }

    static func defaultAmrap() -> Workout { Workout.defaultAmrap() }
    static func defaultForTime() -> Workout { Workout.defaultForTime() }
    static func defaultEmom() -> Workout { Workout.defaultEmom() }
    static func defaultTabata() -> Workout { Workout.defaultTabata() }
}
