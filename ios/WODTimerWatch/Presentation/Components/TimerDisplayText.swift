import CoreText
import SwiftUI
import UIKit
import WatchKit

/// The giant live clock: heavy, rounded, in the workout's colour, as big
/// as the space allows. Its size is set once from `reference`, the longest
/// value the workout can show (1.3.1), so it never refits as it counts.
/// Sized from the digit height (digits have no descenders), not the line
/// height, so bare seconds ("53") fill the height the way "9:45" fills the
/// width.
struct BigClock: View {
    let text: String
    var reference: String? = nil
    let color: Color
    var maxHeight: CGFloat = .infinity

    /// Advance widths of SF Rounded heavy, in ems (tabular digits).
    static func ems(_ text: String) -> CGFloat {
        text.reduce(CGFloat(0)) { $0 + ($1 == ":" ? 0.34 : $1 == "/" ? 0.42 : 0.64) }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            // Digits fill 0.76 em of height; a slash ("8/8") reaches above
            // and below them, so it gets the taller allowance.
            let heightEm: CGFloat = (reference ?? text).contains("/") ? 0.98 : 0.76
            let size = max(10, min(w / max(Self.ems(reference ?? text), 0.64), h / heightEm))
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

    /// Value sizes are drawn for the 46mm and shrink with the height left
    /// under the title bar (about 58pt of every screen is title bar and
    /// bottom margin), so every setup screen fits above START on a 40mm.
    static func scaled(_ base: CGFloat) -> CGFloat {
        let usable = WKInterfaceDevice.current().screenBounds.height - 58
        return (base * min(1, max(0.6, usable / 190))).rounded()
    }

    /// True when `size` is already the size to draw at (SetupValueRow fits
    /// it to the room it measured), so the screen-height rule is skipped.
    var exact = false
    var labelSize: CGFloat = SetupValue.standardLabelSize

    static let standardLabelSize: CGFloat = 12

    /// Label letter spacing, a tenth of the size (1.2 at 12pt).
    static func tracking(_ labelSize: CGFloat) -> CGFloat { labelSize * 0.1 }

    var body: some View {
        VStack(spacing: 0) {
            Text(label)
                .font(.system(size: labelSize, weight: .bold, design: .rounded))
                .tracking(Self.tracking(labelSize))
                .lineLimit(1)
                .fixedSize()
                .foregroundStyle(labelColor)
            Text(value)
                .font(.system(size: exact ? size : Self.scaled(size), weight: .heavy, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(focused ? .white : .white.opacity(0.45))
        }
    }
}

/// The values of an interval setup side by side (26 Nov 2026): EMOM's
/// EVERY and ROUNDS, Tabata's WORK, REST and ROUNDS. Stacked, with START
/// and RUN IN WORKOUT under them, they needed more height than any watch
/// has: the column overflowed both ways, so the labels ran up into the
/// title and back button and the values shrank to about 12pt on a 40mm (20pt on
/// a 49mm), the smallest text on a screen that exists to set them. One
/// row takes the room that is really there (measured, not guessed from
/// the screen height) and gives every value one size: the largest at
/// which each cell, as wide as its label or the widest value the Crown
/// can reach, fits the width, and a label over a value fits the height.
/// Cell widths are fixed per field, so nothing moves or resizes as the
/// Crown turns.
struct SetupValueRow: View {
    struct Item: Equatable {
        let label: String
        let value: String
        /// The widest value the Crown can reach in this field.
        let widest: String
        let labelColor: Color
    }

    /// How a row is drawn: one value size, one label size, one gap.
    struct Fit: Equatable {
        let valueSize: CGFloat
        let labelSize: CGFloat
        let gap: CGFloat
    }

    let items: [Item]
    let focused: Int
    let onSelect: (Int) -> Void

    /// The label size and gap a row is tried at, roomiest first. Three
    /// 12pt labels are wider than a 40mm screen before any value is drawn,
    /// so a row whose values would fall under `comfortable` takes the
    /// tighter style when that makes them bigger.
    static let styles: [(labelSize: CGFloat, gap: CGFloat)] = [(SetupValue.standardLabelSize, 8), (10, 6)]
    static let comfortable: CGFloat = 20
    /// No bigger than the single-value screens' numbers.
    static let maxSize: CGFloat = 44
    static let minSize: CGFloat = 12

    /// Advance widths of SF Rounded heavy in ems, as BigClock counts them,
    /// with the "s" of a seconds value ("20s").
    static func ems(_ text: String) -> CGFloat {
        text.reduce(CGFloat(0)) { $0 + ($1 == ":" ? 0.34 : $1 == "s" ? 0.58 : 0.64) }
    }

    static func labelWidth(_ label: String, labelSize: CGFloat) -> CGFloat {
        let font = GlyphMetrics.font(size: labelSize, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .kern: SetupValue.tracking(labelSize)]
        return (label as NSString).size(withAttributes: attributes).width.rounded(.up)
    }

    static func labelLine(_ labelSize: CGFloat) -> CGFloat {
        GlyphMetrics.font(size: labelSize, weight: .bold).lineHeight
    }

    /// Height of a value line per point of its size.
    static var valueLineEm: CGFloat { GlyphMetrics.font(size: 100, weight: .heavy).lineHeight / 100 }

    static func cellWidth(_ item: Item, fit: Fit) -> CGFloat {
        max(labelWidth(item.label, labelSize: fit.labelSize), (ems(item.widest) * fit.valueSize).rounded(.up))
    }

    static func rowWidth(_ items: [Item], fit: Fit) -> CGFloat {
        items.reduce(0) { $0 + cellWidth($1, fit: fit) } + fit.gap * CGFloat(max(0, items.count - 1))
    }

    static func rowHeight(_ fit: Fit) -> CGFloat {
        labelLine(fit.labelSize) + fit.valueSize * valueLineEm
    }

    /// The largest value size at one label size and gap.
    static func fit(_ items: [Item], width: CGFloat, height: CGFloat, labelSize: CGFloat, gap: CGFloat) -> Fit {
        var size = min(maxSize, ((height - labelLine(labelSize)) / valueLineEm).rounded(.down))
        while size > minSize, rowWidth(items, fit: Fit(valueSize: size, labelSize: labelSize, gap: gap)) > width {
            size -= 1
        }
        return Fit(valueSize: max(minSize, size), labelSize: labelSize, gap: gap)
    }

    /// How the row is drawn in the room it has.
    static func fit(_ items: [Item], width: CGFloat, height: CGFloat) -> Fit {
        var best: Fit?
        for style in styles {
            let candidate = fit(items, width: width, height: height, labelSize: style.labelSize, gap: style.gap)
            if candidate.valueSize >= comfortable { return candidate }
            if candidate.valueSize > (best?.valueSize ?? 0) { best = candidate }
        }
        return best ?? Fit(valueSize: minSize, labelSize: SetupValue.standardLabelSize, gap: 8)
    }

    var body: some View {
        GeometryReader { geo in
            let fit = Self.fit(items, width: geo.size.width, height: geo.size.height)
            HStack(spacing: fit.gap) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    Button { onSelect(index) } label: {
                        SetupValue(
                            label: item.label, value: item.value, labelColor: item.labelColor,
                            size: fit.valueSize, focused: index == focused, exact: true, labelSize: fit.labelSize
                        )
                        .frame(width: Self.cellWidth(item, fit: fit))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Bottom capsules

/// Geometry shared by every bottom action (1.3.1): full-width inset
/// capsules, never edge slabs (the round screen clips those).
enum CapsuleGeometry {
    static let sideMargin: CGFloat = 9
    /// From the screen's bottom edge (the bottom safe inset is ignored; the
    /// capsule's own rounded ends clear the display corners).
    static let bottomMargin: CGFloat = 12
    static let height: CGFloat = 44
    static let startHeight: CGFloat = 48
    static let gap: CGFloat = 6
}

/// One full-width capsule: PAUSE, FINISH, RESUME, AGAIN, DONE.
struct CapsuleButton: View {
    let title: String
    let fill: Color
    var text: Color = .white
    var height: CGFloat = CapsuleGeometry.height
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .tracking(0.8)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(text)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(Capsule().fill(fill))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// The green START, the only green control on a setup screen. EMOM and
/// Tabata carry their computed total inside it ("10:00 total"), For Time
/// its direction and cap; AMRAP already shows its value.
struct StartButton: View {
    var subtitle: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: -1) {
                Text("START")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .tracking(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .opacity(0.7)
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: CapsuleGeometry.startHeight)
            .background(Capsule().fill(Palette.primary))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(subtitle.map { "Start, \($0)" } ?? "Start")
    }
}

/// End control that must be held (0.8s): HOLD TO STOP in red on ink, the
/// capsule filling red from the left while the finger stays down.
struct HoldToStopCapsule: View {
    let onConfirmed: () -> Void
    @State private var fill: CGFloat = 0

    var body: some View {
        ZStack {
            Capsule().fill(Palette.stopInk)
            GeometryReader { geo in
                Rectangle()
                    .fill(Palette.error.opacity(0.35))
                    .frame(width: geo.size.width * fill)
            }
            .clipShape(Capsule())
            Text("HOLD TO STOP")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(0.6)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(Palette.error)
        }
        .frame(maxWidth: .infinity)
        .frame(height: CapsuleGeometry.height)
        .contentShape(Capsule())
        .onTapGesture {}
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
        .accessibilityLabel("Stop workout. Hold to confirm.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Stop workout") { onConfirmed() }
    }
}

// MARK: - Timeline

/// The workout drawn as blocks, widths by seconds (1.3.1, shared with
/// Home, live and end screens): rest blocks pink, the others in the accent.
/// `.full` paints every block (Home); `.elapsed` fills finished parts, the
/// current part partially, and leaves the rest on the track.
struct TimelineBar: View {
    enum Fill: Equatable {
        case full
        case elapsed(Double)
    }

    let parts: [TimelinePart]
    let accent: Color
    var height: CGFloat = 6
    var fill: Fill = .full

    var body: some View {
        GeometryReader { geo in
            let gap: CGFloat = parts.count > 12 ? 1.5 : 2
            let total = CGFloat(max(1, parts.reduce(0) { $0 + $1.seconds }))
            let free = geo.size.width - gap * CGFloat(max(0, parts.count - 1))
            let fractions: [Double] = {
                switch fill {
                case .full: return parts.map { _ in 1 }
                case let .elapsed(seconds): return TimerType.fillFractions(parts, elapsed: seconds)
                }
            }()
            HStack(spacing: gap) {
                ForEach(Array(parts.enumerated()), id: \.offset) { i, part in
                    let width = max(1, free * CGFloat(part.seconds) / total)
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: height / 3).fill(Palette.track)
                        Rectangle()
                            .fill(part.isRest ? Palette.rest : accent)
                            .frame(width: width * fractions[i])
                    }
                    .clipShape(RoundedRectangle(cornerRadius: height / 3))
                    .frame(width: width)
                }
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// Font metrics for the centring rule: how far a text's visible glyph
/// bottom sits above the bottom of its layout box. Digits and capitals end
/// on the baseline; a slash ("2/10") reaches below it, measured from the
/// font's glyph outlines rather than guessed.
enum GlyphMetrics {
    static func font(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let rounded = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: rounded, size: size)
    }

    /// Distance from the bottom of a text's box to its baseline when the
    /// text is centred in a slot of `slotHeight` (the text's own line
    /// height when nil).
    static func baselineInset(size: CGFloat, weight: UIFont.Weight, slotHeight: CGFloat? = nil) -> CGFloat {
        let font = font(size: size, weight: weight)
        let line = font.lineHeight
        let box = slotHeight ?? line
        return (box - line) / 2 - font.descender
    }

    /// How far the glyphs of `text` reach below the baseline.
    static func descent(of text: String, size: CGFloat, weight: UIFont.Weight) -> CGFloat {
        let font = font(size: size, weight: weight) as CTFont
        var deepest: CGFloat = 0
        for unit in text.utf16 {
            var character = unit
            var glyph: CGGlyph = 0
            guard CTFontGetGlyphsForCharacters(font, &character, &glyph, 1) else { continue }
            let bounds = CTFontGetBoundingRectsForGlyphs(font, .default, &glyph, nil, 1)
            deepest = max(deepest, -bounds.minY)
        }
        return deepest
    }

    /// Distance from the bottom of the text's box to the visible bottom of
    /// its glyphs.
    static func glyphInset(text: String, size: CGFloat, weight: UIFont.Weight, slotHeight: CGFloat? = nil) -> CGFloat {
        baselineInset(size: size, weight: weight, slotHeight: slotHeight) - descent(of: text, size: size, weight: weight)
    }
}

/// The centring rule (1.3.1): the timeline sits exactly midway between the
/// visible bottom of the content above it (glyph bottoms, not box edges)
/// and the top of the bottom buttons. The zone starts at the box bottom of
/// the content above and ends at the buttons; `glyphInset` is how far the
/// glyphs end above that box bottom, so the midpoint shifts up by half of
/// it. A fixed zone height per device (a share of the screen) keeps every
/// live and end screen's bar in the same place; nil lets the zone take the
/// space left.
struct TimelineZone<Content: View>: View {
    let glyphInset: CGFloat
    var height: CGFloat? = TimelineZone.standardHeight
    @ViewBuilder let content: () -> Content

    static var standardHeight: CGFloat {
        (WKInterfaceDevice.current().screenBounds.height * 0.1).rounded()
    }

    var body: some View {
        GeometryReader { geo in
            content()
                .frame(width: geo.size.width)
                .position(x: geo.size.width / 2, y: (geo.size.height - glyphInset) / 2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .frame(maxHeight: height == nil ? .infinity : nil)
    }
}

#Preview {
    VStack {
        BigClock(text: "9:45", color: Palette.work)
        TimelineBar(parts: Workout.defaultTabata().timerType.timelineParts, accent: Palette.work, fill: .elapsed(95))
        HStack(spacing: CapsuleGeometry.gap) {
            HoldToStopCapsule {}
            CapsuleButton(title: "RESUME", fill: Palette.mode("amrap"), text: .black) {}
        }
    }
    .background(.black)
}
