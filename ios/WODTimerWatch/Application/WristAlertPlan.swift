import Foundation

/// One alert the system delivers on the wrist when the app cannot (2.4.0).
///
/// Without a running Health workout session the watch suspends the app
/// about two minutes after the wrist drops (Apple's Return to Clock
/// default), and every beep and tap with it. That is the case whenever
/// Track workouts is off, the Health permission was never answered, or
/// Apple's Workout app is recording the class (one session at a time, and
/// the Workout app's keeps priority). Local notifications are the one
/// channel that still reaches the wrist from a suspended app: the system
/// taps and sounds at each change, and a tap on the alert brings the
/// timer back. The plan is pure: the moments a workout turns, computed
/// from the session's own clock, so tests pin it without the notification
/// center.
struct WristAlert: Equatable {
    enum Kind: Equatable {
        /// A round starts (EMOM, or Tabata work after a rest).
        case round(Int, of: Int)
        /// The last round starts.
        case lastRound
        /// Tabata work turns to rest.
        case rest(Int, of: Int)
        /// Halfway through an AMRAP.
        case halfway
        /// The workout clock runs out.
        case finish
        /// A For Time runs into its cap.
        case timeCap
    }

    let kind: Kind
    /// Seconds of workout clock (after GO) when it fires.
    let at: Int
    /// The workout, as the end screen names it ("EMOM · 10 × 1:00").
    let body: String

    /// The short look's one line.
    var title: String {
        switch kind {
        case let .round(n, of): "Round \(n) of \(of)"
        case .lastRound: "Last round"
        case let .rest(n, of): n == of ? "Last rest" : "Rest"
        case .halfway: "Halfway"
        case .finish: "Finished"
        case .timeCap: "Time cap"
        }
    }

    var identifier: String { "wharfwod.alert.\(at)" }
}

/// An alert with the delay from the instant the plan was made.
struct ScheduledAlert: Equatable {
    let alert: WristAlert
    /// Seconds from now until it fires.
    let delay: TimeInterval
}

enum WristAlertPlan {
    /// Pending local notifications are capped by the system (64); a plan
    /// keeps the earliest changes and always the end.
    static let maxAlerts = 60

    /// Every change of the workout, in order, in seconds from GO: EMOM and
    /// Tabata rounds (the last one named), Tabata rests, an AMRAP's halfway
    /// and the end. GO itself is not an alert: the athlete is looking at the
    /// countdown. The 3-2-1 beeps have no alert either; a notification is
    /// one tap per change.
    static func changes(for type: TimerType) -> [WristAlert] {
        let body = LiveRules.configLine(type)
        func alert(_ kind: WristAlert.Kind, at: Int) -> WristAlert { WristAlert(kind: kind, at: at, body: body) }
        var alerts: [WristAlert] = []
        switch type {
        case let .amrap(duration):
            if duration.seconds >= 120 { alerts.append(alert(.halfway, at: duration.seconds / 2)) }
            alerts.append(alert(.finish, at: duration.seconds))
        case let .forTime(cap, _):
            alerts.append(alert(.timeCap, at: cap.seconds))
        case let .emom(interval, rounds):
            let n = rounds.value
            for round in 2 ... max(2, n) where round <= n {
                alerts.append(alert(round == n ? .lastRound : .round(round, of: n), at: (round - 1) * interval.seconds))
            }
            alerts.append(alert(.finish, at: n * interval.seconds))
        case let .tabata(work, rest, rounds):
            let n = rounds.value
            let cycle = work.seconds + rest.seconds
            for round in 1 ... max(1, n) where round <= n {
                let start = (round - 1) * cycle
                if round > 1 {
                    alerts.append(alert(round == n ? .lastRound : .round(round, of: n), at: start))
                }
                alerts.append(alert(.rest(round, of: n), at: start + work.seconds))
            }
            alerts.append(alert(.finish, at: n * cycle))
        }
        return alerts
    }

    /// The alerts still to come for a session, each with its delay from
    /// this instant on the session's own clock. In get ready the delay
    /// includes what is left of the countdown; a paused, finished or
    /// not-yet-started session plans nothing.
    static func schedule(for session: TimerSession) -> [ScheduledAlert] {
        guard let clock = workoutClock(session) else { return [] }
        let due = changes(for: session.workout.timerType)
            .map { ScheduledAlert(alert: $0, delay: TimeInterval($0.at) - clock) }
            .filter { $0.delay > 0 }
        guard due.count > maxAlerts, let last = due.last else { return due }
        return Array(due.prefix(maxAlerts - 1)) + [last]
    }

    /// Seconds of workout clock the session reads right now, negative in
    /// get ready (the time until GO), nil when it is not running.
    static func workoutClock(_ session: TimerSession) -> TimeInterval? {
        switch session.state {
        case .preparing:
            let left = Double(session.workout.prepCountdown.seconds - session.currentIntervalElapsed.seconds)
                - Double(session.intervalElapsedMillis) / 1000
            return -max(0, left)
        case .running, .resting:
            return Double(session.elapsed.seconds) + Double(session.elapsedMillis) / 1000
        default:
            return nil
        }
    }
}
