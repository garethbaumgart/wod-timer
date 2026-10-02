import Foundation

/// The aggregate root for managing an active timer session.
///
/// All timer state modifications go through this struct.
/// State transitions return Result to handle invalid transitions.
struct TimerSession: Equatable {
    let id: UUID
    let workout: Workout
    private(set) var state: TimerState
    private(set) var currentRound: Int
    private(set) var elapsed: TimerDuration
    private(set) var currentIntervalElapsed: TimerDuration
    private(set) var elapsedMillis: Int
    private(set) var intervalElapsedMillis: Int
    private(set) var stateBeforePause: TimerState?
    private(set) var startedAt: Date?
    private(set) var completedAt: Date?

    /// Create a new session from a workout configuration.
    static func fromWorkout(_ workout: Workout) -> TimerSession {
        TimerSession(
            id: UUID(),
            workout: workout,
            state: .ready,
            currentRound: 1,
            elapsed: .zero,
            currentIntervalElapsed: .zero,
            elapsedMillis: 0,
            intervalElapsedMillis: 0,
            stateBeforePause: nil,
            startedAt: nil,
            completedAt: nil
        )
    }

    // MARK: - State Transitions

    /// Start the timer session.
    mutating func start() -> Result<TimerSession, TimerError> {
        guard state.canStart else {
            return .failure(.invalidStateTransition(from: state, to: .preparing))
        }

        let hasPrepCountdown = workout.prepCountdown.seconds > 0
        state = hasPrepCountdown ? .preparing : .running
        startedAt = Date()
        return .success(self)
    }

    /// Pause the timer.
    mutating func pause() -> Result<TimerSession, TimerError> {
        guard state.canPause else {
            return .failure(.invalidStateTransition(from: state, to: .paused))
        }

        stateBeforePause = state
        state = .paused
        return .success(self)
    }

    /// Resume from paused state.
    mutating func resume() -> Result<TimerSession, TimerError> {
        guard state.canResume else {
            return .failure(.invalidStateTransition(from: state, to: .running))
        }

        state = stateBeforePause ?? .running
        stateBeforePause = nil
        return .success(self)
    }

    /// Manually complete the workout.
    mutating func complete() -> Result<TimerSession, TimerError> {
        if state == .completed {
            return .failure(.alreadyCompleted)
        }
        if state == .ready {
            return .failure(.invalidStateTransition(from: state, to: .completed))
        }
        markComplete()
        return .success(self)
    }

    /// Main tick function called by the timer engine (~100ms).
    mutating func tick(deltaMs: Int) -> Result<TimerSession, TimerError> {
        guard state.isActive else {
            return .failure(.timerNotActive)
        }

        // Accumulate milliseconds precisely
        let totalElapsedMillis = elapsedMillis + deltaMs
        let totalIntervalMillis = intervalElapsedMillis + deltaMs

        // Convert to whole seconds, keeping remainder
        let newElapsedSeconds = elapsed.seconds + (totalElapsedMillis / 1000)
        let newElapsedMillisRemainder = totalElapsedMillis % 1000

        let newIntervalSeconds = currentIntervalElapsed.seconds + (totalIntervalMillis / 1000)
        let newIntervalMillisRemainder = totalIntervalMillis % 1000

        let newElapsed = TimerDuration(seconds: newElapsedSeconds)
        let newIntervalElapsed = TimerDuration(seconds: newIntervalSeconds)

        // Handle preparation phase
        if state == .preparing {
            if newIntervalElapsed.seconds >= workout.prepCountdown.seconds {
                // Prep done, start the workout. Carry any overshoot into the
                // workout so a large delta (the watch was asleep) loses nothing.
                let overflow = TimerDuration(
                    seconds: newIntervalElapsed.seconds - workout.prepCountdown.seconds
                )
                state = .running
                elapsed = overflow
                currentIntervalElapsed = overflow
                intervalElapsedMillis = newIntervalMillisRemainder
                elapsedMillis = newElapsedMillisRemainder
                return .success(self)
            }
            currentIntervalElapsed = newIntervalElapsed
            intervalElapsedMillis = newIntervalMillisRemainder
            elapsedMillis = newElapsedMillisRemainder
            return .success(self)
        }

        // Route to timer-type-specific handler
        switch workout.timerType {
        case let .amrap(duration):
            return tickAmrap(
                duration: duration,
                newElapsed: newElapsed,
                newElapsedMillis: newElapsedMillisRemainder
            )
        case let .forTime(timeCap, _):
            return tickForTime(
                timeCap: timeCap,
                newElapsed: newElapsed,
                newElapsedMillis: newElapsedMillisRemainder
            )
        case let .emom(intervalDuration, rounds):
            return tickEmom(
                intervalDuration: intervalDuration,
                rounds: rounds,
                newElapsed: newElapsed,
                newIntervalElapsed: newIntervalElapsed,
                newElapsedMillis: newElapsedMillisRemainder,
                newIntervalMillis: newIntervalMillisRemainder
            )
        case let .tabata(workDuration, restDuration, rounds):
            return tickTabata(
                workDuration: workDuration,
                restDuration: restDuration,
                rounds: rounds,
                newElapsed: newElapsed,
                newIntervalElapsed: newIntervalElapsed,
                newElapsedMillis: newElapsedMillisRemainder,
                newIntervalMillis: newIntervalMillisRemainder
            )
        }
    }

    // MARK: - Timer Type Tick Handlers

    private mutating func tickAmrap(
        duration: TimerDuration,
        newElapsed: TimerDuration,
        newElapsedMillis: Int
    ) -> Result<TimerSession, TimerError> {
        if newElapsed.seconds >= duration.seconds {
            markComplete(elapsedAt: duration)
            return .success(self)
        }
        elapsed = newElapsed
        elapsedMillis = newElapsedMillis
        return .success(self)
    }

    private mutating func tickForTime(
        timeCap: TimerDuration,
        newElapsed: TimerDuration,
        newElapsedMillis: Int
    ) -> Result<TimerSession, TimerError> {
        if newElapsed.seconds >= timeCap.seconds {
            markComplete(elapsedAt: timeCap)
            return .success(self)
        }
        elapsed = newElapsed
        elapsedMillis = newElapsedMillis
        return .success(self)
    }

    private mutating func tickEmom(
        intervalDuration: TimerDuration,
        rounds: RoundCount,
        newElapsed: TimerDuration,
        newIntervalElapsed: TimerDuration,
        newElapsedMillis: Int,
        newIntervalMillis: Int
    ) -> Result<TimerSession, TimerError> {
        // Consume every interval the delta covers: after the watch was asleep
        // one catch-up tick can span several rounds, and advancing only one
        // per tick desynced the session from the wall clock.
        let intervalSeconds = intervalDuration.seconds
        var intervalElapsedSeconds = newIntervalElapsed.seconds
        var round = currentRound
        while intervalSeconds > 0 && intervalElapsedSeconds >= intervalSeconds {
            if round >= rounds.value {
                markComplete(elapsedAt: TimerDuration(seconds: intervalSeconds * rounds.value))
                return .success(self)
            }
            intervalElapsedSeconds -= intervalSeconds
            round += 1
        }

        elapsed = newElapsed
        elapsedMillis = newElapsedMillis
        currentIntervalElapsed = TimerDuration(seconds: intervalElapsedSeconds)
        intervalElapsedMillis = newIntervalMillis
        currentRound = round
        return .success(self)
    }

    private mutating func tickTabata(
        workDuration: TimerDuration,
        restDuration: TimerDuration,
        rounds: RoundCount,
        newElapsed: TimerDuration,
        newIntervalElapsed: TimerDuration,
        newElapsedMillis: Int,
        newIntervalMillis: Int
    ) -> Result<TimerSession, TimerError> {
        // Consume every work / rest phase the delta covers (see tickEmom).
        let work = workDuration.seconds
        let rest = restDuration.seconds
        var isWorkPhase = state == .running
        var intervalElapsedSeconds = newIntervalElapsed.seconds
        var round = currentRound
        var phaseSeconds = isWorkPhase ? work : rest
        while work + rest > 0 && intervalElapsedSeconds >= phaseSeconds {
            intervalElapsedSeconds -= phaseSeconds
            if isWorkPhase {
                isWorkPhase = false
            } else {
                if round >= rounds.value {
                    markComplete(elapsedAt: TimerDuration(seconds: (work + rest) * rounds.value))
                    return .success(self)
                }
                round += 1
                isWorkPhase = true
            }
            phaseSeconds = isWorkPhase ? work : rest
        }

        state = isWorkPhase ? .running : .resting
        elapsed = newElapsed
        elapsedMillis = newElapsedMillis
        currentIntervalElapsed = TimerDuration(seconds: intervalElapsedSeconds)
        intervalElapsedMillis = newIntervalMillis
        currentRound = round
        return .success(self)
    }

    /// [elapsedAt] pins the final time to the workout's exact boundary
    /// (10:00 for a 10-minute AMRAP); without it the summary read one tick
    /// short (9:59).
    private mutating func markComplete(elapsedAt: TimerDuration? = nil) {
        state = .completed
        completedAt = Date()
        if let elapsedAt {
            elapsed = elapsedAt
            elapsedMillis = 0
        }
    }

    // MARK: - AMRAP round tally

    /// Count one AMRAP round (tap-to-count). AMRAP sessions start at round 1
    /// and the clock never advances them, so completed rounds are
    /// currentRound - 1.
    mutating func countRound() {
        guard case .amrap = workout.timerType, state == .running else { return }
        currentRound += 1
    }

    /// Correct the AMRAP tally on the end screen; never below zero rounds.
    mutating func adjustRounds(by delta: Int) {
        guard case .amrap = workout.timerType, state == .completed else { return }
        currentRound = max(1, currentRound + delta)
    }

    /// Rounds the athlete counted in an AMRAP.
    var countedRounds: Int { max(0, currentRound - 1) }

    // MARK: - Computed Properties

    /// Time remaining in the current phase/interval.
    var timeRemaining: TimerDuration {
        // While paused, answer for the phase the session paused in, so the
        // clock reads what it read the instant before the pause (a Tabata
        // paused mid-WORK used to be measured against the REST length).
        let phase = state == .paused ? (stateBeforePause ?? state) : state
        if phase == .preparing {
            let remaining = workout.prepCountdown.seconds - currentIntervalElapsed.seconds
            return TimerDuration(seconds: max(0, remaining))
        }

        switch workout.timerType {
        case let .amrap(duration):
            return TimerDuration(seconds: max(0, duration.seconds - elapsed.seconds))
        case let .forTime(timeCap, _):
            return TimerDuration(seconds: max(0, timeCap.seconds - elapsed.seconds))
        case let .emom(intervalDuration, _):
            return TimerDuration(seconds: max(0, intervalDuration.seconds - currentIntervalElapsed.seconds))
        case let .tabata(workDuration, restDuration, _):
            let phaseSeconds = phase == .running ? workDuration.seconds : restDuration.seconds
            return TimerDuration(seconds: max(0, phaseSeconds - currentIntervalElapsed.seconds))
        }
    }

    /// Progress through the workout (0.0 to 1.0).
    var progress: Double {
        if state == .ready { return 0 }
        if state == .completed { return 1 }

        let totalSeconds = workout.timerType.estimatedDuration.seconds
        guard totalSeconds > 0 else { return 0 }

        return min(1.0, max(0.0, Double(elapsed.seconds) / Double(totalSeconds)))
    }

    /// Total rounds for this workout (nil if not applicable).
    var totalRounds: Int? { workout.roundCount }

    /// Whether this is an interval-based workout.
    var isIntervalBased: Bool { workout.isIntervalBased }
}
