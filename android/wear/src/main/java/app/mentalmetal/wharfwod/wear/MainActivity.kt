package app.mentalmetal.wharfwod.wear

import android.Manifest
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
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
                // `--es then run|pause|finish|stop` walks on to that screen (shape and font-size captures).
                // A beat later, so the workout service is up before a stop takes it down again.
                val then = intent?.getStringExtra("then")
                window.decorView.postDelayed({
                    when (then) {
                        "run" -> app.timer.skipPrep()
                        "pause" -> { app.timer.skipPrep(); app.timer.pause() }
                        "finish" -> { app.timer.skipPrep(); app.timer.finish() }
                        "stop" -> { app.timer.skipPrep(); app.timer.stop() }
                    }
                }, 700)
            }
        }
        // Debug capture hook: `--es route setup/tabata` (or voice, health) opens on that screen.
        val debugRoute = if (BuildConfig.DEBUG) intent?.getStringExtra("route") else null
        setContent {
            MaterialTheme {
                Root(app, debugRoute)
            }
        }
    }

    @Composable
    private fun Root(app: WodApp, debugRoute: String? = null) {
        val nav = rememberSwipeDismissableNavController()
        val workoutRunning = app.timer.phase != TimerState.READY
        val backStack by nav.currentBackStackEntryAsState()
        val onLive = backStack?.destination?.route == "live"
        // The one permission ask, when Home first shows (as the Apple Watch app does with Health):
        // the health foreground service that keeps the timer alive needs it, recording or not.
        LaunchedEffect(Unit) {
            val store = app.store
            if (!app.tracker.hasPermission && !store.getBoolean("wear_perm_asked", false)) {
                store.putBoolean("wear_perm_asked", true)
                requestPermissions()
            }
        }
        LaunchedEffect(debugRoute) { if (debugRoute != null && !workoutRunning) nav.navigate(debugRoute) }
        // Where the app opens is decided once. Passed live, it flipped to "live" when a workout
        // started and back to "home" at DONE; each flip rebuilt the graph and reset the back
        // stack, and DONE's own pop then took the one entry left: a black screen with the app
        // still running (caught on the release build of 2.5.2, 19 Nov 2026, before it shipped).
        val start = remember { if (workoutRunning) "live" else "home" }
        SwipeDismissableNavHost(
            navController = nav,
            startDestination = start,
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
                // Back belongs to the timer here, never to the back stack (TimerViewModel.back).
                BackHandler { app.timer.back() }
                // Back to setup when the workout was started from it; to Home when the app
                // opened straight onto a running workout and there is nothing under it.
                LiveScreen(app.timer, ambient) {
                    if (nav.previousBackStackEntry != null) nav.popBackStack()
                    else nav.navigate("home") { popUpTo("live") { inclusive = true } }
                }
            }
            composable("voice") { VoiceScreen(app.audio) }
            composable("health") { HealthScreen(app.tracker, ::requestPermissions) }
        }
    }
}
