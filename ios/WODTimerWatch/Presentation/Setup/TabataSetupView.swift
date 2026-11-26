import SwiftUI

/// Tabata setup: WORK (green) and REST (pink) side by side, ROUNDS (blue)
/// below; tap a value to move it with the Crown. Opens on the last Tabata set: every change is
/// remembered (1.3.1). The total rides inside START.
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
        let last = Self.remembered()
        _workSeconds = State(initialValue: last.work)
        _restSeconds = State(initialValue: last.rest)
        _rounds = State(initialValue: last.rounds)
    }

    private static func remembered() -> (work: Double, rest: Double, rounds: Double) {
        let last = SetupMemory().tabata
        func snap(_ s: Int) -> Double { Double(min(120, max(5, s / 5 * 5))) }
        return (snap(last.work.seconds), snap(last.rest.seconds), Double(min(20, max(1, last.rounds))))
    }

    private func load() {
        let last = Self.remembered()
        workSeconds = last.work
        restSeconds = last.rest
        rounds = last.rounds
    }

    static let fieldOrder: [Field] = [.work, .rest, .rounds]

    /// The row's fields, each with the widest value its Crown range
    /// reaches (2:00 of work or rest, 20 rounds), which sets the row's one
    /// size.
    static func items(work: String, rest: String, rounds: String) -> [SetupValueRow.Item] {
        [
            SetupValueRow.Item(label: "WORK", value: work, widest: "2:00", labelColor: Palette.work),
            SetupValueRow.Item(label: "REST", value: rest, widest: "2:00", labelColor: Palette.rest),
            SetupValueRow.Item(label: "ROUNDS", value: rounds, widest: "20", labelColor: Palette.mode("amrap")),
        ]
    }

    private var work: TimerDuration { TimerDuration(seconds: Int(workSeconds)) }
    private var rest: TimerDuration { TimerDuration(seconds: Int(restSeconds)) }
    private var roundCount: RoundCount { RoundCount(value: Int(rounds)) }
    private var total: TimerDuration {
        TimerDuration(seconds: (work.seconds + rest.seconds) * roundCount.value)
    }
    private var type: TimerType { .tabata(workDuration: work, restDuration: rest, rounds: roundCount) }

    private var crownBinding: Binding<Double> {
        switch focusedField {
        case .work: $workSeconds
        case .rest: $restSeconds
        case .rounds: $rounds
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // One row, sized to the room above START (SetupValueRow).
            SetupValueRow(
                items: Self.items(work: work.phase, rest: rest.phase, rounds: "\(Int(rounds))"),
                focused: Self.fieldOrder.firstIndex(of: focusedField) ?? 0
            ) { focusedField = Self.fieldOrder[$0] }
            StartButton(subtitle: "\(total.clock) total") {
                SetupMemory().save(type)
                viewModel.start(workout: WorkoutFactory.create(timerType: type))
                showingTimer = viewModel.session?.state != .ready
            }
            // Spike (24 Oct 2026): the same WOD run by Apple's Workout app.
            RunInWorkoutButton(type: type)
                .padding(.top, CapsuleGeometry.gap)
        }
        .padding(.horizontal, CapsuleGeometry.sideMargin)
        .padding(.bottom, CapsuleGeometry.bottomMargin)
        .focusable()
        .digitalCrownRotation(
            crownBinding,
            from: focusedField == .rounds ? 1 : 5,
            through: focusedField == .rounds ? 20 : 120,
            by: focusedField == .rounds ? 1 : 5,
            sensitivity: .medium
        )
        .navigationTitle("TABATA")
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
    TabataSetupView(viewModel: TimerViewModel())
}
