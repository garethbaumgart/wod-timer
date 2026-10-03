import SwiftUI

/// Live timer, 1.3.0 "big clock": one phase-coloured clock filling the
/// screen, one phase word when there is a phase to name, one second number
/// (the round, the AMRAP score or the For Time cap), one control.
/// Tap anywhere: skips get ready, counts an AMRAP round. Pause is the
/// button; Stop lives on the paused screen and needs a hold.
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

    @ViewBuilder
    private func live(session: TimerSession) -> some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { _ in
            let phaseColor = Palette.phase(session.state)

            ZStack {
                RadialGradient(
                    colors: [phaseColor.opacity(0.22), .black],
                    center: .center,
                    startRadius: 0,
                    endRadius: 120
                )
                .ignoresSafeArea()

                VStack(spacing: 2) {
                    // Only modes that can show a phase reserve the line, so
                    // AMRAP, EMOM and For Time give it to the clock.
                    if LiveRules.showsPhaseLine(session) {
                        PhaseLine(session: session)
                    }
                    BigClock(text: LiveRules.clockText(session), color: phaseColor, maxHeight: .infinity)
                        .layoutPriority(1)
                    ScoreSlot(session: session, counted: viewModel.hasCountedRound)
                    ProgressBar(
                        progress: session.progress,
                        color: phaseColor,
                        rounds: session.totalRounds
                    )
                    .opacity(session.state == .preparing ? 0 : 1)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
                    controls(session: session)
                        .frame(height: 38)
                }
                .padding(.horizontal, 6)
                // Clear of the display's curved bottom edge (1.3.1: the
                // Pause ring sat on it on a real watch).
                .padding(.bottom, 10)
            }
            .contentShape(Rectangle())
            .onTapGesture { canvasTap(session) }
        }
    }

    @ViewBuilder
    private func controls(session: TimerSession) -> some View {
        if session.state == .preparing {
            Button { viewModel.cancelPrep() } label: {
                ZStack {
                    Circle().fill(Color.white.opacity(0.1))
                    Image(systemName: "xmark").font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Palette.label)
                }
                .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancel, back to setup")
        } else if case .forTime = session.workout.timerType {
            HStack(spacing: 8) {
                FinishButton { viewModel.finish() }
                PauseDisc(paused: false) { viewModel.pause() }
            }
        } else {
            PauseDisc(paused: false) { viewModel.pause() }
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

/// The second number under the clock, in a fixed-height slot.
struct ScoreSlot: View {
    let session: TimerSession
    let counted: Bool

    var body: some View {
        Group {
            if session.state == .preparing {
                hint("TAP TO SKIP")
            } else if let total = session.totalRounds {
                Text("\(session.currentRound)/\(total)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            } else if case .amrap = session.workout.timerType {
                if session.countedRounds == 0 && !counted && session.state == .running {
                    hint("TAP TO COUNT")
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(session.countedRounds)")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
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
                    .foregroundStyle(Palette.label)
            } else {
                Color.clear
            }
        }
        .frame(height: 30)
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
