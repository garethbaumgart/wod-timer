package app.mentalmetal.wharfwod.wear.services

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * Every permission in the manifest has to be justified in Play's Health apps
 * declaration, so the set is pinned here. The exercise session requests no
 * data types (no heart rate), so BODY_SENSORS is not asked for: Health
 * Services only needs it for heart-rate data types.
 */
class PermissionsTest {
    private val manifest = File("src/main/AndroidManifest.xml").readText()

    @Test fun `the runtime prompt asks for activity recognition only`() {
        assertEquals(listOf("android.permission.ACTIVITY_RECOGNITION"), ExerciseTracker.permissions)
    }

    @Test fun `the manifest declares no sensor permission`() {
        assertFalse(manifest.contains("BODY_SENSORS"))
        assertFalse(manifest.contains("HIGH_SAMPLING_RATE_SENSORS"))
    }

    @Test fun `the health foreground service keeps its activity-recognition prerequisite`() {
        assertTrue(manifest.contains("android.permission.FOREGROUND_SERVICE_HEALTH"))
        assertTrue(manifest.contains("android.permission.ACTIVITY_RECOGNITION"))
        assertTrue(manifest.contains("android:foregroundServiceType=\"health\""))
    }
}
