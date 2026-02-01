import SwiftUI

/// Tabata setup: work/rest/rounds with tap-to-focus and Crown adjust.
struct TabataSetupView: View {
    @Bindable var viewModel: TimerViewModel
    @State private var workSeconds: Double = 20
    @State private var restSeconds: Double = 10
    @State private var rounds: Double = 8
    @State private var focusedField: Field = .work
    @State private var showingTimer = false

    enum Field { case work, rest, rounds }

    private var workDuration: TimerDuration { TimerDuration(seconds: Int(workSeconds)) }
    private var restDuration: TimerDuration { TimerDuration(seconds: Int(restSeconds)) }
    private var roundCount: RoundCount { RoundCount(value: Int(rounds)) }
    private var totalDuration: TimerDuration {
        TimerDuration(seconds: (workDuration.seconds + restDuration.seconds) * roundCount.value)
    }

    private var crownBinding: Binding<Double> {
        switch focusedField {
        case .work: $workSeconds
        case .rest: $restSeconds
        case .rounds: $rounds
        }
    }

    private var crownRange: ClosedRange<Double> {
        switch focusedField {
        case .work: 5...120
        case .rest: 5...120
        case .rounds: 1...20
        }
    }

    private var crownStep: Double {
        focusedField == .rounds ? 1 : 5
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("TABATA")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.purple.opacity(0.7))

            Spacer()

            // Work / Rest side by side
            HStack(spacing: 12) {
                valueColumn(
                    label: "WORK",
                    value: workDuration.formatted,
                    color: .green,
                    isFocused: focusedField == .work
                ) { focusedField = .work }

                Text("/")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                valueColumn(
                    label: "REST",
                    value: restDuration.formatted,
                    color: .red,
                    isFocused: focusedField == .rest
                ) { focusedField = .rest }
            }

            // Rounds
            Button { focusedField = .rounds } label: {
                VStack(spacing: 1) {
                    Text("ROUNDS")
                        .font(.system(size: 8))
                        .tracking(1)
                        .foregroundStyle(.purple.opacity(0.6))
                    Text("\(Int(rounds))")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(focusedField == .rounds ? .white : .white.opacity(0.5))
                }
            }
            .buttonStyle(.plain)

            Text("Tap value · Crown adjusts")
                .font(.system(size: 8))
                .foregroundStyle(.purple.opacity(0.4))

            Spacer()

            Text("\(totalDuration.formatted) total")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)

            Button {
                let timerType = TimerType.tabata(
                    workDuration: workDuration,
                    restDuration: restDuration,
                    rounds: roundCount
                )
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
            crownBinding,
            from: crownRange.lowerBound,
            through: crownRange.upperBound,
            by: crownStep,
            sensitivity: .medium
        )
        .navigationBarBackButtonHidden(showingTimer)
        .navigationDestination(isPresented: $showingTimer) {
            ActiveTimerView(viewModel: viewModel)
        }
    }

    private func valueColumn(
        label: String,
        value: String,
        color: Color,
        isFocused: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            VStack(spacing: 1) {
                Text(label)
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(isFocused ? color : color.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TabataSetupView(viewModel: TimerViewModel())
}
