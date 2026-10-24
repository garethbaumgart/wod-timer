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
import androidx.health.services.client.data.ExerciseTrackedStatus
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
 * Keeps the timer alive on the wrist, in two layers. [WorkoutService], a
 * foreground service with an ongoing activity, holds the process for the
 * whole workout and puts the chip on the watch face: that alone keeps the
 * clock, beeps and taps going with the wrist down, and it is all the timer
 * runs by default (timer only, 24 Oct 2026). Health Services' exercise
 * session is opt-in ("Record as workout"): it makes the WOD the watch's one
 * recognised exercise, which ends whatever another app is recording, so
 * Wharf WOD stays out of the way of Fitbit or Samsung Health unless asked.
 *
 * The session requests no data types, so the only runtime permission is
 * ACTIVITY_RECOGNITION, which the health foreground service needs as well:
 * Health Services needs BODY_SENSORS only for heart-rate data, and every
 * manifest permission has to be justified in Play's Health apps declaration.
 */
class ExerciseTracker(private val context: Context, store: KeyValueStore) : WorkoutTracking {
    companion object {
        private const val TAG = "WharfWOD.Exercise"
        /** 2.2.0's "Track workouts" switch; kept as a key, no longer read: recording is [RECORD_KEY]. */
        const val ENABLED_KEY = "wear_health_track"
        /** Opt-in exercise session. Missing reads as off, so the update turns recording off for everyone. */
        const val RECORD_KEY = "wear_record_workout"

        fun exerciseType(type: TimerType): ExerciseType =
            if (type is TimerType.Tabata) ExerciseType.HIGH_INTENSITY_INTERVAL_TRAINING else ExerciseType.STRENGTH_TRAINING

        val permissions = listOf(Manifest.permission.ACTIVITY_RECOGNITION)

        /** Whether the athlete asked for an exercise session (the default is timer only). */
        fun recordsWorkouts(store: KeyValueStore): Boolean = store.getBoolean(RECORD_KEY, false)

        /**
         * Whether GO starts an exercise: only when recording is on and no
         * other app is mid-exercise. Health Services runs one exercise at a
         * time across all apps, so starting ours would end theirs; an
         * unknown status (the query failed) is treated as free. The status is
         * one of the `ExerciseTrackedStatus` integer constants.
         */
        fun shouldStartExercise(record: Boolean, tracked: Int?): Boolean =
            record && tracked != ExerciseTrackedStatus.OTHER_APP_IN_PROGRESS
    }

    enum class Status { IDLE, SERVICE_ONLY, EXERCISING, NO_PERMISSION, OTHER_APP }

    private val store = store
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val client: ExerciseClient? = try {
        HealthServices.getClient(context).exerciseClient
    } catch (e: Exception) {
        null
    }

    var status: Status = Status.IDLE
        private set
    var recordWorkout: Boolean = recordsWorkouts(store)
        private set
    private var exercising = false
    private var pendingType: ExerciseType? = null

    fun setRecordWorkout(on: Boolean) {
        recordWorkout = on
        store.putBoolean(RECORD_KEY, on)
    }

    val hasPermission: Boolean
        get() = permissions.all { ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED }

    override fun begin(workout: Workout) {
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
        pendingType = if (recordWorkout) exerciseType(workout.timerType) else null
    }

    override fun go() {
        val type = pendingType ?: return
        val client = client ?: return
        scope.launch {
            val tracked = runCatching { client.getCurrentExerciseInfoAsync().await().exerciseTrackedStatus }.getOrNull()
            if (!shouldStartExercise(recordWorkout, tracked)) {
                status = Status.OTHER_APP
                Log.i(TAG, "exercise not started: another app is mid-exercise; the service keeps the timer alive")
                return@launch
            }
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
        if (status != Status.NO_PERMISSION) {
            context.stopService(Intent(context, WorkoutService::class.java))
        }
        status = Status.IDLE
    }
}
