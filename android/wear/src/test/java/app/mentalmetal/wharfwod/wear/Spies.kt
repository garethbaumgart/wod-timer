package app.mentalmetal.wharfwod.wear

import app.mentalmetal.wharfwod.wear.application.Ticker
import app.mentalmetal.wharfwod.wear.domain.RoundCount
import app.mentalmetal.wharfwod.wear.domain.TimerDuration
import app.mentalmetal.wharfwod.wear.domain.TimerType
import app.mentalmetal.wharfwod.wear.domain.Workout
import app.mentalmetal.wharfwod.wear.services.AudioCues
import app.mentalmetal.wharfwod.wear.services.HapticCue
import app.mentalmetal.wharfwod.wear.services.WorkoutTracking
import app.mentalmetal.wharfwod.wear.services.WristHaptics

class SpyHaptics : WristHaptics {
    val log = mutableListOf<String>()
    override fun play(cue: HapticCue) { log.add(cue.name) }
    override fun cancelPending() { log.add("cancel") }
}

class SpyAudio : AudioCues {
    val log = mutableListOf<String>()
    override fun playHighBeep() { log.add("beep:high") }
    override fun playLowBeep(secondsLeft: Int) { log.add("beep:low_$secondsLeft") }
    override fun playGo() { log.add("voice:go") }
    override fun playLetsGo() { log.add("voice:go") }
    override fun playRest() { log.add("voice:rest") }
    override fun playHalfway() { log.add("voice:halfway") }
    override fun playGetReady() { log.add("voice:get_ready") }
    override fun playTenSeconds() { log.add("voice:ten_seconds") }
    override fun playLastRound() { log.add("voice:last_round") }
    override fun playKeepGoing() { log.add("voice:keep_going") }
    override fun playComeOn() { log.add("voice:keep_going") }
    override fun playAlmostThere() { log.add("voice:almost_there") }
    override fun playGoodJob() { log.add("voice:good_job") }
    override fun playThatsIt() { log.add("voice:good_job") }
    override fun playNextRound() { log.add("voice:next_round") }
    override fun playComplete() { log.add("voice:complete") }
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
