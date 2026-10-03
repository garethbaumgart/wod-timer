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
            ScrollViewReader { proxy in
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
                modeRow("FOR TIME", code: "fortime", summary: memory.summary("fortime")) {
                    ForTimeSetupView(viewModel: viewModel)
                }
                modeRow("EMOM", code: "emom", summary: memory.summary("emom")) {
                    EmomSetupView(viewModel: viewModel)
                }
                .id("emom")
                modeRow("AMRAP", code: "amrap", summary: memory.summary("amrap")) {
                    AmrapSetupView(viewModel: viewModel)
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
            .onAppear {
                if CommandLine.arguments.contains("--home-scroll") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        proxy.scrollTo("emom", anchor: .top)
                    }
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

    /// Preview only: Home row layout, `--home-variant WA...WF` at launch.
    static let variant: String = {
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--home-variant"), i + 1 < args.count { return args[i + 1] }
        return ""
    }()

    private func modeRow<Destination: View>(
        _ name: String,
        code: String,
        summary: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        let v = Self.variant
        let parts = SetupMemory().shape(code)
        let total = TimerDuration(seconds: parts.reduce(0) { $0 + $1.0 }).clock
        let accent = Palette.mode(code)
        return NavigationLink(destination: destination()) {
            Group {
                switch v {
                case "WA", "WB", "WE":
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 9) {
                            RoundedRectangle(cornerRadius: 1.5).fill(accent).frame(width: 3.5, height: 34)
                            VStack(alignment: .leading, spacing: 1) {
                                nameText(name)
                                summaryText(summary)
                            }
                        }
                        TimelineBar(parts: parts, accent: code == "tabata" ? Palette.work : accent, height: 6)
                        if v != "WA" { totalText(total) }
                    }
                case "WC":
                    VStack(alignment: .leading, spacing: 4) {
                        nameText(name)
                        summaryText(summary)
                        TimelineBar(parts: parts, accent: accent, height: 7)
                        totalText(total)
                    }
                case "WD":
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 7) {
                            RoundedRectangle(cornerRadius: 1.5).fill(accent).frame(width: 3.5, height: 18)
                            nameText(name, size: 17)
                            Spacer(minLength: 2)
                            summaryText(summary, size: 13)
                        }
                        TimelineBar(parts: parts, accent: code == "tabata" ? Palette.work : accent, height: 6)
                        totalText(total)
                    }
                case "WF":
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 7) {
                            RoundedRectangle(cornerRadius: 1.5).fill(accent).frame(width: 3.5, height: 18)
                            nameText(name, size: 18)
                        }
                        TimelineBar(parts: parts, accent: accent, height: 8)
                        Text("\(summary) · \(total)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                default:
                    HStack(spacing: 9) {
                        RoundedRectangle(cornerRadius: 1.5).fill(accent).frame(width: 3.5, height: 34)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(name)
                                .font(.system(size: 19, weight: .heavy, design: .rounded))
                                .foregroundStyle(Palette.brand)
                            summaryText(summary)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .listRowBackground(
            v == "WE"
                ? AnyView(RoundedRectangle(cornerRadius: 14).fill(
                    LinearGradient(colors: [accent.opacity(0.28), accent.opacity(0.06)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)))
                : nil
        )
    }

    private func nameText(_ name: String, size: CGFloat = 19) -> some View {
        Text(name)
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private func summaryText(_ summary: String, size: CGFloat = 14) -> some View {
        Text(summary)
            .font(.system(size: size, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white.opacity(0.75))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private func totalText(_ total: String) -> some View {
        Text("\(total) total")
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Palette.label)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

/// Preview only: the workout drawn as parts, widths by seconds; rest blue.
struct TimelineBar: View {
    let parts: [(Int, Bool)]
    let accent: Color
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let gap: CGFloat = parts.count > 12 ? 1.5 : 2
            let total = CGFloat(max(1, parts.reduce(0) { $0 + $1.0 }))
            let free = geo.size.width - gap * CGFloat(max(0, parts.count - 1))
            HStack(spacing: gap) {
                ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                    RoundedRectangle(cornerRadius: height / 3)
                        .fill(part.1 ? Palette.rest : accent)
                        .frame(width: max(1, free * CGFloat(part.0) / total))
                }
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

#Preview {
    HomeView()
}
