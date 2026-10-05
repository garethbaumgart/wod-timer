package app.mentalmetal.wharfwod.wear.domain

import app.mentalmetal.wharfwod.wear.amrap
import app.mentalmetal.wharfwod.wear.emom
import app.mentalmetal.wharfwod.wear.forTime
import app.mentalmetal.wharfwod.wear.tabata
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class TimerSessionTest {
    private fun TimerSession.ok(): TimerSession = (this as TimerSession.Result.Ok).session
    private fun TimerSession.Result.ok(): TimerSession = (this as TimerSession.Result.Ok).session
    private fun TimerSession.ticked(ms: Int) = tick(ms).ok()
    private fun started(w: Workout) = TimerSession.fromWorkout(w).start().ok()

    @Test fun `start goes to get ready with a prep, straight to work without`() {
        assertEquals(TimerState.PREPARING, started(amrap(prep = 10)).state)
        assertEquals(TimerState.RUNNING, started(amrap(prep = 0)).state)
    }

    @Test fun `cannot start twice, pause only while active, resume only when paused`() {
        val s = started(amrap())
        assertTrue(s.start() is TimerSession.Result.Err)
        assertTrue(s.resume() is TimerSession.Result.Err)
        val paused = s.pause().ok()
        assertEquals(TimerState.PAUSED, paused.state)
        assertEquals(TimerState.RUNNING, paused.resume().ok().state)
    }

    @Test fun `resume restores the rest phase it paused in`() {
        val s = started(tabata(work = 4, rest = 3, rounds = 2)).ticked(4000)
        assertEquals(TimerState.RESTING, s.state)
        assertEquals(TimerState.RESTING, s.pause().ok().resume().ok().state)
    }

    @Test fun `milliseconds accumulate into whole seconds`() {
        var s = started(amrap())
        repeat(15) { s = s.ticked(100) }
        assertEquals(1, s.elapsed.seconds)
        assertEquals(500, s.elapsedMillis)
    }

    @Test fun `AMRAP and For Time complete at the exact boundary`() {
        val a = started(amrap(seconds = 60)).ticked(59_900).ticked(100)
        assertEquals(TimerState.COMPLETED, a.state)
        assertEquals(60, a.elapsed.seconds)
        val f = started(forTime(cap = 30)).ticked(30_000)
        assertEquals(TimerState.COMPLETED, f.state)
        assertEquals(30, f.elapsed.seconds)
    }

    @Test fun `EMOM advances rounds and completes after the last`() {
        var s = started(emom(interval = 5, rounds = 3))
        s = s.ticked(5000)
        assertEquals(2, s.currentRound)
        assertEquals(5, s.timeRemaining.seconds)
        s = s.ticked(5000)
        assertEquals(3, s.currentRound)
        s = s.ticked(5000)
        assertEquals(TimerState.COMPLETED, s.state)
        assertEquals(15, s.elapsed.seconds)
    }

    @Test fun `a large EMOM delta consumes every interval it covers`() {
        val s = started(emom(interval = 60, rounds = 10)).ticked(1000).ticked(180_000)
        assertEquals(4, s.currentRound)
        assertEquals(59, s.timeRemaining.seconds)
    }

    @Test fun `Tabata walks work and rest, and a large delta consumes every phase`() {
        var s = started(tabata(work = 20, rest = 10, rounds = 8))
        s = s.ticked(20_000)
        assertEquals(TimerState.RESTING, s.state)
        s = s.ticked(10_000)
        assertEquals(TimerState.RUNNING, s.state)
        assertEquals(2, s.currentRound)
        val jumped = started(tabata(work = 20, rest = 10, rounds = 8)).ticked(75_000)
        assertEquals(3, jumped.currentRound)
        assertEquals(TimerState.RUNNING, jumped.state)
        assertEquals(5, jumped.timeRemaining.seconds)
    }

    @Test fun `Tabata completes at the exact total`() {
        val s = started(tabata(work = 20, rest = 10, rounds = 8)).ticked(300_000)
        assertEquals(TimerState.COMPLETED, s.state)
        assertEquals(240, s.elapsed.seconds)
    }

    @Test fun `prep overshoot carries into the workout`() {
        val s = started(amrap(prep = 10)).ticked(12_000)
        assertEquals(TimerState.RUNNING, s.state)
        assertEquals(2, s.elapsed.seconds)
    }

    @Test fun `a paused Tabata keeps the countdown of the phase it paused in`() {
        val mid = started(tabata(work = 20, rest = 10, rounds = 8)).ticked(5000).pause().ok()
        assertEquals(15, mid.timeRemaining.seconds)
        val rest = started(tabata(work = 20, rest = 10, rounds = 8)).ticked(23_000).pause().ok()
        assertEquals(7, rest.timeRemaining.seconds)
    }

    @Test fun `AMRAP rounds are counted while running and corrected on the end screen, never below zero`() {
        var s = started(amrap(seconds = 60)).countRound().countRound()
        assertEquals(2, s.countedRounds)
        s = s.ticked(60_000)
        assertEquals(TimerState.COMPLETED, s.state)
        s = s.adjustRounds(-5)
        assertEquals(0, s.countedRounds)
        assertEquals(1, s.adjustRounds(1).countedRounds)
        assertEquals(0, started(emom()).countRound().countedRounds)
    }

    @Test fun `complete is refused twice and from ready`() {
        assertTrue(TimerSession.fromWorkout(amrap()).complete() is TimerSession.Result.Err)
        val done = started(amrap()).complete().ok()
        assertTrue(done.complete() is TimerSession.Result.Err)
        assertTrue(done.tick(100) is TimerSession.Result.Err)
    }

    @Test fun `progress and clock format`() {
        val s = started(amrap(seconds = 100)).ticked(25_000)
        assertEquals(0.25, s.progress, 0.0001)
        assertEquals("1:15", s.timeRemaining.clock)
        assertEquals("0:05", TimerDuration.of(5).clock)
        assertEquals("20s", TimerDuration.of(20).phase)
        assertEquals("2:00", TimerDuration.of(120).phase)
        assertEquals(7200, TimerDuration.of(99_999).seconds)
    }
}
