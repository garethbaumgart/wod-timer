import SwiftUI

/// Circular progress indicator around the watch screen edge.
struct CircularProgressRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat

    init(progress: Double, color: Color, lineWidth: CGFloat = 4) {
        self.progress = progress
        self.color = color
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: min(1.0, max(0.0, progress)))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
        }
    }
}

#Preview {
    CircularProgressRing(progress: 0.65, color: .green)
        .frame(width: 150, height: 150)
}
