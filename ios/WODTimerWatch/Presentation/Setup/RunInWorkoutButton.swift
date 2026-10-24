import SwiftUI

/// The second way to start a WOD (spike, 24 Oct 2026): hand it to Apple's
/// Workout app, which runs the intervals with its own heart rate, calories
/// and alerts. Sits under START on the EMOM and Tabata setups. A failure
/// shows as one line under the capsule, never as a sheet.
struct RunInWorkoutButton: View {
    let type: TimerType
    @State private var opening = false
    @State private var problem: String?

    var body: some View {
        VStack(spacing: 2) {
            CapsuleButton(title: opening ? "OPENING" : "RUN IN WORKOUT", fill: Palette.soft, height: 34) {
                open()
            }
            .disabled(opening)
            .accessibilityLabel("Run in the Workout app")
            if let problem {
                Text(problem)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.error)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func open() {
        guard !opening else { return }
        opening = true
        problem = nil
        SetupMemory().save(type)
        Task { @MainActor in
            do {
                try await WorkoutHandoff.open(type)
            } catch {
                problem = WorkoutHandoff.message(for: error)
            }
            opening = false
        }
    }
}

#Preview {
    RunInWorkoutButton(type: .emom(intervalDuration: TimerDuration(seconds: 60), rounds: RoundCount(value: 10)))
}
