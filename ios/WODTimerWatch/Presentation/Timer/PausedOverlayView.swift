import SwiftUI

/// Paused: the phase word, the clock dimmed in its phase colour, the score,
/// then Stop (hold) beside a filled Resume. Tap anywhere else resumes.
struct PausedOverlayView: View {
    @Bindable var viewModel: TimerViewModel

    var body: some View {
        if let session = viewModel.session {
            VStack(spacing: 0) {
                PhaseLine(session: session)
                BigClock(
                    text: LiveRules.clockText(session),
                    color: Palette.phase(LiveRules.effectivePhase(session)),
                    maxHeight: .infinity
                )
                .opacity(0.45)
                .layoutPriority(1)
                ScoreSlot(session: session, counted: true)
                ProgressBar(progress: session.progress, color: Palette.paused, rounds: session.totalRounds)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
                Spacer(minLength: 2)
                HStack(spacing: 10) {
                    HoldToEndButton { viewModel.stop() }
                    if case .forTime = session.workout.timerType {
                        FinishButton(compact: true) { viewModel.finish() }
                    }
                    PauseDisc(paused: true, size: 50) { viewModel.resume() }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 10)
            .contentShape(Rectangle())
            .onTapGesture { viewModel.resume() }
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    PausedOverlayView(viewModel: TimerViewModel())
}
