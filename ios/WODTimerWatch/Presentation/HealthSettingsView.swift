import HealthKit
import SwiftUI

/// Health (2.2.0): the workout session that keeps the timer alive when the
/// wrist drops and saves the WOD to Health. One switch, what it does, and
/// where the permission stands.
struct HealthSettingsView: View {
    let tracker: HealthWorkoutTracker

    var body: some View {
        List {
            Toggle(isOn: Binding(get: { tracker.enabled }, set: { tracker.setEnabled($0) })) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Track workouts")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text("Saves each WOD to Health")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.label)
                }
            }
            .tint(Palette.primary)
            Text(tracker.enabled
                ? "Keeps the clock, beeps and taps going while your wrist is down, and brings the timer back when you raise it."
                : "Off: the timer only runs while it is on screen, so cues stop when your wrist drops.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.label)
                .listRowBackground(Color.clear)
            if tracker.enabled {
                Text(Self.permissionLine(tracker.authorization))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(tracker.authorization == .sharingDenied ? Palette.error : Palette.label)
                    .listRowBackground(Color.clear)
            }
            if case let .failed(message) = tracker.status {
                Text("Last session failed: \(message)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.error)
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Health")
    }

    static func permissionLine(_ authorization: HKAuthorizationStatus) -> String {
        switch authorization {
        case .sharingAuthorized:
            "Workouts: allowed"
        case .sharingDenied:
            "Workouts: not allowed. Allow Wharf WOD under Settings, Privacy & Security, Health on this watch."
        default:
            "Workouts: permission not answered yet"
        }
    }
}

#Preview {
    HealthSettingsView(tracker: HealthWorkoutTracker())
}
