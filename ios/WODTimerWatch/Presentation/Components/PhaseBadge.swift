import SwiftUI

/// Phase indicator pill (GET READY / WORK / REST).
struct PhaseBadge: View {
    let state: TimerState
    let timerType: TimerType?

    var label: String {
        switch state {
        case .preparing: "GET READY"
        case .running:
            timerType?.displayLabel ?? "WORK"
        case .resting: "REST"
        case .paused: "PAUSED"
        case .completed: "COMPLETE"
        default: ""
        }
    }

    var color: Color {
        switch state {
        case .preparing: .blue
        case .running: .green
        case .resting: .red
        case .paused: .orange
        case .completed: .teal
        default: .gray
        }
    }

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .bold))
            .tracking(2)
            .foregroundStyle(color)
    }
}

#Preview {
    VStack(spacing: 10) {
        PhaseBadge(state: .preparing, timerType: nil)
        PhaseBadge(state: .running, timerType: .amrap(duration: TimerDuration(seconds: 600)))
        PhaseBadge(state: .resting, timerType: nil)
    }
}
