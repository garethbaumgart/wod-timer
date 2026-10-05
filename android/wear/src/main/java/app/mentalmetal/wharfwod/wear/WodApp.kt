package app.mentalmetal.wharfwod.wear

import android.app.Application
import android.content.Context
import app.mentalmetal.wharfwod.wear.application.PrefsStore
import app.mentalmetal.wharfwod.wear.application.SetupMemory
import app.mentalmetal.wharfwod.wear.application.TimerEngine
import app.mentalmetal.wharfwod.wear.application.TimerViewModel
import app.mentalmetal.wharfwod.wear.services.ExerciseTracker
import app.mentalmetal.wharfwod.wear.services.VibratorHaptics
import app.mentalmetal.wharfwod.wear.services.WearAudioService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob

/**
 * Process-level home of the timer, so a workout survives the activity
 * (wrist down, the watch face, a tap on the ongoing chip) while the
 * foreground service holds the process.
 */
class WodApp : Application() {
    val store by lazy { PrefsStore(getSharedPreferences("wharfwod", Context.MODE_PRIVATE)) }
    val setupMemory by lazy { SetupMemory(store) }
    val audio by lazy { WearAudioService(this, store).also { it.preload() } }
    val haptics by lazy { VibratorHaptics(this) }
    val tracker by lazy { ExerciseTracker(this, store) }
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    val engine by lazy { TimerEngine(scope) }
    val timer: TimerViewModel by lazy {
        TimerViewModel(haptics, audio, tracker, store, engine).also { vm ->
            engine.onTick = { elapsed -> vm.onTick(elapsed) }
        }
    }

    companion object {
        fun of(context: Context): WodApp = context.applicationContext as WodApp
    }
}
