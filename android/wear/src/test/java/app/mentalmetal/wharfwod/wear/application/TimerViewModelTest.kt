package app.mentalmetal.wharfwod.wear.application

import app.mentalmetal.wharfwod.wear.SpyAudio
import app.mentalmetal.wharfwod.wear.SpyHaptics
import app.mentalmetal.wharfwod.wear.SpyTicker
import app.mentalmetal.wharfwod.wear.SpyTracker
import app.mentalmetal.wharfwod.wear.amrap
import app.mentalmetal.wharfwod.wear.domain.TimerState
import app.mentalmetal.wharfwod.wear.domain.Workout
import app.mentalmetal.wharfwod.wear.emom
import app.mentalmetal.wharfwod.wear.forTime
import app.mentalmetal.wharfwod.wear.services.VoiceSettings
import app.mentalmetal.wharfwod.wear.tabata
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class TimerViewModelTest {
    private class Rig(settings: VoiceSettings? = null) {
        val haptics = SpyHaptics()
        val audio = SpyAudio(settings)
        val tracker = SpyTracker()
        val ticker = SpyTicker()
        val store = MemoryStore()
        var clock = 0L
        val vm = TimerViewModel(haptics, audio, tracker, store, ticker, now = { clock })

        /** Drives the real tick path in 100ms steps. */
        fun tick(fromSec: Double, toSec: Double) {
            var step = Math.round(fromSec * 10)
            val last = Math.round(toSec * 10)
            while (step < last) {
                step += 1
                vm.onTick(step * 100)
            }
        }

        fun pips() = audio.log.count { it == "beep:mid" }

        fun halfwayTaps() = haptics.log.count { it == "HALFWAY" }

        /** Ticks in 100ms steps and notes each mid-round pip as "STATE:round:secondsLeft". */
        fun pipMoments(fromSec: Double, toSec: Double): List<String> {
            val moments = mutableListOf<String>()
            var step = Math.round(fromSec * 10)
            val last = Math.round(toSec * 10)
            while (step < last) {
                step += 1
                val before = pips()
                vm.onTick(step * 100)
                val s = vm.session
                if (pips() > before && s != null) moments.add("${s.state}:${s.currentRound}:${s.timeRemaining.seconds}")
            }
            return moments
        }
    }

    /** Starts [workout] and runs it to its end, returning the pips. */
    private fun pipsThrough(workout: Workout): List<String> {
        val r = Rig()
        r.vm.start(workout)
        val moments = r.pipMoments(0.0, (workout.prepCountdown.seconds + workout.timerType.estimatedDuration.seconds).toDouble())
        assertEquals(TimerState.COMPLETED, r.vm.phase)
        return moments
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

    @Test fun `GO, halfway, ten seconds and Good job are the only spoken lines, each once`() {
        val r = Rig()
        // 120s: halfway at 60s, ten seconds at 110s. No encouragement lines and
        // no coin flips since 8 Nov 2026: GO is "Go", the end is "Good job".
        r.vm.start(amrap(seconds = 120))
        r.tick(0.0, 120.0)
        val voices = r.audio.log.filter { it.startsWith("voice:") }
        assertEquals(listOf("voice:go", "voice:halfway", "voice:ten_seconds", "voice:good_job"), voices)
        assertEquals(1, r.haptics.log.count { it == "HALFWAY" })
    }

    @Test fun `halfway sits out when it would land on the count-in`() {
        val r = Rig()
        // Halfway of 6s is 3s, on the low 3 beep.
        r.vm.start(amrap(seconds = 6))
        r.tick(0.0, 6.0)
        assertEquals(listOf("voice:go", "voice:good_job"), r.audio.log.filter { it.startsWith("voice:") })
    }

    // 2.5.0: the mid-round pips. Two quick pips halfway through every EMOM
    // interval, Tabata work block and AMRAP / For Time clock of 10s or more,
    // with no setting: Beeps only keeps them, only Silent stops them. The same
    // cases as the watch's MidRoundPipTests.

    @Test fun `an EMOM pips once a round at half the minute and never in get ready`() {
        val r = Rig()
        // A 20s get ready is long enough to pip, and must not.
        r.vm.start(emom(interval = 60, rounds = 3, prep = 20))
        assertEquals("no pips in the get-ready countdown", emptyList<String>(), r.pipMoments(0.0, 20.0))
        assertEquals(listOf("RUNNING:1:30", "RUNNING:2:30", "RUNNING:3:30"), r.pipMoments(20.0, 200.0))
        assertEquals(TimerState.COMPLETED, r.vm.phase)
        assertEquals("round 2's pips are also the workout's halfway: one tap, not two", 3, r.halfwayTaps())
        assertTrue("the spoken Halfway still plays", "voice:halfway" in r.audio.log)
    }

    @Test fun `a 15s interval pips at 7 left`() {
        assertEquals(listOf("RUNNING:1:7", "RUNNING:2:7"), pipsThrough(emom(interval = 15, rounds = 2)))
    }

    @Test fun `a Tabata pips once a work block and never in a rest`() {
        assertEquals(
            listOf("RUNNING:1:10", "RUNNING:2:10", "RUNNING:3:10"),
            pipsThrough(tabata(work = 20, rest = 10, rounds = 3)),
        )
    }

    @Test fun `a phase under 10s never pips`() {
        assertEquals("a 5s work block is too short; a 10s rest is a rest",
            emptyList<String>(), pipsThrough(tabata(work = 5, rest = 10, rounds = 2)))
        assertEquals(emptyList<String>(), pipsThrough(emom(interval = 9, rounds = 2)))
        assertEquals(emptyList<String>(), pipsThrough(amrap(seconds = 9)))
        assertEquals("10s is the shortest phase that pips", listOf("RUNNING:1:5"), pipsThrough(emom(interval = 10, rounds = 1)))
    }

    @Test fun `an AMRAP or For Time pips once at half time with one halfway tap`() {
        for (workout in listOf(amrap(seconds = 600), forTime(cap = 600))) {
            val name = workout.timerType.typeCode
            val r = Rig()
            r.vm.start(workout)
            assertEquals(name, emptyList<String>(), r.pipMoments(0.0, 299.9))
            val heard = r.audio.log.size
            val felt = r.haptics.log.size
            assertEquals(name, listOf("RUNNING:1:300"), r.pipMoments(299.9, 300.0))
            assertEquals("$name: the pips, with the optional line on them",
                listOf("beep:mid", "voice:halfway"), r.audio.log.drop(heard))
            assertEquals("$name: one halfway tap on the tick", listOf("HALFWAY"), r.haptics.log.drop(felt))
            assertEquals(name, emptyList<String>(), r.pipMoments(300.0, 600.0))
            assertEquals(TimerState.COMPLETED, r.vm.phase)
            assertEquals(name, 1, r.halfwayTaps())
        }
    }

    @Test fun `an AMRAP tally never re-arms the pips`() {
        val r = Rig()
        r.vm.start(amrap(seconds = 60))
        assertEquals(listOf("RUNNING:1:30"), r.pipMoments(0.0, 30.0))
        // A round counted on the midpoint: the tally is the athlete's, not a phase.
        r.clock = 30_000
        r.vm.countRound()
        assertEquals(1, r.vm.session?.countedRounds)
        assertEquals(emptyList<String>(), r.pipMoments(30.0, 60.0))
    }

    @Test fun `Beeps only still pips and Silent pips nothing`() {
        val beepsOnly = VoiceSettings(MemoryStore()).apply { setBeepsOnly(true) }
        val beeps = Rig(beepsOnly)
        beeps.vm.start(emom(interval = 60, rounds = 2))
        assertEquals(listOf("RUNNING:1:30", "RUNNING:2:30"), beeps.pipMoments(0.0, 120.0))
        assertFalse(beeps.audio.log.any { it.startsWith("voice:") })

        val silent = Rig(VoiceSettings(MemoryStore()).apply { setMuted(true) })
        silent.vm.start(emom(interval = 60, rounds = 2))
        silent.tick(0.0, 120.0)
        assertEquals(TimerState.COMPLETED, silent.vm.phase)
        assertEquals("Silent plays nothing, pips included", emptyList<String>(), silent.audio.log)
        assertEquals("the wrist still feels the moment, as it does the 3, 2, 1", 2, silent.halfwayTaps())
    }

    @Test fun `a tick far past the midpoint stays quiet but a skipped tick still pips`() {
        // The watch slept from 28s to 32s: the next tick reads 28 left, past 30 and 29.
        val r = Rig()
        r.vm.start(emom(interval = 60, rounds = 2))
        r.tick(0.0, 28.0)
        r.vm.onTick(32_000)
        assertEquals("never late", 0, r.pips())
        assertEquals("the next round still pips", listOf("RUNNING:2:30"), r.pipMoments(32.0, 120.0))

        // One skipped tick (31 left, then 29): the pips land a second late.
        val skip = Rig()
        skip.vm.start(emom(interval = 60, rounds = 1))
        skip.tick(0.0, 29.0)
        assertEquals(0, skip.pips())
        skip.vm.onTick(31_000)
        assertEquals(1, skip.pips())

        // A long suspension across rounds lands in round 3 with 25 left.
        val asleep = Rig()
        asleep.vm.start(emom(interval = 60, rounds = 3))
        asleep.tick(0.0, 10.0)
        asleep.vm.onTick(155_000)
        assertEquals(3, asleep.vm.session?.currentRound)
        assertEquals(emptyList<String>(), asleep.pipMoments(155.0, 180.0))
        assertEquals(0, asleep.pips())

        // An AMRAP woken past its halfway never pips.
        val woken = Rig()
        woken.vm.start(amrap(seconds = 600))
        woken.tick(0.0, 290.0)
        woken.vm.onTick(302_000)
        assertEquals(emptyList<String>(), woken.pipMoments(302.0, 600.0))
        assertEquals(0, woken.pips())
    }

    @Test fun `paused at the midpoint never pips and resuming past it never pips late`() {
        val r = Rig()
        r.vm.start(amrap(seconds = 60))
        r.tick(0.0, 29.0)
        r.vm.pause()
        // Paused, the clock stands at 31 left while the minutes go by.
        r.tick(29.0, 40.0)
        assertEquals(31, r.vm.session?.timeRemaining?.seconds)
        assertEquals(0, r.pips())
        r.vm.resume()
        // The first tick after the resume lands at 27 left.
        r.vm.onTick(44_000)
        assertEquals(27, r.vm.session?.timeRemaining?.seconds)
        assertEquals(emptyList<String>(), r.pipMoments(44.0, 80.0))
        assertEquals(TimerState.COMPLETED, r.vm.phase)
        assertEquals(0, r.pips())

        // A pause before the midpoint moves it with the clock: on time, not late.
        val paused = Rig()
        paused.vm.start(amrap(seconds = 60))
        paused.tick(0.0, 29.0)
        paused.vm.pause()
        paused.vm.resume()
        assertEquals(listOf("RUNNING:1:30"), paused.pipMoments(29.0, 31.0))
    }

    @Test fun `a new workout pips again`() {
        val r = Rig()
        r.vm.start(emom(interval = 20, rounds = 1))
        assertEquals(listOf("RUNNING:1:10"), r.pipMoments(0.0, 20.0))
        r.vm.restart()
        assertEquals("a restart re-arms the pips", listOf("RUNNING:1:10"), r.pipMoments(0.0, 12.0))
        r.vm.reset()
        r.vm.start(emom(interval = 20, rounds = 1))
        assertEquals("and so does a new workout", listOf("RUNNING:1:10"), r.pipMoments(0.0, 12.0))
    }
}
