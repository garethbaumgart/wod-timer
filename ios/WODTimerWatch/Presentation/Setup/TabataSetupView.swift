import SwiftUI

/// Tabata setup: WORK and REST side by side, ROUNDS below; tap a value to
/// move it with the Crown. Opens on the last Tabata started.
struct TabataSetupView: View {
    @Bindable var viewModel: TimerViewModel
    @State private var workSeconds: Double
    @State private var restSeconds: Double
    @State private var rounds: Double
    @State private var focusedField: Field = .work
    @State private var showingTimer = false

    enum Field { case work, rest, rounds }

    init(viewModel: TimerViewModel) {
        self.viewModel = viewModel
        let last = SetupMemory().tabata
        func snap(_ s: Int) -> Double { Double(min(120, max(5, s / 5 * 5))) }
        _workSeconds = State(initialValue: snap(last.work.seconds))
        _restSeconds = State(initialValue: snap(last.rest.seconds))
        _rounds = State(initialValue: Double(min(20, max(1, last.rounds))))
    }

    private var work: TimerDuration { TimerDuration(seconds: Int(workSeconds)) }
    private var rest: TimerDuration { TimerDuration(seconds: Int(restSeconds)) }
    private var roundCount: RoundCount { RoundCount(value: Int(rounds)) }
    private var total: TimerDuration {
        TimerDuration(seconds: (work.seconds + rest.seconds) * roundCount.value)
    }

    private var crownBinding: Binding<Double> {
        switch focusedField {
        case .work: $workSeconds
        case .rest: $restSeconds
        case .rounds: $rounds
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                Button { focusedField = .work } label: {
                    SetupValue(label: "WORK", value: work.phase, labelColor: Palette.work,
                               size: 32, focused: focusedField == .work)
                }
                .buttonStyle(.plain)
                Button { focusedField = .rest } label: {
                    SetupValue(label: "REST", value: rest.phase, labelColor: Palette.rest,
                               size: 32, focused: focusedField == .rest)
                }
                .buttonStyle(.plain)
            }
            Button { focusedField = .rounds } label: {
                SetupValue(label: "ROUNDS", value: "\(Int(rounds))", size: 32, focused: focusedField == .rounds)
            }
            .buttonStyle(.plain)
            Text("\(total.clock) total")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.label)
            Spacer(minLength: 0)
            StartButton {
                let type = TimerType.tabata(workDuration: work, restDuration: rest, rounds: roundCount)
                SetupMemory().save(type)
                viewModel.start(workout: WorkoutFactory.create(timerType: type))
                showingTimer = viewModel.session?.state != .ready
            }
        }
        .padding(.horizontal, 8)
        .focusable()
        .digitalCrownRotation(
            crownBinding,
            from: focusedField == .rounds ? 1 : 5,
            through: focusedField == .rounds ? 20 : 120,
            by: focusedField == .rounds ? 1 : 5,
            sensitivity: .medium
        )
        .navigationTitle("Tabata")
        .navigationBarBackButtonHidden(showingTimer)
        .navigationDestination(isPresented: $showingTimer) {
            ActiveTimerView(viewModel: viewModel)
        }
    }
}

#Preview {
    TabataSetupView(viewModel: TimerViewModel())
}
