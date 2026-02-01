import SwiftUI

/// Large time display (MM:SS) optimized for watch readability.
struct TimerDisplayText: View {
    let duration: TimerDuration
    let size: CGFloat

    init(_ duration: TimerDuration, size: CGFloat = 52) {
        self.duration = duration
        self.size = size
    }

    var body: some View {
        Text(duration.formatted)
            .font(.system(size: size, weight: .ultraLight, design: .default))
            .monospacedDigit()
            .foregroundStyle(.white)
    }
}

#Preview {
    TimerDisplayText(TimerDuration(seconds: 392))
        .background(.black)
}
