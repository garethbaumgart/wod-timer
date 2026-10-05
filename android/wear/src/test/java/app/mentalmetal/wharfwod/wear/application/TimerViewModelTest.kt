package app.mentalmetal.wharfwod.wear.application

import app.mentalmetal.wharfwod.wear.SpyAudio
import app.mentalmetal.wharfwod.wear.SpyHaptics
import app.mentalmetal.wharfwod.wear.SpyTicker
import app.mentalmetal.wharfwod.wear.SpyTracker
import app.mentalmetal.wharfwod.wear.amrap
import app.mentalmetal.wharfwod.wear.domain.TimerState
import app.mentalmetal.wharfwod.wear.emom
import app.mentalmetal.wharfwod.wear.forTime
import app.mentalmetal.wharfwod.wear.tabata
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.random.Random

class TimerViewModelTest {
    private class Rig {
        val haptics = SpyHaptics()
        val audio = SpyAudio()
        val tracker = SpyTracker()
        val ticker = SpyTicker()
        val store = MemoryStore()
        var clock = 0L
        val vm = TimerViewModel(haptics, audio, tracker, store, ticker, Random(1), now = { clock })

        /** Drives the real tick path in 100ms steps. */
        fun tick(fromSec: Double, toSec: Double) {
            var step = Math.round(fromSec * 10)
            val last = Math.round(toSec * 10)
            while (step < last) {
                step += 1
                vm.onTick(step * 100)
            }
        }
    }

    @Test fun `START opens the session, the count-in taps, GO is a double knock and starts the workout`() {
        val r = Rig()
        r.vm.start(amrap(prep = 5))
        assertEquals(listOf("begin:amrap"), r.tracker.calls)
        assertEquals(listOf("start"), r.ticker.calls)
        assertEquals(emptyList<String>(), r.audio.log)
        r.tick(0.0, 0.1)
        assertEquals("the line lands on the first tick, as on the watch", listOf("voice:get_ready"), r.audio.log)
        r.tick(0.1, 4.5)
        assertEquals(listOf("COUNT_IN", "COUNT_IN", "COUNT_IN"), r.haptics.log)
        assertEquals(listOf("voice:get_ready", "beep:low_3", "beep:low_2", "beep:low_1"), r.audio.log)
        r.tick(4.5, 5.1)
        assertEquals(TimerState.RUNNING, r.vm.phase)
        assertEquals(listOf("begin:amrap", "go"), r.tracker.calls)
        assertEquals("GO", r.haptics.log.last())
        assertEquals(listOf("beep:high", "voice:go"), r.audio.log.takeLast(2))
        r.vm.reset()
        assertEquals("end:discard", r.tracker.calls.last())
        assertEquals("stop", r.ticker.calls.last())
    }

    @Test fun `EMOM rounds reach the wrist, the last round is its own cue, the end celebrates`() {
        val r = Rig()
        r.vm.start(emom(interval = 5, rounds = 3))
        assertEquals(listOf("begin:emom", "go"), r.tracker.calls)
        assertEquals(listOf("GO"), r.haptics.log)
        r.tick(0.0, 4.9)
        assertEquals(listOf("COUNT_IN", "COUNT_IN", "COUNT_IN"), r.haptics.log.takeLast(3))
        r.tick(4.9, 5.0)
        assertEquals(2, r.vm.session?.currentRound)
        assertEquals("ROUND_CHANGE", r.haptics.log.last())
        assertEquals(listOf("beep:high", "voice:next_round"), r.audio.log.takeLast(2))
        r.tick(5.0, 10.0)
        assertEquals(3, r.vm.session?.currentRound)
        assertEquals("LAST_ROUND", r.haptics.log.last())
        assertEquals("voice:last_round", r.audio.log.last())
        r.tick(10.0, 15.0)
        assertEquals(TimerState.COMPLETED, r.vm.phase)
        assertEquals("end:keep", r.tracker.calls.last())
        assertEquals("COMPLETE", r.haptics.log.last())
        assertEquals(listOf("beep:high", "voice:good_job"), r.audio.log.takeLast(2))
    }

    @Test fun `a Tabata round start is one wrist cue, rest a falling one`() {
        val r = Rig()
        r.vm.start(tabata(work = 4, rest = 3, rounds = 2))
        r.tick(0.0, 4.0)
        assertEquals(TimerState.RESTING, r.vm.phase)
        assertEquals("WORK_TO_REST", r.haptics.log.last())
        assertEquals("voice:rest", r.audio.log.last())
        r.tick(4.0, 6.9)
        assertEquals(listOf("COUNT_IN", "COUNT_IN"), r.haptics.log.takeLast(2))
        val before = r.haptics.log.size
        r.tick(6.9, 7.0)
        assertEquals(TimerState.RUNNING, r.vm.phase)
        assertEquals(2, r.vm.session?.currentRound)
        assertEquals(listOf("LAST_ROUND"), r.haptics.log.drop(before))
    }

    @Test fun `pause, resume, stop and finish reach the engine, the session and the wrist`() {
        val r = Rig()
        r.vm.start(forTime())
        r.vm.pause()
        assertEquals("pause", r.tracker.calls.last())
        assertEquals("pause", r.ticker.calls.last())
        assertEquals("PAUSE", r.haptics.log.last())
        r.vm.resume()
        assertEquals("resume", r.tracker.calls.last())
        assertEquals("RESUME", r.haptics.log.last())
        r.tick(0.0, 20.0)
        r.vm.stop()
        assertEquals("end:discard", r.tracker.calls.last())
        assertTrue(r.vm.endedEarly)

        val long = Rig()
        long.vm.start(forTime())
        long.tick(0.0, 90.0)
        long.vm.stop()
        assertEquals("end:keep", long.tracker.calls.last())

        val done = Rig()
        done.vm.start(forTime())
        done.tick(0.0, 30.0)
        done.vm.finish()
        assertEquals("end:keep", done.tracker.calls.last())
        assertEquals("COMPLETE", done.haptics.log.last())
        assertFalse(done.vm.endedEarly)
        assertFalse(done.vm.endedAtTimeCap)

        val prep = Rig()
        prep.vm.start(amrap(prep = 10))
        prep.vm.cancelPrep()
        assertEquals(listOf("begin:amrap", "end:discard"), prep.tracker.calls)
        assertEquals(TimerState.READY, prep.vm.phase)
    }

    @Test fun `get ready cannot be paused, a tap skips it, and reaching the cap is a time cap`() {
        val r = Rig()
        r.vm.start(amrap(prep = 10))
        r.vm.pause()
        assertEquals(TimerState.PREPARING, r.vm.phase)
        r.vm.skipPrep()
        assertEquals(TimerState.RUNNING, r.vm.phase)
        assertEquals("GO", r.haptics.log.last())
        assertEquals(listOf("begin:amrap", "go"), r.tracker.calls)

        val cap = Rig()
        cap.vm.start(forTime(cap = 60))
        cap.tick(0.0, 60.0)
        assertEquals(TimerState.COMPLETED, cap.vm.phase)
        assertTrue(cap.vm.endedAtTimeCap)
        assertEquals("voice:complete", cap.audio.log.last())
    }

    @Test fun `a double tap counts one round and the hint is remembered`() {
        val r = Rig()
        r.vm.start(amrap())
        r.vm.countRound()
        assertEquals(0, r.vm.session?.countedRounds)
        r.clock = 800
        r.vm.countRound()
        r.vm.countRound()
        assertEquals(1, r.vm.session?.countedRounds)
        assertTrue(r.vm.hasCountedRound)
        assertTrue(r.store.getBoolean(TimerViewModel.HINT_KEY, false))
        assertEquals("TAP", r.haptics.log.last())
    }

    @Test fun `the clock keeps whole milliseconds across ticks`() {
        val r = Rig()
        r.vm.start(amrap(seconds = 1200))
        for (i in 1..6000) r.vm.onTick(Math.round(i * 100.7))
        assertEquals(604, r.vm.session?.elapsed?.seconds)
    }

    @Test fun `the optional lines wait for a clear moment and the ten-second call fires once`() {
        val r = Rig()
        // 120s: 33% at 40s, halfway at 60s, 85% at 102s, ten seconds at 110s.
        // (In a 60s AMRAP the ten-second call at 50s silences "almost there" at 51s.)
        r.vm.start(amrap(seconds = 120))
        r.tick(0.0, 120.0)
        val voices = r.audio.log.filter { it.startsWith("voice:") }
        assertEquals(listOf("voice:go", "voice:keep_going", "voice:halfway", "voice:almost_there", "voice:ten_seconds", "voice:good_job"), voices)
        assertEquals(1, r.haptics.log.count { it == "HALFWAY" })
    }
}
