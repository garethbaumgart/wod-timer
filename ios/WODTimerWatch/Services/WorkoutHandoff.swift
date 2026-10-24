import Foundation
import HealthKit
import WorkoutKit

/// Hands a WOD to Apple's Workout app instead of timing it here (spike, 24
/// Oct 2026). Wharf WOD composes the intervals; Workout runs them with its
/// own heart rate, calories, rings, Always On display and interval alerts,
/// and saves the workout under the WOD's name. Nothing here opens a session
/// of our own, so Wharf WOD stays a complement to the Workout app rather
/// than a second recorder. EMOM and Tabata first: the two modes that are
/// pure intervals; AMRAP and For Time wait for the spike's verdict.
enum WorkoutHandoff {
    enum Failure: Error, Equatable {
        /// AMRAP and For Time are not composed yet.
        case notComposed(String)
        /// This watch refuses the activity (`CustomWorkout.supportsActivity`).
        case unsupportedActivity(String)
    }

    /// The Workout app's activity for the WOD, the same mapping as the
    /// Health session: Tabata is interval training, the rest functional
    /// strength training.
    static func activity(for type: TimerType) -> HKWorkoutActivityType {
        HealthWorkoutTracker.activityType(for: type)
    }

    /// The interval blocks. EMOM: one work step of the interval, repeated
    /// once per round. Tabata: a work step and a recovery step, repeated
    /// once per round. Nil for the modes the spike does not cover.
    static func blocks(for type: TimerType) -> [IntervalBlock]? {
        switch type {
        case let .emom(interval, rounds):
            return [IntervalBlock(steps: [IntervalStep(.work, goal: seconds(interval))], iterations: rounds.value)]
        case let .tabata(work, rest, rounds):
            return [IntervalBlock(
                steps: [IntervalStep(.work, goal: seconds(work)), IntervalStep(.recovery, goal: seconds(rest))],
                iterations: rounds.value
            )]
        case .amrap, .forTime:
            return nil
        }
    }

    /// The name the Workout app shows and saves, the Home summary with the
    /// mode in front: "EMOM 10 × 1:00", "Tabata 8 × 20s / 10s".
    static func displayName(for type: TimerType) -> String {
        switch type {
        case let .emom(interval, rounds):
            return "EMOM \(rounds.value) × \(interval.clock)"
        case let .tabata(work, rest, rounds):
            return "Tabata \(rounds.value) × \(work.phase) / \(rest.phase)"
        case let .amrap(duration):
            return "AMRAP \(duration.clock)"
        case let .forTime(cap, _):
            return "For Time, cap \(cap.clock)"
        }
    }

    /// The custom workout for the WOD, indoor, under its display name.
    static func customWorkout(for type: TimerType) throws -> CustomWorkout {
        guard let blocks = blocks(for: type) else { throw Failure.notComposed(type.displayLabel) }
        let activity = activity(for: type)
        guard CustomWorkout.supportsActivity(activity) else { throw Failure.unsupportedActivity(type.displayLabel) }
        return CustomWorkout(activity: activity, location: .indoor, displayName: displayName(for: type), blocks: blocks)
    }

    /// Opens the WOD in the Workout app, which offers to start it. Our app
    /// goes to the background; the Workout app owns the session from here.
    @MainActor
    static func open(_ type: TimerType) async throws {
        let plan = WorkoutPlan(.custom(try customWorkout(for: type)))
        try await plan.openInWorkoutApp()
    }

    /// One line for the setup screen when the hand-off fails.
    static func message(for error: Error) -> String {
        switch error {
        case Failure.notComposed(let mode): return "\(mode) is not in the Workout app yet"
        case Failure.unsupportedActivity: return "This watch can't run it in Workout"
        default: return "Workout app didn't open: \(error.localizedDescription)"
        }
    }

    private static func seconds(_ duration: TimerDuration) -> WorkoutGoal {
        .time(Double(duration.seconds), .seconds)
    }
}
