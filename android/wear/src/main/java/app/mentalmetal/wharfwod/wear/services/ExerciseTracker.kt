package app.mentalmetal.wharfwod.wear.services

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.content.ContextCompat
import androidx.health.services.client.ExerciseClient
import androidx.health.services.client.HealthServices
import androidx.health.services.client.data.ExerciseConfig
import androidx.health.services.client.data.ExerciseType
import app.mentalmetal.wharfwod.wear.WorkoutService
import app.mentalmetal.wharfwod.wear.application.KeyValueStore
import app.mentalmetal.wharfwod.wear.domain.TimerType
import app.mentalmetal.wharfwod.wear.domain.Workout
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.launch

/**
 * The Wear equivalent of the watch's HKWorkoutSession, in two layers:
 * [WorkoutService], a foreground service with an ongoing activity, keeps the
 * process alive and puts the chip on the watch face; Health Services'
 * exercise session, where the watch grants it, makes it a recognised
 * workout (one at a time, like Apple Watch). Either can be refused: the
 * timer still runs while the app is on screen.
 *
 * The session requests no data types, so the only runtime permission is
 * ACTIVITY_RECOGNITION: Health Services needs BODY_SENSORS only for
 * heart-rate data, and every manifest permission has to be justified in
 * Play's Health apps declaration.
 */
class ExerciseTracker(private val context: Context, store: KeyValueStore) : WorkoutTracking {
    companion object {
        private const val TAG = "WharfWOD.Exercise"
        const val ENABLED_KEY = "wear_health_track"

        fun exerciseType(type: TimerType): ExerciseType =
            if (type is TimerType.Tabata) ExerciseType.HIGH_INTENSITY_INTERVAL_TRAINING else ExerciseType.STRENGTH_TRAINING

        val permissions = listOf(Manifest.permission.ACTIVITY_RECOGNITION)
    }

    enum class Status { IDLE, SERVICE_ONLY, EXERCISING, NO_PERMISSION, OFF }

    private val store = store
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val client: ExerciseClient? = try {
        HealthServices.getClient(context).exerciseClient
    } catch (e: Exception) {
        null
    }

    var status: Status = Status.IDLE
        private set
    var enabled: Boolean = if (store.contains(ENABLED_KEY)) store.getBoolean(ENABLED_KEY, true) else true
        private set
    private var exercising = false
    private var pendingType: ExerciseType? = null

    fun setEnabled(on: Boolean) {
        enabled = on
        store.putBoolean(ENABLED_KEY, on)
    }

    val hasPermission: Boolean
        get() = permissions.all { ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED }

    override fun begin(workout: Workout) {
        if (!enabled) {
            status = Status.OFF
            return
        }
        if (!hasPermission) {
            status = Status.NO_PERMISSION
            return
        }
        try {
            ContextCompat.startForegroundService(context, Intent(context, WorkoutService::class.java).apply {
                putExtra(WorkoutService.EXTRA_TITLE, workout.timerType.displayLabel)
            })
            status = Status.SERVICE_ONLY
        } catch (e: Exception) {
            Log.w(TAG, "foreground service refused: ${e.message}")
            status = Status.NO_PERMISSION
            return
        }
        pendingType = exerciseType(workout.timerType)
    }

    override fun go() {
        val type = pendingType ?: return
        val client = client ?: return
        scope.launch {
            try {
                client.startExerciseAsync(
                    ExerciseConfig(exerciseType = type, dataTypes = emptySet(), isAutoPauseAndResumeEnabled = false, isGpsEnabled = false),
                ).await()
                exercising = true
                status = Status.EXERCISING
                Log.i(TAG, "exercise started: $type")
            } catch (e: Exception) {
                Log.i(TAG, "exercise not started (${e.message}); service keeps the timer alive")
            }
        }
    }

    override fun pause() {
        if (!exercising) return
        scope.launch { runCatching { client?.pauseExerciseAsync()?.await() } }
    }

    override fun resume() {
        if (!exercising) return
        scope.launch { runCatching { client?.resumeExerciseAsync()?.await() } }
    }

    override fun end(keep: Boolean) {
        pendingType = null
        if (exercising) {
            exercising = false
            scope.launch {
                runCatching { client?.endExerciseAsync()?.await() }
                Log.i(TAG, "exercise ended (keep=$keep)")
            }
        }
        if (status != Status.OFF && status != Status.NO_PERMISSION) {
            context.stopService(Intent(context, WorkoutService::class.java))
        }
        status = if (status == Status.OFF) Status.OFF else Status.IDLE
    }
}
