import HealthKit
import SwiftUI
import UserNotifications
import XCTest
@testable import WODTimerWatch

// 2.4.0: the wrist alerts that stand in for the cues when no Health
// session keeps the app alive (Gareth's Ultra, 15 Oct and 8 Nov 2026: the
// face replaced the timer after about two minutes wrist-down and the
// beeps and taps between rounds stopped), the honest session state, and a
// tracker that no longer fights another app's workout.

private final class StatusTracker: WorkoutTracking {
    var status: HealthWorkoutTracker.Status {
        didSet { if oldValue != status { onStatusChange?(status) } }
    }
    var onStatusChange: ((HealthWorkoutTracker.Status) -> Void)?
    var calls: [String] = []

    init(status: HealthWorkoutTracker.Status) {
        self.status = status
    }

    func begin(_ workout: Workout) { calls.append("begin") }
    func go() { calls.append("go") }
    func pause() {
        calls.append("pause")
        if status == .running { status = .paused }
    }
    func resume() {
        calls.append("resume")
        if status == .paused { status = .running }
    }
    func end(keep: Bool) { calls.append(keep ? "end:keep" : "end:discard") }
}

private final class SpyAlerts: WristAlerting {
    var status: WristAlertStatus
    /// Every schedule call, oldest first.
    private(set) var scheduled: [[ScheduledAlert]] = []
    private(set) var cancels = 0
    /// What the system would fire right now.
    private(set) var pending: [ScheduledAlert] = []

    init(status: WristAlertStatus = .allowed) {
        self.status = status
    }

    func requestAuthorizationIfNeeded(completion: ((WristAlertStatus) -> Void)?) { completion?(status) }
    func schedule(_ alerts: [ScheduledAlert]) {
        scheduled.append(alerts)
        pending = alerts
    }

    func cancelAll() {
        cancels += 1
        pending = []
    }
}

private func makeViewModel(
    status: HealthWorkoutTracker.Status, alertStatus: WristAlertStatus = .allowed
) -> (TimerViewModel, StatusTracker, SpyAlerts) {
    let tracker = StatusTracker(status: status)
    let alerts = SpyAlerts(status: alertStatus)
    let haptics = WatchHapticService(player: { _ in }, scheduler: { _, work in work() })
    return (TimerViewModel(tracker: tracker, haptics: haptics, alerts: alerts), tracker, alerts)
}

private func workout(_ type: TimerType, prep: Int = 0) -> Workout {
    Workout(id: UUID(), name: "t", timerType: type, prepCountdown: TimerDuration(seconds: prep), createdAt: Date())
}

private func seconds(_ s: Int) -> TimerDuration { TimerDuration(seconds: s) }

private func emom(_ interval: Int, _ rounds: Int) -> TimerType {
    .emom(intervalDuration: seconds(interval), rounds: RoundCount(value: rounds))
}

private func tabata(_ work: Int, _ rest: Int, _ rounds: Int) -> TimerType {
    .tabata(workDuration: seconds(work), restDuration: seconds(rest), rounds: RoundCount(value: rounds))
}

/// Drives the real tick path in 100ms steps.
private func tick(_ vm: TimerViewModel, from: Double, to: Double) {
    var step = Int((from * 10).rounded())
    let last = Int((to * 10).rounded())
    while step < last {
        step += 1
        vm.debugTick(elapsed: Double(step) / 10)
    }
}

final class WristAlertPlanTests: XCTestCase {
    func testEmomNamesEveryRoundTheLastOneAndTheEnd() {
        let alerts = WristAlertPlan.changes(for: emom(60, 3))
        XCTAssertEqual(alerts.map(\.at), [60, 120, 180])
        XCTAssertEqual(alerts.map(\.title), ["Round 2 of 3", "Last round", "Finished"])
        XCTAssertEqual(alerts.first?.body, "EMOM · 3 × 1:00")
        XCTAssertEqual(alerts.first?.identifier, "wharfwod.alert.60")
        XCTAssertEqual(WristAlertPlan.changes(for: emom(45, 1)).map(\.title), ["Finished"], "one round has no round change")
    }

    func testTabataAlternatesRestAndRoundAndEndsAfterTheLastRest() {
        let alerts = WristAlertPlan.changes(for: tabata(20, 10, 3))
        XCTAssertEqual(alerts.map(\.at), [20, 30, 50, 60, 80, 90])
        XCTAssertEqual(alerts.map(\.title), ["Rest", "Round 2 of 3", "Rest", "Last round", "Last rest", "Finished"])
        XCTAssertEqual(alerts.first?.body, "TABATA · 3 × 20s / 10s")
    }

    func testAmrapIsHalfwayAndTheEndAndForTimeIsItsCap() {
        let amrap = WristAlertPlan.changes(for: .amrap(duration: seconds(600)))
        XCTAssertEqual(amrap.map(\.title), ["Halfway", "Finished"])
        XCTAssertEqual(amrap.map(\.at), [300, 600])
        XCTAssertEqual(WristAlertPlan.changes(for: .amrap(duration: seconds(90))).map(\.title), ["Finished"], "a short AMRAP has no halfway")
        let cap = WristAlertPlan.changes(for: .forTime(timeCap: seconds(1200)))
        XCTAssertEqual(cap.map(\.title), ["Time cap"])
        XCTAssertEqual(cap.map(\.at), [1200])
        XCTAssertEqual(cap.first?.body, "FOR TIME · CAP 20:00")
    }

    func testTheScheduleCountsFromTheSessionsOwnClock() {
        // EMOM 3 × 5s behind a 4s get ready, 1.5s into the countdown: GO is
        // 2.5s away, so round 2 is 7.5s away.
        var session = TimerSession.fromWorkout(workout(emom(5, 3), prep: 4))
        _ = session.start()
        session = session.projected(byMs: 1500)
        XCTAssertEqual(WristAlertPlan.workoutClock(session) ?? 0, -2.5, accuracy: 0.001)
        let plan = WristAlertPlan.schedule(for: session)
        XCTAssertEqual(plan.map(\.alert.title), ["Round 2 of 3", "Last round", "Finished"])
        XCTAssertEqual(plan.map(\.delay), [7.5, 12.5, 17.5])
        // 6.2s into the workout: round 2 has passed, the last round is 3.8s away.
        session = session.projected(byMs: 2500 + 6200)
        XCTAssertEqual(session.currentRound, 2)
        let later = WristAlertPlan.schedule(for: session)
        XCTAssertEqual(later.map(\.alert.title), ["Last round", "Finished"])
        XCTAssertEqual(later[0].delay, 3.8, accuracy: 0.001)
        XCTAssertEqual(later[1].delay, 8.8, accuracy: 0.001)
    }

    func testAPausedFinishedOrUnstartedSessionPlansNothing() {
        var session = TimerSession.fromWorkout(workout(.amrap(duration: seconds(600))))
        XCTAssertTrue(WristAlertPlan.schedule(for: session).isEmpty, "not started")
        _ = session.start()
        XCTAssertEqual(WristAlertPlan.schedule(for: session).count, 2)
        _ = session.pause()
        XCTAssertTrue(WristAlertPlan.schedule(for: session).isEmpty, "paused")
        _ = session.resume()
        _ = session.complete()
        XCTAssertTrue(WristAlertPlan.schedule(for: session).isEmpty, "finished")
    }

    func testALongWorkoutStaysUnderTheSystemsCapAndKeepsItsEnd() {
        // 100 rounds is the most the setup allows; the system holds 64
        // pending notifications per app.
        var session = TimerSession.fromWorkout(workout(emom(60, 100)))
        _ = session.start()
        let plan = WristAlertPlan.schedule(for: session)
        XCTAssertEqual(plan.count, WristAlertPlan.maxAlerts)
        XCTAssertEqual(plan.first?.alert.title, "Round 2 of 100")
        XCTAssertEqual(plan[plan.count - 2].alert.title, "Round 60 of 100")
        XCTAssertEqual(plan.last?.alert.title, "Finished")
        XCTAssertEqual(plan.last?.delay, 6000)
    }
}

final class WristAlertViewModelTests: XCTestCase {
    func testNoSessionMeansAnAlertForEveryChange() {
        let (vm, tracker, alerts) = makeViewModel(status: .off)
        vm.start(workout: workout(emom(5, 3)))
        XCTAssertEqual(tracker.calls, ["begin", "go"])
        XCTAssertEqual(alerts.pending.map(\.alert.title), ["Round 2 of 3", "Last round", "Finished"])
        XCTAssertEqual(alerts.pending[0].delay, 5, accuracy: 0.05)
        XCTAssertEqual(vm.wristCueState, .alerts)
        XCTAssertNil(vm.sessionNote)
    }

    func testTheGetReadyCountdownIsPartOfTheDelay() {
        let (vm, _, alerts) = makeViewModel(status: .off)
        vm.start(workout: workout(emom(5, 2), prep: 3))
        XCTAssertEqual(alerts.pending.map(\.alert.title), ["Last round", "Finished"])
        XCTAssertEqual(alerts.pending[0].delay, 8, accuracy: 0.05)
        // Skipping the countdown moves every alert up.
        vm.skipPrep()
        XCTAssertEqual(vm.phase, .running)
        XCTAssertEqual(alerts.pending[0].delay, 5, accuracy: 0.05)
    }

    func testARunningSessionNeedsNoAlerts() {
        let (vm, _, alerts) = makeViewModel(status: .running)
        vm.start(workout: workout(emom(5, 3)))
        XCTAssertTrue(alerts.scheduled.isEmpty)
        XCTAssertEqual(vm.wristCueState, .session)
    }

    func testPauseCancelsAndResumeReplansFromTheClock() {
        let (vm, _, alerts) = makeViewModel(status: .off)
        vm.start(workout: workout(emom(5, 3)))
        vm.debugAdvance(seconds: 2)
        vm.pause()
        XCTAssertEqual(alerts.cancels, 1)
        XCTAssertTrue(alerts.pending.isEmpty, "a paused timer never rings")
        vm.resume()
        XCTAssertEqual(alerts.pending.map(\.alert.title), ["Round 2 of 3", "Last round", "Finished"])
        XCTAssertEqual(alerts.pending[0].delay, 3, accuracy: 0.1)
    }

    func testStopFinishAndTheEndCancelTheAlerts() {
        let (stopped, _, stoppedAlerts) = makeViewModel(status: .off)
        stopped.start(workout: workout(emom(5, 2)))
        XCTAssertFalse(stoppedAlerts.pending.isEmpty)
        stopped.stop()
        XCTAssertTrue(stoppedAlerts.pending.isEmpty)

        let (finished, _, finishedAlerts) = makeViewModel(status: .off)
        finished.start(workout: workout(.forTime(timeCap: seconds(600))))
        XCTAssertEqual(finishedAlerts.pending.map(\.alert.title), ["Time cap"])
        finished.finish()
        XCTAssertTrue(finishedAlerts.pending.isEmpty)

        let (ended, _, endedAlerts) = makeViewModel(status: .off)
        ended.start(workout: workout(.amrap(duration: seconds(5))))
        XCTAssertEqual(endedAlerts.pending.map(\.alert.title), ["Finished"])
        tick(ended, from: 0, to: 5.0)
        XCTAssertEqual(ended.phase, .completed)
        XCTAssertTrue(endedAlerts.pending.isEmpty)

        let (cancelled, _, cancelledAlerts) = makeViewModel(status: .off)
        cancelled.start(workout: workout(emom(5, 2), prep: 5))
        XCTAssertFalse(cancelledAlerts.pending.isEmpty)
        cancelled.cancelPrep()
        XCTAssertTrue(cancelledAlerts.pending.isEmpty)
    }

    func testAnotherAppTakingTheSessionSwitchesToAlertsAndIsRemembered() {
        let (vm, tracker, alerts) = makeViewModel(status: .running)
        vm.start(workout: workout(emom(60, 10)))
        vm.debugAdvance(seconds: 130)
        XCTAssertTrue(alerts.scheduled.isEmpty)
        tracker.status = .takenOver
        XCTAssertEqual(alerts.pending.first?.alert.title, "Round 4 of 10")
        XCTAssertEqual(alerts.pending[0].delay, 50, accuracy: 0.1)
        XCTAssertEqual(alerts.pending.last?.alert.title, "Finished")
        XCTAssertEqual(vm.wristCueState, .alerts)
        XCTAssertEqual(vm.sessionLostAt, 130)
        XCTAssertEqual(vm.sessionNote, "Last workout: another app's workout took over at 2:10; the alerts carried on.")
        // The next START starts clean.
        vm.stop()
        tracker.status = .running
        vm.start(workout: workout(emom(60, 10)))
        XCTAssertNil(vm.sessionNote)
    }

    func testTheSessionComingUpCancelsTheAlerts() {
        let (vm, tracker, alerts) = makeViewModel(status: .starting)
        vm.start(workout: workout(emom(5, 3)))
        XCTAssertFalse(alerts.pending.isEmpty, "planned while the permission is pending")
        XCTAssertEqual(vm.wristCueState, .pending)
        tracker.status = .running
        XCTAssertTrue(alerts.pending.isEmpty)
        XCTAssertEqual(vm.wristCueState, .session)
    }

    func testWithoutThePermissionTheGlyphWarns() {
        let (vm, tracker, _) = makeViewModel(status: .off, alertStatus: .denied)
        vm.start(workout: workout(emom(5, 3)))
        XCTAssertEqual(vm.wristCueState, .none)
        XCTAssertEqual(WristCueGlyph.symbol(.none), "bell.slash.fill")
        XCTAssertEqual(WristCueGlyph.symbol(.alerts), "bell.fill")
        XCTAssertEqual(WristCueGlyph.symbol(.session), "figure.strengthtraining.traditional")
        XCTAssertNil(WristCueGlyph.symbol(.pending))
        tracker.status = .takenOver
        XCTAssertEqual(vm.sessionNote, "Last workout: another app's workout took over at 0:00; nothing reached your wrist off screen.")
    }

    func testTheDefaultAlertsUnderTestsDoNothing() {
        XCTAssertTrue(TimerViewModel.defaultAlerts() is NoopWristAlerts)
        XCTAssertEqual(NoopWorkoutTracker().status, .running, "previews show the normal state")
    }
}

final class SessionStateTests: XCTestCase {
    func testHomeNamesAnUnansweredPermission() {
        XCTAssertEqual(HomeView.healthLabel(enabled: false, authorization: .sharingAuthorized), "Off")
        XCTAssertEqual(HomeView.healthLabel(enabled: true, authorization: .sharingDenied), "Not allowed")
        XCTAssertEqual(HomeView.healthLabel(enabled: true, authorization: .notDetermined), "Not answered")
        XCTAssertEqual(HomeView.healthLabel(enabled: true, authorization: .sharingAuthorized), "On")
    }

    func testATakeoverIsItsOwnStateNotAFailure() {
        let taken = NSError(domain: HKErrorDomain, code: HKError.Code.errorAnotherWorkoutSessionStarted.rawValue)
        XCTAssertEqual(HealthWorkoutTracker.status(for: taken), .takenOver)
        let other = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "boom"])
        XCTAssertEqual(HealthWorkoutTracker.status(for: other), .failed("boom"))
        XCTAssertTrue(HealthWorkoutTracker.Status.running.keepsAppAlive)
        XCTAssertTrue(HealthWorkoutTracker.Status.paused.keepsAppAlive)
        for status: HealthWorkoutTracker.Status in [.idle, .starting, .off, .unavailable, .denied, .failed("x"), .takenOver] {
            XCTAssertFalse(status.keepsAppAlive, "\(status)")
        }
    }

    func testTheAlertsPermissionMapsFromTheSystems() {
        XCTAssertEqual(NotificationWristAlerts.status(from: .notDetermined), .notAsked)
        XCTAssertEqual(NotificationWristAlerts.status(from: .denied), .denied)
        XCTAssertEqual(NotificationWristAlerts.status(from: .authorized), .allowed)
        XCTAssertEqual(NotificationWristAlerts.status(from: .provisional), .allowed)
    }

    func testTheHealthPageNamesEveryState() {
        XCTAssertTrue(HealthSettingsView.permissionLine(.notDetermined).contains("not answered"))
        XCTAssertTrue(HealthSettingsView.alertsLine(.denied).contains("Watch app"))
        XCTAssertEqual(HealthSettingsView.alertsLine(.allowed), "Alerts: allowed")
        XCTAssertEqual(StayOnScreenView.steps.count, 4)
        XCTAssertTrue(StayOnScreenView.steps[1].contains("Return to Clock"))
    }
}
