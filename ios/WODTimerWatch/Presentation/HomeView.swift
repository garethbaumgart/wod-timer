import SwiftUI

/// Home (1.3.1): the stacked Wharf WOD wordmark as the first row, then the
/// four timers in the phone's order (For Time, EMOM, AMRAP, Tabata), each a
/// mode-colour bar, the name in white, the workout it will start and that
/// workout drawn as a timeline. The voice row is unchanged.
struct HomeView: View {
    @State private var viewModel = TimerViewModel()
    @State private var showingTimer = false
    /// Bumped on appear so the remembered workouts refresh after a run.
    @State private var refresh = 0

    /// Every Home screen lists the modes in this order.
    static let modeOrder = Palette.modeOrder

    static func title(_ code: String) -> String {
        switch code {
        case "fortime": "FOR TIME"
        case "emom": "EMOM"
        case "amrap": "AMRAP"
        default: "TABATA"
        }
    }

    var body: some View {
        NavigationStack {
            let memory = SetupMemory()
            let _ = refresh
            ScrollViewReader { proxy in
                List {
                    // The stacked wordmark is too tall for the title slot,
                    // so it is the first row and scrolls away with the list.
                    Image("Wordmark")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 50)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .listRowBackground(Color.clear)
                        .accessibilityLabel("Wharf WOD")
                        .accessibilityAddTraits(.isHeader)
                    ForEach(Self.modeOrder, id: \.self) { code in
                        modeRow(code, summary: memory.summary(code))
                            .id(code)
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
                .onAppear { captureScroll(proxy) }
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

    /// Capture hook: the `home-scrolled` scene shows the lower rows.
    private func captureScroll(_ proxy: ScrollViewProxy) {
        #if targetEnvironment(simulator)
        if CaptureScene.fromLaunchArguments() == .homeScrolled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(nil) { proxy.scrollTo("emom", anchor: .top) }
            }
        }
        #endif
    }

    private var voiceLabel: String {
        let audio = viewModel.audio
        if audio.muted { return "Silent" }
        if audio.beepsOnly { return "Beeps" }
        if audio.randomizePerCue { return "Random" }
        return audio.voicePack.rawValue.capitalized
    }

    @ViewBuilder
    private func setup(_ code: String) -> some View {
        switch code {
        case "fortime": ForTimeSetupView(viewModel: viewModel)
        case "emom": EmomSetupView(viewModel: viewModel)
        case "amrap": AmrapSetupView(viewModel: viewModel)
        default: TabataSetupView(viewModel: viewModel)
        }
    }

    private func modeRow(_ code: String, summary: String) -> some View {
        let accent = Palette.mode(code)
        return NavigationLink(destination: setup(code)) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 9) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(accent)
                        .frame(width: 3.5, height: 34)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(Self.title(code))
                            .font(.system(size: 19, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(summary)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                TimelineBar(parts: SetupMemory().shape(code), accent: accent, height: 6)
            }
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    HomeView()
}
