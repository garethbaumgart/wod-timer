import SwiftUI

/// EMOM setup: tap to focus interval/rounds, Crown adjusts.
struct EmomSetupView: View {
    @Bindable var viewModel: TimerViewModel
    @State private var intervalMinutes: Double = 1
    @State private var rounds: Double = 10
    @State private var focusedField: Field = .interval
    @State private var showingTimer = false

    enum Field { case interval, rounds }

    private var intervalDuration: TimerDuration { TimerDuration(seconds: Int(intervalMinutes) * 60) }
    private var roundCount: RoundCount { RoundCount(value: Int(rounds)) }
    private var totalDuration: TimerDuration {
        TimerDuration(seconds: intervalDuration.seconds * roundCount.value)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("EMOM")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.orange.opacity(0.7))

            Spacer()

            // Interval
            valueRow(
                label: "INTERVAL",
                value: intervalDuration.formatted,
                isFocused: focusedField == .interval
            ) { focusedField = .interval }

            // Rounds
            valueRow(
                label: "ROUNDS",
                value: "\(Int(rounds))",
                isFocused: focusedField == .rounds
            ) { focusedField = .rounds }

            Text("Tap value · Crown adjusts")
                .font(.system(size: 8))
                .foregroundStyle(.orange.opacity(0.4))
                .padding(.top, 2)

            Spacer()

            Text("Total: \(totalDuration.formatted)")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)

            Button {
                let timerType = TimerType.emom(intervalDuration: intervalDuration, rounds: roundCount)
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
        .focusable()
        .digitalCrownRotation(
            focusedField == .interval ? $intervalMinutes : $rounds,
            from: focusedField == .interval ? 1 : 1,
            through: focusedField == .interval ? 10 : 30,
            by: 1,
            sensitivity: .medium
        )
        .navigationBarBackButtonHidden(showingTimer)
        .navigationDestination(isPresented: $showingTimer) {
            ActiveTimerView(viewModel: viewModel)
        }
    }

    private func valueRow(label: String, value: String, isFocused: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            VStack(spacing: 1) {
                Text(label)
                    .font(.system(size: 9))
                    .tracking(1)
                    .foregroundStyle(.orange.opacity(0.6))
                Text(value)
                    .font(.system(size: 28, weight: .ultraLight))
                    .foregroundStyle(isFocused ? .white : .white.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    EmomSetupView(viewModel: TimerViewModel())
}
