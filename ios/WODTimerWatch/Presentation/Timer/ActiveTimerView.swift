import SwiftUI

/// Active timer screen: full-screen with progress ring.
/// Tap anywhere to pause. Phase color fills background.
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
                    timerContent(session: session)
                }
            } else {
                Text("No session")
                    .foregroundStyle(.secondary)
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
    private func timerContent(session: TimerSession) -> some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { _ in
            let phaseColor = colorForPhase(session.state)

            ZStack {
                // Phase-colored background glow
                RadialGradient(
                    colors: [phaseColor.opacity(0.2), .black],
                    center: .center,
                    startRadius: 0,
                    endRadius: 120
                )
                .ignoresSafeArea()

                // Progress ring
                CircularProgressRing(
                    progress: session.state == .preparing
                        ? prepProgress(session)
                        : session.progress,
                    color: phaseColor,
                    lineWidth: session.state == .preparing ? 3 : 5
                )
                .padding(6)

                // Content
                VStack(spacing: 2) {
                    // Phase badge
                    PhaseBadge(
                        state: session.state,
                        timerType: session.workout.timerType
                    )

                    // Large time display
                    if session.state == .preparing {
                        // Single digit countdown
                        Text("\(session.timeRemaining.seconds)")
                            .font(.system(size: 72, weight: .ultraLight))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    } else {
                        TimerDisplayText(session.timeRemaining)
                    }

                    // Contextual subtitle
                    if session.state == .preparing {
                        Text("\(session.workout.timerTypeLabel) · \(session.workout.timerType.estimatedDuration.formatted)")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    } else if session.state == .running || session.state == .resting {
                        subtitleText(session: session)
                    }
                }

                // Tap anywhere hint
                VStack {
                    Spacer()
                    Text("TAP TO PAUSE")
                        .font(.system(size: 8))
                        .foregroundStyle(phaseColor.opacity(0.3))
                        .padding(.bottom, 8)
                }
            }
            .onTapGesture {
                viewModel.pause()
            }
        }
    }

    @ViewBuilder
    private func subtitleText(session: TimerSession) -> some View {
        if let totalRounds = session.totalRounds {
            Text("Round \(session.currentRound) / \(totalRounds)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(colorForPhase(session.state).opacity(0.7))
        } else {
            Text("remaining")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private func prepProgress(_ session: TimerSession) -> Double {
        let total = session.workout.prepCountdown.seconds
        guard total > 0 else { return 0 }
        let elapsed = session.currentIntervalElapsed.seconds
        return Double(elapsed) / Double(total)
    }

    private func colorForPhase(_ state: TimerState) -> Color {
        switch state {
        case .preparing: .blue
        case .running: .green
        case .resting: .red
        case .paused: .orange
        case .completed: .teal
        default: .gray
        }
    }
}

#Preview {
    let vm = TimerViewModel()
    ActiveTimerView(viewModel: vm)
}
