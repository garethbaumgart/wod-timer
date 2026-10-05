package app.mentalmetal.wharfwod.wear.domain

/** A validated duration in seconds, 0 to 2 hours, as on the phone and the watch. */
@JvmInline
value class TimerDuration(val seconds: Int) {
    companion object {
        const val MAX_SECONDS = 7200
        val zero = TimerDuration(0)
        fun of(seconds: Int) = TimerDuration(seconds.coerceIn(0, MAX_SECONDS))
        fun fromMinutesAndSeconds(minutes: Int, seconds: Int) = of(minutes * 60 + seconds)
    }

    val minutes: Int get() = seconds / 60
    val remainingSeconds: Int get() = seconds % 60

    /** Clock format used everywhere since 1.3.0: "9:45", "0:11", "12:30". */
    val clock: String get() = "$minutes:" + remainingSeconds.toString().padStart(2, '0')

    /** A phase length the way athletes say it: "20s" under a minute, "2:00" from a minute up. */
    val phase: String get() = if (seconds < 60) "${seconds}s" else clock

    operator fun plus(other: TimerDuration) = of(seconds + other.seconds)
    operator fun minus(other: TimerDuration) = of(seconds - other.seconds)
    operator fun compareTo(other: TimerDuration) = seconds.compareTo(other.seconds)
}

/** A round count, 1 to 99. */
@JvmInline
value class RoundCount(val value: Int) {
    companion object {
        const val MAX = 99
        val tabataDefault = RoundCount(8)
        fun of(value: Int) = RoundCount(value.coerceIn(1, MAX))
    }
}

enum class TimerState {
    READY, PREPARING, RUNNING, RESTING, PAUSED, COMPLETED;

    val isActive: Boolean get() = this == PREPARING || this == RUNNING || this == RESTING
    val canStart: Boolean get() = this == READY
    val canPause: Boolean get() = this == RUNNING || this == RESTING || this == PREPARING
    val canResume: Boolean get() = this == PAUSED
    val isFinished: Boolean get() = this == COMPLETED
}

/** One block of the Home / live / end timeline: work in the mode colour, rest in pink. */
data class TimelinePart(val seconds: Int, val isRest: Boolean)

sealed class TimerType {
    data class Amrap(val duration: TimerDuration) : TimerType()
    data class ForTime(val timeCap: TimerDuration, val countUp: Boolean = true) : TimerType()
    data class Emom(val intervalDuration: TimerDuration, val rounds: RoundCount) : TimerType()
    data class Tabata(val workDuration: TimerDuration, val restDuration: TimerDuration, val rounds: RoundCount) : TimerType()

    val displayLabel: String
        get() = when (this) {
            is Amrap -> "AMRAP"
            is ForTime -> "FOR TIME"
            is Emom -> "EMOM"
            is Tabata -> "TABATA"
        }

    val typeCode: String
        get() = when (this) {
            is Amrap -> "amrap"
            is ForTime -> "fortime"
            is Emom -> "emom"
            is Tabata -> "tabata"
        }

    val estimatedDuration: TimerDuration
        get() = when (this) {
            is Amrap -> duration
            is ForTime -> timeCap
            is Emom -> TimerDuration.of(intervalDuration.seconds * rounds.value)
            is Tabata -> TimerDuration.of((workDuration.seconds + restDuration.seconds) * rounds.value)
        }

    val roundCount: Int?
        get() = when (this) {
            is Emom -> rounds.value
            is Tabata -> rounds.value
            else -> null
        }

    /** The workout drawn as blocks: For Time and AMRAP one bar, EMOM a block per round, Tabata work / rest pairs. */
    val timelineParts: List<TimelinePart>
        get() = when (this) {
            is Amrap -> listOf(TimelinePart(duration.seconds, false))
            is ForTime -> listOf(TimelinePart(timeCap.seconds, false))
            is Emom -> List(rounds.value) { TimelinePart(intervalDuration.seconds, false) }
            is Tabata -> (0 until rounds.value).flatMap {
                listOf(TimelinePart(workDuration.seconds, false), TimelinePart(restDuration.seconds, true))
            }
        }

    companion object {
        val standardTabata: TimerType = Tabata(TimerDuration.of(20), TimerDuration.of(10), RoundCount.tabataDefault)

        /** How far each block is filled after [elapsed] seconds: finished parts 1, the current one partial, the rest 0. */
        fun fillFractions(parts: List<TimelinePart>, elapsed: Double): List<Double> {
            var start = 0.0
            return parts.map { part ->
                val length = maxOf(1, part.seconds).toDouble()
                val fraction = ((elapsed - start) / length).coerceIn(0.0, 1.0)
                start += part.seconds
                fraction
            }
        }
    }
}

data class Workout(
    val name: String,
    val timerType: TimerType,
    val prepCountdown: TimerDuration = TimerDuration.of(10),
) {
    val roundCount: Int? get() = timerType.roundCount
    val totalDuration: TimerDuration get() = prepCountdown + timerType.estimatedDuration

    companion object {
        fun defaultAmrap() = Workout("AMRAP Workout", TimerType.Amrap(TimerDuration.of(600)))
        fun defaultForTime() = Workout("For Time", TimerType.ForTime(TimerDuration.of(1200)))
        fun defaultEmom() = Workout("EMOM", TimerType.Emom(TimerDuration.of(60), RoundCount.of(10)))
        fun defaultTabata() = Workout("Tabata", TimerType.standardTabata)
        fun of(type: TimerType, prepSeconds: Int = 10) = Workout(type.displayLabel, type, TimerDuration.of(prepSeconds))
    }
}
