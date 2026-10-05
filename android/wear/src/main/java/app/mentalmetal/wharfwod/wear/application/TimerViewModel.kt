package app.mentalmetal.wharfwod.wear.application

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import app.mentalmetal.wharfwod.wear.domain.TimerSession
import app.mentalmetal.wharfwod.wear.domain.TimerState
import app.mentalmetal.wharfwod.wear.domain.TimerType
import app.mentalmetal.wharfwod.wear.domain.Workout
import app.mentalmetal.wharfwod.wear.services.AudioCues
import app.mentalmetal.wharfwod.wear.services.HapticCue
import app.mentalmetal.wharfwod.wear.services.WorkoutTracking
import app.mentalmetal.wharfwod.wear.services.WristHaptics
import kotlin.random.Random

/**
 * The timer's state and cue logic, a port of the watch's TimerViewModel:
 * the gym-timer beep pattern (three low beeps, then the high beep with the
 * voice line on it), one wrist cue per change with GO, last round, round,
 * rest, work precedence, optional lines that keep clear of the countdown,
 * and the workout session hooks. Ticks are whole milliseconds of the
 * engine clock, so the deltas sum to the elapsed time itself.
 */
/** What the view model needs from the engine; the real one is [TimerEngine]. */
interface Ticker {
    fun start()
    fun pause()
    fun resume()
    fun stop()
}

object NoopTicker : Ticker {
    override fun start() {}
    override fun pause() {}
    override fun resume() {}
    override fun stop() {}
}

class TimerViewModel(
    val haptics: WristHaptics,
    val audio: AudioCues,
    val tracker: WorkoutTracking,
    private val store: KeyValueStore,
    private val engine: Ticker = NoopTicker,
    private val random: Random = Random.Default,
    private val now: () -> Long = { System.currentTimeMillis() },
) {
    companion object {
        /** AMRAP taps are ignored this long after a counted round, after GO and after a resume. */
        const val ROUND_COUNT_COOLDOWN_MS = 700L
        /** A stop before this many seconds of workout is a false start: the record is discarded. */
        const val KEEP_RECORD_AFTER_SECONDS = 60
        const val HINT_KEY = "wear_hint_amrap_counted"
    }

    var session: TimerSession? by mutableStateOf(null)
        private set
    var phase: TimerState by mutableStateOf(TimerState.READY)
        private set
    /** True when the athlete ended with Stop: the end screen says "Stopped", never celebrates. */
    var endedEarly: Boolean by mutableStateOf(false)
        private set
    /** "TAP TO COUNT" shows until the athlete has counted a round once, ever. */
    var hasCountedRound: Boolean by mutableStateOf(store.getBoolean(HINT_KEY, false))
        private set

    val endedAtTimeCap: Boolean
        get() {
            val s = session ?: return false
            val cap = (s.workout.timerType as? TimerType.ForTime)?.timeCap ?: return false
            return phase == TimerState.COMPLETED && !endedEarly && s.elapsed.seconds >= cap.seconds
        }

    private var lastTickMillis = 0L
    private var lastLowBeep: String? = null
    private var lastVoiceAtMs: Long? = null
    private var playedGo = false
    private var lastRound = 0
    private var playedGetReady = false
    private var playedLastRound = false
    private var playedKeepGoing = false
    private var playedHalfway = false
    private var playedAlmostThere = false
    private var playedTenSeconds = false
    private var lastWorkout: Workout? = null
    private var roundCountBlockedUntil: Long? = null

    private fun blockRoundCount() { roundCountBlockedUntil = now() + ROUND_COUNT_COOLDOWN_MS }

    fun start(workout: Workout) {
        lastWorkout = workout
        resetCueState()
        endedEarly = false
        when (val r = TimerSession.fromWorkout(workout).start()) {
            is TimerSession.Result.Ok -> {
                session = r.session
                phase = r.session.state
                lastTickMillis = 0
                engine.start()
                tracker.begin(workout)
                if (r.session.state == TimerState.RUNNING) {
                    // No get-ready countdown: GO on the high beep right away.
                    playedGo = true
                    audio.playHighBeep()
                    say { if (random.nextBoolean()) audio.playGo() else audio.playLetsGo() }
                    haptics.play(HapticCue.GO)
                    tracker.go()
                    blockRoundCount()
                }
            }
            is TimerSession.Result.Err -> {}
        }
    }

    fun pause() {
        // The get-ready countdown is skipped or cancelled, never paused.
        if (phase == TimerState.PREPARING) return
        val current = session ?: return
        val r = current.pause() as? TimerSession.Result.Ok ?: return
        session = r.session
        phase = TimerState.PAUSED
        engine.pause()
        haptics.play(HapticCue.PAUSE)
        tracker.pause()
    }

    fun resume() {
        val current = session ?: return
        val r = current.resume() as? TimerSession.Result.Ok ?: return
        session = r.session
        phase = r.session.state
        engine.resume()
        haptics.play(HapticCue.RESUME)
        tracker.resume()
        blockRoundCount()
    }

    /** End early: an honest "Stopped", no celebration. */
    fun stop() {
        if (phase == TimerState.COMPLETED) return
        val current = session ?: return
        val r = current.complete() as? TimerSession.Result.Ok ?: return
        endedEarly = true
        session = r.session
        phase = TimerState.COMPLETED
        engine.stop()
        haptics.cancelPending()
        haptics.play(HapticCue.PAUSE)
        tracker.end(keep = r.session.elapsed.seconds >= KEEP_RECORD_AFTER_SECONDS)
    }

    /** For Time's success action: log the time and celebrate. */
    fun finish() {
        if (phase == TimerState.COMPLETED) return
        val current = session ?: return
        val r = current.complete() as? TimerSession.Result.Ok ?: return
        endedEarly = false
        session = r.session
        phase = TimerState.COMPLETED
        engine.stop()
        haptics.play(HapticCue.COMPLETE)
        tracker.end(keep = true)
        audio.playHighBeep()
        playCompletionEncouragement()
    }

    /** Cancel the get-ready countdown (nothing has happened yet). */
    fun cancelPrep() {
        if (phase == TimerState.PREPARING) reset()
    }

    /** Skip the rest of the get-ready countdown. */
    fun skipPrep() {
        if (phase != TimerState.PREPARING) return
        val current = session ?: return
        val remainingMs = current.timeRemaining.seconds * 1000
        val r = current.tick(remainingMs) as? TimerSession.Result.Ok ?: return
        handleCues(current, r.session)
        session = r.session
        phase = r.session.state
    }

    /** Count an AMRAP round (tap anywhere while running). */
    fun countRound() {
        if (phase != TimerState.RUNNING) return
        val current = session ?: return
        if (current.workout.timerType !is TimerType.Amrap) return
        val t = now()
        roundCountBlockedUntil?.let { if (t < it) return }
        roundCountBlockedUntil = t + ROUND_COUNT_COOLDOWN_MS
        session = current.countRound()
        haptics.play(HapticCue.TAP)
        if (!hasCountedRound) {
            hasCountedRound = true
            store.putBoolean(HINT_KEY, true)
        }
    }

    /** Correct the AMRAP tally on the end screen. */
    fun adjustRounds(delta: Int) {
        if (phase != TimerState.COMPLETED) return
        session = session?.adjustRounds(delta)
    }

    fun restart() {
        val workout = lastWorkout ?: return
        if (phase != TimerState.COMPLETED) return
        start(workout)
    }

    fun reset() {
        engine.stop()
        haptics.cancelPending()
        tracker.end(keep = false)
        session = null
        phase = TimerState.READY
        endedEarly = false
        lastWorkout = null
        resetCueState()
    }

    /** The engine's tick with the elapsed milliseconds of its clock. */
    fun onTick(elapsedMs: Long) {
        val current = session ?: return
        val deltaMs = (elapsedMs - lastTickMillis).toInt()
        lastTickMillis = elapsedMs
        when (val r = current.tick(deltaMs)) {
            is TimerSession.Result.Ok -> {
                handleCues(current, r.session)
                session = r.session
                if (r.session.state == TimerState.COMPLETED) {
                    phase = TimerState.COMPLETED
                    engine.stop()
                    haptics.play(HapticCue.COMPLETE)
                    tracker.end(keep = true)
                    playEndCues()
                } else {
                    phase = r.session.state
                }
            }
            is TimerSession.Result.Err -> {
                if (current.state == TimerState.COMPLETED && phase != TimerState.COMPLETED) {
                    phase = TimerState.COMPLETED
                    engine.stop()
                    haptics.play(HapticCue.COMPLETE)
                    tracker.end(keep = true)
                    playEndCues()
                }
            }
        }
    }

    /** The end is a change like any other: the high beep with the line on it; a capped For Time is a DNF. */
    private fun playEndCues() {
        audio.playHighBeep()
        if (endedAtTimeCap) audio.playComplete() else playCompletionEncouragement()
    }

    private fun handleCues(old: TimerSession, new: TimerSession) {
        var voiceCuePlayed = false
        var changeBeeped = false
        fun changeBeep() {
            if (changeBeeped) return
            changeBeeped = true
            audio.playHighBeep()
        }
        // One wrist cue per tick: GO, then last round, round, rest, work.
        var wristCue: HapticCue? = null

        if (new.state == TimerState.PREPARING && !playedGetReady) {
            playedGetReady = true
            say { audio.playGetReady() }
            voiceCuePlayed = true
        }

        playPhaseCountdown(new)

        if (old.state == TimerState.PREPARING && new.state == TimerState.RUNNING && !playedGo) {
            playedGo = true
            changeBeep()
            say { if (random.nextBoolean()) audio.playGo() else audio.playLetsGo() }
            wristCue = HapticCue.GO
            tracker.go()
            blockRoundCount()
            voiceCuePlayed = true
        }

        val roundChanged = new.currentRound != lastRound && lastRound != 0

        if (old.state == TimerState.RUNNING && new.state == TimerState.RESTING && !roundChanged) {
            changeBeep()
            say { audio.playRest() }
            if (wristCue == null) wristCue = HapticCue.WORK_TO_REST
            voiceCuePlayed = true
        }

        if (old.state == TimerState.RESTING && new.state == TimerState.RUNNING && wristCue == null) {
            wristCue = HapticCue.REST_TO_WORK
        }

        if (roundChanged) {
            lastRound = new.currentRound
            changeBeep()
            val total = new.totalRounds
            if (total != null && new.currentRound == total && !playedLastRound) {
                playedLastRound = true
                say { audio.playLastRound() }
                wristCue = HapticCue.LAST_ROUND
            } else {
                say { audio.playNextRound() }
                if (wristCue != HapticCue.GO) wristCue = HapticCue.ROUND_CHANGE
            }
            voiceCuePlayed = true
        } else if (lastRound == 0) {
            lastRound = new.currentRound
        }

        wristCue?.let { haptics.play(it) }

        if (voiceCuePlayed || !clearToSpeak(new)) return

        if (new.progress >= 0.33 && old.progress < 0.33 && !playedKeepGoing) {
            playedKeepGoing = true
            say { if (random.nextBoolean()) audio.playKeepGoing() else audio.playComeOn() }
            return
        }
        if (new.progress >= 0.5 && old.progress < 0.5 && !playedHalfway) {
            playedHalfway = true
            say { audio.playHalfway() }
            haptics.play(HapticCue.HALFWAY)
            return
        }
        if (new.progress >= 0.85 && old.progress < 0.85 && !playedAlmostThere) {
            playedAlmostThere = true
            say { audio.playAlmostThere() }
            return
        }
        if (new.state != TimerState.PREPARING && !playedTenSeconds && new.workout.timerType.estimatedDuration.seconds > 15) {
            val remaining = workoutRemaining(new)
            if (remaining in 9..10) {
                playedTenSeconds = true
                say { audio.playTenSeconds() }
            }
        }
    }

    private fun say(cue: () -> Unit) {
        lastVoiceAtMs = lastTickMillis
        cue()
    }

    /** More than four seconds before the phase's countdown and two seconds after the last line. */
    private fun clearToSpeak(s: TimerSession): Boolean {
        if (!s.state.isActive || s.timeRemaining.seconds <= 4) return false
        val last = lastVoiceAtMs ?: return true
        return lastTickMillis - last >= 2000
    }

    /** A low beep and a firm tap with 3, 2 and 1 seconds left in every phase. */
    private fun playPhaseCountdown(s: TimerSession) {
        if (!s.state.isActive) return
        val left = s.timeRemaining.seconds
        if (left < 1 || left > 3 || left >= phaseSeconds(s)) return
        val key = "${s.state}:${s.currentRound}:$left"
        if (key == lastLowBeep) return
        lastLowBeep = key
        audio.playLowBeep(left)
        haptics.play(HapticCue.COUNT_IN)
    }

    private fun phaseSeconds(s: TimerSession): Int {
        if (s.state == TimerState.PREPARING) return s.workout.prepCountdown.seconds
        return when (val t = s.workout.timerType) {
            is TimerType.Amrap -> t.duration.seconds
            is TimerType.ForTime -> t.timeCap.seconds
            is TimerType.Emom -> t.intervalDuration.seconds
            is TimerType.Tabata -> if (s.state == TimerState.RESTING) t.restDuration.seconds else t.workDuration.seconds
        }
    }

    private fun workoutRemaining(s: TimerSession): Int =
        maxOf(0, s.workout.timerType.estimatedDuration.seconds - s.elapsed.seconds)

    private fun playCompletionEncouragement() {
        if (random.nextBoolean()) audio.playGoodJob() else audio.playThatsIt()
    }

    private fun resetCueState() {
        lastLowBeep = null
        lastVoiceAtMs = null
        playedGo = false
        lastRound = 0
        playedGetReady = false
        playedLastRound = false
        playedKeepGoing = false
        playedHalfway = false
        playedAlmostThere = false
        playedTenSeconds = false
    }
}
