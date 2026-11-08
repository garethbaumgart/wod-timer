import Foundation
import Observation
import UserNotifications

/// Where the alerts permission stands.
enum WristAlertStatus: Equatable {
    case notAsked
    case allowed
    case denied
}

/// The wrist alerts (2.4.0): local notifications the system delivers at
/// each change when the app is not kept alive by a Health workout session
/// (see WristAlertPlan). The protocol keeps the notification center out
/// of the view model, so tests read what was scheduled and cancelled.
protocol WristAlerting: AnyObject {
    var status: WristAlertStatus { get }
    /// Asked once, when Home appears, the way the Health permission is.
    func requestAuthorizationIfNeeded(completion: ((WristAlertStatus) -> Void)?)
    /// Replaces whatever was scheduled with these.
    func schedule(_ alerts: [ScheduledAlert])
    /// Drops every pending alert and clears delivered ones from the list.
    func cancelAll()
}

/// No notifications: tests, previews and the simulator capture hooks.
final class NoopWristAlerts: WristAlerting {
    var status: WristAlertStatus

    init(status: WristAlertStatus = .allowed) {
        self.status = status
    }

    func requestAuthorizationIfNeeded(completion: ((WristAlertStatus) -> Void)?) { completion?(status) }
    func schedule(_ alerts: [ScheduledAlert]) {}
    func cancelAll() {}
}

@Observable
final class NotificationWristAlerts: WristAlerting {
    private(set) var status: WristAlertStatus = .notAsked

    /// One thread, so the alerts of a workout group in the list.
    static let thread = "wharfwod.workout"

    @ObservationIgnored private let center = UNUserNotificationCenter.current()

    init() {
        refresh()
    }

    static func status(from authorization: UNAuthorizationStatus) -> WristAlertStatus {
        switch authorization {
        case .notDetermined: .notAsked
        case .denied: .denied
        default: .allowed
        }
    }

    func refresh() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.status = Self.status(from: settings.authorizationStatus)
            }
        }
    }

    func requestAuthorizationIfNeeded(completion: ((WristAlertStatus) -> Void)? = nil) {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }
            guard settings.authorizationStatus == .notDetermined else {
                DispatchQueue.main.async {
                    self.status = Self.status(from: settings.authorizationStatus)
                    completion?(self.status)
                }
                return
            }
            self.center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    self.status = granted ? .allowed : .denied
                    completion?(self.status)
                }
            }
        }
    }

    func schedule(_ alerts: [ScheduledAlert]) {
        center.removeAllPendingNotificationRequests()
        for scheduled in alerts {
            let content = UNMutableNotificationContent()
            content.title = scheduled.alert.title
            content.body = scheduled.alert.body
            content.sound = .default
            content.threadIdentifier = Self.thread
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(0.1, scheduled.delay), repeats: false)
            center.add(UNNotificationRequest(identifier: scheduled.alert.identifier, content: content, trigger: trigger))
        }
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
}
