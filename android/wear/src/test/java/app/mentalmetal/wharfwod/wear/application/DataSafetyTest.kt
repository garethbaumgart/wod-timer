package app.mentalmetal.wharfwod.wear.application

import app.mentalmetal.wharfwod.wear.SpyAudio
import app.mentalmetal.wharfwod.wear.SpyHaptics
import app.mentalmetal.wharfwod.wear.SpyTracker
import app.mentalmetal.wharfwod.wear.domain.TimerType
import app.mentalmetal.wharfwod.wear.services.ExerciseTracker
import app.mentalmetal.wharfwod.wear.services.VoicePack
import app.mentalmetal.wharfwod.wear.services.VoiceSettings
import com.google.gson.JsonParser
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
        // Gson, not android.jar's org.json.JSONObject: JVM unit tests stub
        // JSONObject.getJSONObject to null when returnDefaultValues is on.
        val json = JsonParser.parseString(fixtureFile(version).readText(Charsets.UTF_8)).asJsonObject
        val keys = json.getAsJsonObject("keys")
        val expect = json.getAsJsonObject("expect")
        val store = MemoryStore()
        for (entry in keys.entrySet()) {
            val spec = entry.value.asJsonObject
            when {
                spec.has("string") -> store.putString(entry.key, spec.get("string").asString)
                spec.has("bool") -> store.putBoolean(entry.key, spec.get("bool").asBoolean)
            }
        }

        val memory = SetupMemory(store)
        val amrap = memory.last("amrap") as TimerType.Amrap
        assertEquals(expect.get("amrapSeconds").asInt, amrap.duration.seconds)
        val forTime = memory.last("fortime") as TimerType.ForTime
        assertEquals(expect.get("forTimeCap").asInt, forTime.timeCap.seconds)
        assertEquals(expect.get("forTimeCountUp").asBoolean, forTime.countUp)
        val emom = memory.last("emom") as TimerType.Emom
        assertEquals(expect.get("emomInterval").asInt, emom.intervalDuration.seconds)
        assertEquals(expect.get("emomRounds").asInt, emom.rounds.value)
        val tabata = memory.last("tabata") as TimerType.Tabata
        assertEquals(expect.get("tabataWork").asInt, tabata.workDuration.seconds)
        assertEquals(expect.get("tabataRest").asInt, tabata.restDuration.seconds)
        assertEquals(expect.get("tabataRounds").asInt, tabata.rounds.value)

        val voice = VoiceSettings(store)
        assertEquals(VoicePack.from(expect.get("voicePack").asString), voice.voicePack)
        assertEquals(expect.get("random").asBoolean, voice.randomizePerCue)
        assertEquals(expect.get("muted").asBoolean, voice.muted)
        assertEquals(expect.get("beeps").asBoolean, voice.beepsOnly)

        val vm = TimerViewModel(SpyHaptics(), SpyAudio(), SpyTracker(), store)
        assertEquals(expect.get("hintCounted").asBoolean, vm.hasCountedRound)

        assertEquals(
            expect.get("healthTrack").asBoolean,
            store.getBoolean(ExerciseTracker.ENABLED_KEY, true),
        )
        assertTrue(store.contains(ExerciseTracker.ENABLED_KEY))
        assertEquals(expect.get("permAsked").asBoolean, store.getBoolean("wear_perm_asked", false))
        assertTrue(store.getString("some_plugin_key")!!.contains("💪"))

        memory.save(amrap)
        assertEquals(
            store.getString("some_plugin_key"),
            keys.getAsJsonObject("some_plugin_key").get("string").asString,
        )
    }

    private fun fixtureFile(version: String): File {
        return File(repoRoot(), "test/fixtures/data_safety/wear/$version/prefs.json")
    }

    private fun repoRoot(): File {
        val cwd = System.getProperty("user.dir") ?: error("user.dir missing")
        var dir = File(cwd).canonicalFile
        repeat(12) {
            if (File(dir, "pubspec.yaml").isFile) return dir
            dir = dir.parentFile ?: error("pubspec.yaml not found from $cwd")
        }
        error("pubspec.yaml not found from $cwd")
    }
}
