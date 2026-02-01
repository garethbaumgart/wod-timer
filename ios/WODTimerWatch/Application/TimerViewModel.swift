import Foundation
import Observation

/// Main state management for the timer.
/// Manages TimerSession lifecycle, triggers haptic + voice cues.
@Observable
final class TimerViewModel {
    // MARK: - Published State

    private(set) var session: TimerSession?
    private(set) var phase: TimerState = .ready

    // MARK: - Dependencies

    private let engine = TimerEngine()
    private let haptics = WatchHapticService()
    let audio = WatchAudioService()
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
    private var playedAlmostThere = false
    private var playedTenSeconds = false
    private var playedFinalCountdown = false
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
            playCompletionEncouragement()
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

        let deltaMs = Int((elapsed - lastTickElapsed) * 1000)
        lastTickElapsed = elapsed

        let oldSession = current
        let result = current.tick(deltaMs: deltaMs)

        switch result {
        case let .success(updated):
            handleCues(old: oldSession, new: updated)

            if updated.state == .completed {
                session = updated
                phase = .completed
                engine.stop()
                haptics.complete()
                playCompletionEncouragement()
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
                playCompletionEncouragement()
            }
        }
    }

    // MARK: - Cue Logic (Haptics + Voice)

    /// Ported from timer_notifier.dart _handleAudioCues.
    /// Plays voice cues alongside haptic feedback.
    private func handleCues(old: TimerSession, new: TimerSession) {
        var voiceCuePlayed = false

        // "Get ready" when entering prep
        if new.state == .preparing && !playedGetReady {
            playedGetReady = true
            audio.playGetReady()
            voiceCuePlayed = true
        }

        // Countdown ticks during preparation (3, 2, 1)
        if !voiceCuePlayed && new.state == .preparing {
            let remaining = new.timeRemaining.seconds
            if remaining <= 3 && remaining > 0 && remaining != lastCountdownSecond {
                lastCountdownSecond = remaining
                audio.playCountdown(remaining)
                haptics.prepTick()
                voiceCuePlayed = true
            }
        }

        // "Go!" or "Let's go!" when prep → running
        if old.state == .preparing && new.state == .running && !playedGo {
            playedGo = true
            if Bool.random() {
                audio.playGo()
            } else {
                audio.playLetsGo()
            }
            haptics.go()
            voiceCuePlayed = true
        }

        // Detect round change
        let roundChanged = new.currentRound != lastRound && lastRound != 0

        // Work → Rest transition (prefer round cue if both happen)
        if old.state == .running && new.state == .resting && !roundChanged {
            audio.playRest()
            haptics.workToRest()
            voiceCuePlayed = true
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
                audio.playLastRound()
                haptics.lastRound()
            } else {
                audio.playNextRound()
                haptics.roundChange()
            }
            voiceCuePlayed = true
        } else if lastRound == 0 {
            lastRound = new.currentRound
        }

        // Motivational cue at ~33% progress
        if !voiceCuePlayed && new.progress >= 0.33 && old.progress < 0.33 && !playedKeepGoing {
            playedKeepGoing = true
            if Bool.random() {
                audio.playKeepGoing()
            } else {
                audio.playComeOn()
            }
            voiceCuePlayed = true
        }

        // Halfway point
        if !voiceCuePlayed && new.progress >= 0.5 && old.progress < 0.5 && !playedHalfway {
            playedHalfway = true
            audio.playHalfway()
            haptics.halfway()
            voiceCuePlayed = true
        }

        // "Almost there" at ~85% progress
        if !voiceCuePlayed && new.progress >= 0.85 && old.progress < 0.85 && !playedAlmostThere {
            playedAlmostThere = true
            audio.playAlmostThere()
            voiceCuePlayed = true
        }

        // "Ten seconds" warning (only if workout > 15s to avoid overlap)
        if !voiceCuePlayed && new.state == .running && !playedTenSeconds {
            let remaining = new.timeRemaining.seconds
            if remaining <= 10 && remaining > 7 {
                playedTenSeconds = true
                audio.playTenSeconds()
                voiceCuePlayed = true
            }
        }

        // Final countdown (single pre-recorded "5, 4, 3, 2, 1" clip)
        if !voiceCuePlayed && new.state == .running && !playedFinalCountdown {
            let remaining = new.timeRemaining.seconds
            if remaining <= 5 && remaining > 0 {
                playedFinalCountdown = true
                audio.playFinalCountdown()
                haptics.finalCountdown()
            }
        }
    }

    /// Plays "Good job" or "That's it" after completion,
    /// delayed if final countdown was still playing.
    private func playCompletionEncouragement() {
        let delay: TimeInterval = playedFinalCountdown ? 0.6 : 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.phase == .completed else { return }
            if Bool.random() {
                self.audio.playGoodJob()
            } else {
                self.audio.playThatsIt()
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
        playedAlmostThere = false
        playedTenSeconds = false
        playedFinalCountdown = false
    }
}
