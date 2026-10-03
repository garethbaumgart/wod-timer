import SwiftUI

/// For Time setup: the cap (whole minutes on the Crown) and the count
/// direction as one tappable line. Opens on the last For Time set: every
/// change is remembered (1.3.1).
struct ForTimeSetupView: View {
    @Bindable var viewModel: TimerViewModel
    @State private var capMinutes: Double
    @State private var countUp: Bool
    @State private var showingTimer = false

    init(viewModel: TimerViewModel) {
        self.viewModel = viewModel
        let last = SetupMemory().forTime
        _capMinutes = State(initialValue: Double(max(1, last.cap.seconds / 60)))
        _countUp = State(initialValue: last.countUp)
    }

    private var timeCap: TimerDuration { TimerDuration(seconds: Int(capMinutes) * 60) }
    private var type: TimerType { .forTime(timeCap: timeCap, countUp: countUp) }

    private func load() {
        let last = SetupMemory().forTime
        capMinutes = Double(max(1, last.cap.seconds / 60))
        countUp = last.countUp
    }

    var body: some View {
        VStack(spacing: 4) {
            Spacer(minLength: 0)
            SetupValue(label: "TIME CAP", value: timeCap.clock)
                .focusable()
                .digitalCrownRotation($capMinutes, from: 1, through: 60, by: 1, sensitivity: .medium)
            Button { countUp.toggle() } label: {
                VStack(spacing: 0) {
                    Text(countUp ? "COUNTS UP" : "COUNTS DOWN")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.white)
                    Text("TAP TO CHANGE")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Palette.label)
                }
                .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
            StartButton {
                SetupMemory().save(type)
                viewModel.start(workout: WorkoutFactory.create(timerType: type))
                showingTimer = viewModel.session?.state != .ready
            }
        }
        .padding(.horizontal, 8)
        .navigationTitle("FOR TIME")
        .onAppear(perform: load)
        .onChange(of: type) { _, newType in SetupMemory().save(newType) }
        .navigationBarBackButtonHidden(showingTimer)
        .navigationDestination(isPresented: $showingTimer) {
            ActiveTimerView(viewModel: viewModel)
        }
    }
}

#Preview {
    ForTimeSetupView(viewModel: TimerViewModel())
}
