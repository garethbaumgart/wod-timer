import SwiftUI

/// For Time setup: Digital Crown for cap, UP/DOWN toggle.
struct ForTimeSetupView: View {
    @Bindable var viewModel: TimerViewModel
    @State private var capMinutes: Double = 20
    @State private var countUp = true
    @State private var showingTimer = false

    private var capSeconds: Int { Int(capMinutes) * 60 }
    private var timeCap: TimerDuration { TimerDuration(seconds: capSeconds) }

    var body: some View {
        VStack(spacing: 4) {
            Text("FOR TIME")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.blue.opacity(0.7))

            Spacer()

            Text("Time Cap")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            TimerDisplayText(timeCap, size: 42)
                .focusable()
                .digitalCrownRotation(
                    $capMinutes,
                    from: 1,
                    through: 60,
                    by: 1,
                    sensitivity: .medium
                )

            // Count direction toggle
            HStack(spacing: 4) {
                directionButton("UP", isSelected: countUp) { countUp = true }
                directionButton("DOWN", isSelected: !countUp) { countUp = false }
            }
            .padding(.top, 4)

            Text("Crown to adjust")
                .font(.system(size: 9))
                .foregroundStyle(.blue.opacity(0.4))

            Spacer()

            Text("10s prep + \(timeCap.formatted) cap")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)

            Button {
                let timerType = TimerType.forTime(timeCap: timeCap, countUp: countUp)
                let workout = WorkoutFactory.create(timerType: timerType)
                viewModel.start(workout: workout)
                showingTimer = true
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

    private func directionButton(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .blue.opacity(0.6))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ForTimeSetupView(viewModel: TimerViewModel())
}
