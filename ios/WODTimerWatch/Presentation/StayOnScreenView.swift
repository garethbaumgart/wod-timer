import SwiftUI

/// Why the clock face can replace the timer, and the one watch setting
/// that brings the timer back (2.4.0). About two minutes after the wrist
/// drops, watchOS returns to the clock face (Settings > General > Return
/// to Clock, the default) unless the app is told to come back; since
/// watchOS 7 only the athlete can set that, no code can. The row on Home
/// shows until this page has been read once.
struct StayOnScreenView: View {
    /// One additive key, like the other hints.
    static let seenKey = "watch_hint_return_to_app_seen"

    var onDismiss: () -> Void = {}
    @Environment(\.dismiss) private var dismiss

    static let steps = [
        "Open Settings on the watch",
        "General, then Return to Clock",
        "Tap Wharf WOD, then Custom",
        "Turn on Return to App and pick After 1 hour",
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Two minutes after your wrist drops, the watch goes back to the clock face. To land on the timer when you raise it:")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.label)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(Self.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .firstTextBaseline, spacing: 7) {
                            Text("\(index + 1)")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Palette.primary)
                            Text(step)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                }
                Text("Return to App is listed once the watch has run a Health session from Wharf WOD: keep Track workouts on under Health and allow Workouts. Without a session, the alerts tap you at each change, and a tap on one brings the timer back.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.label)
                CapsuleButton(title: "GOT IT", fill: Palette.primary, text: .black) {
                    UserDefaults.standard.set(true, forKey: Self.seenKey)
                    onDismiss()
                    dismiss()
                }
                .frame(height: CapsuleGeometry.height)
                .padding(.top, 4)
            }
            .padding(.horizontal, CapsuleGeometry.sideMargin)
        }
        .navigationTitle("Stay on screen")
    }
}

#Preview {
    NavigationStack { StayOnScreenView() }
}
