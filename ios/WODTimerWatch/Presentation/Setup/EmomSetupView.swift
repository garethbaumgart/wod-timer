import SwiftUI

/// EMOM setup: EVERY (green, 15s steps as on the phone) and ROUNDS (blue);
/// tap a value to move it with the Crown. Opens on the last EMOM set: every change is
/// remembered (1.3.1). The total rides inside START.
struct EmomSetupView: View {
    @Bindable var viewModel: TimerViewModel
    @State private var intervalSeconds: Double
    @State private var rounds: Double
    @State private var focusedField: Field = .interval
    @State private var showingTimer = false

    enum Field { case interval, rounds }

    init(viewModel: TimerViewModel) {
        self.viewModel = viewModel
        let last = Self.remembered()
        _intervalSeconds = State(initialValue: last.interval)
        _rounds = State(initialValue: last.rounds)
    }

    private static func remembered() -> (interval: Double, rounds: Double) {
        let last = SetupMemory().emom
        return (Double(min(600, max(15, last.interval.seconds / 15 * 15))), Double(min(30, max(1, last.rounds))))
    }

    private func load() {
        let last = Self.remembered()
        intervalSeconds = last.interval
        rounds = last.rounds
    }

    private var interval: TimerDuration { TimerDuration(seconds: Int(intervalSeconds)) }
    private var roundCount: RoundCount { RoundCount(value: Int(rounds)) }
    private var total: TimerDuration { TimerDuration(seconds: interval.seconds * roundCount.value) }
    private var type: TimerType { .emom(intervalDuration: interval, rounds: roundCount) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            Button { focusedField = .interval } label: {
                SetupValue(label: "EVERY", value: interval.clock, labelColor: Palette.work,
                           size: 36, focused: focusedField == .interval)
            }
            .buttonStyle(.plain)
            Button { focusedField = .rounds } label: {
                SetupValue(label: "ROUNDS", value: "\(Int(rounds))", labelColor: Palette.mode("amrap"),
                           size: 36, focused: focusedField == .rounds)
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
            StartButton(subtitle: "\(total.clock) total") {
                SetupMemory().save(type)
                viewModel.start(workout: WorkoutFactory.create(timerType: type))
                showingTimer = viewModel.session?.state != .ready
            }
        }
        .padding(.horizontal, CapsuleGeometry.sideMargin)
        .padding(.bottom, CapsuleGeometry.bottomMargin)
        .focusable()
        .digitalCrownRotation(
            focusedField == .interval ? $intervalSeconds : $rounds,
            from: focusedField == .interval ? 15 : 1,
            through: focusedField == .interval ? 600 : 30,
            by: focusedField == .interval ? 15 : 1,
            sensitivity: .medium
        )
        .navigationTitle("EMOM")
        .onAppear(perform: load)
        .onChange(of: type) { _, newType in SetupMemory().save(newType) }
        .navigationBarBackButtonHidden(showingTimer)
        // Last, outside the Crown focus container, so it reaches the edge.
        .ignoresSafeArea(edges: .bottom)
        .navigationDestination(isPresented: $showingTimer) {
            ActiveTimerView(viewModel: viewModel)
        }
    }
}

#Preview {
    EmomSetupView(viewModel: TimerViewModel())
}
