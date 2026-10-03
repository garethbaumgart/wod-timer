import SwiftUI

/// The 1.3.1 palette, one meaning per colour, shared with the phone: each
/// workout wears its Home colour while it runs (For Time orange, EMOM pink,
/// AMRAP blue, Tabata green for work and pink for rest), get ready is white.
enum Palette {
    static let prepare = Color.white
    static let work = Color(hex: 0x00FF88)
    static let rest = Color(hex: 0xFF0088)
    static let paused = Color(hex: 0x8A8A93)
    static let label = Color(hex: 0x9A9AA2)
    static let dim = Color(hex: 0x6A6A72)
    static let wheelDim = Color(hex: 0x3A3D58)
    static let error = Color(hex: 0xFF4444)
    /// START green.
    static let primary = Color(hex: 0x00FF88)
    /// Brand neon orange (same as For Time).
    static let brand = Color(hex: 0xFF6B1A)
    /// Unfilled timeline blocks.
    static let track = Color(hex: 0x24253A)
    /// PAUSE and DONE capsules.
    static let soft = Color(hex: 0x16172A)
    /// HOLD TO STOP capsule.
    static let stopInk = Color(hex: 0x1A0E14)

    /// Home order, every Home screen: For Time, EMOM, AMRAP, Tabata.
    static let modeOrder = ["fortime", "emom", "amrap", "tabata"]

    static func modeHex(_ code: String) -> UInt32 {
        switch code {
        case "fortime": 0xFF6B1A
        case "emom": 0xFF0088
        case "amrap": 0x00AAFF
        default: 0x00FF88
        }
    }

    /// Mode colour: bar, timeline, live clock, AGAIN / RESUME.
    static func mode(_ code: String) -> Color { Color(hex: modeHex(code)) }
    static func mode(_ type: TimerType) -> Color { mode(type.typeCode) }

    /// The colour a live session wears right now (or paused in): white in
    /// the get-ready countdown, Tabata work green / rest pink, otherwise
    /// the workout's colour.
    static func live(_ session: TimerSession) -> Color {
        let phase = LiveRules.effectivePhase(session)
        if phase == .preparing { return prepare }
        if case .tabata = session.workout.timerType {
            return phase == .resting ? rest : work
        }
        return mode(session.workout.timerType)
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

/// Live-screen rules shared by the running, paused and end views.
enum LiveRules {
    /// The phase the session is in, or paused in.
    static func effectivePhase(_ session: TimerSession) -> TimerState {
        session.state == .paused ? (session.stateBeforePause ?? .running) : session.state
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

    /// The longest value the clock can show for this workout, in its display
    /// form. The clock's size is set once from it (1.3.1) and never refits
    /// per tick: For Time the cap, AMRAP the duration, EMOM the interval,
    /// Tabata the longer of work / rest.
    static func referenceClock(_ type: TimerType) -> String {
        func display(_ d: TimerDuration) -> String { d.seconds <= 60 ? "\(d.seconds)" : d.clock }
        switch type {
        case let .amrap(duration): return duration.clock
        case let .forTime(cap, _): return cap.clock
        case let .emom(interval, _): return display(interval)
        case let .tabata(work, rest, _): return display(max(work, rest))
        }
    }

    /// Seconds into the workout, fractional, for the timeline fill.
    static func elapsedSeconds(_ session: TimerSession) -> Double {
        if effectivePhase(session) == .preparing { return 0 }
        return Double(session.elapsed.seconds) + Double(session.elapsedMillis) / 1000
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

    /// What the end screen says (1.3.1): the status word, the hero (nil for
    /// a capped For Time, which shows no score) and the one label line.
    /// EMOM and Tabata put the total on the label ("ROUNDS · 4:00"); so does
    /// a stopped AMRAP, where the elapsed time is part of the result.
    struct EndSummary: Equatable {
        let word: String
        let hero: String?
        let label: String
    }

    static func endSummary(_ session: TimerSession, endedEarly: Bool, endedAtTimeCap: Bool) -> EndSummary {
        if endedAtTimeCap {
            return EndSummary(word: "Time cap", hero: nil, label: "")
        }
        let word = endedEarly ? "Stopped" : "Finished"
        switch session.workout.timerType {
        case .amrap:
            let label = endedEarly ? "ROUNDS · \(session.elapsed.clock)" : "ROUNDS"
            return EndSummary(word: word, hero: "\(session.countedRounds)", label: label)
        case .forTime:
            return EndSummary(word: word, hero: session.elapsed.clock, label: "TIME")
        default:
            let total = session.totalRounds ?? 0
            let rounds = endedEarly ? session.currentRound : total
            return EndSummary(word: word, hero: "\(rounds)/\(total)", label: "ROUNDS · \(session.elapsed.clock)")
        }
    }
}

/// The fixed-height phase line over the clock, reserved in every mode and
/// blank when there is no phase to name, so the digits never jump.
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
