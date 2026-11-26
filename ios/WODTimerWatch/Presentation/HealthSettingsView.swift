import HealthKit
import SwiftUI

/// Health (2.2.0): the workout session that keeps the timer alive when the
/// wrist drops and saves the WOD to Health. One switch, what it does, and
/// where the permission stands. Since 2.4.0 also what happens without a
/// session: the wrist alerts, their permission, what the last workout did,
/// and the Return to App setting that keeps the timer on screen.
struct HealthSettingsView: View {
    let tracker: HealthWorkoutTracker
    var alerts: WristAlerting = NoopWristAlerts()
    /// The view model's line about the last workout, when the session was
    /// taken over under it.
    var note: String? = nil

    private static let bodySize: CGFloat = 13

    var body: some View {
        ScrollViewReader { proxy in
            list
                .onAppear { captureScroll(proxy) }
        }
        .navigationTitle("Health")
    }

    /// Capture hook: the `health-lost` scene shows the Off screen section.
    private func captureScroll(_ proxy: ScrollViewProxy) {
        #if targetEnvironment(simulator)
        if CaptureScene.fromLaunchArguments() == .healthLost {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(nil) { proxy.scrollTo("offscreen", anchor: .top) }
            }
        }
        #endif
    }

    private var list: some View {
        List {
            Toggle(isOn: Binding(get: { tracker.enabled }, set: { tracker.setEnabled($0) })) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Track workouts")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text("Saves each WOD to Health")
                        .font(.system(size: Self.bodySize, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.label)
                }
            }
            .tint(Palette.primary)
            line(tracker.enabled
                ? "Keeps the clock, beeps and taps going while your wrist is down, and brings the timer back when you raise it."
                : "Off: the timer runs on screen only; off screen the alerts below tap you at each change.")
            if tracker.enabled {
                line(Self.permissionLine(tracker.authorization), error: tracker.authorization == .sharingDenied)
                // Health never says whether the heart rate may be read, so
                // the page says where it shows and where to allow it.
                if tracker.authorization == .sharingAuthorized {
                    if tracker.heartQuestionOpen {
                        // Never answered: Home asked once and left it there.
                        Button {
                            tracker.askForHeartRate()
                        } label: {
                            Text("Allow heart rate")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        line(Self.heartRateOffer)
                    } else {
                        line(Self.heartRateLine)
                    }
                }
            }
            if case let .failed(message) = tracker.status {
                line("Last session failed: \(message)", error: true)
            }
            Section("Off screen") {
                line("Without a Health session (Track workouts off, Workouts not allowed, or another app recording a workout) the watch alerts you at each round, rest and finish. Tap an alert to come back to the timer.")
                if alerts.status == .notAsked {
                    Button {
                        alerts.requestAuthorizationIfNeeded(completion: nil)
                    } label: {
                        Text("Allow alerts")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                } else {
                    line(Self.alertsLine(alerts.status), error: alerts.status == .denied)
                }
                if let note {
                    line(note)
                }
                line("Keep the timer on screen while your wrist is down: Settings, General, Return to Clock, Wharf WOD, Return to App.")
            }
            .id("offscreen")
        }
    }

    private func line(_ text: String, error: Bool = false) -> some View {
        Text(text)
            .font(.system(size: Self.bodySize, weight: .medium, design: .rounded))
            .foregroundStyle(error ? Palette.error : Palette.label)
            .listRowBackground(Color.clear)
    }

    /// Home's notice and row when Track workouts is on and Health will not
    /// let the app save one (27 Nov 2026).
    static let workoutsOffTitle = "Workouts is off"
    static let workoutsOffRow = "No heart rate, no beeps wrist down"
    static let workoutsOffNotice = "No heart rate, and the beeps stop when your wrist drops. Turn Workouts on for Wharf WOD in Settings, Privacy & Security, Health."

    static func permissionLine(_ authorization: HKAuthorizationStatus) -> String {
        switch authorization {
        case .sharingAuthorized:
            "Workouts: allowed"
        case .sharingDenied:
            "Workouts: not allowed, so no Health session runs: no heart rate, and the beeps stop when your wrist drops. Turn Workouts on for Wharf WOD under Settings, Privacy & Security, Health on this watch."
        default:
            "Workouts: permission not answered yet, so no session runs. Reopen Home to answer it."
        }
    }

    /// 2.7.0: the heart rate on the timer and the end screen.
    static let heartRateLine = "Heart rate: on the timer while you work, average and peak when you finish. If it never shows, allow Heart Rate for Wharf WOD under Settings, Privacy & Security, Health on this watch."

    static let heartRateOffer = "Shows your heart rate on the timer while you work, and the average and peak when you finish. Wharf WOD does not store or share it."

    static func alertsLine(_ status: WristAlertStatus) -> String {
        switch status {
        case .allowed: "Alerts: allowed"
        case .denied: "Alerts: not allowed. Allow notifications for Wharf WOD in the Watch app on your iPhone."
        case .notAsked: "Alerts: not asked yet"
        }
    }
}

#Preview {
    HealthSettingsView(tracker: HealthWorkoutTracker())
}
