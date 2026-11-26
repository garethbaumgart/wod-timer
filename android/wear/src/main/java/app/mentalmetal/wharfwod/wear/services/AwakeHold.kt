package app.mentalmetal.wharfwod.wear.services

import app.mentalmetal.wharfwod.wear.domain.Workout

/** What [AwakeHold] holds; on a watch, a partial wake lock. */
interface CpuLock {
    /** Keeps the processor running until [release], or for [timeoutMs] at most. */
    fun acquire(timeoutMs: Long)
    fun release()
}

/**
 * Keeps the processor running while the workout clock runs (26 Nov 2026).
 *
 * The foreground service keeps the process, not the processor. Once the
 * screen goes ambient or off a watch suspends its CPU between the system's
 * own wake-ups, and the timer's ticks stop with it: no beeps, no taps, and
 * a clock that only catches up when the wrist comes back, which is what the
 * Apple Watch app did before it had a workout session (2.1.0). An emulator
 * never suspends, so every run there kept perfect time and nothing showed
 * it; with a workout running and the screen off, `dumpsys power` listed no
 * wake lock of ours. A partial wake lock is the sanctioned way to keep
 * ticking with the screen off, and belongs with a foreground service.
 *
 * Held from START to the end, let go while paused (nothing is due until
 * the athlete resumes, and a WOD left paused must not drain the watch) and
 * always with a time limit: the whole workout plus a margin, so a lock the
 * app somehow never released ends by itself.
 */
class AwakeHold(private val lock: CpuLock) {
    companion object {
        /** Past the workout's own length: the end cues, and a tick that runs late. */
        const val MARGIN_MS = 60_000L

        /** The longest the workout's clock can still need the processor: get ready, the workout, the margin. */
        fun budgetMs(workout: Workout): Long =
            (workout.prepCountdown.seconds + workout.timerType.estimatedDuration.seconds) * 1000L + MARGIN_MS
    }

    var held = false
        private set
    private var budgetMs = 0L

    /** START: the clock runs from here, get ready included. */
    fun begin(workout: Workout) {
        budgetMs = budgetMs(workout)
        take()
    }

    fun pause() = drop()

    /** Resuming takes the whole budget again: what is left is never more. */
    fun resume() {
        if (budgetMs > 0) take()
    }

    /** The end, a stop, or a cancelled get ready. */
    fun end() {
        budgetMs = 0
        drop()
    }

    private fun take() {
        lock.acquire(budgetMs)
        held = true
    }

    private fun drop() {
        if (!held) return
        held = false
        lock.release()
    }
}
