import SwiftUI

/// Paused: the phase word, the clock dimmed in its own colour, the score,
/// the timeline where it stopped, then HOLD TO STOP beside RESUME in the
/// workout's colour. Tap anywhere above the capsules resumes.
struct PausedOverlayView: View {
    @Bindable var viewModel: TimerViewModel

    var body: some View {
        if let session = viewModel.session {
            LiveScreen(session: session, counted: true, paused: true) {
                viewModel.resume()
            } buttons: {
                HStack(spacing: CapsuleGeometry.gap) {
                    HoldToStopCapsule { viewModel.stop() }
                    CapsuleButton(title: "RESUME", fill: Palette.mode(session.workout.timerType), text: .black) {
                        viewModel.resume()
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    PausedOverlayView(viewModel: TimerViewModel())
}
