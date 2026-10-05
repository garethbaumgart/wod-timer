package app.mentalmetal.wharfwod.wear.services

import app.mentalmetal.wharfwod.wear.domain.Workout

/** The wrist cues, the same vocabulary as the Apple Watch app (2.2.0). */
enum class HapticCue { COUNT_IN, GO, ROUND_CHANGE, LAST_ROUND, WORK_TO_REST, REST_TO_WORK, HALFWAY, COMPLETE, PAUSE, RESUME, TAP }

interface WristHaptics {
    fun play(cue: HapticCue)
    fun cancelPending()
}

/** Vibration waveforms: alternating off / on segments in ms with an amplitude per segment. */
data class Waveform(val timings: LongArray, val amplitudes: IntArray)

/**
 * watchOS has no haptic intensity; Wear OS has amplitude, so the same
 * vocabulary maps to waveforms. A knock is 150ms at full amplitude; GO is
 * two, the last round three, a round adds a rising pulse, rest a falling
 * one; 3, 2, 1 is one firm tap. Knocks sit 350ms apart so each is felt.
 */
object HapticPatterns {
    private const val KNOCK = 150L
    private const val GAP = 350L

    fun waveform(cue: HapticCue): Waveform = when (cue) {
        HapticCue.COUNT_IN -> wave(0L to 0, 70L to 220)
        HapticCue.GO -> wave(0L to 0, KNOCK to 255, GAP to 0, KNOCK to 255)
        HapticCue.ROUND_CHANGE, HapticCue.REST_TO_WORK ->
            wave(0L to 0, KNOCK to 255, GAP to 0, 60L to 110, 60L to 0, 90L to 255)
        HapticCue.WORK_TO_REST -> wave(0L to 0, KNOCK to 255, GAP to 0, 90L to 255, 60L to 0, 60L to 110)
        HapticCue.LAST_ROUND -> wave(0L to 0, KNOCK to 255, GAP to 0, KNOCK to 255, GAP to 0, KNOCK to 255)
        HapticCue.HALFWAY -> wave(0L to 0, 80L to 180, 90L to 0, 80L to 180)
        HapticCue.COMPLETE -> wave(0L to 0, 50L to 120, 60L to 0, 50L to 180, 60L to 0, 90L to 255, 400L to 0, KNOCK to 255)
        HapticCue.PAUSE -> wave(0L to 0, 100L to 180)
        HapticCue.RESUME -> wave(0L to 0, 80L to 220)
        HapticCue.TAP -> wave(0L to 0, 30L to 120)
    }

    private fun wave(vararg segments: Pair<Long, Int>) =
        Waveform(segments.map { it.first }.toLongArray(), segments.map { it.second }.toIntArray())
}

/** What the audio service plays; the view model only knows these names. */
interface AudioCues {
    fun playHighBeep()
    fun playLowBeep(secondsLeft: Int)
    fun playGo()
    fun playLetsGo()
    fun playRest()
    fun playHalfway()
    fun playGetReady()
    fun playTenSeconds()
    fun playLastRound()
    fun playKeepGoing()
    fun playComeOn()
    fun playAlmostThere()
    fun playGoodJob()
    fun playThatsIt()
    fun playNextRound()
    fun playComplete()
}

/**
 * Keeps the app alive for the whole workout, the Wear equivalent of the
 * watch's HKWorkoutSession: a foreground service with an ongoing activity
 * and, where Health Services allows it, an exercise session.
 */
interface WorkoutTracking {
    /** START: open the session so the app survives the get-ready countdown. */
    fun begin(workout: Workout)
    /** GO: the exercise proper starts here. */
    fun go()
    fun pause()
    fun resume()
    /** `keep` false: a cancelled get ready or a stop inside the first minute. */
    fun end(keep: Boolean)
}

object NoopWorkoutTracker : WorkoutTracking {
    override fun begin(workout: Workout) {}
    override fun go() {}
    override fun pause() {}
    override fun resume() {}
    override fun end(keep: Boolean) {}
}
