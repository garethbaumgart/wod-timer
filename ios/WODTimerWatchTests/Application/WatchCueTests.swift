import AVFoundation
import HealthKit
import WatchKit
import XCTest
@testable import WODTimerWatch

// 2.2.0: the wrist cues, the workout-session hooks and the bundle
// declarations that keep the watch app running off screen.

private final class SpyTracker: WorkoutTracking {
    var calls: [String] = []
    var status: HealthWorkoutTracker.Status = .running {
        didSet { onStatusChange?(status) }
    }
    var onStatusChange: ((HealthWorkoutTracker.Status) -> Void)?
    func begin(_ workout: Workout) { calls.append("begin:\(workout.timerType.typeCode)") }
    func go() { calls.append("go") }
    func pause() { calls.append("pause") }
    func resume() { calls.append("resume") }
    func end(keep: Bool) { calls.append(keep ? "end:keep" : "end:discard") }
}

private func makeViewModel() -> (TimerViewModel, SpyTracker, WatchHapticService) {
    let tracker = SpyTracker()
    // The scheduler runs pattern tails at once, so the log holds whole patterns.
    let haptics = WatchHapticService(player: { _ in }, scheduler: { _, work in work() })
    return (TimerViewModel(tracker: tracker, haptics: haptics), tracker, haptics)
}

private func workout(_ type: TimerType, prep: Int = 0) -> Workout {
    Workout(id: UUID(), name: "t", timerType: type, prepCountdown: TimerDuration(seconds: prep), createdAt: Date())
}

private func names(_ cue: WatchHapticService.Cue) -> [String] {
    WatchHapticService.pattern(cue).map { WatchHapticService.name($0.type) }
}

/// Drives the real tick path (debugAdvance skips the cues) in 100ms steps.
private func tick(_ vm: TimerViewModel, from: Double, to: Double) {
    var step = Int((from * 10).rounded())
    let last = Int((to * 10).rounded())
    while step < last {
        step += 1
        vm.debugTick(elapsed: Double(step) / 10)
    }
}

final class WristCueTests: XCTestCase {
    func testPatternsLeadWithTheFirmestHapticAndLeaveTheEngineRoom() {
        XCTAssertEqual(names(.go), ["notification", "notification"])
        XCTAssertEqual(names(.lastRound), ["notification", "notification", "notification"])
        XCTAssertEqual(names(.roundChange).first, "notification")
        XCTAssertEqual(names(.workToRest), ["notification", "directionDown"])
        XCTAssertEqual(names(.countIn), ["start"])
        XCTAssertEqual(names(.complete).first, "success")
        for cue in WatchHapticService.Cue.allCases {
            let times = WatchHapticService.pattern(cue).map(\.at)
            XCTAssertEqual(times.first, 0, "\(cue) starts at once")
            for (a, b) in zip(times, times.dropFirst()) {
                XCTAssertGreaterThanOrEqual(b - a, 0.4, "\(cue) spaces its taps")
            }
        }
    }

    func testANewCueDropsTheTailOfTheOneBefore() {
        var pending: [() -> Void] = []
        let haptics = WatchHapticService(player: { _ in }, scheduler: { _, work in pending.append(work) })
        haptics.play(.go)
        XCTAssertEqual(haptics.log, ["notification"])
        haptics.play(.tap)
        pending.forEach { $0() }
        XCTAssertEqual(haptics.log, ["notification", "click"], "GO's second knock never lands after a tap")
        pending.removeAll()
        haptics.play(.go)
        haptics.cancelPending()
        pending.forEach { $0() }
        XCTAssertEqual(haptics.log, ["notification", "click", "notification"])
    }

    func testStartOpensTheSessionAndGoStartsTheWorkoutWithADoubleKnock() {
        let (vm, tracker, haptics) = makeViewModel()
        vm.start(workout: workout(.amrap(duration: TimerDuration(seconds: 600)), prep: 5))
        XCTAssertEqual(tracker.calls, ["begin:amrap"])
        tick(vm, from: 0, to: 4.5)
        // 3, 2, 1 of get ready on the wrist: firm single taps.
        XCTAssertEqual(haptics.log, ["start", "start", "start"])
        tick(vm, from: 4.5, to: 5.1)
        XCTAssertEqual(vm.phase, .running)
        XCTAssertEqual(tracker.calls, ["begin:amrap", "go"])
        XCTAssertEqual(Array(haptics.log.suffix(2)), ["notification", "notification"])
        vm.reset()
        XCTAssertEqual(tracker.calls.last, "end:discard")
    }

    func testEmomRoundsReachTheWristAndTheLastRoundKnocksThreeTimes() {
        let (vm, tracker, haptics) = makeViewModel()
        vm.start(workout: workout(.emom(intervalDuration: TimerDuration(seconds: 5), rounds: RoundCount(value: 3))))
        XCTAssertEqual(tracker.calls, ["begin:emom", "go"], "no get ready: the workout starts at START")
        XCTAssertEqual(haptics.log, ["notification", "notification"])
        tick(vm, from: 0, to: 4.9)
        XCTAssertEqual(Array(haptics.log.suffix(3)), ["start", "start", "start"], "3, 2, 1 before the round")
        tick(vm, from: 4.9, to: 5.0)
        XCTAssertEqual(vm.session?.currentRound, 2)
        XCTAssertEqual(Array(haptics.log.suffix(2)), ["notification", "directionUp"])
        tick(vm, from: 5.0, to: 10.0)
        XCTAssertEqual(vm.session?.currentRound, 3)
        XCTAssertEqual(Array(haptics.log.suffix(3)), ["notification", "notification", "notification"])
        tick(vm, from: 10.0, to: 15.0)
        XCTAssertEqual(vm.phase, .completed)
        XCTAssertEqual(tracker.calls.last, "end:keep")
        XCTAssertEqual(Array(haptics.log.suffix(2)), ["success", "notification"])
    }

    func testATabataRoundStartIsOneWristCueNotTwo() {
        let (vm, _, haptics) = makeViewModel()
        vm.start(workout: workout(.tabata(
            workDuration: TimerDuration(seconds: 4), restDuration: TimerDuration(seconds: 3), rounds: RoundCount(value: 2)
        )))
        tick(vm, from: 0, to: 4.0)
        XCTAssertEqual(vm.phase, .resting)
        XCTAssertEqual(Array(haptics.log.suffix(2)), ["notification", "directionDown"])
        tick(vm, from: 4.0, to: 6.9)
        XCTAssertEqual(Array(haptics.log.suffix(2)), ["start", "start"], "a 3s rest counts 2, 1")
        let before = haptics.log.count
        tick(vm, from: 6.9, to: 7.0)
        XCTAssertEqual(vm.phase, .running)
        XCTAssertEqual(vm.session?.currentRound, 2)
        XCTAssertEqual(
            Array(haptics.log.dropFirst(before)), ["notification", "notification", "notification"],
            "round 2 of 2 is the last round; rest-to-work adds nothing on top"
        )
    }

    func testPauseResumeStopAndFinishReachTheSessionAndTheWrist() {
        let (vm, tracker, haptics) = makeViewModel()
        vm.start(workout: workout(.forTime(timeCap: TimerDuration(seconds: 600))))
        vm.pause()
        XCTAssertEqual(tracker.calls.last, "pause")
        XCTAssertEqual(haptics.log.last, "stop")
        vm.resume()
        XCTAssertEqual(tracker.calls.last, "resume")
        XCTAssertEqual(haptics.log.last, "start")
        vm.debugAdvance(seconds: 20)
        vm.stop()
        XCTAssertEqual(tracker.calls.last, "end:discard", "a stop in the first minute is a false start")

        let (long, longTracker, _) = makeViewModel()
        long.start(workout: workout(.forTime(timeCap: TimerDuration(seconds: 600))))
        long.debugAdvance(seconds: 90)
        long.stop()
        XCTAssertEqual(longTracker.calls.last, "end:keep")

        let (done, doneTracker, doneHaptics) = makeViewModel()
        done.start(workout: workout(.forTime(timeCap: TimerDuration(seconds: 600))))
        done.debugAdvance(seconds: 30)
        done.finish()
        XCTAssertEqual(doneTracker.calls.last, "end:keep")
        XCTAssertEqual(Array(doneHaptics.log.suffix(2)), ["success", "notification"])

        let (prep, prepTracker, _) = makeViewModel()
        prep.start(workout: workout(.amrap(duration: TimerDuration(seconds: 600)), prep: 10))
        prep.cancelPrep()
        XCTAssertEqual(prepTracker.calls, ["begin:amrap", "end:discard"])
    }

    func testTheClockKeepsWholeMillisecondsAcrossTicks() {
        // 100.7ms ticks for ten minutes. Truncating each delta lost 0.7ms a
        // tick, so a 10:00 AMRAP ran about four seconds long.
        let (vm, _, _) = makeViewModel()
        vm.start(workout: workout(.amrap(duration: TimerDuration(seconds: 1200))))
        for i in 1 ... 6000 { vm.debugTick(elapsed: Double(i) * 0.1007) }
        XCTAssertEqual(vm.session?.elapsed.seconds, 604)
    }
}

// 2.5.0: the mid-round pips. Two quick pips halfway through every EMOM
// interval, Tabata work block and AMRAP / For Time clock of 10s or more,
// with no setting: Beeps only keeps them, only Silent stops them. Mirrors
// the phone's timer_cues_test.
final class MidRoundPipTests: XCTestCase {
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

    /// A view model with the voice on (or Beeps only), never Silent.
    private func pipViewModel(beepsOnly: Bool = false) -> (TimerViewModel, WatchHapticService) {
        let (vm, _, haptics) = makeViewModel()
        vm.audio.setMuted(false)
        vm.audio.setBeepsOnly(beepsOnly)
        return (vm, haptics)
    }

    private func pipCount(_ vm: TimerViewModel) -> Int {
        vm.audio.cueLog.filter { $0 == "beep:mid" }.count
    }

    private func halfwayTaps(_ haptics: WatchHapticService) -> Int {
        haptics.log.filter { $0 == "retry" }.count
    }

    /// Ticks in 100ms steps and notes each pip as "state:round:secondsLeft".
    private func pipMoments(_ vm: TimerViewModel, from: Double, to: Double) -> [String] {
        var moments: [String] = []
        var step = Int((from * 10).rounded())
        let last = Int((to * 10).rounded())
        while step < last {
            step += 1
            let before = pipCount(vm)
            vm.debugTick(elapsed: Double(step) / 10)
            if pipCount(vm) > before, let session = vm.session {
                moments.append("\(session.state):\(session.currentRound):\(session.timeRemaining.seconds)")
            }
        }
        return moments
    }

    /// Starts [type] and runs it to its end, returning the pips.
    private func pipsThrough(_ type: TimerType, prep: Int = 0) -> [String] {
        let (vm, _) = pipViewModel()
        vm.start(workout: workout(type, prep: prep))
        let moments = pipMoments(vm, from: 0, to: Double(prep + type.estimatedDuration.seconds))
        XCTAssertEqual(vm.phase, .completed)
        return moments
    }

    private func emom(_ interval: Int, _ rounds: Int) -> TimerType {
        .emom(intervalDuration: TimerDuration(seconds: interval), rounds: RoundCount(value: rounds))
    }

    private func tabata(_ work: Int, _ rest: Int, _ rounds: Int) -> TimerType {
        .tabata(workDuration: TimerDuration(seconds: work), restDuration: TimerDuration(seconds: rest),
                rounds: RoundCount(value: rounds))
    }

    func testAnEmomPipsOnceARoundAtHalfTheMinuteAndNeverInGetReady() {
        let (vm, haptics) = pipViewModel()
        // A 20s get ready is long enough to pip, and must not.
        vm.start(workout: workout(emom(60, 3), prep: 20))
        XCTAssertEqual(pipMoments(vm, from: 0, to: 20), [], "no pips in the get-ready countdown")
        XCTAssertEqual(pipMoments(vm, from: 20, to: 200), ["running:1:30", "running:2:30", "running:3:30"])
        XCTAssertEqual(vm.phase, .completed)
        XCTAssertEqual(halfwayTaps(haptics), 3, "round 2's pips are also the workout's halfway: one tap, not two")
        XCTAssertTrue(vm.audio.cueLog.contains("voice:halfway"), "the spoken Halfway still plays")
    }

    func testAFifteenSecondIntervalPipsAtSevenLeft() {
        XCTAssertEqual(pipsThrough(emom(15, 2)), ["running:1:7", "running:2:7"])
    }

    func testATabataPipsOnceAWorkBlockAndNeverInARest() {
        XCTAssertEqual(pipsThrough(tabata(20, 10, 3)), ["running:1:10", "running:2:10", "running:3:10"])
    }

    func testAPhaseUnderTenSecondsNeverPips() {
        XCTAssertEqual(pipsThrough(tabata(5, 10, 2)), [], "a 5s work block is too short; a 10s rest is a rest")
        XCTAssertEqual(pipsThrough(emom(9, 2)), [])
        XCTAssertEqual(pipsThrough(.amrap(duration: TimerDuration(seconds: 9))), [])
        XCTAssertEqual(pipsThrough(emom(10, 1)), ["running:1:5"], "10s is the shortest phase that pips")
    }

    func testAnAmrapOrForTimePipsOnceAtHalfTimeWithOneHalfwayTap() {
        for type in [TimerType.amrap(duration: TimerDuration(seconds: 600)), .forTime(timeCap: TimerDuration(seconds: 600))] {
            let (vm, haptics) = pipViewModel()
            vm.start(workout: workout(type))
            XCTAssertEqual(pipMoments(vm, from: 0, to: 299.9), [], "\(type)")
            let heard = vm.audio.cueLog.count
            let felt = haptics.log.count
            XCTAssertEqual(pipMoments(vm, from: 299.9, to: 300), ["running:1:300"], "\(type)")
            XCTAssertEqual(Array(vm.audio.cueLog.dropFirst(heard)), ["beep:mid", "voice:halfway"],
                           "\(type): the pips, with the optional line on them")
            XCTAssertEqual(Array(haptics.log.dropFirst(felt)), ["retry"], "\(type): one halfway tap on the tick")
            XCTAssertEqual(pipMoments(vm, from: 300, to: 600), [], "\(type)")
            XCTAssertEqual(vm.phase, .completed)
            XCTAssertEqual(halfwayTaps(haptics), 1, "\(type)")
        }
    }

    func testAnAmrapTallyNeverRearmsThePips() {
        let (vm, _) = pipViewModel()
        vm.start(workout: workout(.amrap(duration: TimerDuration(seconds: 60))))
        XCTAssertEqual(pipMoments(vm, from: 0, to: 30), ["running:1:30"])
        // A round counted on the midpoint: the tally is the athlete's, not a phase.
        vm.debugCountRounds(1)
        XCTAssertEqual(pipMoments(vm, from: 30, to: 60), [])
    }

    func testBeepsOnlyStillPipsAndSilentPipsNothing() {
        let (beeps, _) = pipViewModel(beepsOnly: true)
        beeps.start(workout: workout(emom(60, 2)))
        XCTAssertEqual(pipMoments(beeps, from: 0, to: 120), ["running:1:30", "running:2:30"])
        XCTAssertFalse(beeps.audio.cueLog.contains { $0.hasPrefix("voice:") })

        let (silent, haptics) = pipViewModel()
        silent.audio.setMuted(true)
        silent.start(workout: workout(emom(60, 2)))
        tick(silent, from: 0, to: 120)
        XCTAssertEqual(silent.phase, .completed)
        XCTAssertEqual(silent.audio.cueLog, [], "Silent plays nothing, pips included")
        XCTAssertEqual(halfwayTaps(haptics), 2, "the wrist still feels the moment, as it does the 3, 2, 1")
    }

    func testATickFarPastTheMidpointStaysQuietButASkippedTickStillPips() {
        // The watch slept from 28s to 32s: the next tick reads 28 left, past 30 and 29.
        let (vm, _) = pipViewModel()
        vm.start(workout: workout(emom(60, 2)))
        tick(vm, from: 0, to: 28)
        vm.debugTick(elapsed: 32)
        XCTAssertEqual(pipCount(vm), 0, "never late")
        XCTAssertEqual(pipMoments(vm, from: 32, to: 120), ["running:2:30"], "the next round still pips")

        // One skipped tick (31 left, then 29): the pips land a second late.
        let (skip, _) = pipViewModel()
        skip.start(workout: workout(emom(60, 1)))
        tick(skip, from: 0, to: 29)
        XCTAssertEqual(pipCount(skip), 0)
        skip.debugTick(elapsed: 31)
        XCTAssertEqual(pipCount(skip), 1)

        // A long suspension across rounds lands in round 3 with 25 left.
        let (asleep, _) = pipViewModel()
        asleep.start(workout: workout(emom(60, 3)))
        tick(asleep, from: 0, to: 10)
        asleep.debugTick(elapsed: 155)
        XCTAssertEqual(asleep.session?.currentRound, 3)
        XCTAssertEqual(pipMoments(asleep, from: 155, to: 180), [])
        XCTAssertEqual(pipCount(asleep), 0)

        // An AMRAP woken past its halfway never pips.
        let (amrap, _) = pipViewModel()
        amrap.start(workout: workout(.amrap(duration: TimerDuration(seconds: 600))))
        tick(amrap, from: 0, to: 290)
        amrap.debugTick(elapsed: 302)
        XCTAssertEqual(pipMoments(amrap, from: 302, to: 600), [])
        XCTAssertEqual(pipCount(amrap), 0)
    }

    func testPausedAtTheMidpointNeverPipsAndResumingPastItNeverPipsLate() {
        let (vm, _) = pipViewModel()
        vm.start(workout: workout(.amrap(duration: TimerDuration(seconds: 60))))
        tick(vm, from: 0, to: 29)
        vm.pause()
        // Paused, the clock stands at 31 left while the minutes go by.
        tick(vm, from: 29, to: 40)
        XCTAssertEqual(vm.session?.timeRemaining.seconds, 31)
        XCTAssertEqual(pipCount(vm), 0)
        vm.resume()
        // The first tick after the resume lands at 27 left.
        vm.debugTick(elapsed: 44)
        XCTAssertEqual(vm.session?.timeRemaining.seconds, 27)
        XCTAssertEqual(pipMoments(vm, from: 44, to: 80), [])
        XCTAssertEqual(vm.phase, .completed)
        XCTAssertEqual(pipCount(vm), 0)

        // A pause before the midpoint moves it with the clock: on time, not late.
        let (paused, _) = pipViewModel()
        paused.start(workout: workout(.amrap(duration: TimerDuration(seconds: 60))))
        tick(paused, from: 0, to: 29)
        paused.pause()
        paused.resume()
        XCTAssertEqual(pipMoments(paused, from: 29, to: 31), ["running:1:30"])
    }

    func testANewWorkoutPipsAgain() {
        let (vm, _) = pipViewModel()
        vm.start(workout: workout(emom(20, 1)))
        XCTAssertEqual(pipMoments(vm, from: 0, to: 20), ["running:1:10"])
        vm.restart()
        XCTAssertEqual(pipMoments(vm, from: 0, to: 12), ["running:1:10"], "a restart re-arms the pips")
        vm.reset()
        vm.start(workout: workout(emom(20, 1)))
        XCTAssertEqual(pipMoments(vm, from: 0, to: 12), ["running:1:10"], "and so does a new workout")
    }
}

final class HealthTrackerTests: XCTestCase {
    private func freshDefaults() -> (UserDefaults, () -> Void) {
        let suite = "watch-cue-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return (defaults, { defaults.removePersistentDomain(forName: suite) })
    }

    func testTrackingIsOnUntilTurnedOffAndTheChoicePersists() {
        let (defaults, cleanup) = freshDefaults()
        defer { cleanup() }
        XCTAssertTrue(HealthWorkoutTracker(defaults: defaults).enabled, "a missing key reads as on")
        HealthWorkoutTracker(defaults: defaults).setEnabled(false)
        XCTAssertFalse(HealthWorkoutTracker(defaults: defaults).enabled)
    }

    func testTabataIsIntervalTrainingTheRestFunctionalStrength() {
        XCTAssertEqual(HealthWorkoutTracker.activityType(for: .standardTabata), .highIntensityIntervalTraining)
        XCTAssertEqual(
            HealthWorkoutTracker.activityType(for: .amrap(duration: TimerDuration(seconds: 600))),
            .functionalStrengthTraining
        )
        XCTAssertEqual(
            HealthWorkoutTracker.activityType(for: .emom(intervalDuration: TimerDuration(seconds: 60), rounds: RoundCount(value: 10))),
            .functionalStrengthTraining
        )
        XCTAssertEqual(
            HealthWorkoutTracker.activityType(for: .forTime(timeCap: TimerDuration(seconds: 1200))),
            .functionalStrengthTraining
        )
    }

    func testAnOffSwitchNeverOpensASession() {
        let (defaults, cleanup) = freshDefaults()
        defer { cleanup() }
        let tracker = HealthWorkoutTracker(defaults: defaults)
        tracker.setEnabled(false)
        tracker.begin(Workout.defaultAmrap())
        XCTAssertEqual(tracker.status, .off)
        tracker.go()
        tracker.end(keep: true)
        XCTAssertEqual(tracker.status, .off)
    }

    func testTheDefaultTrackerUnderTestsDoesNothing() {
        XCTAssertTrue(TimerViewModel.defaultTracker() is NoopWorkoutTracker)
    }
}

final class WatchBundleTests: XCTestCase {
    func testTheWatchAppDeclaresTheBackgroundModesAndHealthStrings() {
        let info = Bundle.main.infoDictionary ?? [:]
        // WKBackgroundModes takes only session types; background audio is
        // UIBackgroundModes, as on iOS (App Store validation rejects "audio"
        // under WKBackgroundModes).
        let sessions = info["WKBackgroundModes"] as? [String] ?? []
        XCTAssertEqual(sessions, ["workout-processing"], "the workout session needs it, and nothing else belongs here")
        let background = info["UIBackgroundModes"] as? [String] ?? []
        XCTAssertTrue(background.contains("audio"), "cues in the background need it")
        XCTAssertFalse((info["NSHealthUpdateUsageDescription"] as? String ?? "").isEmpty)
        XCTAssertFalse((info["NSHealthShareUsageDescription"] as? String ?? "").isEmpty)
    }

    func testTheAudioSessionIsPlaybackAndTheSoundCheckIsABeepWithALine() {
        let audio = WatchAudioService()
        XCTAssertNil(audio.sessionProblem)
        XCTAssertEqual(AVAudioSession.sharedInstance().category, .playback)
        let muted = audio.muted
        let beeps = audio.beepsOnly
        audio.setMuted(false)
        audio.setBeepsOnly(false)
        audio.playSoundCheck()
        XCTAssertEqual(Array(audio.cueLog.suffix(2)), ["beep:high", "voice:lets_go"])
        XCTAssertTrue(audio.outputDescription.contains("volume"))
        audio.setMuted(muted)
        audio.setBeepsOnly(beeps)
    }
}

// 2.2.1: the screen draws the clock for each frame's own moment, and the
// engine ticks once a second on the turns of the clock. With the wrist
// down, Always On draws frames ahead of time; drawn from the last tick,
// the clock stood on one number for seconds, then jumped (Gareth's Ultra,
// 15 Oct 2026).
final class WatchClockTests: XCTestCase {
    func testAFrameDrawnAheadReadsWhatTheTicksWillRead() {
        for workout in [Workout.defaultForTime(), .defaultEmom(), .defaultAmrap(), .defaultTabata()] {
            var base = TimerSession.fromWorkout(workout)
            _ = base.start()
            var ticked = base
            let end = (workout.prepCountdown.seconds + workout.timerType.estimatedDuration.seconds + 2) * 1000
            for ms in stride(from: 250, through: end, by: 250) {
                if case let .success(next) = ticked.tick(deltaMs: 250) { ticked = next }
                let frame = base.projected(byMs: ms)
                let at = "\(workout.timerType.typeCode) at \(ms)ms"
                XCTAssertEqual(LiveRules.clockText(frame), LiveRules.clockText(ticked), at)
                XCTAssertEqual(frame.state, ticked.state, at)
                XCTAssertEqual(frame.currentRound, ticked.currentRound, at)
            }
            XCTAssertEqual(base.state, .preparing, "projecting leaves the session alone")
        }
    }

    func testAPausedOrFinishedSessionProjectsToItself() {
        var session = TimerSession.fromWorkout(workout(.amrap(duration: TimerDuration(seconds: 60))))
        _ = session.start()
        _ = session.tick(deltaMs: 3000)
        _ = session.pause()
        XCTAssertEqual(session.projected(byMs: 30000), session)
        _ = session.resume()
        XCTAssertEqual(session.projected(byMs: -500), session, "a frame before the last tick shows the last tick")
        _ = session.complete()
        XCTAssertEqual(session.projected(byMs: 30000), session)
    }

    func testTheScreenShowsTheClockForTheFramesMoment() throws {
        let (vm, _, _) = makeViewModel()
        vm.start(workout: workout(.amrap(duration: TimerDuration(seconds: 60))))
        let origin = try XCTUnwrap(vm.clockOrigin)
        func shown(_ seconds: Double) -> String? {
            vm.displaySession(at: origin.addingTimeInterval(seconds)).map(LiveRules.clockText)
        }
        XCTAssertEqual(shown(5.5), "55")
        vm.debugTick(elapsed: 3)
        XCTAssertEqual(shown(5.5), "55", "a tick in between changes no frame")
        XCTAssertEqual(shown(49.2), "11")
        XCTAssertEqual(shown(59.9), "1")
        XCTAssertEqual(shown(75), "0")

        vm.pause()
        XCTAssertNil(vm.clockOrigin)
        XCTAssertEqual(
            vm.displaySession(at: Date().addingTimeInterval(30)).map(LiveRules.clockText), "57",
            "paused, every frame shows the paused clock"
        )
        vm.resume()
        XCTAssertNotNil(vm.clockOrigin)
        vm.stop()
        XCTAssertNil(vm.clockOrigin)
    }

    func testATickBehindTheLastOneAddsNothing() {
        let (vm, _, _) = makeViewModel()
        vm.start(workout: workout(.amrap(duration: TimerDuration(seconds: 600))))
        vm.debugTick(elapsed: 5)
        vm.debugTick(elapsed: 4.9)
        XCTAssertEqual(vm.session?.elapsed.seconds, 5)
        XCTAssertEqual(vm.session?.elapsedMillis, 0)
        vm.debugTick(elapsed: 6.2)
        XCTAssertEqual(vm.session?.elapsed.seconds, 6)
        XCTAssertEqual(vm.session?.elapsedMillis, 200)
    }

    func testTheEngineAimsJustPastEachTurnOfTheClock() {
        XCTAssertEqual(TimerEngine.delayToNextTick(after: 0), 1.005, accuracy: 1e-9)
        XCTAssertEqual(TimerEngine.delayToNextTick(after: 4.005), 1.0, accuracy: 1e-9)
        XCTAssertEqual(TimerEngine.delayToNextTick(after: 4.6), 0.405, accuracy: 1e-9)
        XCTAssertEqual(TimerEngine.delayToNextTick(after: 3.998), 0.007, accuracy: 1e-9, "a hair early aims at the turn it missed")
        XCTAssertEqual(TimerEngine.delayToNextTick(after: 3.9996), 1.0054, accuracy: 1e-9, "within half a millisecond is the turn")
    }

    func testTheRealEngineTicksOnTheTurns() {
        let engine = TimerEngine()
        var ticks: [TimeInterval] = []
        let two = expectation(description: "two ticks")
        engine.onTick = { elapsed in
            ticks.append(elapsed)
            if ticks.count == 2 { two.fulfill() }
        }
        engine.start()
        wait(for: [two], timeout: 3)
        engine.stop()
        XCTAssertLessThan(ticks[0], 0.05, "the first tick fires at once")
        XCTAssertGreaterThanOrEqual(ticks[1], 1.0, "the second waits for the turn")
        XCTAssertLessThan(ticks[1], 1.25, "and lands just past it")
    }

    func testFramesSitOnTheTurnsOfTheWorkoutClock() {
        let origin = Date(timeIntervalSinceReferenceDate: 1000.3)
        let start = origin.addingTimeInterval(12.7)
        let schedule = LiveClockSchedule(origin: origin)

        let alwaysOn = Array(schedule.entries(from: start, mode: .lowFrequency).prefix(4))
        XCTAssertEqual(alwaysOn[0], start, "the first frame is now")
        for (i, seconds) in [13.0, 14.0, 15.0].enumerated() {
            XCTAssertEqual(alwaysOn[i + 1].timeIntervalSince(origin), seconds, accuracy: 1e-6)
        }

        let live = Array(schedule.entries(from: start, mode: .normal).prefix(3))
        XCTAssertEqual(live[1].timeIntervalSince(origin), 12.8, accuracy: 1e-6)
        XCTAssertEqual(live[2].timeIntervalSince(origin), 12.9, accuracy: 1e-6)

        let unanchored = Array(LiveClockSchedule(origin: nil).entries(from: start, mode: .lowFrequency).prefix(2))
        XCTAssertEqual(unanchored[1].timeIntervalSince(start), 1, accuracy: 1e-6)
    }
}
