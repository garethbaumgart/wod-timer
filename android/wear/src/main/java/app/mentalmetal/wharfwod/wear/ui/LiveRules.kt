package app.mentalmetal.wharfwod.wear.ui

import app.mentalmetal.wharfwod.wear.domain.TimerDuration
import app.mentalmetal.wharfwod.wear.domain.TimerSession
import app.mentalmetal.wharfwod.wear.domain.TimerState
import app.mentalmetal.wharfwod.wear.domain.TimerType

/** Live-screen rules shared by the running, paused and end screens (a port of the watch's LiveRules). */
object LiveRules {
    enum class Tone { PREPARE, WORK, REST, PAUSED, MODE }

    data class PhaseWord(val text: String, val tone: Tone)

    data class EndSummary(val word: String, val hero: String?, val label: String)

    fun effectivePhase(s: TimerSession): TimerState =
        if (s.state == TimerState.PAUSED) (s.stateBeforePause ?: TimerState.RUNNING) else s.state

    fun phaseSeconds(s: TimerSession): Int {
        if (s.state == TimerState.PREPARING) return s.workout.prepCountdown.seconds
        return when (val t = s.workout.timerType) {
            is TimerType.Amrap -> t.duration.seconds
            is TimerType.ForTime -> t.timeCap.seconds
            is TimerType.Emom -> t.intervalDuration.seconds
            is TimerType.Tabata -> if (effectivePhase(s) == TimerState.RESTING) t.restDuration.seconds else t.workDuration.seconds
        }
    }

    fun isCountUp(s: TimerSession) = (s.workout.timerType as? TimerType.ForTime)?.countUp == true

    /** "9:45", "0:11", or bare seconds ("55") under a minute or in a phase of a minute or less. */
    fun clockText(s: TimerSession): String {
        if (s.state != TimerState.PREPARING && isCountUp(s)) return s.elapsed.clock
        val secs = s.timeRemaining.seconds
        return if (secs < 60 || phaseSeconds(s) <= 60) "$secs" else s.timeRemaining.clock
    }

    /** The longest value the clock can show, so its size is set once per workout. */
    fun referenceClock(type: TimerType): String {
        fun display(d: TimerDuration) = if (d.seconds <= 60) "${d.seconds}" else d.clock
        return when (type) {
            is TimerType.Amrap -> type.duration.clock
            is TimerType.ForTime -> type.timeCap.clock
            is TimerType.Emom -> display(type.intervalDuration)
            is TimerType.Tabata -> display(if (type.workDuration.seconds >= type.restDuration.seconds) type.workDuration else type.restDuration)
        }
    }

    fun elapsedSeconds(s: TimerSession): Double =
        if (effectivePhase(s) == TimerState.PREPARING) 0.0 else s.elapsed.seconds + s.elapsedMillis / 1000.0

    /** The phase word, or null when there is none to name (AMRAP, EMOM and For Time work). */
    fun phaseWord(s: TimerSession): PhaseWord? {
        val isTabata = s.workout.timerType is TimerType.Tabata
        return when (s.state) {
            TimerState.PREPARING -> PhaseWord("GET READY", Tone.PREPARE)
            TimerState.PAUSED -> if (!isTabata) PhaseWord("PAUSED", Tone.PAUSED)
            else PhaseWord(if (effectivePhase(s) == TimerState.RESTING) "PAUSED · REST" else "PAUSED · WORK", Tone.PAUSED)
            TimerState.RESTING -> when {
                !isTabata -> null
                s.currentRound >= (s.totalRounds ?: 0) -> PhaseWord("LAST REST", Tone.REST)
                s.timeRemaining.seconds <= 5 -> PhaseWord("NEXT · WORK", Tone.WORK)
                else -> PhaseWord("REST", Tone.REST)
            }
            TimerState.RUNNING -> when {
                !isTabata -> null
                s.timeRemaining.seconds <= 5 -> PhaseWord("NEXT · REST", Tone.REST)
                else -> PhaseWord("WORK", Tone.WORK)
            }
            else -> null
        }
    }

    /** "AMRAP · 10:00", "FOR TIME · CAP 20:00", "EMOM · 10 × 1:00", "TABATA · 8 × 20s / 10s". */
    fun configLine(type: TimerType): String = when (type) {
        is TimerType.Amrap -> "AMRAP · ${type.duration.clock}"
        is TimerType.ForTime -> "FOR TIME · CAP ${type.timeCap.clock}"
        is TimerType.Emom -> "EMOM · ${type.rounds.value} × ${type.intervalDuration.clock}"
        is TimerType.Tabata -> "TABATA · ${type.rounds.value} × ${type.workDuration.phase} / ${type.restDuration.phase}"
    }

    fun endSummary(s: TimerSession, endedEarly: Boolean, endedAtTimeCap: Boolean): EndSummary {
        if (endedAtTimeCap) return EndSummary("Time cap", null, "")
        val word = if (endedEarly) "Stopped" else "Finished"
        return when (s.workout.timerType) {
            is TimerType.Amrap -> EndSummary(word, "${s.countedRounds}", if (endedEarly) "ROUNDS · ${s.elapsed.clock}" else "ROUNDS")
            is TimerType.ForTime -> EndSummary(word, s.elapsed.clock, "TIME")
            else -> {
                val total = s.totalRounds ?: 0
                val rounds = if (endedEarly) s.currentRound else total
                EndSummary(word, "$rounds/$total", "ROUNDS · ${s.elapsed.clock}")
            }
        }
    }
}
