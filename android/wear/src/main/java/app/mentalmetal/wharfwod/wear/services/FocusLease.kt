package app.mentalmetal.wharfwod.wear.services

/**
 * Counts the cues holding audio focus (which ducks the music) and releases
 * each hold exactly once: on the clip's end when the player reports it, or
 * after [releaseAfterMs] when it never does (SoundPool reports nothing).
 * A port of the phone's SessionLease.
 */
class FocusLease(
    private val onActivate: () -> Unit,
    private val onDeactivate: () -> Unit,
    private val releaseAfterMs: Long,
    private val schedule: (Long, () -> Unit) -> () -> Unit,
) {
    private class Hold {
        var released = false
        var cancelTimer: (() -> Unit)? = null
    }

    private val holds = mutableMapOf<String, Hold>()
    var active = 0
        private set

    /** Opens a hold for [key]; an open hold on the same key is taken over without a flap. */
    fun acquire(key: String) {
        val old = holds[key]
        if (old != null) {
            old.released = true
            old.cancelTimer?.invoke()
        } else {
            active++
        }
        val hold = Hold()
        holds[key] = hold
        if (old == null && active == 1) {
            try {
                onActivate()
            } catch (e: Exception) {
                active--
                holds.remove(key)
                throw e
            }
        }
        hold.cancelTimer = schedule(releaseAfterMs) { release(key, hold) }
    }

    fun complete(key: String) {
        holds[key]?.let { release(key, it) }
    }

    fun releaseAll() {
        holds.entries.toList().forEach { release(it.key, it.value) }
    }

    private fun release(key: String, hold: Hold) {
        if (hold.released) return
        hold.released = true
        hold.cancelTimer?.invoke()
        if (holds[key] === hold) holds.remove(key)
        active--
        if (active <= 0) {
            active = 0
            onDeactivate()
        }
    }
}
