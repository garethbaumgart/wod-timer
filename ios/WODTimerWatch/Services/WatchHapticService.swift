import WatchKit

/// Haptic feedback service for watchOS.
/// Maps workout events to WKHapticType for wrist feedback.
final class WatchHapticService {
    private let device = WKInterfaceDevice.current()

    /// Light tick during prep countdown.
    func prepTick() {
        device.play(.click)
    }

    /// Strong signal when workout starts (GO!).
    func go() {
        device.play(.start)
    }

    /// Descending feel when transitioning from work to rest.
    func workToRest() {
        device.play(.directionDown)
    }

    /// Ascending feel when transitioning from rest to work.
    func restToWork() {
        device.play(.directionUp)
    }

    /// Medium tap on round change.
    func roundChange() {
        device.play(.click)
    }

    /// Attention-getting pulse when last round begins.
    func lastRound() {
        device.play(.notification)
    }

    /// Rhythmic taps for final 3 seconds.
    func finalCountdown() {
        device.play(.click)
    }

    /// Quick double buzz at halfway point.
    func halfway() {
        device.play(.retry)
    }

    /// Celebration pattern on workout completion.
    func complete() {
        device.play(.success)
    }

    /// Medium impact for pause/resume actions.
    func pauseResume() {
        device.play(.click)
    }
}
