import SwiftUI

/// The phone's Signal palette, so a phase reads the same colour on the
/// wrist as on the box (1.3.0: rest was red on the watch, blue on the phone).
enum Palette {
    static let prepare = Color(hex: 0xFFAA00)
    static let work = Color(hex: 0x00FF88)
    static let rest = Color(hex: 0x00AAFF)
    static let paused = Color(hex: 0x8A8A93)
    static let label = Color(hex: 0x9A9AA2)
    static let error = Color(hex: 0xFF4444)
    static let primary = Color(hex: 0x00FF88)

    /// Colour of the phase a session is in (or paused in).
    static func phase(_ state: TimerState) -> Color {
        switch state {
        case .preparing: prepare
        case .resting: rest
        default: work
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Live-screen rules shared by the running and paused views.
enum LiveRules {
    /// The phase the session is in, or paused in.
    static func effectivePhase(_ session: TimerSession) -> TimerState {
        session.state == .paused ? (session.stateBeforePause ?? .running) : session.state
    }

    /// Whether this session can ever show a phase word while live: Tabata
    /// (WORK / REST / NEXT) and the get-ready countdown.
    static func showsPhaseLine(_ session: TimerSession) -> Bool {
        if session.state == .preparing { return true }
        if case .tabata = session.workout.timerType { return true }
        return false
    }

    /// Length of the phase the clock is counting through.
    static func phaseSeconds(_ session: TimerSession) -> Int {
        if session.state == .preparing { return session.workout.prepCountdown.seconds }
        switch session.workout.timerType {
        case let .amrap(duration): return duration.seconds
        case let .forTime(cap, _): return cap.seconds
        case let .emom(interval, _): return interval.seconds
        case let .tabata(work, rest, _):
            return effectivePhase(session) == .resting ? rest.seconds : work.seconds
        }
    }

    static func isCountUp(_ session: TimerSession) -> Bool {
        if case let .forTime(_, up) = session.workout.timerType { return up }
        return false
    }

    /// "9:45", "0:11", or bare seconds ("55") on a countdown under a minute
    /// or in a phase of a minute or less (an EMOM minute counts 60, 59 ...).
    static func clockText(_ session: TimerSession) -> String {
        if session.state != .preparing && isCountUp(session) {
            return session.elapsed.clock
        }
        let s = session.timeRemaining.seconds
        if s < 60 || phaseSeconds(session) <= 60 { return "\(s)" }
        return session.timeRemaining.clock
    }

    /// The phase word, or nil when there is no phase to name (AMRAP, EMOM
    /// and For Time work). Tabata names the next phase for its last 5s.
    static func phaseWord(_ session: TimerSession) -> (String, Color)? {
        let isTabata: Bool = { if case .tabata = session.workout.timerType { return true }; return false }()
        switch session.state {
        case .preparing: return ("GET READY", Palette.prepare)
        case .paused:
            guard isTabata else { return ("PAUSED", Palette.paused) }
            return (effectivePhase(session) == .resting ? "PAUSED · REST" : "PAUSED · WORK", Palette.paused)
        case .resting:
            guard isTabata else { return nil }
            if session.currentRound >= (session.totalRounds ?? 0) { return ("LAST REST", Palette.rest) }
            if session.timeRemaining.seconds <= 5 { return ("NEXT · WORK", Palette.work) }
            return ("REST", Palette.rest)
        case .running:
            guard isTabata else { return nil }
            if session.timeRemaining.seconds <= 5 { return ("NEXT · REST", Palette.rest) }
            return ("WORK", Palette.work)
        default: return nil
        }
    }

    /// "AMRAP · 10:00", "EMOM · 10 × 1:00", "TABATA · 8 × 20s / 10s".
    static func configLine(_ type: TimerType) -> String {
        switch type {
        case let .amrap(d): "AMRAP · \(d.clock)"
        case let .forTime(cap, _): "FOR TIME · CAP \(cap.clock)"
        case let .emom(i, r): "EMOM · \(r.value) × \(i.clock)"
        case let .tabata(w, rest, r): "TABATA · \(r.value) × \(w.phase) / \(rest.phase)"
        }
    }
}

/// The fixed-height phase line under the clock (blank when there is no
/// phase), so the digits never jump.
struct PhaseLine: View {
    let session: TimerSession

    var body: some View {
        Group {
            if let (word, color) = LiveRules.phaseWord(session) {
                Text(word)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                Color.clear
            }
        }
        .frame(height: 18)
    }
}

#Preview {
    PhaseLine(session: TimerSession.fromWorkout(Workout.defaultTabata()))
}
