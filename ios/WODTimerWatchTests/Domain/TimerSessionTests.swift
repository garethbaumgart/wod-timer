import XCTest
@testable import WODTimerWatch

final class TimerSessionTests: XCTestCase {

    // MARK: - State Transitions

    func testStartFromReady() {
        var session = TimerSession.fromWorkout(Workout.defaultAmrap())
        let result = session.start()
        XCTAssertEqual(try result.get().state, .preparing)
    }

    func testStartWithoutPrepGoesDirectlyToRunning() {
        let workout = Workout(
            id: UUID(),
            name: "No Prep",
            timerType: .amrap(duration: TimerDuration(seconds: 60)),
            prepCountdown: .zero,
            createdAt: Date()
        )
        var session = TimerSession.fromWorkout(workout)
        let result = session.start()
        XCTAssertEqual(try result.get().state, .running)
    }

    func testCannotStartFromRunning() {
        var session = makeRunningSession()
        let result = session.start()
        switch result {
        case .success: XCTFail("Should not be able to start from running")
        case let .failure(error):
            XCTAssertEqual(error, .invalidStateTransition(from: .running, to: .preparing))
        }
    }

    func testPauseFromRunning() {
        var session = makeRunningSession()
        let result = session.pause()
        let paused = try! result.get()
        XCTAssertEqual(paused.state, .paused)
        XCTAssertEqual(paused.stateBeforePause, .running)
    }

    func testResumeFromPaused() {
        var session = makePausedSession(from: .running)
        let result = session.resume()
        let resumed = try! result.get()
        XCTAssertEqual(resumed.state, .running)
        XCTAssertNil(resumed.stateBeforePause)
    }

    func testResumeRestoresRestState() {
        var session = makePausedSession(from: .resting)
        let result = session.resume()
        XCTAssertEqual(try result.get().state, .resting)
    }

    func testCannotResumeFromRunning() {
        var session = makeRunningSession()
        let result = session.resume()
        switch result {
        case .success: XCTFail("Should fail")
        case .failure: break
        }
    }

    // MARK: - AMRAP Tick

    func testAmrapTickUpdatesElapsed() {
        var session = makeRunningAmrapSession(durationSeconds: 600)
        let result = session.tick(deltaMs: 1000)
        let updated = try! result.get()
        XCTAssertEqual(updated.elapsed.seconds, 1)
    }

    func testAmrapCompletes() {
        var session = makeRunningAmrapSession(durationSeconds: 5)
        // Tick 6 seconds worth
        for _ in 0..<60 {
            _ = session.tick(deltaMs: 100)
        }
        XCTAssertEqual(session.state, .completed)
    }

    // MARK: - ForTime Tick

    func testForTimeCompletes() {
        var session = makeRunningForTimeSession(capSeconds: 3)
        for _ in 0..<40 {
            _ = session.tick(deltaMs: 100)
        }
        XCTAssertEqual(session.state, .completed)
    }

    // MARK: - EMOM Tick

    func testEmomAdvancesRound() {
        var session = makeRunningEmomSession(intervalSeconds: 2, rounds: 3)
        // Tick past first interval (2 seconds)
        for _ in 0..<25 {
            _ = session.tick(deltaMs: 100)
        }
        XCTAssertEqual(session.currentRound, 2)
    }

    func testEmomCompletes() {
        var session = makeRunningEmomSession(intervalSeconds: 1, rounds: 2)
        // Tick 3 seconds (enough for 2 rounds of 1 second)
        for _ in 0..<30 {
            _ = session.tick(deltaMs: 100)
        }
        XCTAssertEqual(session.state, .completed)
    }

    // MARK: - Tabata Tick

    func testTabataWorkToRest() {
        var session = makeRunningTabataSession(workSeconds: 2, restSeconds: 1, rounds: 2)
        XCTAssertEqual(session.state, .running)
        // Tick past work phase (2 seconds)
        for _ in 0..<25 {
            _ = session.tick(deltaMs: 100)
        }
        XCTAssertEqual(session.state, .resting)
    }

    func testTabataRestToWork() {
        var session = makeRunningTabataSession(workSeconds: 1, restSeconds: 1, rounds: 3)
        // Tick exactly past work (1s = 10 ticks of 100ms)
        for _ in 0..<10 {
            _ = session.tick(deltaMs: 100)
        }
        XCTAssertEqual(session.state, .resting)
        // Tick exactly past rest (1s = 10 more ticks)
        for _ in 0..<10 {
            _ = session.tick(deltaMs: 100)
        }
        XCTAssertEqual(session.state, .running)
        XCTAssertEqual(session.currentRound, 2)
    }

    func testTabataCompletes() {
        var session = makeRunningTabataSession(workSeconds: 1, restSeconds: 1, rounds: 1)
        // Tick 3 seconds (1s work + 1s rest = complete after 1 round)
        for _ in 0..<30 {
            _ = session.tick(deltaMs: 100)
        }
        XCTAssertEqual(session.state, .completed)
    }

    // MARK: - Preparation Phase

    func testPrepPhaseTransitionsToRunning() {
        var session = TimerSession.fromWorkout(Workout.defaultAmrap())
        _ = session.start()
        XCTAssertEqual(session.state, .preparing)

        // Tick past 10s prep
        for _ in 0..<110 {
            _ = session.tick(deltaMs: 100)
        }
        XCTAssertEqual(session.state, .running)
    }

    // MARK: - Millisecond Precision

    func testMillisecondAccumulation() {
        var session = makeRunningAmrapSession(durationSeconds: 600)
        // 9 ticks of 100ms = 900ms, should NOT yet reach 1 second
        for _ in 0..<9 {
            _ = session.tick(deltaMs: 100)
        }
        XCTAssertEqual(session.elapsed.seconds, 0)

        // 10th tick should cross the 1-second boundary
        _ = session.tick(deltaMs: 100)
        XCTAssertEqual(session.elapsed.seconds, 1)
    }

    // MARK: - Progress

    func testProgressComputesCorrectly() {
        var session = makeRunningAmrapSession(durationSeconds: 100)
        // Tick 50 seconds
        for _ in 0..<500 {
            _ = session.tick(deltaMs: 100)
        }
        XCTAssertEqual(session.progress, 0.5, accuracy: 0.01)
    }

    // MARK: - TimeRemaining

    func testTimeRemainingAmrap() {
        var session = makeRunningAmrapSession(durationSeconds: 60)
        for _ in 0..<100 {
            _ = session.tick(deltaMs: 100)
        }
        XCTAssertEqual(session.timeRemaining.seconds, 50)
    }

    // MARK: - Manual Complete

    func testManualComplete() {
        var session = makeRunningSession()
        let result = session.complete()
        XCTAssertEqual(try result.get().state, .completed)
    }

    func testCannotCompleteFromReady() {
        var session = TimerSession.fromWorkout(Workout.defaultAmrap())
        let result = session.complete()
        switch result {
        case .success: XCTFail("Should not complete from ready")
        case .failure: break
        }
    }

    func testCannotCompleteAlreadyCompleted() {
        var session = makeRunningSession()
        _ = session.complete()
        let result = session.complete()
        switch result {
        case .success: XCTFail("Should fail")
        case let .failure(error): XCTAssertEqual(error, .alreadyCompleted)
        }
    }

    // MARK: - Helpers

    private func makeRunningSession() -> TimerSession {
        makeRunningAmrapSession(durationSeconds: 600)
    }

    private func makeRunningAmrapSession(durationSeconds: Int) -> TimerSession {
        let workout = Workout(
            id: UUID(), name: "Test", timerType: .amrap(duration: TimerDuration(seconds: durationSeconds)),
            prepCountdown: .zero, createdAt: Date()
        )
        var session = TimerSession.fromWorkout(workout)
        _ = session.start()
        return session
    }

    private func makeRunningForTimeSession(capSeconds: Int) -> TimerSession {
        let workout = Workout(
            id: UUID(), name: "Test", timerType: .forTime(timeCap: TimerDuration(seconds: capSeconds)),
            prepCountdown: .zero, createdAt: Date()
        )
        var session = TimerSession.fromWorkout(workout)
        _ = session.start()
        return session
    }

    private func makeRunningEmomSession(intervalSeconds: Int, rounds: Int) -> TimerSession {
        let workout = Workout(
            id: UUID(), name: "Test",
            timerType: .emom(intervalDuration: TimerDuration(seconds: intervalSeconds), rounds: RoundCount(value: rounds)),
            prepCountdown: .zero, createdAt: Date()
        )
        var session = TimerSession.fromWorkout(workout)
        _ = session.start()
        return session
    }

    private func makeRunningTabataSession(workSeconds: Int, restSeconds: Int, rounds: Int) -> TimerSession {
        let workout = Workout(
            id: UUID(), name: "Test",
            timerType: .tabata(
                workDuration: TimerDuration(seconds: workSeconds),
                restDuration: TimerDuration(seconds: restSeconds),
                rounds: RoundCount(value: rounds)
            ),
            prepCountdown: .zero, createdAt: Date()
        )
        var session = TimerSession.fromWorkout(workout)
        _ = session.start()
        return session
    }

    private func makePausedSession(from beforePause: TimerState) -> TimerSession {
        var session = makeRunningSession()
        if beforePause == .resting {
            // Need a tabata session to get resting state
            let workout = Workout(
                id: UUID(), name: "Test",
                timerType: .tabata(
                    workDuration: TimerDuration(seconds: 1),
                    restDuration: TimerDuration(seconds: 10),
                    rounds: RoundCount(value: 3)
                ),
                prepCountdown: .zero, createdAt: Date()
            )
            session = TimerSession.fromWorkout(workout)
            _ = session.start()
            // Tick past work to get to resting
            for _ in 0..<15 {
                _ = session.tick(deltaMs: 100)
            }
        }
        _ = session.pause()
        return session
    }
}
