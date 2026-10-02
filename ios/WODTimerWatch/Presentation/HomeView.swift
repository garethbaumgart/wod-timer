import SwiftUI

/// Home: the four timers, each showing the workout it will start (the last
/// one run), and the voice. No icons, no definitions, no colour codes:
/// colour means phase, as on the phone.
struct HomeView: View {
    @State private var viewModel = TimerViewModel()
    @State private var showingTimer = false
    /// Bumped on appear so the remembered workouts refresh after a run.
    @State private var refresh = 0

    var body: some View {
        NavigationStack {
            let memory = SetupMemory()
            let _ = refresh
            List {
                modeRow("AMRAP", summary: memory.summary("amrap")) {
                    AmrapSetupView(viewModel: viewModel)
                }
                modeRow("FOR TIME", summary: memory.summary("fortime")) {
                    ForTimeSetupView(viewModel: viewModel)
                }
                modeRow("EMOM", summary: memory.summary("emom")) {
                    EmomSetupView(viewModel: viewModel)
                }
                modeRow("TABATA", summary: memory.summary("tabata")) {
                    TabataSetupView(viewModel: viewModel)
                }
                NavigationLink {
                    VoiceSettingsView(viewModel: viewModel)
                } label: {
                    HStack {
                        Text("Voice")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Spacer()
                        Text(voiceLabel)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.label)
                    }
                }
            }
            .navigationTitle("Wharf WOD")
            .navigationDestination(isPresented: $showingTimer) {
                ActiveTimerView(viewModel: viewModel)
            }
            .onAppear {
                refresh += 1
                // Promo-footage hook: `simctl launch ... --promo-autostart`
                // starts a default AMRAP after a beat so the simulator can be
                // recorded without driving the UI. No effect in normal use.
                if CommandLine.arguments.contains("--promo-autostart") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        viewModel.start(workout: WorkoutFactory.defaultAmrap())
                        showingTimer = true
                    }
                }
            }
        }
    }

    private var voiceLabel: String {
        let audio = viewModel.audio
        if audio.muted { return "Silent" }
        if audio.randomizePerCue { return "Random" }
        return audio.voicePack.rawValue.capitalized
    }

    private func modeRow<Destination: View>(
        _ name: String,
        summary: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                Text(summary)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    HomeView()
}
