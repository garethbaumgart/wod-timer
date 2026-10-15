import Foundation

/// The workout clock. Ticks once a second, a few milliseconds after each
/// second of the clock turns over, and re-aims every tick at the next turn
/// so it never drifts (2.2.1). Every cue lands on a whole second (the
/// 3-2-1 beeps, GO, rounds, rest), so each one is heard within
/// milliseconds of being due. The ten ticks a second this replaces caught
/// them up to 100ms late and kept the app busy with the wrist down, where
/// watchOS weighs a background workout app's CPU. The screen does not
/// need ticks: it draws the clock for the moment of each frame
/// (TimerViewModel.displaySession(at:)).
/// Uses DispatchSourceTimer for better background precision than Timer.
/// All state mutations are synchronized on the internal serial queue.
final class TimerEngine {
    private var timer: DispatchSourceTimer?
    private var startTime: Date?
    private var pausedElapsed: TimeInterval = 0
    private let queue = DispatchQueue(label: "com.wodtimer.timerengine", qos: .userInteractive)

    /// How far past each turn of the clock a tick aims.
    static let tickMargin: TimeInterval = 0.005

    var onTick: ((TimeInterval) -> Void)?

    private(set) var isPaused: Bool = false

    var isRunning: Bool {
        queue.sync { timer != nil && startTime != nil }
    }

    /// The moment the clock read zero, pauses taken out: the clock reads
    /// `now - origin`. Nil while paused or stopped.
    var origin: Date? {
        queue.sync { startTime?.addingTimeInterval(-pausedElapsed) }
    }

    /// The clock right now.
    var elapsed: TimeInterval {
        queue.sync { pausedElapsed + (startTime.map { Date().timeIntervalSince($0) } ?? 0) }
    }

    func start() {
        queue.sync {
            cancelTimer()
            startTime = Date()
            pausedElapsed = 0
            isPaused = false
            createTimer()
        }
    }

    func pause() {
        queue.sync {
            guard let startTime else { return }
            pausedElapsed += Date().timeIntervalSince(startTime)
            self.startTime = nil
            isPaused = true
            cancelTimer()
        }
    }

    func resume() {
        queue.sync {
            guard startTime == nil, isPaused else { return }
            startTime = Date()
            isPaused = false
            createTimer()
        }
    }

    func stop() {
        queue.sync {
            cancelTimer()
            startTime = nil
            pausedElapsed = 0
            isPaused = false
        }
    }

    /// Seconds from `elapsed` until just past the clock's next whole second.
    /// A tick that fires a hair early aims at the turn it just missed.
    static func delayToNextTick(after elapsed: TimeInterval) -> TimeInterval {
        let nextTurn = (elapsed + 0.0005).rounded(.down) + 1
        return nextTurn + tickMargin - elapsed
    }

    /// Must be called on `queue`. The first tick fires at once.
    private func createTimer() {
        let source = DispatchSource.makeTimerSource(queue: queue)
        source.schedule(deadline: .now(), leeway: .milliseconds(5))
        source.setEventHandler { [weak self] in
            self?.fire()
        }
        source.resume()
        timer = source
    }

    /// Must be called on `queue`.
    private func fire() {
        guard let timer, let startTime else { return }
        let elapsed = pausedElapsed + Date().timeIntervalSince(startTime)
        timer.schedule(deadline: .now() + Self.delayToNextTick(after: elapsed), leeway: .milliseconds(5))
        DispatchQueue.main.async {
            self.onTick?(elapsed)
        }
    }

    /// Must be called on `queue`.
    private func cancelTimer() {
        timer?.cancel()
        timer = nil
    }

    deinit {
        timer?.cancel()
    }
}
