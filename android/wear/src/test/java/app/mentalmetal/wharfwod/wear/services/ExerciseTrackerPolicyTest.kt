package app.mentalmetal.wharfwod.wear.services

import androidx.health.services.client.data.ExerciseTrackedStatus
import app.mentalmetal.wharfwod.wear.application.MemoryStore
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Timer only by default (24 Oct 2026): the foreground service keeps the
 * timer alive on its own, and the Health Services exercise, which ends
 * whatever another app is recording, is opt-in.
 */
class ExerciseTrackerPolicyTest {
    @Test fun `a fresh watch does not record`() {
        assertFalse(ExerciseTracker.recordsWorkouts(MemoryStore()))
    }

    @Test fun `the 2 2 0 Track workouts key is not read as a recording choice`() {
        val store = MemoryStore()
        store.putBoolean(ExerciseTracker.ENABLED_KEY, true)
        assertFalse("the old switch meant 'keep the timer alive', not 'record'", ExerciseTracker.recordsWorkouts(store))
    }

    @Test fun `opting in is remembered under its own additive key`() {
        val store = MemoryStore()
        store.putBoolean(ExerciseTracker.RECORD_KEY, true)
        assertTrue(ExerciseTracker.recordsWorkouts(store))
        assertEquals(setOf(ExerciseTracker.RECORD_KEY), store.values.keys)
    }

    @Test fun `GO starts an exercise only when recording and nobody else is mid-exercise`() {
        assertFalse(ExerciseTracker.shouldStartExercise(record = false, tracked = ExerciseTrackedStatus.NO_EXERCISE_IN_PROGRESS))
        assertFalse(ExerciseTracker.shouldStartExercise(record = true, tracked = ExerciseTrackedStatus.OTHER_APP_IN_PROGRESS))
        assertTrue(ExerciseTracker.shouldStartExercise(record = true, tracked = ExerciseTrackedStatus.NO_EXERCISE_IN_PROGRESS))
        assertTrue(ExerciseTracker.shouldStartExercise(record = true, tracked = ExerciseTrackedStatus.OWNED_EXERCISE_IN_PROGRESS))
        assertTrue("an unanswered query does not block the athlete", ExerciseTracker.shouldStartExercise(record = true, tracked = null))
    }

    @Test fun `the exercise type still follows the mode when recording`() {
        assertEquals(
            androidx.health.services.client.data.ExerciseType.HIGH_INTENSITY_INTERVAL_TRAINING,
            ExerciseTracker.exerciseType(app.mentalmetal.wharfwod.wear.domain.TimerType.Tabata(
                app.mentalmetal.wharfwod.wear.domain.TimerDuration.of(20),
                app.mentalmetal.wharfwod.wear.domain.TimerDuration.of(10),
                app.mentalmetal.wharfwod.wear.domain.RoundCount.of(8),
            )),
        )
    }
}
