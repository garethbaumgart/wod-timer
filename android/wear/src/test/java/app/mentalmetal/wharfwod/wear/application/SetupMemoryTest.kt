package app.mentalmetal.wharfwod.wear.application

import app.mentalmetal.wharfwod.wear.domain.RoundCount
import app.mentalmetal.wharfwod.wear.domain.TimerDuration
import app.mentalmetal.wharfwod.wear.domain.TimerType
import org.junit.Assert.assertEquals
import org.junit.Test

class SetupMemoryTest {
    @Test fun `each mode round-trips its last setup and the latest change wins`() {
        val m = SetupMemory(MemoryStore())
        val emom = TimerType.Emom(TimerDuration.of(90), RoundCount.of(12))
        m.save(emom)
        assertEquals(emom, m.last("emom"))
        m.save(TimerType.Emom(TimerDuration.of(45), RoundCount.of(20)))
        assertEquals("20 × 0:45", m.summary("emom"))
        assertEquals(20, m.shape("emom").size)
    }

    @Test fun `one mode never overwrites another, and a missing or corrupt value reads as the default`() {
        val store = MemoryStore()
        val m = SetupMemory(store)
        m.save(TimerType.Amrap(TimerDuration.of(900)))
        assertEquals("CAP 20:00 · UP", m.summary("fortime"))
        assertEquals("8 × 20s / 10s", m.summary("tabata"))
        store.putString(SetupMemory.key("amrap"), "garbage")
        assertEquals("10:00", m.summary("amrap"))
        store.putString(SetupMemory.key("amrap"), SetupMemory.encode(TimerType.Emom(TimerDuration.of(60), RoundCount.of(5))))
        assertEquals("10:00", m.summary("amrap"))
    }

    @Test fun `summaries read as the watch shows them`() {
        assertEquals("15:00", SetupMemory.summary(TimerType.Amrap(TimerDuration.of(900))))
        assertEquals("CAP 12:00 · UP", SetupMemory.summary(TimerType.ForTime(TimerDuration.of(720))))
        assertEquals("8 × 20s / 10s", SetupMemory.summary(TimerType.standardTabata))
        assertEquals(listOf("fortime", "emom", "amrap", "tabata"), SetupMemory.modeOrder)
    }
}
