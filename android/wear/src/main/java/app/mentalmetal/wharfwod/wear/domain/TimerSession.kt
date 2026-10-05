package app.mentalmetal.wharfwod.wear.domain

/**
 * The aggregate root of a running timer, a port of the watch's TimerSession:
 * every change goes through [tick], [pause], [resume], [complete], and a
 * large delta (the watch was asleep) is consumed interval by interval.
 */
data class TimerSession(
    val workout: Workout,
    val state: TimerState = TimerState.READY,
    val currentRound: Int = 1,
    val elapsed: TimerDuration = TimerDuration.zero,
    val currentIntervalElapsed: TimerDuration = TimerDuration.zero,
    val elapsedMillis: Int = 0,
    val intervalElapsedMillis: Int = 0,
    val stateBeforePause: TimerState? = null,
) {
    sealed class Failure {
        data class InvalidTransition(val from: TimerState, val to: TimerState) : Failure()
        object AlreadyCompleted : Failure()
        object NotActive : Failure()
    }

    sealed class Result {
        data class Ok(val session: TimerSession) : Result()
        data class Err(val failure: Failure) : Result()
    }

    fun start(): Result {
        if (!state.canStart) return Result.Err(Failure.InvalidTransition(state, TimerState.PREPARING))
        val next = if (workout.prepCountdown.seconds > 0) TimerState.PREPARING else TimerState.RUNNING
        return Result.Ok(copy(state = next))
    }

    fun pause(): Result {
        if (!state.canPause) return Result.Err(Failure.InvalidTransition(state, TimerState.PAUSED))
        return Result.Ok(copy(stateBeforePause = state, state = TimerState.PAUSED))
    }

    fun resume(): Result {
        if (!state.canResume) return Result.Err(Failure.InvalidTransition(state, TimerState.RUNNING))
        return Result.Ok(copy(state = stateBeforePause ?: TimerState.RUNNING, stateBeforePause = null))
    }

    fun complete(): Result {
        if (state == TimerState.COMPLETED) return Result.Err(Failure.AlreadyCompleted)
        if (state == TimerState.READY) return Result.Err(Failure.InvalidTransition(state, TimerState.COMPLETED))
        return Result.Ok(markComplete())
    }

    /** The engine's tick, about every 100ms; a delta can span minutes after sleep. */
    fun tick(deltaMs: Int): Result {
        if (!state.isActive) return Result.Err(Failure.NotActive)
        val totalElapsedMillis = elapsedMillis + deltaMs
        val totalIntervalMillis = intervalElapsedMillis + deltaMs
        val newElapsedSeconds = elapsed.seconds + totalElapsedMillis / 1000
        val newElapsedRemainder = totalElapsedMillis % 1000
        val newIntervalSeconds = currentIntervalElapsed.seconds + totalIntervalMillis / 1000
        val newIntervalRemainder = totalIntervalMillis % 1000
        val newElapsed = TimerDuration.of(newElapsedSeconds)
        val newIntervalElapsed = TimerDuration.of(newIntervalSeconds)

        if (state == TimerState.PREPARING) {
            if (newIntervalElapsed.seconds >= workout.prepCountdown.seconds) {
                // Prep done: carry the overshoot into the workout, so a large delta loses nothing.
                val overflow = TimerDuration.of(newIntervalElapsed.seconds - workout.prepCountdown.seconds)
                return Result.Ok(copy(
                    state = TimerState.RUNNING, elapsed = overflow, currentIntervalElapsed = overflow,
                    intervalElapsedMillis = newIntervalRemainder, elapsedMillis = newElapsedRemainder,
                ))
            }
            return Result.Ok(copy(
                currentIntervalElapsed = newIntervalElapsed, intervalElapsedMillis = newIntervalRemainder,
                elapsedMillis = newElapsedRemainder,
            ))
        }

        return when (val type = workout.timerType) {
            is TimerType.Amrap -> tickFixed(type.duration, newElapsed, newElapsedRemainder)
            is TimerType.ForTime -> tickFixed(type.timeCap, newElapsed, newElapsedRemainder)
            is TimerType.Emom -> tickEmom(type, newElapsed, newIntervalElapsed, newElapsedRemainder, newIntervalRemainder)
            is TimerType.Tabata -> tickTabata(type, newElapsed, newIntervalElapsed, newElapsedRemainder, newIntervalRemainder)
        }
    }

    private fun tickFixed(duration: TimerDuration, newElapsed: TimerDuration, remainder: Int): Result {
        if (newElapsed.seconds >= duration.seconds) return Result.Ok(markComplete(duration))
        return Result.Ok(copy(elapsed = newElapsed, elapsedMillis = remainder))
    }

    private fun tickEmom(
        type: TimerType.Emom, newElapsed: TimerDuration, newIntervalElapsed: TimerDuration,
        elapsedRemainder: Int, intervalRemainder: Int,
    ): Result {
        // Consume every interval the delta covers (a catch-up tick after sleep can span rounds).
        val intervalSeconds = type.intervalDuration.seconds
        var intervalElapsedSeconds = newIntervalElapsed.seconds
        var round = currentRound
        while (intervalSeconds > 0 && intervalElapsedSeconds >= intervalSeconds) {
            if (round >= type.rounds.value) {
                return Result.Ok(markComplete(TimerDuration.of(intervalSeconds * type.rounds.value)))
            }
            intervalElapsedSeconds -= intervalSeconds
            round += 1
        }
        return Result.Ok(copy(
            elapsed = newElapsed, elapsedMillis = elapsedRemainder,
            currentIntervalElapsed = TimerDuration.of(intervalElapsedSeconds), intervalElapsedMillis = intervalRemainder,
            currentRound = round,
        ))
    }

    private fun tickTabata(
        type: TimerType.Tabata, newElapsed: TimerDuration, newIntervalElapsed: TimerDuration,
        elapsedRemainder: Int, intervalRemainder: Int,
    ): Result {
        val work = type.workDuration.seconds
        val rest = type.restDuration.seconds
        var isWorkPhase = state == TimerState.RUNNING
        var intervalElapsedSeconds = newIntervalElapsed.seconds
        var round = currentRound
        var phaseSeconds = if (isWorkPhase) work else rest
        while (work + rest > 0 && intervalElapsedSeconds >= phaseSeconds) {
            intervalElapsedSeconds -= phaseSeconds
            if (isWorkPhase) {
                isWorkPhase = false
            } else {
                if (round >= type.rounds.value) {
                    return Result.Ok(markComplete(TimerDuration.of((work + rest) * type.rounds.value)))
                }
                round += 1
                isWorkPhase = true
            }
            phaseSeconds = if (isWorkPhase) work else rest
        }
        return Result.Ok(copy(
            state = if (isWorkPhase) TimerState.RUNNING else TimerState.RESTING,
            elapsed = newElapsed, elapsedMillis = elapsedRemainder,
            currentIntervalElapsed = TimerDuration.of(intervalElapsedSeconds), intervalElapsedMillis = intervalRemainder,
            currentRound = round,
        ))
    }

    /** [elapsedAt] pins the final time to the exact boundary (10:00 for a 10-minute AMRAP). */
    private fun markComplete(elapsedAt: TimerDuration? = null): TimerSession =
        if (elapsedAt != null) copy(state = TimerState.COMPLETED, elapsed = elapsedAt, elapsedMillis = 0)
        else copy(state = TimerState.COMPLETED)

    /** Count one AMRAP round (tap to count); the clock never advances AMRAP rounds. */
    fun countRound(): TimerSession =
        if (workout.timerType is TimerType.Amrap && state == TimerState.RUNNING) copy(currentRound = currentRound + 1) else this

    /** Correct the AMRAP tally on the end screen; never below zero rounds. */
    fun adjustRounds(delta: Int): TimerSession =
        if (workout.timerType is TimerType.Amrap && state == TimerState.COMPLETED) copy(currentRound = maxOf(1, currentRound + delta)) else this

    val countedRounds: Int get() = maxOf(0, currentRound - 1)

    /** Time remaining in the current phase (the paused phase while paused). */
    val timeRemaining: TimerDuration
        get() {
            val phase = if (state == TimerState.PAUSED) (stateBeforePause ?: state) else state
            if (phase == TimerState.PREPARING) {
                return TimerDuration.of(maxOf(0, workout.prepCountdown.seconds - currentIntervalElapsed.seconds))
            }
            return when (val type = workout.timerType) {
                is TimerType.Amrap -> TimerDuration.of(maxOf(0, type.duration.seconds - elapsed.seconds))
                is TimerType.ForTime -> TimerDuration.of(maxOf(0, type.timeCap.seconds - elapsed.seconds))
                is TimerType.Emom -> TimerDuration.of(maxOf(0, type.intervalDuration.seconds - currentIntervalElapsed.seconds))
                is TimerType.Tabata -> {
                    val phaseSeconds = if (phase == TimerState.RUNNING) type.workDuration.seconds else type.restDuration.seconds
                    TimerDuration.of(maxOf(0, phaseSeconds - currentIntervalElapsed.seconds))
                }
            }
        }

    /** Progress through the workout, 0 to 1. */
    val progress: Double
        get() {
            if (state == TimerState.READY) return 0.0
            if (state == TimerState.COMPLETED) return 1.0
            val total = workout.timerType.estimatedDuration.seconds
            if (total <= 0) return 0.0
            return (elapsed.seconds.toDouble() / total).coerceIn(0.0, 1.0)
        }

    val totalRounds: Int? get() = workout.roundCount

    companion object {
        fun fromWorkout(workout: Workout) = TimerSession(workout)
    }
}
