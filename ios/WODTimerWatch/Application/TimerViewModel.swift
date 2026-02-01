import Foundation
import Observation

/// Main state management for the timer.
/// Manages TimerSession lifecycle, triggers haptic cues.
@Observable
final class TimerViewModel {
    // MARK: - Published State

    private(set) var session: TimerSession?
    private(set) var phase: TimerState = .ready

    // MARK: - Dependencies

    private let engine = TimerEngine()
    private let haptics = WatchHapticService()
    let recentsStore = RecentWorkoutsStore()

    // MARK: - Internal State

    private var lastTickElapsed: TimeInterval = 0
    private var lastCountdownSecond: Int = -1
    private var playedGo = false
    private var lastRound: Int = 0
    private var playedGetReady = false
    private var playedLastRound = false
    private var playedKeepGoing = false
    private var playedHalfway = false
    private var lastWorkout: Workout?

    init() {
        engine.onTick = { [weak self] elapsed in
            self?.onTick(elapsed: elapsed)
        }
    }

    // MARK: - Public Actions

    func start(workout: Workout) {
        lastWorkout = workout
        resetCueState()

        var newSession = TimerSession.fromWorkout(workout)
        let result = newSession.start()

        switch result {
        case let .success(started):
            session = started
            phase = started.state
            lastTickElapsed = 0
            engine.start()
            recentsStore.save(workout)
        case .failure:
            break
        }
    }

    func pause() {
        guard var current = session else { return }
        let result = current.pause()

        switch result {
        case let .success(paused):
            session = paused
            phase = .paused
            engine.pause()
            haptics.pauseResume()
        case .failure:
            break
        }
    }

    func resume() {
        guard var current = session else { return }
        let result = current.resume()

        switch result {
        case let .success(resumed):
            session = resumed
            phase = resumed.state
            engine.resume()
            haptics.pauseResume()
        case .failure:
            break
        }
    }

    func stop() {
        guard var current = session else { return }
        let result = current.complete()

        switch result {
        case let .success(completed):
            session = completed
            phase = .completed
            engine.stop()
            haptics.complete()
        case .failure:
            break
        }
    }

    func restart() {
        guard let workout = lastWorkout, phase == .completed else { return }
        engine.stop()
        start(workout: workout)
    }

    func reset() {
        engine.stop()
        session = nil
        phase = .ready
        lastWorkout = nil
        resetCueState()
    }

    // MARK: - Tick Handler

    private func onTick(elapsed: TimeInterval) {
        guard var current = session else { return }

        // Calculate delta since last tick in milliseconds
        let deltaMs = Int((elapsed - lastTickElapsed) * 1000)
        lastTickElapsed = elapsed

        let oldSession = current
        let result = current.tick(deltaMs: deltaMs)

        switch result {
        case let .success(updated):
            handleHapticCues(old: oldSession, new: updated)

            if updated.state == .completed {
                session = updated
                phase = .completed
                engine.stop()
                haptics.complete()
            } else {
                session = updated
                phase = updated.state
            }

        case .failure:
            if current.state == .completed {
                session = current
                phase = .completed
                engine.stop()
                haptics.complete()
            }
        }
    }

    // MARK: - Haptic Cue Logic

    /// Ported from timer_notifier.dart _handleAudioCues.
    /// On watch: haptics replace audio as primary feedback.
    private func handleHapticCues(old: TimerSession, new: TimerSession) {
        var cuePlayed = false

        // "Get ready" haptic when entering prep
        if new.state == .preparing && !playedGetReady {
            playedGetReady = true
            cuePlayed = true
        }

        // Countdown ticks during preparation (3, 2, 1)
        if !cuePlayed && new.state == .preparing {
            let remaining = new.timeRemaining.seconds
            if remaining <= 3 && remaining > 0 && remaining != lastCountdownSecond {
                lastCountdownSecond = remaining
                haptics.prepTick()
                cuePlayed = true
            }
        }

        // GO! when transitioning from preparing to running
        if old.state == .preparing && new.state == .running && !playedGo {
            playedGo = true
            haptics.go()
            cuePlayed = true
        }

        // Detect round change
        let roundChanged = new.currentRound != lastRound && lastRound != 0

        // Work → Rest transition (Tabata)
        if old.state == .running && new.state == .resting && !roundChanged {
            haptics.workToRest()
            cuePlayed = true
        }

        // Rest → Work transition
        if old.state == .resting && new.state == .running {
            haptics.restToWork()
        }

        // Round change (EMOM/Tabata)
        if roundChanged {
            lastRound = new.currentRound

            if let totalRounds = new.totalRounds,
               new.currentRound == totalRounds,
               !playedLastRound {
                playedLastRound = true
                haptics.lastRound()
            } else {
                haptics.roundChange()
            }
            cuePlayed = true
        } else if lastRound == 0 {
            lastRound = new.currentRound
        }

        // Halfway haptic
        if !cuePlayed && new.progress >= 0.5 && old.progress < 0.5 && !playedHalfway {
            playedHalfway = true
            haptics.halfway()
            cuePlayed = true
        }

        // Keep going haptic at ~33%
        if !cuePlayed && new.progress >= 0.33 && old.progress < 0.33 && !playedKeepGoing {
            playedKeepGoing = true
            // No distinct haptic for this — skip to avoid haptic fatigue
        }

        // Final 3 seconds countdown ticks (for overall timer, not interval)
        if !cuePlayed && new.state == .running {
            let remaining = new.timeRemaining.seconds
            if remaining <= 3 && remaining > 0 {
                haptics.finalCountdown()
            }
        }
    }

    private func resetCueState() {
        lastCountdownSecond = -1
        playedGo = false
        lastRound = 0
        playedGetReady = false
        playedLastRound = false
        playedKeepGoing = false
        playedHalfway = false
    }
}
