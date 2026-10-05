package app.mentalmetal.wharfwod.wear.services

import app.mentalmetal.wharfwod.wear.application.MemoryStore
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.random.Random

class HapticPatternsTest {
    private fun knocks(cue: HapticCue): Int {
        val w = HapticPatterns.waveform(cue)
        return w.timings.indices.count { w.amplitudes[it] == 255 && w.timings[it] >= 150 }
    }

    @Test fun `every pattern starts with no delay and alternates off and on`() {
        for (cue in HapticCue.entries) {
            val w = HapticPatterns.waveform(cue)
            assertEquals(cue.name, 0L, w.timings[0])
            assertEquals(cue.name, 0, w.amplitudes[0])
            assertEquals(cue.name, w.timings.size, w.amplitudes.size)
            assertTrue(cue.name, w.amplitudes[1] > 0)
        }
    }

    @Test fun `GO knocks twice, the last round three times, a round and rest once with a direction`() {
        assertEquals(2, knocks(HapticCue.GO))
        assertEquals(3, knocks(HapticCue.LAST_ROUND))
        assertEquals(1, knocks(HapticCue.ROUND_CHANGE))
        assertEquals(1, knocks(HapticCue.WORK_TO_REST))
        val up = HapticPatterns.waveform(HapticCue.ROUND_CHANGE).amplitudes
        val down = HapticPatterns.waveform(HapticCue.WORK_TO_REST).amplitudes
        assertTrue(up[3] < up[5])
        assertTrue(down[3] > down[5])
    }

    @Test fun `knocks sit at least 350ms apart and the count-in is one firm tap`() {
        val go = HapticPatterns.waveform(HapticCue.GO)
        assertTrue(go.timings[2] >= 350)
        val tap = HapticPatterns.waveform(HapticCue.COUNT_IN)
        assertEquals(2, tap.timings.size)
        assertTrue(tap.amplitudes[1] >= 200)
    }
}

class FocusLeaseTest {
    private class Timers {
        val pending = mutableListOf<Pair<Long, () -> Unit>>()
        val schedule: (Long, () -> Unit) -> () -> Unit = { delay, work ->
            val entry = delay to work
            pending.add(entry)
            ({ pending.remove(entry); Unit })
        }
        fun fireAll() { pending.toList().forEach { pending.remove(it); it.second() } }
    }

    private fun lease(t: Timers, log: MutableList<String>, activate: () -> Unit = { log.add("on") }) =
        FocusLease(activate, { log.add("off") }, 2200, t.schedule)

    @Test fun `overlapping cues share one activation and release after the last`() {
        val t = Timers(); val log = mutableListOf<String>(); val l = lease(t, log)
        l.acquire("p0"); l.acquire("p1")
        assertEquals(listOf("on"), log)
        l.complete("p0")
        assertEquals(listOf("on"), log)
        l.complete("p1")
        assertEquals(listOf("on", "off"), log)
    }

    @Test fun `a player that never reports completion is released by the timeout, once`() {
        val t = Timers(); val log = mutableListOf<String>(); val l = lease(t, log)
        l.acquire("p0")
        assertEquals(2200L, t.pending.single().first)
        t.fireAll()
        assertEquals(listOf("on", "off"), log)
        l.complete("p0")
        assertEquals(listOf("on", "off"), log)
    }

    @Test fun `a new clip on the same player takes over without a flap`() {
        val t = Timers(); val log = mutableListOf<String>(); val l = lease(t, log)
        l.acquire("p0"); l.acquire("p0")
        assertEquals(listOf("on"), log)
        assertEquals(1, l.active)
        t.fireAll()
        assertEquals(listOf("on", "off"), log)
    }

    @Test fun `a failed activation leaves nothing held`() {
        val t = Timers(); val log = mutableListOf<String>()
        val l = lease(t, log) { throw IllegalStateException("no focus") }
        try { l.acquire("p0") } catch (e: IllegalStateException) {}
        assertEquals(0, l.active)
        assertTrue(t.pending.isEmpty())
    }
}

class VoiceSettingsTest {
    @Test fun `a fresh install is Major with the voice on, and every choice persists`() {
        val store = MemoryStore()
        val v = VoiceSettings(store)
        assertEquals(VoicePack.MAJOR, v.voicePack)
        assertEquals("audio/major/countdown_go.mp3", v.voiceFile("countdown_go"))
        assertEquals("audio/beeps/high.wav", v.beepFile("high"))
        v.setVoicePack(VoicePack.HOLLY); v.setBeepsOnly(true)
        val again = VoiceSettings(store)
        assertEquals(VoicePack.HOLLY, again.voicePack)
        assertTrue(again.beepsOnly)
        assertEquals("Beeps", again.label)
    }

    @Test fun `Beeps only drops the voice and keeps the beeps, Silent drops both`() {
        val v = VoiceSettings(MemoryStore())
        v.setBeepsOnly(true)
        assertNull(v.voiceFile("rest"))
        assertEquals("audio/beeps/low_3.wav", v.beepFile("low_3"))
        v.setMuted(true)
        assertNull(v.beepFile("high"))
        assertEquals("Silent", v.label)
    }

    @Test fun `Random picks a pack per line and an unknown stored pack reads as Major`() {
        val store = MemoryStore()
        store.putString(VoiceSettings.PACK_KEY, "sergeant-x")
        val v = VoiceSettings(store, Random(7))
        assertEquals(VoicePack.MAJOR, v.voicePack)
        v.setRandomizePerCue(true)
        val packs = (1..30).map { v.voiceFile("rest")!!.split("/")[1] }.toSet()
        assertEquals(setOf("major", "liam", "holly"), packs)
        assertFalse(VoiceSettings(store).muted)
    }
}
