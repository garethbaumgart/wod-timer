import HealthKit
import WorkoutKit
import XCTest
@testable import WODTimerWatch

// Spike (24 Oct 2026): the WOD composed for Apple's Workout app. The
// structure is what the Workout app runs, so it is pinned here; whether the
// watch opens it is the TestFlight check on the wrist.

final class WorkoutHandoffTests: XCTestCase {
    func testEmomIsOneWorkStepOfTheIntervalPerRound() throws {
        let type = TimerType.emom(intervalDuration: TimerDuration(seconds: 60), rounds: RoundCount(value: 10))
        let blocks = try XCTUnwrap(WorkoutHandoff.blocks(for: type))
        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks[0].iterations, 10)
        XCTAssertEqual(blocks[0].steps.map(\.purpose), [.work])
        XCTAssertEqual(blocks[0].steps.map(seconds), [60])
        XCTAssertEqual(WorkoutHandoff.activity(for: type), .functionalStrengthTraining)
        XCTAssertEqual(WorkoutHandoff.displayName(for: type), "EMOM 10 × 1:00")
    }

    func testTabataIsWorkThenRestPerRound() throws {
        let type = TimerType.tabata(
            workDuration: TimerDuration(seconds: 20), restDuration: TimerDuration(seconds: 10), rounds: RoundCount(value: 8)
        )
        let blocks = try XCTUnwrap(WorkoutHandoff.blocks(for: type))
        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks[0].iterations, 8)
        XCTAssertEqual(blocks[0].steps.map(\.purpose), [.work, .recovery])
        XCTAssertEqual(blocks[0].steps.map(seconds), [20, 10])
        XCTAssertEqual(WorkoutHandoff.activity(for: type), .highIntensityIntervalTraining)
        XCTAssertEqual(WorkoutHandoff.displayName(for: type), "Tabata 8 × 20s / 10s")
    }

    func testLongIntervalsKeepWholeSeconds() throws {
        let type = TimerType.emom(intervalDuration: TimerDuration(seconds: 150), rounds: RoundCount(value: 4))
        let blocks = try XCTUnwrap(WorkoutHandoff.blocks(for: type))
        XCTAssertEqual(blocks[0].steps.map(seconds), [150])
        XCTAssertEqual(WorkoutHandoff.displayName(for: type), "EMOM 4 × 2:30")
    }

    func testAmrapAndForTimeAreNotComposedYet() {
        let amrap = TimerType.amrap(duration: TimerDuration(seconds: 600))
        let forTime = TimerType.forTime(timeCap: TimerDuration(seconds: 1200))
        XCTAssertNil(WorkoutHandoff.blocks(for: amrap))
        XCTAssertNil(WorkoutHandoff.blocks(for: forTime))
        XCTAssertThrowsError(try WorkoutHandoff.customWorkout(for: amrap)) { error in
            XCTAssertEqual(error as? WorkoutHandoff.Failure, .notComposed("AMRAP"))
            XCTAssertEqual(WorkoutHandoff.message(for: error), "AMRAP is not in the Workout app yet")
        }
    }

    /// The custom workout itself, where this watch supports the activity
    /// (the simulator may not; the structure is pinned above either way).
    func testTheCustomWorkoutCarriesTheNameAndIsIndoor() throws {
        let type = TimerType.emom(intervalDuration: TimerDuration(seconds: 60), rounds: RoundCount(value: 10))
        guard CustomWorkout.supportsActivity(.functionalStrengthTraining) else {
            throw XCTSkip("this device refuses custom functional strength workouts")
        }
        let workout = try WorkoutHandoff.customWorkout(for: type)
        XCTAssertEqual(workout.displayName, "EMOM 10 × 1:00")
        XCTAssertEqual(workout.location, .indoor)
        XCTAssertEqual(workout.activity, .functionalStrengthTraining)
        XCTAssertNil(workout.warmup)
        XCTAssertNil(workout.cooldown)
        XCTAssertEqual(workout.blocks.count, 1)
    }

    private func seconds(_ step: IntervalStep) -> Double {
        guard case let .time(value, unit) = step.step.goal else { return -1 }
        return Measurement(value: value, unit: unit).converted(to: .seconds).value
    }
}
