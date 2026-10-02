import SwiftUI

/// EMOM setup: EVERY (15s steps, as on the phone) and ROUNDS; tap a value
/// to move it with the Crown. Opens on the last EMOM started.
struct EmomSetupView: View {
    @Bindable var viewModel: TimerViewModel
    @State private var intervalSeconds: Double
    @State private var rounds: Double
    @State private var focusedField: Field = .interval
    @State private var showingTimer = false

    enum Field { case interval, rounds }

    init(viewModel: TimerViewModel) {
        self.viewModel = viewModel
        let last = SetupMemory().emom
        _intervalSeconds = State(initialValue: Double(min(600, max(15, last.interval.seconds / 15 * 15))))
        _rounds = State(initialValue: Double(min(30, max(1, last.rounds))))
    }

    private var interval: TimerDuration { TimerDuration(seconds: Int(intervalSeconds)) }
    private var roundCount: RoundCount { RoundCount(value: Int(rounds)) }
    private var total: TimerDuration { TimerDuration(seconds: interval.seconds * roundCount.value) }

    var body: some View {
        VStack(spacing: 2) {
            Spacer(minLength: 0)
            Button { focusedField = .interval } label: {
                SetupValue(label: "EVERY", value: interval.clock, size: 38, focused: focusedField == .interval)
            }
            .buttonStyle(.plain)
            Button { focusedField = .rounds } label: {
                SetupValue(label: "ROUNDS", value: "\(Int(rounds))", size: 38, focused: focusedField == .rounds)
            }
            .buttonStyle(.plain)
            Text("\(total.clock) total")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.label)
            Spacer(minLength: 0)
            StartButton {
                let type = TimerType.emom(intervalDuration: interval, rounds: roundCount)
                SetupMemory().save(type)
                viewModel.start(workout: WorkoutFactory.create(timerType: type))
                showingTimer = viewModel.session?.state != .ready
            }
        }
        .padding(.horizontal, 8)
        .focusable()
        .digitalCrownRotation(
            focusedField == .interval ? $intervalSeconds : $rounds,
            from: focusedField == .interval ? 15 : 1,
            through: focusedField == .interval ? 600 : 30,
            by: focusedField == .interval ? 15 : 1,
            sensitivity: .medium
        )
        .navigationTitle("EMOM")
        .navigationBarBackButtonHidden(showingTimer)
        .navigationDestination(isPresented: $showingTimer) {
            ActiveTimerView(viewModel: viewModel)
        }
    }
}

#Preview {
    EmomSetupView(viewModel: TimerViewModel())
}
