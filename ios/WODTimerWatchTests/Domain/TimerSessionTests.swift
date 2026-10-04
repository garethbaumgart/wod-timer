import SwiftUI
import WatchKit
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

    // MARK: - 1.3.0 regressions

    /// A Tabata paused mid-WORK was measured against the REST length
    /// (12s into 20s work showed 0:00 instead of 8).
    func testTabataPausedMidWorkKeepsWorkCountdown() {
        var session = makeRunningTabataSession(workSeconds: 20, restSeconds: 10, rounds: 8)
        _ = session.tick(deltaMs: 12_000)
        XCTAssertEqual(session.state, .running)
        XCTAssertEqual(session.timeRemaining.seconds, 8)
        _ = session.pause()
        XCTAssertEqual(session.timeRemaining.seconds, 8)
        _ = session.resume()
        XCTAssertEqual(session.timeRemaining.seconds, 8)
    }

    func testTabataPausedMidRestKeepsRestCountdown() {
        var session = makeRunningTabataSession(workSeconds: 20, restSeconds: 10, rounds: 8)
        _ = session.tick(deltaMs: 20_000)
        _ = session.tick(deltaMs: 3_000)
        XCTAssertEqual(session.state, .resting)
        _ = session.pause()
        XCTAssertEqual(session.timeRemaining.seconds, 7)
    }

    /// After the watch slept, one catch-up tick spanning several rounds
    /// used to advance only one.
    func testEmomLargeDeltaConsumesEveryInterval() {
        var session = makeRunningEmomSession(intervalSeconds: 60, rounds: 10)
        _ = session.tick(deltaMs: 185_000)
        XCTAssertEqual(session.currentRound, 4)
        XCTAssertEqual(session.timeRemaining.seconds, 55)
        XCTAssertEqual(session.elapsed.seconds, 185)
    }

    func testTabataLargeDeltaConsumesEveryPhase() {
        var session = makeRunningTabataSession(workSeconds: 20, restSeconds: 10, rounds: 8)
        _ = session.tick(deltaMs: 95_000) // 3 rounds (90s) + 5s into work
        XCTAssertEqual(session.currentRound, 4)
        XCTAssertEqual(session.state, .running)
        XCTAssertEqual(session.timeRemaining.seconds, 15)
    }

    func testLargeDeltaPastTheEndCompletesAtTheExactTotal() {
        var session = makeRunningEmomSession(intervalSeconds: 60, rounds: 3)
        _ = session.tick(deltaMs: 500_000)
        XCTAssertEqual(session.state, .completed)
        XCTAssertEqual(session.elapsed.seconds, 180)
    }

    func testPrepOvershootCarriesIntoTheWorkout() {
        let workout = Workout(
            id: UUID(), name: "Test", timerType: .amrap(duration: TimerDuration(seconds: 600)),
            prepCountdown: TimerDuration(seconds: 10), createdAt: Date()
        )
        var session = TimerSession.fromWorkout(workout)
        _ = session.start()
        _ = session.tick(deltaMs: 25_000)
        XCTAssertEqual(session.state, .running)
        XCTAssertEqual(session.elapsed.seconds, 15)
    }

    /// The summary read one tick short (9:59 for a 10:00 AMRAP).
    func testAmrapCompletionPinsTheExactDuration() {
        var session = makeRunningAmrapSession(durationSeconds: 600)
        for _ in 0 ..< 6_010 { _ = session.tick(deltaMs: 100) }
        XCTAssertEqual(session.state, .completed)
        XCTAssertEqual(session.elapsed.seconds, 600)
    }

    func testAmrapRoundTallyCountsAndCorrectsButNeverGoesNegative() {
        var session = makeRunningAmrapSession(durationSeconds: 60)
        session.countRound()
        session.countRound()
        XCTAssertEqual(session.countedRounds, 2)
        _ = session.tick(deltaMs: 61_000)
        XCTAssertEqual(session.state, .completed)
        session.adjustRounds(by: 1)
        XCTAssertEqual(session.countedRounds, 3)
        session.adjustRounds(by: -5)
        XCTAssertEqual(session.countedRounds, 0)
    }

    func testRoundTallyOnlyCountsWhileAnAmrapRuns() {
        var emom = makeRunningEmomSession(intervalSeconds: 60, rounds: 10)
        emom.countRound()
        XCTAssertEqual(emom.currentRound, 1)
        var amrap = makeRunningAmrapSession(durationSeconds: 60)
        _ = amrap.pause()
        amrap.countRound()
        XCTAssertEqual(amrap.countedRounds, 0)
    }

    func testClockFormatNeverZeroPadsMinutes() {
        XCTAssertEqual(TimerDuration(seconds: 585).clock, "9:45")
        XCTAssertEqual(TimerDuration(seconds: 11).clock, "0:11")
        XCTAssertEqual(TimerDuration(seconds: 750).clock, "12:30")
        XCTAssertEqual(TimerDuration(seconds: 20).phase, "20s")
        XCTAssertEqual(TimerDuration(seconds: 120).phase, "2:00")
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

/// View-model rules added in 1.3.0 (simulator test runs have the capture
/// hooks, which advance the session without waiting on the engine).
final class TimerViewModelRulesTests: XCTestCase {

    private func forTime(cap: Int) -> Workout {
        Workout(
            id: UUID(), name: "Test", timerType: .forTime(timeCap: TimerDuration(seconds: cap)),
            prepCountdown: .zero, createdAt: Date()
        )
    }

    func testGetReadyCannotBePaused() {
        let vm = TimerViewModel()
        vm.start(workout: Workout.defaultAmrap())
        XCTAssertEqual(vm.phase, .preparing)
        vm.pause()
        XCTAssertEqual(vm.phase, .preparing)
        vm.reset()
    }

    func testStopIsHonestAndFinishIsAFinish() {
        let stopped = TimerViewModel()
        stopped.start(workout: forTime(cap: 600))
        stopped.debugAdvance(seconds: 30)
        stopped.stop()
        XCTAssertEqual(stopped.phase, .completed)
        XCTAssertTrue(stopped.endedEarly)

        let finished = TimerViewModel()
        finished.start(workout: forTime(cap: 600))
        finished.debugAdvance(seconds: 30)
        finished.finish()
        XCTAssertEqual(finished.phase, .completed)
        XCTAssertFalse(finished.endedEarly)
        XCTAssertFalse(finished.endedAtTimeCap)
        stopped.reset(); finished.reset()
    }

    func testReachingTheCapIsATimeCap() {
        let vm = TimerViewModel()
        vm.start(workout: forTime(cap: 60))
        vm.debugAdvance(seconds: 61)
        XCTAssertEqual(vm.phase, .completed)
        XCTAssertTrue(vm.endedAtTimeCap)
        vm.reset()
    }

    func testADoubleTapCountsOneRound() {
        let vm = TimerViewModel()
        vm.start(workout: Workout(
            id: UUID(), name: "Test", timerType: .amrap(duration: TimerDuration(seconds: 600)),
            prepCountdown: .zero, createdAt: Date()
        ))
        // Starting straight into work arms the cooldown, as GO does.
        vm.countRound()
        XCTAssertEqual(vm.session?.countedRounds, 0)
        Thread.sleep(forTimeInterval: 0.75)
        vm.countRound()
        vm.countRound()
        XCTAssertEqual(vm.session?.countedRounds, 1)
        vm.reset()
    }
}


/// 1.3.1: every mode reopens on its last setup, saved on each change.
final class SetupMemoryTests: XCTestCase {
    private let keys = ["amrap", "fortime", "emom", "tabata"].map { "watch_setup_\($0)" }

    override func setUp() {
        super.setUp()
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    override func tearDown() {
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        super.tearDown()
    }

    func testEachModeRoundTripsItsLastSetup() {
        let memory = SetupMemory()
        memory.save(.amrap(duration: TimerDuration(seconds: 900)))
        memory.save(.forTime(timeCap: TimerDuration(seconds: 1500), countUp: false))
        memory.save(.emom(intervalDuration: TimerDuration(seconds: 90), rounds: RoundCount(value: 12)))
        memory.save(.tabata(workDuration: TimerDuration(seconds: 40), restDuration: TimerDuration(seconds: 20),
                            rounds: RoundCount(value: 6)))

        let reread = SetupMemory()
        XCTAssertEqual(reread.amrap.seconds, 900)
        XCTAssertEqual(reread.forTime.cap.seconds, 1500)
        XCTAssertFalse(reread.forTime.countUp)
        XCTAssertEqual(reread.emom.interval.seconds, 90)
        XCTAssertEqual(reread.emom.rounds, 12)
        XCTAssertEqual(reread.tabata.work.seconds, 40)
        XCTAssertEqual(reread.tabata.rest.seconds, 20)
        XCTAssertEqual(reread.tabata.rounds, 6)
        XCTAssertEqual(reread.summary("emom"), "12 × 1:30")
        XCTAssertEqual(reread.summary("tabata"), "6 × 40s / 20s")
        XCTAssertEqual(reread.summary("fortime"), "CAP 25:00 · DOWN")
    }

    func testTheLatestChangeWins() {
        let memory = SetupMemory()
        memory.save(.emom(intervalDuration: TimerDuration(seconds: 60), rounds: RoundCount(value: 10)))
        memory.save(.emom(intervalDuration: TimerDuration(seconds: 75), rounds: RoundCount(value: 10)))
        memory.save(.emom(intervalDuration: TimerDuration(seconds: 75), rounds: RoundCount(value: 14)))
        XCTAssertEqual(SetupMemory().summary("emom"), "14 × 1:15")
    }

    func testOneModeNeverOverwritesAnother() {
        let memory = SetupMemory()
        memory.save(.amrap(duration: TimerDuration(seconds: 1200)))
        memory.save(.tabata(workDuration: TimerDuration(seconds: 30), restDuration: TimerDuration(seconds: 15),
                            rounds: RoundCount(value: 10)))
        XCTAssertEqual(SetupMemory().amrap.seconds, 1200)
    }
}

/// Beeps only: since 2.1.0 the beeps carry every countdown and change, so
/// Beeps only is the beeps with the voice taken away.
final class BeepsOnlyTests: XCTestCase {

    func testTheChoicePersists() {
        let key = "watch_voice_beeps"
        let before = UserDefaults.standard.object(forKey: key)
        defer { UserDefaults.standard.set(before, forKey: key) }
        WatchAudioService().setBeepsOnly(true)
        XCTAssertTrue(WatchAudioService().beepsOnly)
        WatchAudioService().setBeepsOnly(false)
        XCTAssertFalse(WatchAudioService().beepsOnly)
    }
}

// MARK: - 1.3.1 Home, timeline and end-screen rules

final class HomeAndTimelineTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "HomeAndTimelineTests")
        defaults.removePersistentDomain(forName: "HomeAndTimelineTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "HomeAndTimelineTests")
        super.tearDown()
    }

    // Home order: For Time, EMOM, AMRAP, Tabata on every Home screen.

    func testHomeOrderIsForTimeEmomAmrapTabata() {
        XCTAssertEqual(HomeView.modeOrder, ["fortime", "emom", "amrap", "tabata"])
        XCTAssertEqual(Palette.modeOrder, HomeView.modeOrder)
    }

    func testHomeTitlesAreTheModeNames() {
        XCTAssertEqual(HomeView.modeOrder.map(HomeView.title), ["FOR TIME", "EMOM", "AMRAP", "TABATA"])
    }

    func testModeColoursHaveOneMeaningEach() {
        XCTAssertEqual(Palette.modeHex("fortime"), 0xFF6B1A)
        XCTAssertEqual(Palette.modeHex("emom"), 0xFF0088)
        XCTAssertEqual(Palette.modeHex("amrap"), 0x00AAFF)
        XCTAssertEqual(Palette.modeHex("tabata"), 0x00FF88)
    }

    // SetupMemory.shape per mode: the remembered workout as timeline blocks.

    func testShapeForTimeIsOneBarOfTheCap() {
        let memory = SetupMemory(defaults: defaults)
        XCTAssertEqual(memory.shape("fortime"), [TimelinePart(seconds: 1200, isRest: false)])
        memory.save(.forTime(timeCap: TimerDuration(seconds: 300), countUp: false))
        XCTAssertEqual(memory.shape("fortime"), [TimelinePart(seconds: 300, isRest: false)])
    }

    func testShapeAmrapIsOneBarOfTheDuration() {
        let memory = SetupMemory(defaults: defaults)
        XCTAssertEqual(memory.shape("amrap"), [TimelinePart(seconds: 600, isRest: false)])
        memory.save(.amrap(duration: TimerDuration(seconds: 720)))
        XCTAssertEqual(memory.shape("amrap"), [TimelinePart(seconds: 720, isRest: false)])
    }

    func testShapeEmomIsOneBlockPerRound() {
        let memory = SetupMemory(defaults: defaults)
        XCTAssertEqual(memory.shape("emom"), Array(repeating: TimelinePart(seconds: 60, isRest: false), count: 10))
        memory.save(.emom(intervalDuration: TimerDuration(seconds: 90), rounds: RoundCount(value: 3)))
        XCTAssertEqual(memory.shape("emom"), Array(repeating: TimelinePart(seconds: 90, isRest: false), count: 3))
    }

    func testShapeTabataIsWorkRestPairs() {
        let memory = SetupMemory(defaults: defaults)
        let pair = [TimelinePart(seconds: 20, isRest: false), TimelinePart(seconds: 10, isRest: true)]
        XCTAssertEqual(memory.shape("tabata"), (0 ..< 8).flatMap { _ in pair })
        memory.save(.tabata(workDuration: TimerDuration(seconds: 40), restDuration: TimerDuration(seconds: 20),
                            rounds: RoundCount(value: 2)))
        let longPair = [TimelinePart(seconds: 40, isRest: false), TimelinePart(seconds: 20, isRest: true)]
        XCTAssertEqual(memory.shape("tabata"), longPair + longPair)
    }

    func testShapeIgnoresAnotherModeSavedUnderTheKey() {
        let memory = SetupMemory(defaults: defaults)
        memory.save(.emom(intervalDuration: TimerDuration(seconds: 30), rounds: RoundCount(value: 4)))
        XCTAssertEqual(memory.shape("amrap"), [TimelinePart(seconds: 600, isRest: false)])
    }

    // Timeline fill: finished parts 1, the current part partial, the rest 0.

    func testFillFractionsEmom() {
        let parts = Workout.defaultEmom().timerType.timelineParts
        let fractions = TimerType.fillFractions(parts, elapsed: 125)
        XCTAssertEqual(fractions.count, 10)
        XCTAssertEqual(fractions[0], 1)
        XCTAssertEqual(fractions[1], 1)
        XCTAssertEqual(fractions[2], 5.0 / 60, accuracy: 0.0001)
        XCTAssertEqual(fractions[3], 0)
        XCTAssertEqual(fractions[9], 0)
    }

    func testFillFractionsTabataAndBounds() {
        let parts = Workout.defaultTabata().timerType.timelineParts
        XCTAssertEqual(TimerType.fillFractions(parts, elapsed: 0), Array(repeating: 0, count: 16))
        let mid = TimerType.fillFractions(parts, elapsed: 33)
        XCTAssertEqual(mid[0], 1)
        XCTAssertEqual(mid[1], 1)
        XCTAssertEqual(mid[2], 0.15, accuracy: 0.0001)
        XCTAssertEqual(mid[3], 0)
        XCTAssertEqual(TimerType.fillFractions(parts, elapsed: 240), Array(repeating: 1, count: 16))
        XCTAssertEqual(TimerType.fillFractions(parts, elapsed: 999), Array(repeating: 1, count: 16))
    }

    // The clock's size comes from the workout's longest value, once.

    func testReferenceClockPerMode() {
        XCTAssertEqual(LiveRules.referenceClock(.forTime(timeCap: TimerDuration(seconds: 1200))), "20:00")
        XCTAssertEqual(LiveRules.referenceClock(.amrap(duration: TimerDuration(seconds: 600))), "10:00")
        XCTAssertEqual(LiveRules.referenceClock(.emom(intervalDuration: TimerDuration(seconds: 60), rounds: .one)), "60")
        XCTAssertEqual(LiveRules.referenceClock(.emom(intervalDuration: TimerDuration(seconds: 90), rounds: .one)), "1:30")
        XCTAssertEqual(LiveRules.referenceClock(.standardTabata), "20")
        XCTAssertEqual(LiveRules.referenceClock(.tabata(workDuration: TimerDuration(seconds: 30),
                                                        restDuration: TimerDuration(seconds: 90), rounds: .one)), "1:30")
    }

    // End screen: word, hero and the one label line.

    func testEndSummaryEmomStoppedAndFinished() {
        var session = TimerSession.fromWorkout(Workout.defaultEmom())
        _ = session.start()
        _ = session.tick(deltaMs: 10_000)
        _ = session.tick(deltaMs: 125_000)
        _ = session.complete()
        let stopped = LiveRules.endSummary(session, endedEarly: true, endedAtTimeCap: false)
        XCTAssertEqual(stopped, .init(word: "Stopped", hero: "3/10", label: "ROUNDS · 2:05"))

        var full = TimerSession.fromWorkout(Workout.defaultEmom())
        _ = full.start()
        _ = full.tick(deltaMs: 10_000)
        _ = full.tick(deltaMs: 600_000)
        let finished = LiveRules.endSummary(full, endedEarly: false, endedAtTimeCap: false)
        XCTAssertEqual(finished, .init(word: "Finished", hero: "10/10", label: "ROUNDS · 10:00"))
    }

    func testEndSummaryTabataFinishedPutsTheTotalOnTheLabel() {
        var session = TimerSession.fromWorkout(Workout.defaultTabata())
        _ = session.start()
        _ = session.tick(deltaMs: 10_000)
        _ = session.tick(deltaMs: 240_000)
        XCTAssertEqual(session.state, .completed)
        let summary = LiveRules.endSummary(session, endedEarly: false, endedAtTimeCap: false)
        XCTAssertEqual(summary, .init(word: "Finished", hero: "8/8", label: "ROUNDS · 4:00"))
    }

    func testEndSummaryForTimeAndTimeCap() {
        var session = TimerSession.fromWorkout(Workout.defaultForTime())
        _ = session.start()
        _ = session.tick(deltaMs: 10_000)
        _ = session.tick(deltaMs: 754_000)
        _ = session.complete()
        XCTAssertEqual(LiveRules.endSummary(session, endedEarly: false, endedAtTimeCap: false),
                       .init(word: "Finished", hero: "12:34", label: "TIME"))
        XCTAssertEqual(LiveRules.endSummary(session, endedEarly: false, endedAtTimeCap: true),
                       .init(word: "Time cap", hero: nil, label: ""))
    }

    func testEndSummaryAmrap() {
        var session = TimerSession.fromWorkout(Workout.defaultAmrap())
        _ = session.start()
        _ = session.tick(deltaMs: 10_000)
        _ = session.tick(deltaMs: 29_000)
        session.countRound(); session.countRound(); session.countRound()
        _ = session.complete()
        XCTAssertEqual(LiveRules.endSummary(session, endedEarly: true, endedAtTimeCap: false),
                       .init(word: "Stopped", hero: "3", label: "ROUNDS · 0:29"))
        XCTAssertEqual(LiveRules.endSummary(session, endedEarly: false, endedAtTimeCap: false),
                       .init(word: "Finished", hero: "3", label: "ROUNDS"))
    }

    func testCaptureScenesCoverEveryState() {
        let names = Set(CaptureScene.allCases.map(\.rawValue))
        for required in ["home", "home-scrolled", "setup-fortime", "setup-emom", "setup-amrap", "setup-tabata",
                         "live-prep", "live-prep-fortime", "live-prep-emom", "live-prep-tabata",
                         "live-fortime", "live-emom", "live-amrap",
                         "live-tabata-work", "live-tabata-rest", "live-tabata-next",
                         "paused-fortime", "paused-emom", "paused-amrap", "paused-tabata",
                         "finished-fortime", "timecap-fortime", "finished-emom", "stopped-emom",
                         "finished-amrap", "stopped-amrap", "finished-tabata", "stopped-tabata"] {
            XCTAssertTrue(names.contains(required), "missing capture scene \(required)")
        }
    }
}

// MARK: - 2.0.0 live rules (clock text, phase word, colours, config line)

final class LiveRulesTests: XCTestCase {
    private func workout(_ type: TimerType, prep: Int = 0) -> Workout {
        Workout(id: UUID(), name: "t", timerType: type, prepCountdown: TimerDuration(seconds: prep), createdAt: Date())
    }

    /// A started session, `seconds` in (one catch-up tick, as the engine would after sleep).
    private func session(_ type: TimerType, prep: Int = 0, after ms: Int = 0) -> TimerSession {
        var s = TimerSession.fromWorkout(workout(type, prep: prep))
        _ = s.start()
        if ms > 0 { _ = s.tick(deltaMs: ms) }
        return s
    }

    private let forTime = TimerType.forTime(timeCap: TimerDuration(seconds: 1200))
    private let countDown = TimerType.forTime(timeCap: TimerDuration(seconds: 1200), countUp: false)
    private let amrap = TimerType.amrap(duration: TimerDuration(seconds: 600))
    private let emom = TimerType.emom(intervalDuration: TimerDuration(seconds: 60), rounds: RoundCount(value: 10))
    private let tabata = TimerType.standardTabata

    func testClockTextCountsUpOnACountUpForTimeAndDownOtherwise() {
        XCTAssertEqual(LiveRules.clockText(session(forTime, after: 65_000)), "1:05")
        XCTAssertEqual(LiveRules.clockText(session(countDown, after: 65_000)), "18:55")
        XCTAssertEqual(LiveRules.clockText(session(amrap, after: 30_000)), "9:30")
        XCTAssertTrue(LiveRules.isCountUp(session(forTime)))
        XCTAssertFalse(LiveRules.isCountUp(session(countDown)))
        XCTAssertFalse(LiveRules.isCountUp(session(amrap)))
    }

    func testClockTextIsBareSecondsUnderAMinuteOrInAMinutePhase() {
        XCTAssertEqual(LiveRules.clockText(session(amrap, after: 545_000)), "55")
        XCTAssertEqual(LiveRules.clockText(session(emom)), "60", "an EMOM minute never reads 1:00")
        XCTAssertEqual(LiveRules.clockText(session(emom, after: 5_000)), "55")
        XCTAssertEqual(LiveRules.clockText(session(tabata)), "20")
        XCTAssertEqual(LiveRules.clockText(session(tabata, after: 22_000)), "8")
        let longRest = TimerType.tabata(workDuration: TimerDuration(seconds: 20), restDuration: TimerDuration(seconds: 90), rounds: RoundCount(value: 2))
        XCTAssertEqual(LiveRules.clockText(session(longRest, after: 20_000)), "1:30")
        XCTAssertEqual(LiveRules.clockText(session(longRest, after: 50_000)), "1:00")
        XCTAssertEqual(LiveRules.clockText(session(longRest, after: 51_000)), "59")
    }

    func testClockTextInGetReadyIsTheCountdownInEveryMode() {
        XCTAssertEqual(LiveRules.clockText(session(amrap, prep: 10, after: 4_000)), "6")
        XCTAssertEqual(LiveRules.clockText(session(forTime, prep: 10, after: 4_000)), "6")
        XCTAssertEqual(LiveRules.clockText(session(forTime, prep: 10)), "10")
    }

    func testPhaseWordNamesOnlyGetReadyPausedAndTabataPhases() {
        let prep = LiveRules.phaseWord(session(amrap, prep: 10, after: 1_000))
        XCTAssertEqual(prep?.0, "GET READY")
        XCTAssertEqual(prep?.1, Palette.prepare)
        XCTAssertNil(LiveRules.phaseWord(session(amrap, after: 5_000)))
        XCTAssertNil(LiveRules.phaseWord(session(emom, after: 5_000)))
        XCTAssertNil(LiveRules.phaseWord(session(forTime, after: 5_000)))

        let work = LiveRules.phaseWord(session(tabata, after: 5_000))
        XCTAssertEqual(work?.0, "WORK")
        XCTAssertEqual(work?.1, Palette.work)
        let nextRest = LiveRules.phaseWord(session(tabata, after: 16_000))
        XCTAssertEqual(nextRest?.0, "NEXT · REST")
        XCTAssertEqual(nextRest?.1, Palette.rest)
        let rest = LiveRules.phaseWord(session(tabata, after: 22_000))
        XCTAssertEqual(rest?.0, "REST")
        XCTAssertEqual(rest?.1, Palette.rest)
        let nextWork = LiveRules.phaseWord(session(tabata, after: 26_000))
        XCTAssertEqual(nextWork?.0, "NEXT · WORK")
        XCTAssertEqual(nextWork?.1, Palette.work)

        let two = TimerType.tabata(workDuration: TimerDuration(seconds: 20), restDuration: TimerDuration(seconds: 10), rounds: RoundCount(value: 2))
        let lastRest = LiveRules.phaseWord(session(two, after: 52_000))
        XCTAssertEqual(lastRest?.0, "LAST REST")
        XCTAssertEqual(lastRest?.1, Palette.rest)
    }

    func testPausedPhaseWordSaysWhichTabataPhaseResumes() {
        var plain = session(emom, after: 5_000)
        _ = plain.pause()
        XCTAssertEqual(LiveRules.phaseWord(plain)?.0, "PAUSED")
        XCTAssertEqual(LiveRules.phaseWord(plain)?.1, Palette.paused)

        var inWork = session(tabata, after: 5_000)
        _ = inWork.pause()
        XCTAssertEqual(LiveRules.phaseWord(inWork)?.0, "PAUSED · WORK")
        var inRest = session(tabata, after: 22_000)
        _ = inRest.pause()
        XCTAssertEqual(LiveRules.phaseWord(inRest)?.0, "PAUSED · REST")
        XCTAssertEqual(LiveRules.effectivePhase(inRest), .resting)
        XCTAssertEqual(LiveRules.clockText(inRest), "8", "the clock keeps the paused phase's countdown")
    }

    func testLiveColourIsWhiteInGetReadyThenTheWorkoutsOwn() {
        XCTAssertEqual(Palette.live(session(emom, prep: 10, after: 1_000)), Palette.prepare)
        XCTAssertEqual(Palette.live(session(forTime, after: 1_000)), Palette.mode("fortime"))
        XCTAssertEqual(Palette.live(session(emom, after: 1_000)), Palette.mode("emom"))
        XCTAssertEqual(Palette.live(session(amrap, after: 1_000)), Palette.mode("amrap"))
        XCTAssertEqual(Palette.live(session(tabata, after: 5_000)), Palette.work)
        XCTAssertEqual(Palette.live(session(tabata, after: 22_000)), Palette.rest)
        var paused = session(tabata, after: 22_000)
        _ = paused.pause()
        XCTAssertEqual(Palette.live(paused), Palette.rest, "paused keeps its phase colour")
        XCTAssertEqual(Palette.mode(tabata), Palette.work)
        XCTAssertEqual(Palette.mode(emom), Palette.rest, "EMOM pink is the rest pink: one hue, two names")
    }

    func testPhaseSecondsIsTheLengthTheClockCountsThrough() {
        XCTAssertEqual(LiveRules.phaseSeconds(session(amrap, prep: 10)), 10)
        XCTAssertEqual(LiveRules.phaseSeconds(session(amrap)), 600)
        XCTAssertEqual(LiveRules.phaseSeconds(session(forTime)), 1200)
        XCTAssertEqual(LiveRules.phaseSeconds(session(emom)), 60)
        XCTAssertEqual(LiveRules.phaseSeconds(session(tabata)), 20)
        XCTAssertEqual(LiveRules.phaseSeconds(session(tabata, after: 22_000)), 10)
        var paused = session(tabata, after: 22_000)
        _ = paused.pause()
        XCTAssertEqual(LiveRules.phaseSeconds(paused), 10)
    }

    func testElapsedSecondsForTheTimelineIsZeroInPrepThenFractional() {
        XCTAssertEqual(LiveRules.elapsedSeconds(session(amrap, prep: 10, after: 4_000)), 0)
        XCTAssertEqual(LiveRules.elapsedSeconds(session(amrap, after: 1_700)), 1.7, accuracy: 0.0001)
        XCTAssertEqual(LiveRules.elapsedSeconds(session(amrap, prep: 10, after: 12_500)), 2.5, accuracy: 0.0001)
    }

    func testConfigLinePerMode() {
        XCTAssertEqual(LiveRules.configLine(amrap), "AMRAP · 10:00")
        XCTAssertEqual(LiveRules.configLine(forTime), "FOR TIME · CAP 20:00")
        XCTAssertEqual(LiveRules.configLine(emom), "EMOM · 10 × 1:00")
        XCTAssertEqual(LiveRules.configLine(tabata), "TABATA · 8 × 20s / 10s")
        let long = TimerType.tabata(workDuration: TimerDuration(seconds: 20), restDuration: TimerDuration(seconds: 90), rounds: RoundCount(value: 3))
        XCTAssertEqual(LiveRules.configLine(long), "TABATA · 3 × 20s / 1:30")
    }
}

// MARK: - 2.0.0 view-model rules

final class TimerViewModelMoreRulesTests: XCTestCase {
    private let hintKey = "watch_hint_amrap_counted"

    private func amrap(prep: Int = 0, seconds: Int = 600) -> Workout {
        Workout(id: UUID(), name: "t", timerType: .amrap(duration: TimerDuration(seconds: seconds)),
                prepCountdown: TimerDuration(seconds: prep), createdAt: Date())
    }

    func testSkipPrepStartsTheClockAtZeroAndArmsTheTapCooldown() {
        let vm = TimerViewModel()
        vm.start(workout: amrap(prep: 10))
        vm.debugAdvance(seconds: 2)
        XCTAssertEqual(vm.phase, .preparing)
        vm.skipPrep()
        XCTAssertEqual(vm.phase, .running)
        XCTAssertEqual(vm.session?.elapsed.seconds, 0)
        vm.countRound()
        XCTAssertEqual(vm.session?.countedRounds, 0, "a tap that skipped the countdown never counts")
        vm.skipPrep()
        XCTAssertEqual(vm.phase, .running, "no-op outside get ready")
        vm.reset()
    }

    func testCancelPrepOnlyLeavesFromGetReady() {
        let vm = TimerViewModel()
        vm.start(workout: amrap(prep: 10))
        vm.cancelPrep()
        XCTAssertEqual(vm.phase, .ready)
        XCTAssertNil(vm.session)

        vm.start(workout: amrap())
        vm.debugAdvance(seconds: 3)
        vm.cancelPrep()
        XCTAssertEqual(vm.phase, .running, "a running workout is never cancelled silently")
        vm.reset()
    }

    func testRestartOnlyFromTheEndScreenAndResetForgetsTheWorkout() {
        let vm = TimerViewModel()
        vm.start(workout: amrap(seconds: 5))
        vm.debugAdvance(seconds: 2)
        vm.restart()
        XCTAssertEqual(vm.session?.elapsed.seconds, 2, "restart while running is a no-op")
        vm.debugAdvance(seconds: 5)
        XCTAssertEqual(vm.phase, .completed)
        vm.restart()
        XCTAssertEqual(vm.phase, .running)
        XCTAssertEqual(vm.session?.elapsed.seconds, 0)
        XCTAssertFalse(vm.endedEarly)
        vm.reset()
        XCTAssertEqual(vm.phase, .ready)
        vm.restart()
        XCTAssertEqual(vm.phase, .ready, "nothing to restart after a reset")
    }

    func testStopAndFinishAfterTheEndAreNoOps() {
        let vm = TimerViewModel()
        vm.start(workout: amrap(seconds: 5))
        vm.debugAdvance(seconds: 6)
        XCTAssertEqual(vm.phase, .completed)
        XCTAssertFalse(vm.endedEarly)
        vm.stop()
        XCTAssertFalse(vm.endedEarly, "Finished stands once the clock ran out")
        vm.finish()
        XCTAssertEqual(vm.phase, .completed)
        vm.pause()
        XCTAssertEqual(vm.phase, .completed)
        vm.reset()
    }

    func testAdjustRoundsOnlyOnTheEndScreenAndNeverBelowZero() {
        let vm = TimerViewModel()
        vm.start(workout: amrap())
        vm.debugAdvance(seconds: 2)
        vm.adjustRounds(by: 3)
        XCTAssertEqual(vm.session?.countedRounds, 0, "not while running")
        vm.stop()
        vm.adjustRounds(by: 3)
        XCTAssertEqual(vm.session?.countedRounds, 3)
        vm.adjustRounds(by: -5)
        XCTAssertEqual(vm.session?.countedRounds, 0)
        vm.reset()
    }

    func testCountingARoundRemembersTheHintForEver() {
        let before = UserDefaults.standard.object(forKey: hintKey)
        UserDefaults.standard.removeObject(forKey: hintKey)
        defer { UserDefaults.standard.set(before, forKey: hintKey) }

        let vm = TimerViewModel()
        XCTAssertFalse(vm.hasCountedRound)
        vm.start(workout: amrap())
        Thread.sleep(forTimeInterval: 0.75)
        vm.countRound()
        XCTAssertEqual(vm.session?.countedRounds, 1)
        XCTAssertTrue(vm.hasCountedRound)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: hintKey))
        XCTAssertTrue(TimerViewModel().hasCountedRound, "read back on the next launch")
        vm.reset()
    }

    func testPauseAndResumeKeepATabataInItsPhase() {
        let vm = TimerViewModel()
        vm.start(workout: Workout(id: UUID(), name: "t", timerType: .standardTabata, prepCountdown: .zero, createdAt: Date()))
        vm.debugAdvance(seconds: 22)
        XCTAssertEqual(vm.phase, .resting)
        vm.pause()
        XCTAssertEqual(vm.phase, .paused)
        XCTAssertEqual(vm.session?.stateBeforePause, .resting)
        vm.resume()
        XCTAssertEqual(vm.phase, .resting)
        XCTAssertEqual(vm.session?.timeRemaining.seconds, 8)
        vm.reset()
    }

    func testTimeCapOnlyWhenTheClockRanOutOnAForTime() {
        let vm = TimerViewModel()
        let cap = Workout(id: UUID(), name: "t", timerType: .forTime(timeCap: TimerDuration(seconds: 30)), prepCountdown: .zero, createdAt: Date())
        vm.start(workout: cap)
        vm.debugAdvance(seconds: 10)
        vm.stop()
        XCTAssertFalse(vm.endedAtTimeCap, "stopped early, not capped")
        vm.reset()
        vm.start(workout: amrap(seconds: 5))
        vm.debugAdvance(seconds: 6)
        XCTAssertFalse(vm.endedAtTimeCap, "an AMRAP running out is a finish")
        vm.reset()
    }
}

// MARK: - Setup memory, recents and the voice settings store

final class SetupMemoryMoreTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "SetupMemoryMoreTests")
        defaults.removePersistentDomain(forName: "SetupMemoryMoreTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "SetupMemoryMoreTests")
        super.tearDown()
    }

    func testSummariesOfAFreshInstall() {
        let memory = SetupMemory(defaults: defaults)
        XCTAssertEqual(memory.summary("amrap"), "10:00")
        XCTAssertEqual(memory.summary("fortime"), "CAP 20:00 · UP")
        XCTAssertEqual(memory.summary("emom"), "10 × 1:00")
        XCTAssertEqual(memory.summary("tabata"), "8 × 20s / 10s")
    }

    func testTypeOfEachModeIsWhatWasSaved() {
        let memory = SetupMemory(defaults: defaults)
        XCTAssertEqual(memory.type("amrap"), .amrap(duration: TimerDuration(seconds: 600)))
        XCTAssertEqual(memory.type("fortime"), .forTime(timeCap: TimerDuration(seconds: 1200), countUp: true))
        XCTAssertEqual(memory.type("emom"), .emom(intervalDuration: TimerDuration(seconds: 60), rounds: RoundCount(value: 10)))
        XCTAssertEqual(memory.type("tabata"), .standardTabata)
        let saved = TimerType.forTime(timeCap: TimerDuration(seconds: 300), countUp: false)
        memory.save(saved)
        XCTAssertEqual(memory.type("fortime"), saved)
        XCTAssertEqual(memory.summary("fortime"), "CAP 5:00 · DOWN")
    }

    func testCorruptDataUnderAKeyReadsAsTheDefaultAndIsLeftAlone() {
        defaults.set(Data("not json".utf8), forKey: "watch_setup_emom")
        let memory = SetupMemory(defaults: defaults)
        XCTAssertEqual(memory.emom.interval.seconds, 60)
        XCTAssertEqual(memory.emom.rounds, 10)
        XCTAssertEqual(defaults.data(forKey: "watch_setup_emom"), Data("not json".utf8))
    }

    func testAModeNeverStartedSinceOneThreeFallsBackToItsNewestRecent() {
        let recents = RecentWorkoutsStore(defaults: defaults)
        recents.save(Workout(id: UUID(), name: "old", timerType: .amrap(duration: TimerDuration(seconds: 480)),
                             prepCountdown: .zero, createdAt: Date()))
        recents.save(Workout(id: UUID(), name: "older emom", timerType: .emom(intervalDuration: TimerDuration(seconds: 45), rounds: RoundCount(value: 8)),
                             prepCountdown: .zero, createdAt: Date()))
        let memory = SetupMemory(defaults: defaults)
        XCTAssertEqual(memory.amrap.seconds, 480)
        XCTAssertEqual(memory.emom.interval.seconds, 45)
        XCTAssertEqual(memory.emom.rounds, 8)
        XCTAssertEqual(memory.tabata.rounds, 8, "no recent Tabata: the default")
        // A save wins over the recents from then on.
        memory.save(.amrap(duration: TimerDuration(seconds: 900)))
        XCTAssertEqual(SetupMemory(defaults: defaults).amrap.seconds, 900)
    }
}

final class RecentWorkoutsStoreTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "RecentWorkoutsStoreTests")
        defaults.removePersistentDomain(forName: "RecentWorkoutsStoreTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "RecentWorkoutsStoreTests")
        super.tearDown()
    }

    private func workout(_ type: TimerType) -> Workout {
        Workout(id: UUID(), name: type.displayLabel, timerType: type, prepCountdown: .zero, createdAt: Date())
    }

    func testEmptyUntilSaved() {
        XCTAssertEqual(RecentWorkoutsStore(defaults: defaults).load(), [])
    }

    func testNewestFirstSameSetupDedupedAtMostThree() {
        let store = RecentWorkoutsStore(defaults: defaults)
        let a = workout(.amrap(duration: TimerDuration(seconds: 600)))
        let b = workout(.emom(intervalDuration: TimerDuration(seconds: 60), rounds: RoundCount(value: 10)))
        let c = workout(.standardTabata)
        let d = workout(.forTime(timeCap: TimerDuration(seconds: 1200)))
        store.save(a)
        store.save(b)
        XCTAssertEqual(store.load().map(\.timerType), [b.timerType, a.timerType])
        store.save(workout(a.timerType))
        XCTAssertEqual(store.load().map(\.timerType), [a.timerType, b.timerType], "the same setup moves to the front once")
        store.save(c)
        store.save(d)
        XCTAssertEqual(store.load().map(\.timerType), [d.timerType, c.timerType, a.timerType])
    }

    func testCorruptDataReadsAsEmpty() {
        defaults.set(Data("{oops".utf8), forKey: "recent_workouts")
        XCTAssertEqual(RecentWorkoutsStore(defaults: defaults).load(), [])
    }
}

final class WatchAudioSettingsTests: XCTestCase {
    private let keys = ["watch_voice_pack", "watch_voice_random", "watch_voice_muted", "watch_voice_beeps"]
    private var saved: [String: Any?] = [:]

    override func setUp() {
        super.setUp()
        for key in keys {
            saved[key] = UserDefaults.standard.object(forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    override func tearDown() {
        for key in keys {
            if let value = saved[key] ?? nil {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        super.tearDown()
    }

    func testAFreshInstallIsMajorWithVoiceOn() {
        let audio = WatchAudioService()
        XCTAssertEqual(audio.voicePack, .major)
        XCTAssertFalse(audio.randomizePerCue)
        XCTAssertFalse(audio.muted)
        XCTAssertFalse(audio.beepsOnly)
        XCTAssertEqual(audio.volume, 1)
    }

    func testEveryChoicePersistsAcrossLaunches() {
        let audio = WatchAudioService()
        audio.setVoicePack(.holly)
        audio.setRandomizePerCue(true)
        audio.setMuted(true)
        let again = WatchAudioService()
        XCTAssertEqual(again.voicePack, .holly)
        XCTAssertTrue(again.randomizePerCue)
        XCTAssertTrue(again.muted)
        again.setMuted(false)
        again.setRandomizePerCue(false)
        XCTAssertFalse(WatchAudioService().muted)
        XCTAssertFalse(WatchAudioService().randomizePerCue)
    }

    func testAnUnknownStoredPackReadsAsMajorAndIsLeftAlone() {
        UserDefaults.standard.set("siri", forKey: "watch_voice_pack")
        XCTAssertEqual(WatchAudioService().voicePack, .major)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "watch_voice_pack"), "siri")
    }

    func testVolumeClampsToTheUnitRange() {
        let audio = WatchAudioService()
        audio.setVolume(3)
        XCTAssertEqual(audio.volume, 1)
        audio.setVolume(-2)
        XCTAssertEqual(audio.volume, 0)
        audio.setVolume(0.4)
        XCTAssertEqual(audio.volume, 0.4, accuracy: 0.0001)
    }
}

// MARK: - Palette, geometry and the domain's small types

final class PaletteAndGeometryTests: XCTestCase {
    func testPaletteHasOneMeaningPerColour() {
        XCTAssertEqual(Palette.work, Color(hex: 0x00FF88))
        XCTAssertEqual(Palette.primary, Palette.work, "START is work green")
        XCTAssertEqual(Palette.rest, Color(hex: 0xFF0088))
        XCTAssertEqual(Palette.prepare, .white)
        XCTAssertEqual(Palette.brand, Palette.mode("fortime"))
        XCTAssertEqual(Palette.track, Color(hex: 0x24253A))
        XCTAssertEqual(Palette.soft, Color(hex: 0x16172A))
        XCTAssertEqual(Palette.stopInk, Color(hex: 0x1A0E14))
        XCTAssertEqual(Palette.error, Color(hex: 0xFF4444))
        XCTAssertEqual(Palette.wheelDim, Color(hex: 0x3A3D58))
        XCTAssertEqual(Palette.mode("yoga"), Palette.mode("tabata"), "unknown codes fall back to green")
    }

    func testBottomCapsulesAreInsetNotEdgeSlabs() {
        XCTAssertEqual(CapsuleGeometry.height, 44)
        XCTAssertEqual(CapsuleGeometry.startHeight, 48)
        XCTAssertEqual(CapsuleGeometry.sideMargin, 9)
        XCTAssertEqual(CapsuleGeometry.gap, 6)
        XCTAssertGreaterThanOrEqual(CapsuleGeometry.bottomMargin, 10)
        XCTAssertLessThanOrEqual(CapsuleGeometry.bottomMargin, 12)
    }

    func testBigClockWidthEstimateTreatsColonAndSlashAsNarrow() {
        XCTAssertEqual(BigClock.ems("10:00"), 4 * 0.64 + 0.34, accuracy: 0.0001)
        XCTAssertEqual(BigClock.ems("8/8"), 2 * 0.64 + 0.42, accuracy: 0.0001)
        XCTAssertEqual(BigClock.ems("55"), 1.28, accuracy: 0.0001)
        XCTAssertLessThan(BigClock.ems("9:45"), BigClock.ems("12:30"))
    }

    func testGlyphMetricsKnowTheSlashDescendsAndDigitsDoNot() {
        let slash = GlyphMetrics.descent(of: "2/10", size: 28, weight: .heavy)
        let digits = GlyphMetrics.descent(of: "2410", size: 28, weight: .heavy)
        XCTAssertGreaterThan(slash, 1)
        XCTAssertLessThan(digits, 1)
        XCTAssertGreaterThan(GlyphMetrics.baselineInset(size: 11, weight: .bold), 0)
        XCTAssertGreaterThan(GlyphMetrics.glyphInset(text: "ROUNDS", size: 11, weight: .bold), 0)
    }

    func testScoreSlotInsetIsSmallerWhenTheRoundSlashDescends() {
        let rounds = ScoreSlot.glyphInset(for: Workout.defaultEmom())
        let plain = ScoreSlot.glyphInset(for: Workout.defaultAmrap())
        XCTAssertLessThan(rounds, plain)
        XCTAssertEqual(ScoreSlot.glyphInset(for: Workout.defaultTabata()), rounds)
        XCTAssertEqual(ScoreSlot.glyphInset(for: Workout.defaultForTime()), plain)
        XCTAssertEqual(ScoreSlot.height, 30)
    }

    func testTimelineZoneAndSetupValueScaleWithTheScreen() {
        XCTAssertGreaterThan(TimelineZone<Color>.standardHeight, 0)
        XCTAssertEqual(TimelineZone<Color>.standardHeight, (WKInterfaceDevice.current().screenBounds.height * 0.1).rounded())
        let scaled = SetupValue.scaled(52)
        XCTAssertGreaterThanOrEqual(scaled, 31)
        XCTAssertLessThanOrEqual(scaled, 52)
        XCTAssertEqual(RoundsWheel.heroReference, "10:00")
    }
}

final class DomainTypesTests: XCTestCase {
    func testTimerTypeLabelsCodesAndTotals() {
        XCTAssertEqual(TimerType.standardTabata.displayLabel, "TABATA")
        XCTAssertEqual(TimerType.standardTabata.typeCode, "tabata")
        XCTAssertEqual(TimerType.standardTabata.estimatedDuration.seconds, 240)
        let emom = TimerType.emom(intervalDuration: TimerDuration(seconds: 90), rounds: RoundCount(value: 4))
        XCTAssertEqual(emom.displayLabel, "EMOM")
        XCTAssertEqual(emom.typeCode, "emom")
        XCTAssertEqual(emom.estimatedDuration.seconds, 360)
        let forTime = TimerType.forTime(timeCap: TimerDuration(seconds: 1200))
        XCTAssertEqual(forTime.displayLabel, "FOR TIME")
        XCTAssertEqual(forTime.typeCode, "fortime")
        XCTAssertEqual(forTime.estimatedDuration.seconds, 1200)
        let amrap = TimerType.amrap(duration: TimerDuration(seconds: 600))
        XCTAssertEqual(amrap.displayLabel, "AMRAP")
        XCTAssertEqual(amrap.typeCode, "amrap")
        XCTAssertEqual(amrap.estimatedDuration.seconds, 600)
    }

    func testWorkoutTotalsRestAndRounds() {
        let tabata = Workout.defaultTabata()
        XCTAssertEqual(tabata.totalDuration.seconds, 250)
        XCTAssertTrue(tabata.hasRestPeriods)
        XCTAssertTrue(tabata.isIntervalBased)
        XCTAssertEqual(tabata.roundCount, 8)
        XCTAssertEqual(tabata.timerTypeLabel, "TABATA")
        let amrap = Workout.defaultAmrap()
        XCTAssertEqual(amrap.totalDuration.seconds, 610)
        XCTAssertFalse(amrap.hasRestPeriods)
        XCTAssertNil(amrap.roundCount)
        XCTAssertEqual(Workout.defaultEmom().roundCount, 10)
        XCTAssertNil(Workout.defaultForTime().roundCount)
        XCTAssertEqual(WorkoutFactory.create(timerType: .standardTabata).prepCountdown.seconds, 10)
        XCTAssertEqual(WorkoutFactory.create(timerType: .standardTabata, prepCountdown: .zero).name, "TABATA")
    }

    func testTimerStateFlagsAndLabels() {
        XCTAssertTrue(TimerState.ready.canStart)
        XCTAssertFalse(TimerState.running.canStart)
        for active in [TimerState.preparing, .running, .resting] {
            XCTAssertTrue(active.isActive)
            XCTAssertTrue(active.canPause)
            XCTAssertFalse(active.canResume)
        }
        for idle in [TimerState.ready, .paused, .completed] {
            XCTAssertFalse(idle.isActive)
            XCTAssertFalse(idle.canPause)
        }
        XCTAssertTrue(TimerState.paused.canResume)
        XCTAssertTrue(TimerState.completed.isFinished)
        XCTAssertEqual(TimerState.preparing.displayLabel, "Get Ready")
        XCTAssertEqual(TimerState.completed.displayLabel, "Complete")
    }

    func testTimerErrorMessages() {
        XCTAssertEqual(TimerError.invalidStateTransition(from: .ready, to: .paused).message, "Cannot transition from Ready to Paused")
        XCTAssertEqual(TimerError.timerNotActive.message, "Timer is not active")
        XCTAssertEqual(TimerError.alreadyCompleted.message, "Workout is already completed")
    }
}


// MARK: - 2.1.0 gym-timer beeps

/// The schedule, second by second, through the real view model and audio
/// service: low beeps with 3, 2, 1 seconds left in every phase, then the high
/// beep with the voice line on it. Mirrors the phone's timer_cues_test.
final class GymBeepScheduleTests: XCTestCase {
    private let keys = ["watch_voice_pack", "watch_voice_random", "watch_voice_muted", "watch_voice_beeps"]
    private var saved: [String: Any?] = [:]

    override func setUp() {
        super.setUp()
        for key in keys {
            saved[key] = UserDefaults.standard.object(forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    override func tearDown() {
        for key in keys {
            if let value = saved[key] ?? nil {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        super.tearDown()
    }

    private func workout(_ type: TimerType, prep: Int = 0) -> Workout {
        Workout(id: UUID(), name: "Test", timerType: type, prepCountdown: TimerDuration(seconds: prep),
                createdAt: Date())
    }

    /// Runs [type] tick by tick to its end and returns what was heard, with
    /// the random picks folded to one name each.
    private func heard(_ type: TimerType, prep: Int = 0, beepsOnly: Bool = false,
                       ticks: ((TimerViewModel, Int) -> Void)? = nil) -> [String] {
        let vm = TimerViewModel()
        vm.audio.setBeepsOnly(beepsOnly)
        vm.start(workout: workout(type, prep: prep))
        let total = prep + type.estimatedDuration.seconds
        for s in 1 ... total {
            vm.debugTick(elapsed: TimeInterval(s))
            ticks?(vm, s)
        }
        XCTAssertEqual(vm.phase, .completed)
        defer { vm.reset() }
        return vm.audio.cueLog.map {
            $0.replacingOccurrences(of: "lets_go", with: "countdown_go")
                .replacingOccurrences(of: "come_on", with: "keep_going")
                .replacingOccurrences(of: "thats_it", with: "good_job")
        }
    }

    private let countIn = ["beep:low_3", "beep:low_2", "beep:low_1", "beep:high"]

    func testAmrapCountsInToTheEndAndKeepsTheOptionalLinesClear() {
        XCTAssertEqual(heard(.amrap(duration: TimerDuration(seconds: 60))),
                       ["beep:high", "voice:countdown_go", "voice:keep_going", "voice:halfway",
                        "voice:ten_seconds"] + countIn + ["voice:good_job"])
    }

    func testThePrepCountdownIsLowBeepsThenGoOnTheHighBeep() {
        XCTAssertEqual(Array(heard(.amrap(duration: TimerDuration(seconds: 60)), prep: 10).prefix(6)),
                       ["voice:get_ready"] + countIn + ["voice:countdown_go"])
    }

    func testEmomCountsInToEveryMinute() {
        var expected: [String] = ["beep:high", "voice:countdown_go"]
        expected += countIn
        expected += ["voice:next_round", "voice:halfway"]
        expected += countIn
        expected += ["voice:last_round", "voice:almost_there", "voice:ten_seconds"]
        expected += countIn
        expected += ["voice:good_job"]
        let emom = TimerType.emom(intervalDuration: TimerDuration(seconds: 60), rounds: RoundCount(value: 3))
        XCTAssertEqual(heard(emom), expected)
    }

    func testTabataCountsInToEveryWorkAndRest() {
        var expected: [String] = ["beep:high", "voice:countdown_go"]
        for line in ["voice:rest", "voice:last_round", "voice:rest", "voice:good_job"] {
            expected += countIn
            expected.append(line)
        }
        let tabata = TimerType.tabata(workDuration: TimerDuration(seconds: 20),
                                      restDuration: TimerDuration(seconds: 10), rounds: RoundCount(value: 2))
        XCTAssertEqual(heard(tabata), expected)
    }

    func testACappedForTimeEndsOnTheHighBeepWithTheNeutralLine() {
        XCTAssertEqual(heard(.forTime(timeCap: TimerDuration(seconds: 60))).suffix(5),
                       countIn + ["voice:complete"])
    }

    func testBeepsOnlyKeepsEveryBeepAndDropsEveryLine() {
        let tabata = TimerType.tabata(workDuration: TimerDuration(seconds: 20), restDuration: TimerDuration(seconds: 10),
                                      rounds: RoundCount(value: 2))
        XCTAssertEqual(heard(tabata, prep: 10, beepsOnly: true),
                       countIn + countIn + countIn + countIn + countIn)
    }

    func testShortPhasesSkipTheBeepsTheyStartOn() {
        let beeps = heard(.tabata(workDuration: TimerDuration(seconds: 3), restDuration: TimerDuration(seconds: 2),
                                  rounds: RoundCount(value: 1)))
            .filter { $0.hasPrefix("beep:") }
        XCTAssertEqual(beeps, ["beep:high", "beep:low_2", "beep:low_1", "beep:high", "beep:low_1", "beep:high"])
    }

    func testFinishIsTheHighBeepWithTheEncouragement() {
        let vm = TimerViewModel()
        vm.start(workout: workout(.forTime(timeCap: TimerDuration(seconds: 600))))
        for s in 1 ... 30 { vm.debugTick(elapsed: TimeInterval(s)) }
        vm.finish()
        XCTAssertEqual(vm.audio.cueLog.suffix(2).first, "beep:high")
        XCTAssertTrue(["voice:good_job", "voice:thats_it"].contains(vm.audio.cueLog.last ?? ""))
        vm.reset()
    }
}
