import Foundation

/// Precise timer engine that fires at ~100ms intervals.
/// Uses DispatchSourceTimer for better background precision than Timer.
/// All state mutations are synchronized on the internal serial queue.
final class TimerEngine {
    private var timer: DispatchSourceTimer?
    private var startTime: Date?
    private var pausedElapsed: TimeInterval = 0
    private let queue = DispatchQueue(label: "com.wodtimer.timerengine", qos: .userInteractive)

    var onTick: ((TimeInterval) -> Void)?

    private(set) var isPaused: Bool = false

    var isRunning: Bool {
        queue.sync { timer != nil && startTime != nil }
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

    /// Must be called on `queue`.
    private func createTimer() {
        let source = DispatchSource.makeTimerSource(queue: queue)
        source.schedule(deadline: .now(), repeating: .milliseconds(100), leeway: .milliseconds(10))
        source.setEventHandler { [weak self] in
            guard let self, let startTime = self.startTime else { return }
            let elapsed = self.pausedElapsed + Date().timeIntervalSince(startTime)
            DispatchQueue.main.async {
                self.onTick?(elapsed)
            }
        }
        source.resume()
        timer = source
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
