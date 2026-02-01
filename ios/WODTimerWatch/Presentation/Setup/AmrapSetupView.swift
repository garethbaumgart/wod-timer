import SwiftUI

/// AMRAP setup: Digital Crown adjusts duration, large START button.
struct AmrapSetupView: View {
    @Bindable var viewModel: TimerViewModel
    @State private var durationMinutes: Double = 10
    @State private var showingTimer = false

    private var durationSeconds: Int { Int(durationMinutes) * 60 }
    private var duration: TimerDuration { TimerDuration(seconds: durationSeconds) }
    private var prepSeconds: Int { 10 }

    var body: some View {
        VStack(spacing: 4) {
            Text("AMRAP")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.green.opacity(0.7))

            Spacer()

            Text("Duration")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            TimerDisplayText(duration, size: 42)
                .focusable()
                .digitalCrownRotation(
                    $durationMinutes,
                    from: 1,
                    through: 60,
                    by: 1,
                    sensitivity: .medium
                )

            Text("Crown to adjust")
                .font(.system(size: 9))
                .foregroundStyle(.green.opacity(0.4))

            Spacer()

            Text("10s prep + \(duration.formatted) work")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)

            Button {
                let timerType = TimerType.amrap(duration: duration)
                let workout = WorkoutFactory.create(timerType: timerType)
                viewModel.start(workout: workout)
                showingTimer = viewModel.session?.state != .ready
            } label: {
                Text("START")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding(.horizontal, 8)
        .navigationBarBackButtonHidden(showingTimer)
        .navigationDestination(isPresented: $showingTimer) {
            ActiveTimerView(viewModel: viewModel)
        }
    }
}

#Preview {
    AmrapSetupView(viewModel: TimerViewModel())
}
