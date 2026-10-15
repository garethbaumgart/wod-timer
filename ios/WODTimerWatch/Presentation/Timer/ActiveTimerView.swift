import SwiftUI

/// Live timer (1.3.1): one clock in the workout's colour, sized once per
/// workout, with a phase word when there is a phase to name, one second
/// line (the round, the AMRAP score or the For Time cap), the Home timeline
/// filling block by block, and the actions as bottom capsules. Tap anywhere
/// above the capsules: skips get ready, counts an AMRAP round. Stop lives
/// on the paused screen (and in get ready) and needs a hold.
struct ActiveTimerView: View {
    @Bindable var viewModel: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let session = viewModel.session {
                switch viewModel.phase {
                case .completed:
                    CompletedView(viewModel: viewModel)
                case .paused:
                    PausedOverlayView(viewModel: viewModel)
                default:
                    live(session: session)
                }
            } else {
                Color.black
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.phase) { _, newPhase in
            if newPhase == .ready {
                dismiss()
            }
        }
    }

    /// Each frame shows the clock for its own moment (2.2.1), so the
    /// frames Always On draws ahead of time read right when they show.
    /// Taps act on the live session, not the frame.
    @ViewBuilder
    private func live(session: TimerSession) -> some View {
        TimelineView(LiveClockSchedule(origin: viewModel.clockOrigin)) { context in
            let shown = viewModel.displaySession(at: context.date) ?? session
            LiveScreen(session: shown, counted: viewModel.hasCountedRound, paused: false) {
                canvasTap(session)
            } buttons: {
                controls(session: shown)
            }
        }
    }

    @ViewBuilder
    private func controls(session: TimerSession) -> some View {
        if session.state == .preparing {
            HoldToStopCapsule { viewModel.cancelPrep() }
        } else if case .forTime = session.workout.timerType {
            HStack(spacing: CapsuleGeometry.gap) {
                CapsuleButton(title: "FINISH", fill: .white, text: .black) { viewModel.finish() }
                    .accessibilityLabel("Finish workout and log your time")
                CapsuleButton(title: "PAUSE", fill: Palette.soft) { viewModel.pause() }
            }
        } else {
            CapsuleButton(title: "PAUSE", fill: Palette.soft) { viewModel.pause() }
        }
    }

    private func canvasTap(_ session: TimerSession) {
        switch session.state {
        case .preparing: viewModel.skipPrep()
        case .running: viewModel.countRound()
        default: break
        }
    }
}

/// When the live screen draws (2.2.1): ten times a second on the wrist,
/// once a second in Always On, where watchOS draws about once a second at
/// best and may render a batch of frames ahead. The entries sit on the
/// turns of the workout clock (counted from its origin, not the wall
/// clock), so each new second shows the moment it starts and holds for
/// the whole second.
struct LiveClockSchedule: TimelineSchedule {
    let origin: Date?

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        let step: TimeInterval = mode == .lowFrequency ? 1 : 0.1
        let base = origin ?? startDate
        var turn = (startDate.timeIntervalSince(base) / step).rounded(.down)
        var first: Date? = startDate
        return AnyIterator {
            if let date = first {
                first = nil
                return date
            }
            var next: Date
            repeat {
                turn += 1
                next = base.addingTimeInterval(turn * step)
            } while next <= startDate
            return next
        }
    }
}

/// The live layout shared by the running and paused screens: phase line,
/// clock, second slot, the timeline placed by the centring rule, buttons.
/// Every line has a fixed slot, so nothing moves as the numbers count or
/// when get ready turns into the workout.
struct LiveScreen<Buttons: View>: View {
    let session: TimerSession
    let counted: Bool
    let paused: Bool
    let onCanvasTap: () -> Void
    @ViewBuilder let buttons: () -> Buttons

    var body: some View {
        let color = Palette.live(session)
        let type = session.workout.timerType
        ZStack {
            RadialGradient(
                colors: [color.opacity(paused ? 0.08 : 0.22), .black],
                center: .center,
                startRadius: 0,
                endRadius: 120
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    // The phase slot is reserved in every mode (empty after
                    // GO for AMRAP, EMOM and For Time), so the clock's box is
                    // the same in get ready and running: nothing moves at GO.
                    PhaseLine(session: session)
                    BigClock(
                        text: LiveRules.clockText(session),
                        reference: LiveRules.referenceClock(type),
                        color: color
                    )
                    .opacity(paused ? 0.45 : 1)
                    .layoutPriority(1)
                    ScoreSlot(session: session, counted: counted)
                    TimelineZone(glyphInset: ScoreSlot.glyphInset(for: session.workout)) {
                        TimelineBar(
                            parts: type.timelineParts,
                            accent: Palette.mode(type),
                            height: 5,
                            fill: .elapsed(LiveRules.elapsedSeconds(session))
                        )
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: onCanvasTap)
                buttons()
                    .frame(height: CapsuleGeometry.height)
            }
            .padding(.horizontal, CapsuleGeometry.sideMargin)
            .padding(.bottom, CapsuleGeometry.bottomMargin)
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

/// The second line under the clock, in a fixed-height slot with one
/// baseline whatever it shows ("2/10", "3 ROUNDS", "TAP TO COUNT", "CAP
/// 20:00"), so the timeline under it never moves.
struct ScoreSlot: View {
    let session: TimerSession
    let counted: Bool

    static let height: CGFloat = 30
    static let numberSize: CGFloat = 28

    /// Where the slot's glyphs end above its box bottom (the centring rule).
    /// Fixed per workout, so the timeline never moves: EMOM and Tabata show
    /// the round ("2/10", whose slash descends), the others end on the
    /// baseline.
    static func glyphInset(for workout: Workout) -> CGFloat {
        let text = workout.roundCount == nil ? "0" : "0/0"
        return GlyphMetrics.glyphInset(text: text, size: numberSize, weight: .heavy, slotHeight: height)
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            // Invisible reference that pins the baseline for every variant.
            Text("0")
                .font(.system(size: Self.numberSize, weight: .heavy, design: .rounded))
                .hidden()
                .frame(width: 0)
            content
        }
        .frame(height: Self.height)
    }

    @ViewBuilder private var content: some View {
        if session.state == .preparing {
            hint("TAP TO SKIP")
        } else if let total = session.totalRounds {
            number("\(session.currentRound)/\(total)")
        } else if case .amrap = session.workout.timerType {
            if session.countedRounds == 0 && !counted && session.state == .running {
                hint("TAP TO COUNT")
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    number("\(session.countedRounds)")
                    Text("ROUNDS")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Palette.label)
                }
            }
        } else if case let .forTime(cap, up) = session.workout.timerType, up {
            Text("CAP \(cap.clock)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .tracking(1)
                .monospacedDigit()
                .foregroundStyle(Palette.label)
        } else {
            Text(" ")
                .font(.system(size: Self.numberSize, weight: .heavy, design: .rounded))
        }
    }

    private func number(_ text: String) -> some View {
        Text(text)
            .font(.system(size: Self.numberSize, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .tracking(1.2)
            .foregroundStyle(Palette.label)
    }
}

#Preview {
    let vm = TimerViewModel()
    ActiveTimerView(viewModel: vm)
}
