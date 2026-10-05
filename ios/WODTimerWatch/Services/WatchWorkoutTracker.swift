import Foundation
import HealthKit
import Observation
import os

/// Keeps the app running for the whole workout (2.2.0).
///
/// A watchOS app is suspended the moment the wrist drops. On 2.1.0 that
/// silenced every beep, line and tap after GO, froze the clock until the
/// next wrist raise and sent the athlete back to the watch face (Gareth,
/// 5 Oct 2026). The sanctioned way to stay alive is an HKWorkoutSession:
/// while one runs the app keeps ticking in the background, may play
/// haptics and short audio clips there, comes back on wrist raise, and the
/// WOD lands in Health as a workout.
protocol WorkoutTracking: AnyObject {
    /// START: open the session, so the app survives the get-ready countdown.
    func begin(_ workout: Workout)
    /// GO: the Health workout starts here, not at START.
    func go()
    func pause()
    func resume()
    /// `keep` false discards the Health record (a cancelled get ready, a
    /// stop inside the first minute).
    func end(keep: Bool)
}

/// No session: tests, previews, the simulator capture hooks and the promo
/// hook, where a Health permission sheet would cover the screen.
final class NoopWorkoutTracker: WorkoutTracking {
    func begin(_ workout: Workout) {}
    func go() {}
    func pause() {}
    func resume() {}
    func end(keep: Bool) {}
}

@Observable
final class HealthWorkoutTracker: NSObject, WorkoutTracking {
    enum Status: Equatable {
        case idle
        /// Waiting for the permission answer or for the session to come up.
        case starting
        case running
        case paused
        /// Health is off in Settings: the timer only runs while on screen.
        case off
        case unavailable
        case denied
        case failed(String)
    }

    private(set) var status: Status = .idle
    /// Health only reveals share decisions; the one the app asks for.
    private(set) var authorization: HKAuthorizationStatus = .notDetermined
    /// The switch in Health settings. One additive key: missing reads as
    /// on, so the update turns the session on for everyone.
    private(set) var enabled: Bool

    static let enabledKey = "watch_health_track"
    /// Console on a paired Mac shows the session's life: `log stream
    /// --predicate 'subsystem == "app.mentalmetal.wharfwod.watchkitapp"'`.
    static let log = Logger(subsystem: "app.mentalmetal.wharfwod.watchkitapp", category: "workout")

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let store = HKHealthStore()
    @ObservationIgnored private var session: HKWorkoutSession?
    @ObservationIgnored private var collecting = false
    /// Set by end(keep:) until the session reports ended, so a second end
    /// (DONE after a finish) can't change what happens to the record, and
    /// a new begin (AGAIN) waits for the old session to close.
    @ObservationIgnored private var ending = false
    @ObservationIgnored private var goPending = false
    @ObservationIgnored private var keepOnEnd = true
    @ObservationIgnored private var pendingWorkout: Workout?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        enabled = defaults.object(forKey: Self.enabledKey) == nil ? true : defaults.bool(forKey: Self.enabledKey)
        super.init()
        refreshAuthorization()
    }

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Tabata is interval training; the others are what the Workout app
    /// calls functional strength training (the CrossFit choice).
    static func activityType(for type: TimerType) -> HKWorkoutActivityType {
        if case .tabata = type { return .highIntensityIntervalTraining }
        return .functionalStrengthTraining
    }

    func setEnabled(_ on: Bool) {
        enabled = on
        defaults.set(on, forKey: Self.enabledKey)
        if on {
            requestAuthorizationIfNeeded()
        } else if session == nil {
            status = .off
        }
    }

    /// The one permission the app asks for: to save workouts. Asked when
    /// Home appears, the standard workout-app moment, with the purpose
    /// string on the sheet; never during a countdown. Health answers
    /// without a sheet once the athlete has decided.
    func requestAuthorizationIfNeeded(completion: ((Bool) -> Void)? = nil) {
        guard enabled, Self.isAvailable else {
            completion?(false)
            return
        }
        refreshAuthorization()
        guard authorization == .notDetermined else {
            completion?(authorization == .sharingAuthorized)
            return
        }
        store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: []) { [weak self] _, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.refreshAuthorization()
                completion?(self.authorization == .sharingAuthorized)
            }
        }
    }

    private func refreshAuthorization() {
        guard Self.isAvailable else { return }
        authorization = store.authorizationStatus(for: HKObjectType.workoutType())
    }

    // MARK: - WorkoutTracking

    func begin(_ workout: Workout) {
        // A session still open from an interrupted run is discarded first.
        if session != nil, !ending { end(keep: false) }
        guard enabled else {
            status = .off
            return
        }
        guard Self.isAvailable else {
            status = .unavailable
            return
        }
        pendingWorkout = workout
        goPending = false
        status = .starting
        // AGAIN right after a finish: the last session is still closing,
        // so this one starts when it reports ended.
        if session != nil { return }
        startWhenAuthorized(workout)
    }

    private func startWhenAuthorized(_ workout: Workout) {
        requestAuthorizationIfNeeded { [weak self] authorized in
            guard let self, self.pendingWorkout?.id == workout.id else { return }
            guard authorized else {
                self.status = .denied
                Self.log.notice("workout session not started: Health sharing not authorized")
                return
            }
            self.startSession(for: workout)
        }
    }

    func go() {
        goPending = true
        beginCollection()
    }

    func pause() {
        guard let session, session.state == .running else { return }
        session.pause()
        status = .paused
    }

    func resume() {
        guard let session, session.state == .paused else { return }
        session.resume()
        status = .running
    }

    func end(keep: Bool) {
        pendingWorkout = nil
        goPending = false
        guard let session, !ending else {
            if status == .starting { status = .idle }
            return
        }
        ending = true
        keepOnEnd = keep && collecting
        if collecting {
            // The delegate finishes or discards the record once stopped.
            session.stopActivity(with: Date())
        } else {
            session.end()
        }
    }

    // MARK: - Session

    private func startSession(for workout: Workout) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = Self.activityType(for: workout.timerType)
        configuration.locationType = .indoor
        do {
            let session = try HKWorkoutSession(healthStore: store, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)
            session.delegate = self
            self.session = session
            collecting = false
            keepOnEnd = true
            session.startActivity(with: Date())
            status = .running
            Self.log.info("workout session started (\(configuration.activityType.rawValue))")
            if goPending { beginCollection() }
        } catch {
            status = .failed(error.localizedDescription)
            Self.log.error("workout session failed to start: \(error.localizedDescription)")
        }
    }

    private func beginCollection() {
        guard let session, !collecting else { return }
        collecting = true
        session.associatedWorkoutBuilder().beginCollection(withStart: Date()) { success, error in
            Self.log.info("collection began: \(success) \(error?.localizedDescription ?? "")")
        }
    }

    /// The session is gone: forget it, and start the workout waiting on it.
    private func clear(_ ended: HKWorkoutSession) {
        guard ended === session else { return }
        session = nil
        collecting = false
        ending = false
        if let pending = pendingWorkout {
            startWhenAuthorized(pending)
        } else if status != .off {
            status = .idle
        }
    }

    // MARK: - Crash recovery

    /// After a crash mid-workout the system relaunches the app and hands
    /// the session back. The timer is gone, so the Health record is closed
    /// with what it collected rather than left open against the next start.
    static func recoverCrashedSession() {
        guard isAvailable else { return }
        let store = HKHealthStore()
        store.recoverActiveWorkoutSession { session, _ in
            guard let session else { return }
            RecoveryCloser.close(session)
        }
    }
}

/// Holds the recovered session's delegate until it has ended.
private final class RecoveryCloser: NSObject, HKWorkoutSessionDelegate {
    private static var active: RecoveryCloser?

    static func close(_ session: HKWorkoutSession) {
        let closer = RecoveryCloser()
        active = closer
        session.delegate = closer
        session.stopActivity(with: Date())
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState, date: Date
    ) {
        switch toState {
        case .stopped:
            let builder = workoutSession.associatedWorkoutBuilder()
            builder.endCollection(withEnd: date) { _, _ in
                builder.finishWorkout { _, _ in workoutSession.end() }
            }
        case .ended:
            Self.active = nil
        default:
            break
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Self.active = nil
    }
}

extension HealthWorkoutTracker: HKWorkoutSessionDelegate {
    func workoutSession(
        _ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState, date: Date
    ) {
        Self.log.info("workout session \(fromState.rawValue) -> \(toState.rawValue)")
        switch toState {
        case .stopped:
            let builder = workoutSession.associatedWorkoutBuilder()
            if keepOnEnd {
                builder.endCollection(withEnd: date) { _, _ in
                    builder.finishWorkout { workout, error in
                        Self.log.info("workout saved: \(workout != nil) \(error?.localizedDescription ?? "")")
                        workoutSession.end()
                    }
                }
            } else {
                builder.discardWorkout()
                workoutSession.end()
            }
        case .ended:
            DispatchQueue.main.async { [weak self] in
                guard let self, workoutSession === self.session else { return }
                self.clear(workoutSession)
            }
        default:
            break
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Self.log.error("workout session failed: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            guard let self, workoutSession === self.session else { return }
            self.status = .failed(error.localizedDescription)
            self.clear(workoutSession)
        }
    }
}
