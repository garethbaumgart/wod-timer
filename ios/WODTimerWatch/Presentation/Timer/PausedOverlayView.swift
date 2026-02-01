import SwiftUI

/// Paused state: big Resume + smaller End button.
/// Resume is larger and green to prevent accidental workout termination.
struct PausedOverlayView: View {
    @Bindable var viewModel: TimerViewModel

    var body: some View {
        VStack(spacing: 4) {
            Text("PAUSED")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2)
                .foregroundStyle(.orange)

            if let session = viewModel.session {
                TimerDisplayText(session.timeRemaining, size: 38)
                    .opacity(0.6)

                Text(session.workout.timerTypeLabel)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Resume button — large and green
            Button {
                viewModel.resume()
            } label: {
                Text("RESUME")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            // End button — smaller and red
            Button {
                viewModel.stop()
            } label: {
                Text("END")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.bordered)
            .tint(.red.opacity(0.3))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    PausedOverlayView(viewModel: TimerViewModel())
}
