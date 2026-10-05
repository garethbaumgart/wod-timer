package app.mentalmetal.wharfwod.wear.services

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.SoundPool
import android.os.Handler
import android.os.Looper
import app.mentalmetal.wharfwod.wear.application.KeyValueStore
import kotlin.random.Random

/**
 * Plays the cue clips (the phone's assets, 1 MB) through a SoundPool, with
 * the phone's ducking policy: transient-may-duck focus on the media stream,
 * held from the first beep to 2.2s after the last clip (SoundPool reports
 * no completion), then given back so the music returns.
 */
class WearAudioService(
    private val context: Context,
    store: KeyValueStore,
    random: Random = Random.Default,
    private val sink: ((String) -> Unit)? = null,
) : AudioCues {
    companion object {
        /** The longest clip is 1.7s ("complete"); the focus hold outlasts it. */
        const val RELEASE_AFTER_MS = 2200L
    }

    val settings = VoiceSettings(store, random)

    /** What was played, oldest first ("beep:high", "voice:lets_go"), for the sound check and tests. */
    val cueLog = mutableListOf<String>()

    private val handler = Handler(Looper.getMainLooper())
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
        .build()
    private val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
        .setAudioAttributes(attributes)
        .setWillPauseWhenDucked(false)
        .setOnAudioFocusChangeListener { }
        .build()
    private val lease = FocusLease(
        onActivate = { audioManager.requestAudioFocus(focusRequest) },
        onDeactivate = { audioManager.abandonAudioFocusRequest(focusRequest) },
        releaseAfterMs = RELEASE_AFTER_MS,
        schedule = { delayMs, work ->
            val runnable = Runnable { work() }
            handler.postDelayed(runnable, delayMs)
            ({ handler.removeCallbacks(runnable) })
        },
    )

    private val pool: SoundPool? = if (sink == null) {
        SoundPool.Builder().setMaxStreams(4).setAudioAttributes(attributes).build()
    } else null
    private val sounds = mutableMapOf<String, Int>()
    private var nextKey = 0

    /** Loads every clip once (about 1 MB); called at app start. */
    fun preload() {
        val pool = pool ?: return
        val assets = context.assets
        for (dir in listOf("audio/beeps") + VoicePack.entries.map { "audio/${it.code}" }) {
            for (file in assets.list(dir).orEmpty()) {
                val path = "$dir/$file"
                if (path !in sounds) {
                    assets.openFd(path).use { fd -> sounds[path] = pool.load(fd, 1) }
                }
            }
        }
    }

    override fun playHighBeep() = beep("high")
    override fun playLowBeep(secondsLeft: Int) = beep("low_${secondsLeft.coerceIn(1, 3)}")
    override fun playGo() = voice("countdown_go")
    override fun playLetsGo() = voice("lets_go")
    override fun playRest() = voice("rest")
    override fun playHalfway() = voice("halfway")
    override fun playGetReady() = voice("get_ready")
    override fun playTenSeconds() = voice("ten_seconds")
    override fun playLastRound() = voice("last_round")
    override fun playKeepGoing() = voice("keep_going")
    override fun playComeOn() = voice("come_on")
    override fun playAlmostThere() = voice("almost_there")
    override fun playGoodJob() = voice("good_job")
    override fun playThatsIt() = voice("thats_it")
    override fun playNextRound() = voice("next_round")
    override fun playComplete() = voice("complete")

    /** The high beep with the chosen voice's "Let's go" on it, as a change sounds. */
    fun playSoundCheck() {
        playHighBeep()
        playLetsGo()
    }

    /** Where the next cue comes out and the media volume it plays at. */
    val outputDescription: String
        get() {
            val names = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
                .filter { it.isSink }
                .map { device ->
                    when (device.type) {
                        android.media.AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "Speaker"
                        android.media.AudioDeviceInfo.TYPE_BLUETOOTH_A2DP, android.media.AudioDeviceInfo.TYPE_BLUETOOTH_SCO ->
                            device.productName.toString().ifBlank { "Bluetooth" }
                        else -> device.productName.toString().ifBlank { "Output" }
                    }
                }
                .distinct()
            val route = if (names.isEmpty()) "No output" else names.joinToString(" + ")
            val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
            val volume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC) * 100 / max
            return "$route, volume $volume%"
        }

    private fun beep(name: String) {
        val path = settings.beepFile(name) ?: return
        log("beep:$name")
        play(path)
    }

    private fun voice(name: String) {
        val path = settings.voiceFile(name) ?: return
        log("voice:$name")
        play(path)
    }

    private fun play(path: String) {
        sink?.let { it(path); return }
        val pool = pool ?: return
        val id = sounds[path] ?: return
        val key = "p${nextKey++ % 4}"
        try {
            lease.acquire(key)
        } catch (e: Exception) {
            // No focus (a call?): play anyway, the lease holds nothing.
        }
        pool.play(id, 1f, 1f, 1, 0, 1f)
    }

    private fun log(cue: String) {
        cueLog.add(cue)
        if (cueLog.size > 400) cueLog.removeAt(0)
    }

    fun release() {
        lease.releaseAll()
        pool?.release()
    }
}
