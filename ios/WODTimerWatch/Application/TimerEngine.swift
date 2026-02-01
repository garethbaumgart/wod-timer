import Foundation

/// Precise timer engine that fires at ~100ms intervals.
/// Uses DispatchSourceTimer for better background precision than Timer.
final class TimerEngine {
    private var timer: DispatchSourceTimer?
    private var startTime: Date?
    private var pausedElapsed: TimeInterval = 0
    private let queue = DispatchQueue(label: "com.wodtimer.timerengine", qos: .userInteractive)

    var onTick: ((TimeInterval) -> Void)?

    var isRunning: Bool { timer != nil && startTime != nil }

    func start() {
        stop()
        startTime = Date()
        pausedElapsed = 0
        createTimer()
    }

    func pause() {
        guard let startTime else { return }
        pausedElapsed += Date().timeIntervalSince(startTime)
        self.startTime = nil
        timer?.cancel()
        timer = nil
    }

    func resume() {
        guard startTime == nil else { return }
        startTime = Date()
        createTimer()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        startTime = nil
        pausedElapsed = 0
    }

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

    deinit {
        timer?.cancel()
    }
}
