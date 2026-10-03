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

/// 1.3.1: Beeps only mirrors the phone's beep-fallback cues.
final class BeepsOnlyTests: XCTestCase {
    func testTimingCuesBeepAndEncouragementStaysQuiet() {
        for cue in ["countdown_3", "countdown_go", "rest", "last_round", "next_round", "ten_seconds"] {
            XCTAssertTrue(WatchAudioService.beepCues.contains(cue), cue)
        }
        for cue in ["halfway", "keep_going", "good_job", "come_on", "almost_there", "thats_it"] {
            XCTAssertFalse(WatchAudioService.beepCues.contains(cue), cue)
        }
    }

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
                         "live-prep", "live-fortime", "live-emom", "live-amrap",
                         "live-tabata-work", "live-tabata-rest", "live-tabata-next",
                         "paused-fortime", "paused-emom", "paused-amrap", "paused-tabata",
                         "finished-fortime", "timecap-fortime", "finished-emom", "stopped-emom",
                         "finished-amrap", "stopped-amrap", "finished-tabata", "stopped-tabata"] {
            XCTAssertTrue(names.contains(required), "missing capture scene \(required)")
        }
    }
}
