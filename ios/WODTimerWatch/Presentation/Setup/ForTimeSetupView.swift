import SwiftUI

/// For Time setup: the cap (whole minutes on the Crown) and the count
/// direction as a two-option switch, like the phone (1.3.1). Opens on the last For Time set: every
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
            SetupValue(label: "TIME CAP", value: timeCap.clock, size: 46)
                .focusable()
                .digitalCrownRotation($capMinutes, from: 1, through: 60, by: 1, sensitivity: .medium)
            CountDirectionSwitch(countUp: $countUp)
            Spacer(minLength: 0)
            StartButton(subtitle: "\(countUp ? "Counts up" : "Counts down") · cap \(timeCap.clock)") {
                SetupMemory().save(type)
                viewModel.start(workout: WorkoutFactory.create(timerType: type))
                showingTimer = viewModel.session?.state != .ready
            }
        }
        .padding(.horizontal, CapsuleGeometry.sideMargin)
        .padding(.bottom, CapsuleGeometry.bottomMargin)
        .navigationTitle("FOR TIME")
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

/// "COUNT UP" | "COUNT DOWN": the selected option white with black text,
/// on a soft pill.
struct CountDirectionSwitch: View {
    @Binding var countUp: Bool

    var body: some View {
        HStack(spacing: 2) {
            option("COUNT UP", selected: countUp) { countUp = true }
            option("COUNT DOWN", selected: !countUp) { countUp = false }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 13).fill(Palette.soft))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Count direction")
    }

    private func option(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(0.6)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(selected ? .black : Palette.label)
                .frame(maxWidth: .infinity)
                .frame(height: 22)
                .background(RoundedRectangle(cornerRadius: 10).fill(selected ? Color.white : Color.clear))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

#Preview {
    ForTimeSetupView(viewModel: TimerViewModel())
}
