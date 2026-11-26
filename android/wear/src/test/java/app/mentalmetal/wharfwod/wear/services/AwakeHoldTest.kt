package app.mentalmetal.wharfwod.wear.services

import app.mentalmetal.wharfwod.wear.amrap
import app.mentalmetal.wharfwod.wear.emom
import app.mentalmetal.wharfwod.wear.tabata
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * 26 Nov 2026: with a workout running and the screen off the app held no
 * wake lock, so a real watch was free to suspend its processor and the
 * timer's ticks with it (an emulator never suspends, so no run showed it).
 * The hold lasts while the clock runs, lets go while paused and never
 * outlives the workout.
 */
class AwakeHoldTest {
    private class SpyLock : CpuLock {
        val log = mutableListOf<String>()
        override fun acquire(timeoutMs: Long) { log.add("acquire:$timeoutMs") }
        override fun release() { log.add("release") }
    }

    @Test fun `START takes the processor for the whole workout and the end gives it back`() {
        val lock = SpyLock()
        val hold = AwakeHold(lock)
        hold.begin(emom(interval = 60, rounds = 10, prep = 10))
        assertTrue(hold.held)
        assertEquals("get ready, ten minutes and the margin", listOf("acquire:670000"), lock.log)
        hold.end()
        assertFalse(hold.held)
        assertEquals(listOf("acquire:670000", "release"), lock.log)
    }

    @Test fun `a paused workout lets the watch sleep and resuming takes it again`() {
        val lock = SpyLock()
        val hold = AwakeHold(lock)
        hold.begin(tabata(work = 20, rest = 10, rounds = 8, prep = 10))
        hold.pause()
        assertFalse("a WOD left paused must not hold the processor", hold.held)
        hold.pause()
        hold.resume()
        assertTrue(hold.held)
        hold.end()
        assertEquals(listOf("acquire:310000", "release", "acquire:310000", "release"), lock.log)
    }

    @Test fun `every hold has a time limit no longer than the workout needs`() {
        assertEquals(60_000L + AwakeHold.MARGIN_MS, AwakeHold.budgetMs(amrap(seconds = 60, prep = 0)))
        // The longest workout the setup screens allow: an hour, plus get ready.
        val longest = AwakeHold.budgetMs(amrap(seconds = 3600, prep = 10))
        assertEquals(3_670_000L, longest)
        assertTrue("never an unbounded lock", longest < 2 * 3_600_000L)
    }

    @Test fun `nothing is released that was not taken and nothing is taken after the end`() {
        val lock = SpyLock()
        val hold = AwakeHold(lock)
        hold.end()
        hold.pause()
        hold.resume()
        assertEquals("no workout, no lock", emptyList<String>(), lock.log)
        hold.begin(amrap(seconds = 600, prep = 10))
        hold.end()
        hold.resume()
        hold.end()
        assertEquals(listOf("acquire:670000", "release"), lock.log)
        assertFalse(hold.held)
    }

    @Test fun `AGAIN takes a fresh hold for the new workout`() {
        val lock = SpyLock()
        val hold = AwakeHold(lock)
        hold.begin(amrap(seconds = 600, prep = 10))
        hold.end()
        hold.begin(amrap(seconds = 300, prep = 10))
        assertEquals(listOf("acquire:670000", "release", "acquire:370000"), lock.log)
        assertTrue(hold.held)
    }

    @Test fun `the tracker holds it from START, lets go on pause and at the end`() {
        // The tracker needs a watch to run; its wiring is pinned from the source.
        val tracker = File("src/main/java/app/mentalmetal/wharfwod/wear/services/ExerciseTracker.kt").readText()
        fun body(name: String) = tracker.substringAfter("override fun $name(").substringBefore("\n    }")
        assertTrue(body("begin").contains("awake.begin(workout)"))
        assertTrue("before the exercise check: timer only is the default", body("pause").trimStart().substringAfter("{").trimStart().startsWith("awake.pause()"))
        assertTrue(body("resume").trimStart().substringAfter("{").trimStart().startsWith("awake.resume()"))
        assertTrue(body("end").contains("awake.end()"))
        assertTrue(tracker.contains("PowerManager.PARTIAL_WAKE_LOCK"))
        assertTrue("every acquire carries its limit", tracker.contains("lock.acquire(timeoutMs)"))
    }
}
