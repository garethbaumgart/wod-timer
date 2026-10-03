import SwiftUI

/// The giant live clock: heavy, rounded, phase-coloured, as big as the
/// space allows. Sized from the digit height (digits have no descenders),
/// not the line height, so bare seconds ("53") fill the height the way
/// "9:45" fills the width.
struct BigClock: View {
    let text: String
    let color: Color
    var maxHeight: CGFloat = 92

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            // Advance widths of SF Rounded heavy, in ems (tabular digits).
            let ems = text.reduce(CGFloat(0)) { $0 + ($1 == ":" ? 0.34 : 0.64) }
            let size = max(10, min(w / max(ems, 0.64), h / 0.76))
            Text(text)
                .font(.system(size: size, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(color)
                .frame(width: w, height: size * 1.3)
                .position(x: w / 2, y: h / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: maxHeight)
        .accessibilityLabel(text)
    }
}

/// A setup value under its label ("DURATION", "10:00"), heavy and big.
struct SetupValue: View {
    let label: String
    let value: String
    var labelColor: Color = Palette.label
    var size: CGFloat = 52
    var focused = true

    var body: some View {
        VStack(spacing: 0) {
            Text(label)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(labelColor)
            Text(value)
                .font(.system(size: size, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(focused ? .white : .white.opacity(0.45))
        }
    }
}

/// The green START, the only green control on a setup screen. EMOM and
/// Tabata carry their computed total inside it ("10:00 total"), where it
/// is new information; AMRAP and For Time already show it as their value.
struct StartButton: View {
    var subtitle: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: -1) {
                Text("START")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .opacity(0.72)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Palette.primary)
        .foregroundStyle(.black)
        .accessibilityLabel(subtitle.map { "Start, \($0)" } ?? "Start")
    }
}

/// Round control: Pause (outlined) or Resume (filled white).
struct PauseDisc: View {
    let paused: Bool
    var size: CGFloat = 40
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(paused ? Color.white : Color.white.opacity(0.12))
                Circle().stroke(Color.white.opacity(paused ? 0 : 0.8), lineWidth: 2)
                Image(systemName: paused ? "play.fill" : "pause.fill")
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(paused ? Color.black : Color.white)
                    .offset(x: paused ? size * 0.04 : 0)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(paused ? "Resume" : "Pause")
    }
}

/// For Time's success action: white, labelled.
struct FinishButton: View {
    var compact = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "flag.fill").font(.system(size: 13, weight: .bold))
                if !compact {
                    Text("FINISH").font(.system(size: 15, weight: .heavy, design: .rounded))
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: compact ? 40 : .infinity, minHeight: 36)
            .background(Capsule().fill(Color.white))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Finish workout and log your time")
    }
}

/// End control that must be held (0.8s). A short press shows HOLD inside
/// the button; the red ring fills while the finger stays down.
struct HoldToEndButton: View {
    let onConfirmed: () -> Void
    @State private var fill: CGFloat = 0
    @State private var showHint = false

    var body: some View {
        ZStack {
            Circle().fill(Palette.error.opacity(0.12))
            Circle().stroke(Palette.error.opacity(showHint ? 1 : 0.7), lineWidth: 1.5)
            Circle()
                .trim(from: 0, to: fill)
                .stroke(Palette.error, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if showHint {
                Text("HOLD")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.error)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Palette.error)
                    .frame(width: 14, height: 14)
            }
        }
        .frame(width: 44, height: 44)
        .contentShape(Circle())
        .onTapGesture { flashHint() }
        .onLongPressGesture(minimumDuration: 0.8, maximumDistance: 30) {
            onConfirmed()
        } onPressingChanged: { pressing in
            if pressing {
                withAnimation(.linear(duration: 0.8)) { fill = 1 }
            } else {
                withAnimation(.easeOut(duration: 0.15)) { fill = 0 }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("End workout. Hold to confirm.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "End workout") { onConfirmed() }
    }

    private func flashHint() {
        showHint = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { showHint = false }
    }
}

#Preview {
    BigClock(text: "9:45", color: Palette.work).background(.black)
}

/// The phone's progress bar: a slim track filling in the phase colour, with
/// a tick between rounds for EMOM and Tabata.
struct ProgressBar: View {
    let progress: Double
    let color: Color
    var rounds: Int?

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Color(hex: 0x2A2A34))
                Capsule()
                    .fill(color)
                    .frame(width: max(0, min(1, progress)) * w)
                if let rounds, rounds > 1 {
                    ForEach(1 ..< rounds, id: \.self) { i in
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 1.5)
                            .offset(x: w * CGFloat(i) / CGFloat(rounds))
                    }
                }
            }
        }
        .frame(height: 5)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}
