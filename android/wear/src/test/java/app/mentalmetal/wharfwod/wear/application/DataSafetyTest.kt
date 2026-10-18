package app.mentalmetal.wharfwod.wear.application

import app.mentalmetal.wharfwod.wear.SpyAudio
import app.mentalmetal.wharfwod.wear.SpyHaptics
import app.mentalmetal.wharfwod.wear.SpyTracker
import app.mentalmetal.wharfwod.wear.domain.TimerType
import app.mentalmetal.wharfwod.wear.services.ExerciseTracker
import app.mentalmetal.wharfwod.wear.services.VoicePack
import app.mentalmetal.wharfwod.wear.services.VoiceSettings
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class DataSafetyTest {
    @Test fun `2_2_0-wear fixture loads through SetupMemory VoiceSettings and TimerViewModel`() {
        assertFixture("2.2.0-wear")
    }

    @Test fun `2_2_1 fixture loads through SetupMemory VoiceSettings and TimerViewModel`() {
        assertFixture("2.2.1")
    }

    private fun assertFixture(version: String) {
        val json = JSONObject(fixtureFile(version).readText(Charsets.UTF_8))
        val keys = json.getJSONObject("keys")
        val expect = json.getJSONObject("expect")
        val store = MemoryStore()
        val keyIter = keys.keys()
        while (keyIter.hasNext()) {
            val key = keyIter.next()
            val spec = keys.getJSONObject(key)
            when {
                spec.has("string") -> store.putString(key, spec.getString("string"))
                spec.has("bool") -> store.putBoolean(key, spec.getBoolean("bool"))
            }
        }

        val memory = SetupMemory(store)
        val amrap = memory.last("amrap") as TimerType.Amrap
        assertEquals(expect.getInt("amrapSeconds"), amrap.duration.seconds)
        val forTime = memory.last("fortime") as TimerType.ForTime
        assertEquals(expect.getInt("forTimeCap"), forTime.timeCap.seconds)
        assertEquals(expect.getBoolean("forTimeCountUp"), forTime.countUp)
        val emom = memory.last("emom") as TimerType.Emom
        assertEquals(expect.getInt("emomInterval"), emom.intervalDuration.seconds)
        assertEquals(expect.getInt("emomRounds"), emom.rounds.value)
        val tabata = memory.last("tabata") as TimerType.Tabata
        assertEquals(expect.getInt("tabataWork"), tabata.workDuration.seconds)
        assertEquals(expect.getInt("tabataRest"), tabata.restDuration.seconds)
        assertEquals(expect.getInt("tabataRounds"), tabata.rounds.value)

        val voice = VoiceSettings(store)
        assertEquals(VoicePack.from(expect.getString("voicePack")), voice.voicePack)
        assertEquals(expect.getBoolean("random"), voice.randomizePerCue)
        assertEquals(expect.getBoolean("muted"), voice.muted)
        assertEquals(expect.getBoolean("beeps"), voice.beepsOnly)

        val vm = TimerViewModel(SpyHaptics(), SpyAudio(), SpyTracker(), store)
        assertEquals(expect.getBoolean("hintCounted"), vm.hasCountedRound)

        assertEquals(
            expect.getBoolean("healthTrack"),
            store.getBoolean(ExerciseTracker.ENABLED_KEY, true),
        )
        assertTrue(store.contains(ExerciseTracker.ENABLED_KEY))
        assertEquals(expect.getBoolean("permAsked"), store.getBoolean("wear_perm_asked", false))
        assertTrue(store.getString("some_plugin_key")!!.contains("💪"))

        memory.save(amrap)
        assertEquals(store.getString("some_plugin_key"), keys.getJSONObject("some_plugin_key").getString("string"))
    }

    private fun fixtureFile(version: String): File {
        return File(repoRoot(), "test/fixtures/data_safety/wear/$version/prefs.json")
    }

    private fun repoRoot(): File {
        var dir = File(System.getProperty("user.dir")).canonicalFile
        repeat(12) {
            if (File(dir, "pubspec.yaml").isFile) return dir
            dir = dir.parentFile ?: error("pubspec.yaml not found from ${System.getProperty("user.dir")}")
        }
        error("pubspec.yaml not found from ${System.getProperty("user.dir")}")
    }
}
