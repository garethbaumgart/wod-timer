import SwiftUI

/// End screen (1.3.1): the status word, the config line, the hero in the
/// workout's colour (For Time the time, EMOM / Tabata the rounds, AMRAP
/// the count, fixed with the Crown), one label line (EMOM, Tabata and a
/// stopped AMRAP put the total on it), the timeline filled to where the
/// workout ended, then AGAIN | DONE. A capped For Time shows no score,
/// only the full timeline. Fits without scrolling on every watch size.
struct CompletedView: View {
    @Bindable var viewModel: TimerViewModel

    private static let labelSize: CGFloat = 11

    var body: some View {
        if let session = viewModel.session {
            let type = session.workout.timerType
            let accent = Palette.mode(type)
            let summary = LiveRules.endSummary(
                session, endedEarly: viewModel.endedEarly, endedAtTimeCap: viewModel.endedAtTimeCap
            )
            let bar = TimelineBar(
                parts: type.timelineParts,
                accent: accent,
                height: 5,
                fill: .elapsed(LiveRules.elapsedSeconds(session))
            )
            VStack(spacing: 0) {
                Text(summary.word)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(LiveRules.configLine(type))
                    .font(.system(size: Self.labelSize, weight: .bold, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(Palette.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let hero = summary.hero {
                    Group {
                        if case .amrap = type {
                            RoundsWheel(viewModel: viewModel, accent: accent)
                        } else {
                            BigClock(text: hero, color: accent)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)
                    Text(summary.label)
                        .font(.system(size: Self.labelSize, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .monospacedDigit()
                        .foregroundStyle(Palette.label)
                        .lineLimit(1)
                    TimelineZone(glyphInset: GlyphMetrics.baselineInset(size: Self.labelSize, weight: .bold)) {
                        bar
                    }
                } else {
                    // Time cap: nothing between the config line and the
                    // timeline, which sits midway between it and the buttons.
                    TimelineZone(
                        glyphInset: GlyphMetrics.baselineInset(size: Self.labelSize, weight: .bold),
                        height: nil
                    ) {
                        bar
                    }
                }
                HStack(spacing: CapsuleGeometry.gap) {
                    CapsuleButton(title: "AGAIN", fill: accent, text: .black) { viewModel.restart() }
                    // DONE lands on this mode's setup (the timer was pushed
                    // from it), with the workout just run remembered.
                    CapsuleButton(title: "DONE", fill: Palette.soft) { viewModel.reset() }
                }
                .frame(height: CapsuleGeometry.height)
            }
            .padding(.horizontal, CapsuleGeometry.sideMargin)
            .padding(.bottom, CapsuleGeometry.bottomMargin)
            .ignoresSafeArea(edges: .bottom)
            .navigationBarBackButtonHidden(true)
        }
    }
}

/// The AMRAP count as a wheel the Crown turns: the selected number in AMRAP
/// blue, sized by the same rule as the other end heroes (the time hero's
/// width), with its neighbours dim above and below, faded and clipped to
/// the hero's box (on a 40mm there is no room for them beside a hero-sized
/// count). Focused by default, so the Crown fixes the count the moment the
/// end screen shows.
struct RoundsWheel: View {
    @Bindable var viewModel: TimerViewModel
    let accent: Color
    @State private var value: Double
    @FocusState private var focused: Bool

    /// The other heroes' widest form ("12:34", "10/10"): the count takes
    /// the same size so every end screen reads the same.
    static let heroReference = "10:00"

    init(viewModel: TimerViewModel, accent: Color) {
        self.viewModel = viewModel
        self.accent = accent
        _value = State(initialValue: Double(viewModel.session?.countedRounds ?? 0))
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let size = max(10, min(w / BigClock.ems(Self.heroReference), h / 0.76))
            let count = Int(value.rounded())
            ZStack {
                ZStack {
                    neighbour(count - 1, size: size).offset(y: -size * 0.52)
                    neighbour(count + 1, size: size).offset(y: size * 0.52)
                }
                .frame(width: w, height: h)
                .mask(
                    LinearGradient(
                        stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.3),
                                .init(color: .black, location: 0.7), .init(color: .clear, location: 1)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                Text("\(count)")
                    .font(.system(size: size, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(accent)
                    .frame(width: w, height: size * 1.3)
            }
            .frame(width: w, height: h)
        }
        .focusable()
        .focused($focused)
        .digitalCrownRotation(
            $value, from: 0, through: 999, by: 1,
            sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true
        )
        .onAppear { focused = true }
        .onChange(of: Int(value.rounded())) { old, new in
            viewModel.adjustRounds(by: new - old)
        }
        .accessibilityElement()
        .accessibilityLabel("Rounds")
        .accessibilityValue("\(Int(value.rounded()))")
        .accessibilityHint("Turn the Digital Crown to fix the count")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(999, value + 1)
            case .decrement: value = max(0, value - 1)
            @unknown default: break
            }
        }
    }

    @ViewBuilder
    private func neighbour(_ n: Int, size: CGFloat) -> some View {
        if n >= 0 {
            Text("\(n)")
                .font(.system(size: size * 0.4, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Palette.wheelDim)
        }
    }
}

#Preview {
    CompletedView(viewModel: TimerViewModel())
}
