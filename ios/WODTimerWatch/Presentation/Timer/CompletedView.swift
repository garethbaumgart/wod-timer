import SwiftUI

/// Completed state: summary with Restart/Done buttons.
struct CompletedView: View {
    @Bindable var viewModel: TimerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.teal)

            Text("COMPLETE")
                .font(.system(size: 12, weight: .bold))
                .tracking(2)
                .foregroundStyle(.teal)

            if let session = viewModel.session {
                // Summary stats
                if let totalRounds = session.totalRounds {
                    HStack(spacing: 16) {
                        statColumn(label: "ROUNDS", value: "\(totalRounds)")
                        statColumn(label: "TIME", value: session.elapsed.formatted)
                    }
                    .padding(.vertical, 4)
                } else {
                    VStack(spacing: 2) {
                        Text("TOTAL TIME")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        TimerDisplayText(session.elapsed, size: 28)
                    }
                    .padding(.vertical, 4)
                }

                Text("\(session.workout.timerTypeLabel) · \(session.workout.timerType.estimatedDuration.formatted)")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Restart button
            Button {
                viewModel.restart()
            } label: {
                Text("RESTART")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.teal)
            }
            .buttonStyle(.bordered)
            .tint(.teal.opacity(0.2))

            // Done button — back to home
            Button {
                viewModel.reset()
                dismiss()
            } label: {
                Text("DONE")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.bordered)
            .tint(.gray.opacity(0.2))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .navigationBarBackButtonHidden(true)
    }

    private func statColumn(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
                .tracking(1)
            Text(value)
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    CompletedView(viewModel: TimerViewModel())
}
