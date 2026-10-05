package app.mentalmetal.wharfwod.wear.application

import android.os.SystemClock
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * Ticks about every 100ms with the elapsed milliseconds of a monotonic
 * clock, so the session follows the wall clock whatever the tick jitter
 * (and catches up after the process was held off).
 */
class TimerEngine(
    private val scope: CoroutineScope,
    private val clock: () -> Long = { SystemClock.elapsedRealtime() },
) : Ticker {
    var onTick: ((Long) -> Unit)? = null

    private var job: Job? = null
    private var startAt = 0L
    private var pausedElapsed = 0L

    var isPaused = false
        private set
    val isRunning: Boolean get() = job != null

    override fun start() {
        stop()
        pausedElapsed = 0
        startAt = clock()
        isPaused = false
        launchTicker()
    }

    override fun pause() {
        if (job == null) return
        pausedElapsed += clock() - startAt
        isPaused = true
        cancelTicker()
    }

    override fun resume() {
        if (!isPaused) return
        startAt = clock()
        isPaused = false
        launchTicker()
    }

    override fun stop() {
        cancelTicker()
        pausedElapsed = 0
        isPaused = false
    }

    private fun launchTicker() {
        job = scope.launch {
            while (isActive) {
                onTick?.invoke(pausedElapsed + clock() - startAt)
                delay(100)
            }
        }
    }

    private fun cancelTicker() {
        job?.cancel()
        job = null
    }
}
