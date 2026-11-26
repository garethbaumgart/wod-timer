import HealthKit
import SwiftUI
import WatchKit

/// Home: the four timers in the phone's order (For Time, EMOM, AMRAP,
/// Tabata), then the Voice and Health rows (2.2.0). Since 2.7.0 it is laid
/// out as on Wear OS: the wordmark on one line in the top bar, beside the
/// clock, and the timers as a 2x2 of tiles that fills the first screen,
/// each with its name in its colour, the workout it will start and that
/// workout drawn as a timeline. Before, the stacked wordmark was the first
/// row and the timers full-width rows under it: a 40mm showed one and a
/// half of them and a 49mm two (watch review, 26 Nov 2026).
struct HomeView: View {
    @State private var viewModel = TimerViewModel()
    @State private var showingTimer = false
    /// The mode whose setup is pushed (a tile was tapped).
    @State private var openedMode: String?
    /// True once the list has moved up under the top bar: the wordmark
    /// steps aside rather than sit over a tile's name.
    @State private var scrolled = false
    /// Bumped on appear so the remembered workouts refresh after a run.
    @State private var refresh = 0
    /// The Return to App row shows until the athlete has read it (2.4.0).
    @State private var stayOnScreenSeen = UserDefaults.standard.bool(forKey: StayOnScreenView.seenKey)

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
            // The room between the top bar and the display's bottom corners:
            // the grid is exactly that tall, so no tile is cut by a corner,
            // and the rows after it start below the fold.
            GeometryReader { screen in
            ScrollViewReader { proxy in
                List {
                    ModeGrid(tiles: Self.tiles(memory)) { top in
                        let now = HomeGrid.isScrolled(gridTop: top, restingTop: screen.frame(in: .global).minY)
                        if now != scrolled { scrolled = now }
                    } onOpen: {
                        openedMode = $0
                    }
                        .frame(height: HomeGrid.height(safeHeight: screen.size.height))
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    if !stayOnScreenSeen {
                        NavigationLink {
                            StayOnScreenView { stayOnScreenSeen = true }
                        } label: {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Stay on screen")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                Text("One watch setting")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(Palette.label)
                            }
                        }
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
                    .id("voice")
                    if let tracker = viewModel.tracker as? HealthWorkoutTracker {
                        NavigationLink {
                            HealthSettingsView(tracker: tracker, alerts: viewModel.alerts, note: viewModel.sessionNote)
                        } label: {
                            HStack {
                                Text("Health")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                Spacer()
                                Text(Self.healthLabel(tracker))
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Palette.label)
                            }
                        }
                    }
                }
                .onAppear { captureScroll(proxy) }
            }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    WordmarkLine()
                        .opacity(scrolled ? 0 : 1)
                        .animation(.easeOut(duration: 0.15), value: scrolled)
                }
            }
            .navigationDestination(isPresented: $showingTimer) {
                ActiveTimerView(viewModel: viewModel)
            }
            .navigationDestination(item: $openedMode) { code in
                setup(code)
            }
            .onAppear {
                refresh += 1
                // The one Health permission (save workouts), asked here as
                // workout apps do, never during a countdown.
                (viewModel.tracker as? HealthWorkoutTracker)?.requestAuthorizationIfNeeded()
                // The alerts permission (2.4.0), asked the same way: the
                // system taps the wrist at each change when no Health
                // session keeps the app alive.
                viewModel.alerts.requestAuthorizationIfNeeded(completion: nil)
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
                withAnimation(nil) { proxy.scrollTo("voice", anchor: .top) }
            }
        }
        #endif
    }

    static func healthLabel(_ tracker: HealthWorkoutTracker) -> String {
        healthLabel(enabled: tracker.enabled, authorization: tracker.authorization)
    }

    /// Honest about the one case 2.2.0 hid: a permission sheet dismissed
    /// without an answer left the row on "On" while no session ever ran.
    static func healthLabel(enabled: Bool, authorization: HKAuthorizationStatus) -> String {
        guard enabled else { return "Off" }
        switch authorization {
        case .sharingDenied: return "Not allowed"
        case .notDetermined: return "Not answered"
        default: return "On"
        }
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

    /// The four timers as Home's tiles, each with its remembered workout.
    static func tiles(_ memory: SetupMemory) -> [HomeGrid.Tile] {
        modeOrder.map {
            HomeGrid.Tile(code: $0, title: title($0), summary: memory.tileSummary($0), parts: memory.shape($0))
        }
    }
}

/// The four timers, two to a row, in Home's order read left to right. The
/// names share one size and the workouts another, set from the widest of
/// each against the tile's real width, so no tile's text is smaller than
/// its neighbour's.
struct ModeGrid: View {
    let tiles: [HomeGrid.Tile]
    /// The grid's top on the screen, as the list scrolls.
    var onTopChange: (CGFloat) -> Void = { _ in }
    let onOpen: (String) -> Void

    var body: some View {
        GeometryReader { geo in
            let metrics = HomeGrid.metrics()
            let fit = HomeGrid.fit(tiles, gridWidth: geo.size.width, metrics: metrics)
            let top = geo.frame(in: .global).minY
            VStack(spacing: HomeGrid.gap) {
                ForEach(HomeGrid.rows(tiles), id: \.first?.code) { row in
                    HStack(spacing: HomeGrid.gap) {
                        ForEach(row, id: \.code) { tile in
                            ModeTile(tile: tile, metrics: metrics, fit: fit) { onOpen(tile.code) }
                        }
                    }
                }
            }
            .onAppear { onTopChange(top) }
            .onChange(of: top) { _, new in onTopChange(new) }
        }
    }
}

/// The wordmark on one line, for the top bar: WHARF in white, WOD in the
/// brand green, the full stop in the brand pink, as the Wear OS Home
/// writes it.
struct WordmarkLine: View {
    /// 15pt on a 40mm, where it has to clear a four-digit clock, growing
    /// with the screen to 17pt.
    static func size(screenWidth: CGFloat = WKInterfaceDevice.current().screenBounds.width) -> CGFloat {
        (15 * min(1.15, max(1, screenWidth / 162))).rounded()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("WHARF")
                .foregroundStyle(.white)
            (Text("WOD").foregroundStyle(Palette.primary) + Text(".").foregroundStyle(Palette.rest))
        }
        .font(.system(size: Self.size(), weight: .heavy, design: .rounded))
        .lineLimit(1)
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Wharf WOD")
        .accessibilityAddTraits(.isHeader)
    }
}

/// Home's grid (2.7.0): the sizes of a tile, drawn for the 40mm and grown
/// with the screen's width up to the 49mm.
enum HomeGrid {
    static let gap: CGFloat = 4
    static let columns = 2

    struct Tile: Equatable {
        let code: String
        let title: String
        let summary: String
        let parts: [TimelinePart]
    }

    struct Metrics: Equatable {
        let title: CGFloat
        let summary: CGFloat
        let padding: CGFloat
        let bar: CGFloat
        let radius: CGFloat
    }

    /// The grid is as tall as the screen's safe area, less the point the
    /// list keeps above its first row; never so short a tile's lines touch.
    static func height(safeHeight: CGFloat) -> CGFloat {
        max(2 * 52 + gap, safeHeight - 1)
    }

    /// The list counts as scrolled once the grid's top is this far above
    /// where it rests (the top of the safe area).
    static let scrolledAfter: CGFloat = 6

    static func isScrolled(gridTop: CGFloat, restingTop: CGFloat) -> Bool {
        gridTop < restingTop - scrolledAfter
    }

    /// The text sizes the four tiles share.
    struct Fit: Equatable {
        let title: CGFloat
        let summary: CGFloat
    }

    /// Text may sit this close to a tile's side (the timeline keeps the
    /// full padding).
    static let textInset: CGFloat = 4
    /// No smaller than this, whatever the workout: past it the one line
    /// that still does not fit shrinks alone.
    static let smallestSummary: CGFloat = 9
    static let smallestTitle: CGFloat = 12

    /// Home's order, two to a row.
    static func rows<T>(_ order: [T]) -> [[T]] {
        stride(from: 0, to: order.count, by: columns).map { Array(order[$0 ..< min($0 + columns, order.count)]) }
    }

    static func tileWidth(gridWidth: CGFloat) -> CGFloat {
        (gridWidth - gap * CGFloat(columns - 1)) / CGFloat(columns)
    }

    /// The width of `text` at `size`, with the room digits take once they
    /// are set to one width.
    static func textWidth(_ text: String, size: CGFloat, weight: UIFont.Weight) -> CGFloat {
        let font = GlyphMetrics.font(size: size, weight: weight)
        let drawn = (text as NSString).size(withAttributes: [.font: font]).width
        let digits = CGFloat(text.filter(\.isNumber).count)
        return drawn + digits * size * 0.03
    }

    /// The base size, or the largest half point at which the widest of
    /// `texts` fits `room`, never under `floor`.
    static func commonSize(_ texts: [String], base: CGFloat, weight: UIFont.Weight, room: CGFloat, floor: CGFloat) -> CGFloat {
        let widest = texts.map { textWidth($0, size: base, weight: weight) }.max() ?? 0
        guard widest > room, widest > 0 else { return base }
        return max(floor, (base * room / widest * 2).rounded(.down) / 2)
    }

    static func fit(_ tiles: [Tile], gridWidth: CGFloat, metrics: Metrics) -> Fit {
        let room = tileWidth(gridWidth: gridWidth) - 2 * textInset
        return Fit(
            title: commonSize(tiles.map(\.title), base: metrics.title, weight: .heavy, room: room, floor: smallestTitle),
            summary: commonSize(tiles.map(\.summary), base: metrics.summary, weight: .semibold, room: room, floor: smallestSummary)
        )
    }

    static func metrics(screenWidth: CGFloat = WKInterfaceDevice.current().screenBounds.width) -> Metrics {
        let scale = min(1.3, max(1, screenWidth / 162))
        return Metrics(
            title: (14 * scale).rounded(),
            summary: (12 * scale).rounded(),
            padding: (7 * scale).rounded(),
            bar: (5 * scale).rounded(),
            radius: (16 * scale).rounded()
        )
    }
}

/// One timer on Home: its name in its colour, the workout it will start,
/// and that workout as a timeline. Every line has a fixed height, so the
/// four tiles are one size whatever they say.
struct ModeTile: View {
    let tile: HomeGrid.Tile
    let metrics: HomeGrid.Metrics
    let fit: HomeGrid.Fit
    let action: () -> Void

    var body: some View {
        let accent = Palette.mode(tile.code)
        Button(action: action) {
            VStack(spacing: 0) {
                // The name and the workout sit midway between the tile's top
                // and its timeline, which keeps the foot of the tile.
                VStack(spacing: 1) {
                    Text(tile.title)
                        .font(.system(size: fit.title, weight: .heavy, design: .rounded))
                        .foregroundStyle(accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(height: (metrics.title * 1.2).rounded())
                    Text(tile.summary)
                        .font(.system(size: fit.summary, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(height: (metrics.summary * 1.25).rounded())
                }
                .padding(.horizontal, HomeGrid.textInset - metrics.padding)
                .frame(maxHeight: .infinity)
                TimelineBar(parts: tile.parts, accent: accent, height: metrics.bar)
            }
            .padding(.horizontal, metrics.padding)
            .padding(.top, 2)
            .padding(.bottom, (metrics.padding * 1.3).rounded())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: metrics.radius, style: .continuous).fill(Palette.soft))
            .contentShape(RoundedRectangle(cornerRadius: metrics.radius, style: .continuous))
        }
        .buttonStyle(TileButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(tile.title), \(tile.summary)")
        .accessibilityAddTraits(.isButton)
    }
}

/// A tile gives under the finger, as the system's rows do.
struct TileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    HomeView()
}
