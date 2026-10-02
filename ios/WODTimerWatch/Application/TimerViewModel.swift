import Foundation
import Observation

/// Main state management for the timer.
/// Manages TimerSession lifecycle, triggers haptic + voice cues.
@Observable
final class TimerViewModel {
    // MARK: - Published State

    private(set) var session: TimerSession?
    private(set) var phase: TimerState = .ready

    /// True when the athlete ended the workout with Stop: the end screen
    /// says "Stopped", never celebrates.
    private(set) var endedEarly = false

    /// A For Time that ran into its cap: a DNF, not a finish.
    var endedAtTimeCap: Bool {
        guard phase == .completed, !endedEarly, let session,
              case let .forTime(timeCap, _) = session.workout.timerType else { return false }
        return session.elapsed.seconds >= timeCap.seconds
    }

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

    /// AMRAP taps are ignored for this long after a counted round, after GO
    /// and after a resume, so a double tap or a late prep skip never counts.
    private static let roundCountCooldown: TimeInterval = 0.7
    private var roundCountBlockedUntil: Date?

    /// "TAP TO COUNT" shows until the athlete has counted a round once,
    /// ever (one additive key, like the phone).
    private(set) var hasCountedRound = UserDefaults.standard.bool(forKey: "watch_hint_amrap_counted")

    private func blockRoundCount() {
        roundCountBlockedUntil = Date().addingTimeInterval(Self.roundCountCooldown)
    }

    init() {
        engine.onTick = { [weak self] elapsed in
            self?.onTick(elapsed: elapsed)
        }
    }

    // MARK: - Public Actions

    func start(workout: Workout) {
        lastWorkout = workout
        resetCueState()
        endedEarly = false

        var newSession = TimerSession.fromWorkout(workout)
        let result = newSession.start()

        switch result {
        case let .success(started):
            session = started
            phase = started.state
            lastTickElapsed = 0
            engine.start()
            recentsStore.save(workout)
            if started.state == .running { blockRoundCount() }
        case .failure:
            break
        }
    }

    func pause() {
        // The get-ready countdown is skipped or cancelled, never paused.
        guard phase != .preparing, var current = session else { return }
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
            blockRoundCount()
        case .failure:
            break
        }
    }

    /// End early: an honest "Stopped", no celebration.
    func stop() {
        guard phase != .completed, var current = session else { return }
        let result = current.complete()

        switch result {
        case let .success(completed):
            endedEarly = true
            session = completed
            phase = .completed
            engine.stop()
            haptics.pauseResume()
        case .failure:
            break
        }
    }

    /// For Time's success action: log the time and celebrate.
    func finish() {
        guard phase != .completed, var current = session else { return }
        let result = current.complete()

        switch result {
        case let .success(completed):
            endedEarly = false
            session = completed
            phase = .completed
            engine.stop()
            haptics.complete()
            playCompletionEncouragement()
        case .failure:
            break
        }
    }

    /// Cancel the get-ready countdown (nothing has happened yet).
    func cancelPrep() {
        guard phase == .preparing else { return }
        reset()
    }

    /// Skip the rest of the get-ready countdown.
    func skipPrep() {
        guard phase == .preparing, var current = session else { return }
        let old = current
        let remainingMs = current.timeRemaining.seconds * 1000
        if case let .success(updated) = current.tick(deltaMs: remainingMs) {
            handleCues(old: old, new: updated)
            session = updated
            phase = updated.state
        }
    }

    /// Count an AMRAP round (tap anywhere while running).
    func countRound() {
        guard phase == .running, var current = session,
              case .amrap = current.workout.timerType else { return }
        let now = Date()
        if let blocked = roundCountBlockedUntil, now < blocked { return }
        roundCountBlockedUntil = now.addingTimeInterval(Self.roundCountCooldown)
        current.countRound()
        session = current
        haptics.prepTick()
        if !hasCountedRound {
            hasCountedRound = true
            UserDefaults.standard.set(true, forKey: "watch_hint_amrap_counted")
        }
    }

    /// Correct the AMRAP tally on the end screen.
    func adjustRounds(by delta: Int) {
        guard phase == .completed, var current = session else { return }
        current.adjustRounds(by: delta)
        session = current
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
        endedEarly = false
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
                // A capped For Time is a DNF: no "Good job".
                if !endedAtTimeCap { playCompletionEncouragement() }
            } else {
                session = updated
                phase = updated.state
            }

        case .failure:
            if current.state == .completed, phase != .completed {
                session = current
                phase = .completed
                engine.stop()
                haptics.complete()
                if !endedAtTimeCap { playCompletionEncouragement() }
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
            blockRoundCount()
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

        // "Ten seconds" warning (only if workout > 15s to avoid overlap with
        // final countdown). Whole-workout remaining: for EMOM / Tabata the
        // session's timeRemaining is per interval, which fired this at the
        // end of round 1 and then latched.
        if !voiceCuePlayed && new.state.isActive && new.state != .preparing && !playedTenSeconds
            && new.workout.timerType.estimatedDuration.seconds > 15 {
            let remaining = workoutRemaining(new)
            if remaining <= 10 && remaining > 7 {
                playedTenSeconds = true
                audio.playTenSeconds()
                voiceCuePlayed = true
            }
        }

        // Final countdown (single pre-recorded "5, 4, 3, 2, 1" clip). Whole
        // workout, and resting counts: a Tabata ends on a rest.
        if !voiceCuePlayed && new.state.isActive && new.state != .preparing && !playedFinalCountdown {
            let remaining = workoutRemaining(new)
            if remaining <= 5 && remaining > 0 {
                playedFinalCountdown = true
                audio.playFinalCountdown()
                haptics.finalCountdown()
            }
        }
    }

    /// Seconds left in the WHOLE workout, not the current interval.
    private func workoutRemaining(_ session: TimerSession) -> Int {
        let total = session.workout.timerType.estimatedDuration.seconds
        return max(0, total - session.elapsed.seconds)
    }

    /// Plays "Good job" or "That's it" after completion,
    /// delayed if the final countdown clip may still be playing.
    /// The "5, 4, 3, 2, 1" clip starts at 5s remaining and runs ~5s,
    /// so it should finish near completion. A 1s buffer avoids overlap
    /// if the timer completes slightly before the clip ends.
    private func playCompletionEncouragement() {
        let delay: TimeInterval = playedFinalCountdown ? 1.0 : 0
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

#if targetEnvironment(simulator)
// MARK: - Capture hooks (simulator builds only; see CaptureRoot)

extension TimerViewModel {
    /// Jump the session forward in 100ms steps (as the engine would).
    func debugAdvance(seconds: Int) {
        guard var current = session else { return }
        for _ in 0 ..< seconds * 10 {
            guard current.state.isActive else { break }
            if case let .success(next) = current.tick(deltaMs: 100) { current = next }
        }
        session = current
        phase = current.state
        if current.state == .completed { engine.stop() }
    }

    func debugCountRounds(_ n: Int) {
        guard var current = session else { return }
        for _ in 0 ..< n { current.countRound() }
        session = current
    }

    func debugFinish() { finish() }
}
#endif
