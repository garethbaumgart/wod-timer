package app.mentalmetal.wharfwod.wear

import android.Manifest
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.wear.ambient.AmbientLifecycleObserver
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.currentBackStackEntryAsState
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import app.mentalmetal.wharfwod.wear.application.SetupMemory
import app.mentalmetal.wharfwod.wear.domain.TimerState
import app.mentalmetal.wharfwod.wear.domain.Workout
import app.mentalmetal.wharfwod.wear.services.ExerciseTracker
import app.mentalmetal.wharfwod.wear.ui.HealthScreen
import app.mentalmetal.wharfwod.wear.ui.HomeScreen
import app.mentalmetal.wharfwod.wear.ui.LiveScreen
import app.mentalmetal.wharfwod.wear.ui.SetupScreen
import app.mentalmetal.wharfwod.wear.ui.VoiceScreen

class MainActivity : ComponentActivity() {
    private var ambient by mutableStateOf(false)

    private val permissionLauncher = registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {}

    private val ambientObserver by lazy {
        AmbientLifecycleObserver(this, object : AmbientLifecycleObserver.AmbientLifecycleCallback {
            override fun onEnterAmbient(ambientDetails: AmbientLifecycleObserver.AmbientDetails) { ambient = true }
            override fun onExitAmbient() { ambient = false }
            override fun onUpdateAmbient() {}
        })
    }

    private fun requestPermissions() {
        val wanted = ExerciseTracker.permissions.toMutableList()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) wanted.add(Manifest.permission.POST_NOTIFICATIONS)
        permissionLauncher.launch(wanted.toTypedArray())
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        lifecycle.addObserver(ambientObserver)
        val app = WodApp.of(this)
        // Debug capture hook (store screenshots, smoke runs): `am start ... --es scene emom:5:1`
        // starts that workout at once, the way the Apple Watch app's --capture does.
        intent?.getStringExtra("scene")?.let { scene ->
            if (BuildConfig.DEBUG && app.timer.phase == TimerState.READY) {
                SetupMemory.decode(scene)?.let { type -> app.timer.start(Workout.of(type, prepSeconds = 3)) }
            }
        }
        setContent {
            MaterialTheme {
                Root(app)
            }
        }
    }

    @Composable
    private fun Root(app: WodApp) {
        val nav = rememberSwipeDismissableNavController()
        val workoutRunning = app.timer.phase != TimerState.READY
        val backStack by nav.currentBackStackEntryAsState()
        val onLive = backStack?.destination?.route == "live"
        // The one permission ask, when Home first shows (as the Apple Watch app does with Health).
        LaunchedEffect(Unit) {
            val store = app.store
            if (app.tracker.enabled && !app.tracker.hasPermission && !store.getBoolean("wear_perm_asked", false)) {
                store.putBoolean("wear_perm_asked", true)
                requestPermissions()
            }
        }
        SwipeDismissableNavHost(
            navController = nav,
            startDestination = if (workoutRunning) "live" else "home",
            userSwipeEnabled = !onLive,
        ) {
            composable("home") {
                HomeScreen(app, onMode = { nav.navigate("setup/$it") }, onVoice = { nav.navigate("voice") }, onHealth = { nav.navigate("health") })
            }
            composable("setup/{code}") { entry ->
                val code = entry.arguments?.getString("code") ?: "amrap"
                SetupScreen(code, app.setupMemory) { workout ->
                    app.timer.start(workout)
                    nav.navigate("live")
                }
            }
            composable("live") {
                LiveScreen(app.timer, ambient) { nav.popBackStack() }
            }
            composable("voice") { VoiceScreen(app.audio) }
            composable("health") { HealthScreen(app.tracker, ::requestPermissions) }
        }
    }
}
