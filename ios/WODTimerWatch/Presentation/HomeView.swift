import SwiftUI

/// Home: the Wharf WOD wordmark, the four timers (a mode-colour bar, the
/// name in brand orange, the workout it will start), and the voice. The
/// bars match the phone's Home strips (1.3.1).
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
                // Stacked wordmark as the list header: too tall for the
                // title slot, so it scrolls away with the list.
                Image("Wordmark")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowBackground(Color.clear)
                    .accessibilityLabel("Wharf WOD")
                modeRow("AMRAP", code: "amrap", summary: memory.summary("amrap")) {
                    AmrapSetupView(viewModel: viewModel)
                }
                modeRow("FOR TIME", code: "fortime", summary: memory.summary("fortime")) {
                    ForTimeSetupView(viewModel: viewModel)
                }
                modeRow("EMOM", code: "emom", summary: memory.summary("emom")) {
                    EmomSetupView(viewModel: viewModel)
                }
                modeRow("TABATA", code: "tabata", summary: memory.summary("tabata")) {
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
        if audio.beepsOnly { return "Beeps" }
        if audio.randomizePerCue { return "Random" }
        return audio.voicePack.rawValue.capitalized
    }

    private func modeRow<Destination: View>(
        _ name: String,
        code: String,
        summary: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 9) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Palette.mode(code))
                    .frame(width: 3.5, height: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text(name)
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.brand)
                    Text(summary)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    HomeView()
}
