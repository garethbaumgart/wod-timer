import SwiftUI

/// AMRAP setup: one number (the Crown moves it in whole minutes), START.
/// Opens on the last AMRAP set: every change is remembered (1.3.1), not
/// only the ones that were started.
struct AmrapSetupView: View {
    @Bindable var viewModel: TimerViewModel
    @State private var durationMinutes: Double
    @State private var showingTimer = false

    init(viewModel: TimerViewModel) {
        self.viewModel = viewModel
        _durationMinutes = State(initialValue: Double(max(1, SetupMemory().amrap.seconds / 60)))
    }

    private var duration: TimerDuration { TimerDuration(seconds: Int(durationMinutes) * 60) }
    private var type: TimerType { .amrap(duration: duration) }

    private func load() {
        durationMinutes = Double(max(1, SetupMemory().amrap.seconds / 60))
    }

    var body: some View {
        VStack(spacing: 4) {
            Spacer(minLength: 0)
            SetupValue(label: "DURATION", value: duration.clock)
                .focusable()
                .digitalCrownRotation($durationMinutes, from: 1, through: 60, by: 1, sensitivity: .medium)
            Spacer(minLength: 0)
            StartButton {
                SetupMemory().save(type)
                viewModel.start(workout: WorkoutFactory.create(timerType: type))
                showingTimer = viewModel.session?.state != .ready
            }
        }
        .padding(.horizontal, 8)
        .navigationTitle("AMRAP")
        .onAppear(perform: load)
        .onChange(of: type) { _, newType in SetupMemory().save(newType) }
        .navigationBarBackButtonHidden(showingTimer)
        .navigationDestination(isPresented: $showingTimer) {
            ActiveTimerView(viewModel: viewModel)
        }
    }
}

#Preview {
    AmrapSetupView(viewModel: TimerViewModel())
}
