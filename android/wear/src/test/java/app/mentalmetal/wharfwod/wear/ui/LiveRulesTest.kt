package app.mentalmetal.wharfwod.wear.ui

import app.mentalmetal.wharfwod.wear.amrap
import app.mentalmetal.wharfwod.wear.domain.TimerSession
import app.mentalmetal.wharfwod.wear.domain.TimerType
import app.mentalmetal.wharfwod.wear.emom
import app.mentalmetal.wharfwod.wear.forTime
import app.mentalmetal.wharfwod.wear.tabata
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class LiveRulesTest {
    private fun TimerSession.Result.ok() = (this as TimerSession.Result.Ok).session
    private fun session(w: app.mentalmetal.wharfwod.wear.domain.Workout, ms: Int = 0): TimerSession {
        val s = TimerSession.fromWorkout(w).start().ok()
        return if (ms > 0) s.tick(ms).ok() else s
    }

    @Test fun `clock text counts up on For Time, down otherwise, bare seconds in a minute phase`() {
        assertEquals("1:15", LiveRules.clockText(session(forTime(cap = 1200), 75_000)))
        assertEquals("8:45", LiveRules.clockText(session(amrap(600), 75_000)))
        assertEquals("55", LiveRules.clockText(session(amrap(600), 545_000)))
        assertEquals("60", LiveRules.clockText(session(emom(60, 10))))
        assertEquals("8", LiveRules.clockText(session(amrap(prep = 10), 2000)))
    }

    @Test fun `the phase word names only get ready, paused and Tabata phases`() {
        assertEquals("GET READY", LiveRules.phaseWord(session(amrap(prep = 10)))?.text)
        assertNull(LiveRules.phaseWord(session(amrap())))
        assertNull(LiveRules.phaseWord(session(emom())))
        val t = tabata(work = 20, rest = 10, rounds = 8)
        assertEquals("WORK", LiveRules.phaseWord(session(t, 5000))?.text)
        assertEquals("NEXT · REST", LiveRules.phaseWord(session(t, 16_000))?.text)
        assertEquals("REST", LiveRules.phaseWord(session(t, 21_000))?.text)
        assertEquals("NEXT · WORK", LiveRules.phaseWord(session(t, 26_000))?.text)
        assertEquals("LAST REST", LiveRules.phaseWord(session(t, 231_000))?.text)
        assertEquals("PAUSED · REST", LiveRules.phaseWord(session(t, 21_000).pause().ok())?.text)
        assertEquals("PAUSED", LiveRules.phaseWord(session(amrap()).pause().ok())?.text)
    }

    @Test fun `reference clock and config line per mode`() {
        assertEquals("10:00", LiveRules.referenceClock(amrap().timerType))
        assertEquals("60", LiveRules.referenceClock(emom().timerType))
        assertEquals("20", LiveRules.referenceClock(TimerType.standardTabata))
        assertEquals("EMOM · 10 × 1:00", LiveRules.configLine(emom().timerType))
        assertEquals("TABATA · 8 × 20s / 10s", LiveRules.configLine(TimerType.standardTabata))
        assertEquals("FOR TIME · CAP 20:00", LiveRules.configLine(forTime().timerType))
    }

    @Test fun `end summaries`() {
        val e = session(emom(60, 10), 125_000).complete().ok()
        assertEquals(LiveRules.EndSummary("Stopped", "3/10", "ROUNDS · 2:05"), LiveRules.endSummary(e, endedEarly = true, endedAtTimeCap = false))
        val f = session(forTime(), 754_000).complete().ok()
        assertEquals(LiveRules.EndSummary("Finished", "12:34", "TIME"), LiveRules.endSummary(f, false, false))
        assertEquals(LiveRules.EndSummary("Time cap", null, ""), LiveRules.endSummary(f, false, true))
        val a = session(amrap(600)).countRound().countRound().countRound().tick(600_000).ok()
        assertEquals(LiveRules.EndSummary("Finished", "3", "ROUNDS"), LiveRules.endSummary(a, false, false))
    }
}
