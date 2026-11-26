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
/// What the Health session has measured (2.7.0), in beats a minute: the
/// heart rate now, and the average and peak of the workout so far. The
/// session was already running for every WOD to keep the timer alive; the
/// athlete saw none of what it collects, which the other WOD timers on
/// the watch lead with (watch review, 26 Nov 2026). Shown on the watch
/// only: the app keeps no copy and sends nothing anywhere.
struct HeartReadout: Equatable {
    var current: Int?
    /// When `current` was measured.
    var measuredAt: Date?
    var average: Int?
    var peak: Int?

    static let none = HeartReadout()

    /// A reading older than this is not the heart rate now: the watch came
    /// off the wrist, the sensor lost the skin, or the session stopped
    /// collecting. The screen goes back to the session glyph rather than
    /// stand on a stale number. A workout session measures about every
    /// five seconds, so this rides over two missed readings.
    static let freshFor: TimeInterval = 15

    /// The heart rate as it stands at `date`, or nil when the last
    /// reading is too old to call "now".
    func now(at date: Date) -> Int? {
        guard let current, let measuredAt else { return nil }
        return date.timeIntervalSince(measuredAt) <= Self.freshFor ? current : nil
    }

    /// The end screen's line, once the workout has both numbers.
    var summary: String? {
        guard let average, let peak else { return nil }
        return "AVG \(average) · PEAK \(peak)"
    }

    /// VoiceOver's form of the same line.
    var spokenSummary: String? {
        guard let average, let peak else { return nil }
        return "Heart rate: average \(average), peak \(peak) beats per minute"
    }

    /// Whole beats a minute, and only in the range a heart beats: a
    /// sensor glitch shows nothing rather than a wrong number.
    static func beats(_ value: Double?) -> Int? {
        guard let value, value.isFinite else { return nil }
        let whole = Int(value.rounded())
        return (25 ... 250).contains(whole) ? whole : nil
    }
}

protocol WorkoutTracking: AnyObject {
    /// What the session has measured of the heart (2.7.0); `.none` with
    /// no session, no permission to read it, or nothing measured yet.
    var heart: HeartReadout { get }
    /// Where the session stands. `keepsAppAlive` says whether the app
    /// survives wrist-down on its own; when it does not, the view model
    /// schedules wrist alerts instead (2.4.0, WristAlertPlan).
    var status: HealthWorkoutTracker.Status { get }
    /// Called on the main queue whenever `status` changes.
    var onStatusChange: ((HealthWorkoutTracker.Status) -> Void)? { get set }
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

extension WorkoutTracking {
    var heart: HeartReadout { .none }
}

/// No session: tests, previews, the simulator capture hooks and the promo
/// hook, where a Health permission sheet would cover the screen.
final class NoopWorkoutTracker: WorkoutTracking {
    /// Previews and captures show the normal state (a session running)
    /// unless a scene asks for another.
    var status: HealthWorkoutTracker.Status
    var onStatusChange: ((HealthWorkoutTracker.Status) -> Void)?
    /// A capture scene's heart rate; nothing by default.
    var heart: HeartReadout

    init(status: HealthWorkoutTracker.Status = .running, heart: HeartReadout = .none) {
        self.status = status
        self.heart = heart
    }

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
        /// Another app started a workout session mid-workout (Apple's
        /// Workout app, or its own "looks like a workout" prompt): Apple
        /// Watch runs one session at a time, and ours ended.
        case takenOver

        /// Whether the app keeps running off screen on this state's
        /// account. A paused session is still a session.
        var keepsAppAlive: Bool { self == .running || self == .paused }
    }

    private(set) var status: Status = .idle
    var onStatusChange: ((Status) -> Void)?
    /// The heart rate of the workout under way, or of the one just ended
    /// (the end screen reads its average and peak); cleared at START.
    private(set) var heart = HeartReadout.none
    /// Health only reveals share decisions: saving workouts. Whether the
    /// heart rate may be read it never says; no readings is all that shows.
    private(set) var authorization: HKAuthorizationStatus = .notDetermined
    /// The switch in Health settings. One additive key: missing reads as
    /// on, so the update turns the session on for everyone.
    private(set) var enabled: Bool
    /// True while the heart-rate question has never been answered by an
    /// athlete who has answered the workouts one (2.7.0).
    private(set) var heartQuestionOpen = false

    static let enabledKey = "watch_health_track"
    /// Set once Home has put the heart-rate question by itself, so a
    /// sheet closed without an answer is not put up again at every visit
    /// to Home (one additive key; missing reads as not asked).
    static let heartAskedKey = "watch_health_heart_asked"
    /// Set once Home has said that Workouts is not allowed, and cleared
    /// when it is allowed again, so the notice is put up once each time
    /// the permission is found off (one additive key).
    static let refusedToldKey = "watch_health_refused_told"
    /// Console on a paired Mac shows the session's life: `log stream
    /// --predicate 'subsystem == "app.mentalmetal.wharfwod.watchkitapp"'`.
    static let log = Logger(subsystem: "app.mentalmetal.wharfwod.watchkitapp", category: "workout")

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let store = HKHealthStore()
    @ObservationIgnored private var session: HKWorkoutSession?
    @ObservationIgnored private var builder: HKLiveWorkoutBuilder?
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
        refreshHeartQuestion()
    }

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// What the app writes: the workout. What it reads (2.7.0): the heart
    /// rate, for the timer and the end screen, and nothing else.
    static let shareTypes: Set<HKSampleType> = [HKObjectType.workoutType()]
    static let heartRateType = HKQuantityType(.heartRate)
    static let readTypes: Set<HKObjectType> = [heartRateType]
    static let beatsPerMinute = HKUnit.count().unitDivided(by: .minute())

    private func setStatus(_ new: Status) {
        guard new != status else { return }
        status = new
        onStatusChange?(new)
    }

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
            setStatus(.off)
        }
    }

    /// The permissions the app asks for: to save workouts, and (2.7.0) to
    /// read the heart rate. Asked when Home appears, the standard
    /// workout-app moment, with the purpose strings on the sheet. Health
    /// answers without a sheet once the athlete has decided both, and
    /// shows a sheet with only the heart-rate question to an athlete who
    /// allowed workouts before 2.7.0.
    func requestAuthorizationIfNeeded(completion: ((Bool) -> Void)? = nil) {
        request(explicit: false, completion: completion)
    }

    /// The Health page's button: puts whatever is still open to the
    /// athlete again, whether or not Home already has.
    func askForHeartRate() {
        request(explicit: true, completion: nil)
    }

    private func request(explicit: Bool, completion: ((Bool) -> Void)?) {
        guard enabled, Self.isAvailable else {
            completion?(false)
            return
        }
        #if targetEnvironment(simulator)
        // `--legacy-health-request`: ask as 2.6.2 and earlier did (workouts
        // only), so a UI test can put a simulator where an athlete updating
        // to 2.7.0 stands (WatchHealthSessionUITests).
        if CommandLine.arguments.contains("--legacy-health-request") {
            store.requestAuthorization(toShare: Self.shareTypes, read: []) { [weak self] _, _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.refreshAuthorization()
                    completion?(self.authorization == .sharingAuthorized)
                }
            }
            return
        }
        #endif
        refreshAuthorization()
        let share = Self.shareTypesToAsk(for: authorization)
        store.getRequestStatusForAuthorization(toShare: share, read: Self.readTypes) { [weak self] status, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.refreshAuthorization()
                let open = status == .shouldRequest
                let workoutsAnswered = self.authorization != .notDetermined
                self.heartQuestionOpen = open && workoutsAnswered
                guard Self.shouldPresent(
                    open: open, workoutsAnswered: workoutsAnswered,
                    heartAsked: self.defaults.bool(forKey: Self.heartAskedKey), explicit: explicit
                ) else {
                    completion?(self.authorization == .sharingAuthorized)
                    return
                }
                if workoutsAnswered { self.defaults.set(true, forKey: Self.heartAskedKey) }
                self.store.requestAuthorization(toShare: share, read: Self.readTypes) { [weak self] _, _ in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        self.refreshAuthorization()
                        self.refreshHeartQuestion()
                        completion?(self.authorization == .sharingAuthorized)
                    }
                }
            }
        }
    }

    /// What to ask to save. An athlete who has already answered the
    /// workouts question is asked for the heart rate alone. Asked for
    /// both, watchOS opens its sheet on the Write Access page with the
    /// Workouts switch already on, and a tap meant to turn it on turns it
    /// off: 2.7.0 did that to every athlete updating, and Gareth's watch
    /// came out with the heart rate allowed and Workouts not (27 Nov
    /// 2026), so no session ran: no heart rate, and no countdown or start
    /// beep with the wrist down.
    static func shareTypesToAsk(for authorization: HKAuthorizationStatus) -> Set<HKSampleType> {
        authorization == .notDetermined ? shareTypes : []
    }

    /// The athlete wants sessions (Track workouts is on) and Health will
    /// not let the app save a workout, so none can run: no heart rate, and
    /// off screen only the alerts. Only the athlete can undo it, in the
    /// watch's Settings; Health never shows its sheet a second time.
    var workoutsRefused: Bool {
        Self.workoutsRefused(enabled: enabled, authorization: authorization)
    }

    static func workoutsRefused(enabled: Bool, authorization: HKAuthorizationStatus) -> Bool {
        enabled && authorization == .sharingDenied
    }

    /// Whether Home should say so now: once each time the permission is
    /// found off. Marks it said.
    func takeRefusalNotice() -> Bool {
        guard Self.tellsRefusal(refused: workoutsRefused, told: defaults.bool(forKey: Self.refusedToldKey)) else {
            return false
        }
        defaults.set(true, forKey: Self.refusedToldKey)
        return true
    }

    static func tellsRefusal(refused: Bool, told: Bool) -> Bool {
        refused && !told
    }

    /// Reads the permissions again: the athlete may have changed them in
    /// Settings while the app was off screen.
    func refreshPermissions() {
        refreshAuthorization()
        refreshHeartQuestion()
    }

    /// Whether to put the sheet up. With the workouts question open the
    /// answer is yes every time, as before 2.7.0: the session that keeps
    /// the timer alive depends on it. With only the heart-rate question
    /// open (an athlete from before 2.7.0, or one who closed the sheet on
    /// its second page) Home asks once and then leaves them alone: the
    /// timer needs nothing from it, and the Health page has the button.
    static func shouldPresent(open: Bool, workoutsAnswered: Bool, heartAsked: Bool, explicit: Bool) -> Bool {
        guard open else { return false }
        if !workoutsAnswered { return true }
        return explicit || !heartAsked
    }

    /// Whether the heart-rate question is still unanswered, for the
    /// Health page's button. Health tells an app that much, though never
    /// what the answer was.
    private func refreshHeartQuestion() {
        guard Self.isAvailable else { return }
        refreshAuthorization()
        let share = Self.shareTypesToAsk(for: authorization)
        store.getRequestStatusForAuthorization(toShare: share, read: Self.readTypes) { [weak self] status, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.refreshAuthorization()
                self.heartQuestionOpen = status == .shouldRequest && self.authorization != .notDetermined
            }
        }
    }

    private func refreshAuthorization() {
        guard Self.isAvailable else { return }
        let now = store.authorizationStatus(for: HKObjectType.workoutType())
        if now != authorization { authorization = now }
        if now == .sharingAuthorized, defaults.object(forKey: Self.refusedToldKey) != nil {
            defaults.removeObject(forKey: Self.refusedToldKey)
        }
    }

    // MARK: - WorkoutTracking

    func begin(_ workout: Workout) {
        heart = .none
        // A session still open from an interrupted run is discarded first.
        if session != nil, !ending { end(keep: false) }
        guard enabled else {
            setStatus(.off)
            return
        }
        guard Self.isAvailable else {
            setStatus(.unavailable)
            return
        }
        pendingWorkout = workout
        goPending = false
        setStatus(.starting)
        // AGAIN right after a finish: the last session is still closing,
        // so this one starts when it reports ended.
        if session != nil { return }
        startWhenAuthorized(workout)
    }

    private func startWhenAuthorized(_ workout: Workout) {
        let started: (Bool) -> Void = { [weak self] authorized in
            guard let self, self.pendingWorkout?.id == workout.id else { return }
            guard authorized else {
                self.setStatus(.denied)
                Self.log.notice("workout session not started: Health sharing not authorized")
                return
            }
            self.startSession(for: workout)
        }
        // Workouts already answered: the session starts now. The
        // heart-rate question is Home's to ask, never a countdown's, and
        // a workout never waits on it.
        refreshAuthorization()
        guard authorization == .notDetermined else {
            started(authorization == .sharingAuthorized)
            return
        }
        requestAuthorizationIfNeeded(completion: started)
    }

    func go() {
        goPending = true
        beginCollection()
    }

    func pause() {
        guard let session, session.state == .running else { return }
        session.pause()
        setStatus(.paused)
    }

    func resume() {
        guard let session, session.state == .paused else { return }
        session.resume()
        setStatus(.running)
    }

    func end(keep: Bool) {
        pendingWorkout = nil
        goPending = false
        guard let session, !ending else {
            if status == .starting { setStatus(.idle) }
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
            builder.delegate = self
            session.delegate = self
            self.session = session
            self.builder = builder
            collecting = false
            keepOnEnd = true
            session.startActivity(with: Date())
            setStatus(.running)
            Self.log.info("workout session started (\(configuration.activityType.rawValue))")
            if goPending { beginCollection() }
        } catch {
            setStatus(.failed(error.localizedDescription))
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

    /// The session is gone: forget it and, when we closed it ourselves,
    /// start the workout waiting on it (AGAIN right after a finish). A
    /// session that died under the workout is not restarted: 2.3.x did,
    /// at once and without backoff, which ends the athlete's Apple workout
    /// or loops against it (one session at a time); the view model
    /// switches to wrist alerts instead.
    private func clear(_ ended: HKWorkoutSession, restart: Bool) {
        guard ended === session else { return }
        session = nil
        builder = nil
        collecting = false
        ending = false
        if restart, let pending = pendingWorkout {
            startWhenAuthorized(pending)
        } else if [.starting, .running, .paused].contains(status) {
            setStatus(.idle)
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
                self.clear(workoutSession, restart: true)
            }
        default:
            break
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Self.log.error("workout session failed: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            guard let self, workoutSession === self.session else { return }
            if self.ending {
                // The session we were closing failed instead of ending:
                // closed is closed, and a workout waiting on it still starts.
                self.clear(workoutSession, restart: true)
                return
            }
            // The live session died under the workout, usually because
            // another app started one. Leave it: the alerts take over.
            self.pendingWorkout = nil
            self.goPending = false
            self.setStatus(Self.status(for: error))
            self.clear(workoutSession, restart: false)
        }
    }

    /// Another app's session ending ours is its own state, not a failure.
    static func status(for error: Error) -> Status {
        if let hkError = error as? HKError, hkError.code == .errorAnotherWorkoutSessionStarted {
            return .takenOver
        }
        return .failed(error.localizedDescription)
    }
}

extension HealthWorkoutTracker: HKLiveWorkoutBuilderDelegate {
    /// The builder's own statistics, so the average and peak on the end
    /// screen are the ones Health and Fitness show for the same workout
    /// (pauses left out, GO to the end).
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard collectedTypes.contains(Self.heartRateType),
              let statistics = workoutBuilder.statistics(for: Self.heartRateType) else { return }
        let unit = Self.beatsPerMinute
        let reading = HeartReadout(
            current: HeartReadout.beats(statistics.mostRecentQuantity()?.doubleValue(for: unit)),
            measuredAt: statistics.mostRecentQuantityDateInterval()?.end ?? Date(),
            average: HeartReadout.beats(statistics.averageQuantity()?.doubleValue(for: unit)),
            peak: HeartReadout.beats(statistics.maximumQuantity()?.doubleValue(for: unit))
        )
        DispatchQueue.main.async { [weak self] in
            self?.collected(reading, from: workoutBuilder)
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    /// Takes a reading from the session's own builder. Once AGAIN is
    /// waiting on a session that is still closing, its last readings
    /// belong to the workout before and are dropped.
    func collected(_ reading: HeartReadout, from source: HKLiveWorkoutBuilder?) {
        guard Self.accepts(fromCurrentBuilder: source != nil && source === builder,
                           ending: ending, nextWaiting: pendingWorkout != nil) else { return }
        heart = reading
    }

    static func accepts(fromCurrentBuilder: Bool, ending: Bool, nextWaiting: Bool) -> Bool {
        fromCurrentBuilder && !(ending && nextWaiting)
    }
}
