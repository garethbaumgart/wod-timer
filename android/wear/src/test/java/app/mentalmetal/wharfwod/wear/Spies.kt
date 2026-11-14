package app.mentalmetal.wharfwod.wear

import app.mentalmetal.wharfwod.wear.application.Ticker
import app.mentalmetal.wharfwod.wear.domain.RoundCount
import app.mentalmetal.wharfwod.wear.domain.TimerDuration
import app.mentalmetal.wharfwod.wear.domain.TimerType
import app.mentalmetal.wharfwod.wear.domain.Workout
import app.mentalmetal.wharfwod.wear.services.AudioCues
import app.mentalmetal.wharfwod.wear.services.HapticCue
import app.mentalmetal.wharfwod.wear.services.VoiceSettings
import app.mentalmetal.wharfwod.wear.services.WorkoutTracking
import app.mentalmetal.wharfwod.wear.services.WristHaptics

class SpyHaptics : WristHaptics {
    val log = mutableListOf<String>()
    override fun play(cue: HapticCue) { log.add(cue.name) }
    override fun cancelPending() { log.add("cancel") }
}

/**
 * Logs each cue as "beep:name" / "voice:name". With [settings] it logs only
 * what the real player would play, by the same rules (Beeps only drops the
 * voice, Silent drops everything).
 */
class SpyAudio(private val settings: VoiceSettings? = null) : AudioCues {
    val log = mutableListOf<String>()
    private fun beep(name: String) { if (settings == null || settings.beepFile(name) != null) log.add("beep:$name") }
    private fun voice(name: String) { if (settings == null || settings.voiceFile(name) != null) log.add("voice:$name") }
    override fun playHighBeep() = beep("high")
    override fun playLowBeep(secondsLeft: Int) = beep("low_$secondsLeft")
    override fun playMidBeep() = beep("mid")
    override fun playGo() = voice("go")
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
}

class SpyTracker : WorkoutTracking {
    val calls = mutableListOf<String>()
    override fun begin(workout: Workout) { calls.add("begin:${workout.timerType.typeCode}") }
    override fun go() { calls.add("go") }
    override fun pause() { calls.add("pause") }
    override fun resume() { calls.add("resume") }
    override fun end(keep: Boolean) { calls.add(if (keep) "end:keep" else "end:discard") }
}

class SpyTicker : Ticker {
    val calls = mutableListOf<String>()
    override fun start() { calls.add("start") }
    override fun pause() { calls.add("pause") }
    override fun resume() { calls.add("resume") }
    override fun stop() { calls.add("stop") }
}

fun amrap(seconds: Int = 600, prep: Int = 0) = Workout.of(TimerType.Amrap(TimerDuration.of(seconds)), prep)
fun forTime(cap: Int = 1200, prep: Int = 0) = Workout.of(TimerType.ForTime(TimerDuration.of(cap)), prep)
fun emom(interval: Int = 60, rounds: Int = 10, prep: Int = 0) =
    Workout.of(TimerType.Emom(TimerDuration.of(interval), RoundCount.of(rounds)), prep)
fun tabata(work: Int = 20, rest: Int = 10, rounds: Int = 8, prep: Int = 0) =
    Workout.of(TimerType.Tabata(TimerDuration.of(work), TimerDuration.of(rest), RoundCount.of(rounds)), prep)
