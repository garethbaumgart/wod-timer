package app.mentalmetal.wharfwod.wear.services

import app.mentalmetal.wharfwod.wear.application.KeyValueStore
import kotlin.random.Random

enum class VoicePack(val code: String, val title: String, val detail: String) {
    MAJOR("major", "Major", "Drill sergeant"),
    LIAM("liam", "Liam", "Male coach"),
    HOLLY("holly", "Holly", "Female coach");

    companion object {
        fun from(code: String?) = entries.firstOrNull { it.code == code } ?: MAJOR
    }
}

/**
 * The voice settings and the cue-to-file rules, shared by the real player
 * and the tests: which asset each cue plays for a pack, Random, Beeps only
 * (beeps without voice) and Silent (nothing, haptics only). Persisted
 * since the first version with additive keys.
 */
class VoiceSettings(private val store: KeyValueStore, private val random: Random = Random.Default) {
    companion object {
        const val PACK_KEY = "wear_voice_pack"
        const val RANDOM_KEY = "wear_voice_random"
        const val MUTED_KEY = "wear_voice_muted"
        const val BEEPS_KEY = "wear_voice_beeps"
    }

    var voicePack: VoicePack = VoicePack.from(store.getString(PACK_KEY))
        private set
    var randomizePerCue: Boolean = store.getBoolean(RANDOM_KEY, false)
        private set
    var muted: Boolean = store.getBoolean(MUTED_KEY, false)
        private set
    var beepsOnly: Boolean = store.getBoolean(BEEPS_KEY, false)
        private set

    fun setVoicePack(pack: VoicePack) { voicePack = pack; store.putString(PACK_KEY, pack.code) }
    fun setRandomizePerCue(on: Boolean) { randomizePerCue = on; store.putBoolean(RANDOM_KEY, on) }
    fun setMuted(on: Boolean) { muted = on; store.putBoolean(MUTED_KEY, on) }
    fun setBeepsOnly(on: Boolean) { beepsOnly = on; store.putBoolean(BEEPS_KEY, on) }

    /** "Major", "Random", "Beeps" or "Silent", for the Home row. */
    val label: String
        get() = when {
            muted -> "Silent"
            beepsOnly -> "Beeps"
            randomizePerCue -> "Random"
            else -> voicePack.title
        }

    /** The asset path of a voice line, or null when the voice is off. */
    fun voiceFile(name: String): String? {
        if (muted || beepsOnly) return null
        val pack = if (randomizePerCue) VoicePack.entries[random.nextInt(VoicePack.entries.size)] else voicePack
        return "audio/${pack.code}/$name.mp3"
    }

    /** The asset path of a beep, or null on Silent. */
    fun beepFile(name: String): String? = if (muted) null else "audio/beeps/$name.wav"
}
