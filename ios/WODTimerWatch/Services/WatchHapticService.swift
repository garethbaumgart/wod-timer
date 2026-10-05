import Foundation
import WatchKit

/// Wrist cues (2.2.0). watchOS has no haptic intensity control: strength is
/// the pattern. `.notification` is the firmest single haptic the watch
/// offers, so every change that matters leads with it and the big moments
/// double it; `.click`, 2.1.0's tick and round change, is barely felt mid
/// workout. The engine wants about 100ms between plays, so the patterns
/// leave half a second. One cue per tick: the view model picks the one that
/// matters when two changes land together.
final class WatchHapticService {
    enum Cue: String, CaseIterable {
        /// 3, 2, 1 before every change: prep, round, rest, the end.
        case countIn
        case go
        case roundChange
        case lastRound
        case workToRest
        case restToWork
        case halfway
        case complete
        /// Pause, and the hold that stops early.
        case pause
        case resume
        /// The wrist tap that counts an AMRAP round.
        case tap
    }

    struct Step: Equatable {
        let type: WKHapticType
        let at: TimeInterval
    }

    typealias Player = (WKHapticType) -> Void
    typealias Scheduler = (TimeInterval, @escaping () -> Void) -> Void

    private let player: Player
    private let scheduler: Scheduler
    private var generation = 0

    /// What was played, oldest first ("notification"), for tests.
    private(set) var log: [String] = []

    init(player: Player? = nil, scheduler: Scheduler? = nil) {
        self.player = player ?? { WKInterfaceDevice.current().play($0) }
        self.scheduler = scheduler ?? { delay, work in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        }
    }

    static func pattern(_ cue: Cue) -> [Step] {
        switch cue {
        case .countIn: [Step(type: .start, at: 0)]
        case .go: [Step(type: .notification, at: 0), Step(type: .notification, at: 0.5)]
        case .roundChange, .restToWork: [Step(type: .notification, at: 0), Step(type: .directionUp, at: 0.5)]
        case .lastRound:
            [Step(type: .notification, at: 0), Step(type: .notification, at: 0.5), Step(type: .notification, at: 1.0)]
        case .workToRest: [Step(type: .notification, at: 0), Step(type: .directionDown, at: 0.5)]
        case .halfway: [Step(type: .retry, at: 0)]
        case .complete: [Step(type: .success, at: 0), Step(type: .notification, at: 0.6)]
        case .pause: [Step(type: .stop, at: 0)]
        case .resume: [Step(type: .start, at: 0)]
        case .tap: [Step(type: .click, at: 0)]
        }
    }

    /// Plays the cue's pattern. A new cue drops the tail still to come from
    /// the one before it, so patterns never pile up.
    func play(_ cue: Cue) {
        generation += 1
        let mine = generation
        for step in Self.pattern(cue) {
            if step.at == 0 {
                fire(step.type)
            } else {
                scheduler(step.at) { [weak self] in
                    guard let self, self.generation == mine else { return }
                    self.fire(step.type)
                }
            }
        }
    }

    /// Drops whatever is still to come (a stop right after GO).
    func cancelPending() {
        generation += 1
    }

    private func fire(_ type: WKHapticType) {
        log.append(Self.name(type))
        if log.count > 400 { log.removeFirst(log.count - 400) }
        player(type)
    }

    static func name(_ type: WKHapticType) -> String {
        switch type {
        case .notification: "notification"
        case .directionUp: "directionUp"
        case .directionDown: "directionDown"
        case .success: "success"
        case .failure: "failure"
        case .retry: "retry"
        case .start: "start"
        case .stop: "stop"
        case .click: "click"
        default: "other"
        }
    }
}
