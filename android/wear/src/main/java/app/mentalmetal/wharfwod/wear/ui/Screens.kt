package app.mentalmetal.wharfwod.wear.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.rotary.onRotaryScrollEvent
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material.Text
import app.mentalmetal.wharfwod.wear.WodApp
import app.mentalmetal.wharfwod.wear.application.SetupMemory
import app.mentalmetal.wharfwod.wear.domain.RoundCount
import app.mentalmetal.wharfwod.wear.domain.TimerDuration
import app.mentalmetal.wharfwod.wear.domain.TimerType
import app.mentalmetal.wharfwod.wear.domain.Workout
import app.mentalmetal.wharfwod.wear.services.ExerciseTracker
import app.mentalmetal.wharfwod.wear.services.VoicePack
import app.mentalmetal.wharfwod.wear.services.WearAudioService

// MARK: Home

/** Home: the stacked wordmark, the four timers in the phone's order with the remembered workout drawn as a timeline, then Voice and Health. */
@Composable
fun HomeScreen(app: WodApp, onMode: (String) -> Unit, onVoice: () -> Unit, onHealth: () -> Unit) {
    val state = rememberScalingLazyListState()
    val memory = app.setupMemory
    ScalingLazyColumn(state = state, modifier = Modifier.fillMaxSize().background(Color.Black)) {
        item { Wordmark() }
        for (code in Palette.modeOrder) {
            item { ModeRow(code, memory.summary(code), memory.shape(code)) { onMode(code) } }
        }
        item { SettingsRow("Voice", app.audio.settings.label, onVoice) }
        item { SettingsRow("Health", healthLabel(app.tracker), onHealth) }
    }
}

fun healthLabel(tracker: ExerciseTracker): String = when {
    !tracker.enabled -> "Off"
    !tracker.hasPermission -> "Not allowed"
    else -> "On"
}

@Composable
private fun Wordmark() {
    Column(Modifier.fillMaxWidth().padding(top = 6.dp, bottom = 4.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Text("WHARF", color = Color.White, fontSize = 22.sp, fontWeight = Heavy, letterSpacing = 1.sp)
        Row {
            Text("WOD", color = Palette.work, fontSize = 22.sp, fontWeight = Heavy, letterSpacing = 1.sp)
            Text(".", color = Palette.rest, fontSize = 22.sp, fontWeight = Heavy)
        }
    }
}

@Composable
private fun ModeRow(code: String, summary: String, shape: List<app.mentalmetal.wharfwod.wear.domain.TimelinePart>, onClick: () -> Unit) {
    val accent = Palette.mode(code)
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(Palette.soft)
            .clickable(onClick = onClick)
            .semantics { contentDescription = Palette.title(code) }
            .padding(horizontal = 12.dp, vertical = 8.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.width(3.5.dp).height(30.dp).clip(RoundedCornerShape(2.dp)).background(accent))
            Spacer(Modifier.width(9.dp))
            Column {
                Text(Palette.title(code), color = Color.White, fontSize = 17.sp, fontWeight = Heavy, maxLines = 1)
                Text(summary, color = Color.White.copy(alpha = 0.75f), fontSize = 12.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
            }
        }
        Spacer(Modifier.height(6.dp))
        TimelineBar(shape, accent, height = 5.dp)
    }
}

@Composable
private fun SettingsRow(title: String, value: String, onClick: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(Palette.soft)
            .clickable(onClick = onClick)
            .semantics { contentDescription = "$title, $value" }
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(title, color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)
        Spacer(Modifier.weight(1f))
        Text(value, color = Palette.label, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
    }
}

// MARK: Setup

private class Field(val label: String, val color: Color, val min: Int, val max: Int, val step: Int, val display: (Int) -> String)

private fun fields(code: String): List<Field> = when (code) {
    "amrap" -> listOf(Field("DURATION", Palette.mode("amrap"), 60, 3600, 60) { TimerDuration.of(it).clock })
    "fortime" -> listOf(Field("TIME CAP", Palette.mode("fortime"), 60, 3600, 60) { TimerDuration.of(it).clock })
    "emom" -> listOf(
        Field("EVERY", Palette.work, 15, 600, 15) { TimerDuration.of(it).clock },
        Field("ROUNDS", Palette.mode("amrap"), 1, 30, 1) { "$it" },
    )
    else -> listOf(
        Field("WORK", Palette.work, 5, 300, 5) { TimerDuration.of(it).phase },
        Field("REST", Palette.rest, 5, 300, 5) { TimerDuration.of(it).phase },
        Field("ROUNDS", Palette.mode("amrap"), 1, 20, 1) { "$it" },
    )
}

private fun values(code: String, type: TimerType): List<Int> = when (type) {
    is TimerType.Amrap -> listOf(type.duration.seconds)
    is TimerType.ForTime -> listOf(type.timeCap.seconds)
    is TimerType.Emom -> listOf(type.intervalDuration.seconds, type.rounds.value)
    is TimerType.Tabata -> listOf(type.workDuration.seconds, type.restDuration.seconds, type.rounds.value)
}

private fun type(code: String, v: List<Int>, countUp: Boolean): TimerType = when (code) {
    "amrap" -> TimerType.Amrap(TimerDuration.of(v[0]))
    "fortime" -> TimerType.ForTime(TimerDuration.of(v[0]), countUp)
    "emom" -> TimerType.Emom(TimerDuration.of(v[0]), RoundCount.of(v[1]))
    else -> TimerType.Tabata(TimerDuration.of(v[0]), TimerDuration.of(v[1]), RoundCount.of(v[2]))
}

/**
 * Setup: the mode's values stacked, the focused one white; the rotary
 * (bezel or crown) moves it, a tap on another value focuses it. Every
 * change is remembered. START carries the total.
 */
@Composable
fun SetupScreen(code: String, memory: SetupMemory, onStart: (Workout) -> Unit) {
    val fields = remember(code) { fields(code) }
    val last = remember(code) { memory.last(code) }
    var values by remember(code) { mutableStateOf(values(code, last)) }
    var countUp by remember(code) { mutableStateOf((last as? TimerType.ForTime)?.countUp ?: true) }
    var focused by remember(code) { mutableIntStateOf(0) }
    var accumulated by remember { mutableStateOf(0f) }
    val focusRequester = remember { FocusRequester() }
    val current = type(code, values, countUp)

    fun change(delta: Int) {
        val f = fields[focused]
        values = values.toMutableList().also { it[focused] = (it[focused] + delta * f.step).coerceIn(f.min, f.max) }
        memory.save(type(code, values, countUp))
    }

    LaunchedEffect(Unit) { focusRequester.requestFocus() }
    val g = geometry()

    Column(
        Modifier
            .fillMaxSize()
            .background(Color.Black)
            .onRotaryScrollEvent { event ->
                accumulated += event.verticalScrollPixels
                while (accumulated >= 40f) { change(1); accumulated -= 40f }
                while (accumulated <= -40f) { change(-1); accumulated += 40f }
                true
            }
            .focusRequester(focusRequester)
            .focusable()
            .padding(horizontal = g.sideMargin)
            .padding(top = 18.dp, bottom = g.bottomMargin),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Caption(Palette.title(code), color = Palette.mode(code), size = 12.sp)
        Spacer(Modifier.weight(1f))
        fields.forEachIndexed { i, f ->
            Column(
                Modifier.clickable { focused = i }.semantics { contentDescription = "${f.label} ${f.display(values[i])}" },
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Caption(f.label, color = f.color, size = 10.sp)
                Text(
                    f.display(values[i]),
                    color = if (focused == i) Color.White else Color.White.copy(alpha = 0.45f),
                    fontSize = if (fields.size == 1) 44.sp else if (fields.size == 2) 30.sp else 24.sp,
                    fontWeight = Heavy, maxLines = 1,
                )
            }
        }
        if (code == "fortime") {
            Text(
                if (countUp) "COUNTS UP" else "COUNTS DOWN", color = Palette.label, fontSize = 10.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp,
                modifier = Modifier.padding(top = 2.dp).clickable { countUp = !countUp; memory.save(type(code, values, countUp)) },
            )
        }
        Spacer(Modifier.weight(1f))
        val subtitle = when (current) {
            is TimerType.Amrap -> null
            is TimerType.ForTime -> if (countUp) "up to the cap" else "down from the cap"
            else -> "${current.estimatedDuration.clock} total"
        }
        StartButton(subtitle) {
            memory.save(current)
            onStart(Workout.of(current))
        }
    }
}

// MARK: Voice

/** One list, as on the phone: three voices, Random, Beeps only, Silent; choosing one plays a sample. Under them the sound check. */
@Composable
fun VoiceScreen(audio: WearAudioService) {
    val state = rememberScalingLazyListState()
    var version by remember { mutableIntStateOf(0) }
    var checkResult by remember { mutableStateOf("Plays a beep and a line") }
    val settings = audio.settings
    val current: String = run { version; settings.label }
    ScalingLazyColumn(state = state, modifier = Modifier.fillMaxSize().background(Color.Black)) {
        item { Caption("VOICE", color = Palette.brand, size = 12.sp, modifier = Modifier.padding(top = 4.dp)) }
        val choices = listOf(
            Triple("Major", "Drill sergeant") { settings.setMuted(false); settings.setBeepsOnly(false); settings.setRandomizePerCue(false); settings.setVoicePack(VoicePack.MAJOR); audio.playLetsGo() },
            Triple("Liam", "Male coach") { settings.setMuted(false); settings.setBeepsOnly(false); settings.setRandomizePerCue(false); settings.setVoicePack(VoicePack.LIAM); audio.playLetsGo() },
            Triple("Holly", "Female coach") { settings.setMuted(false); settings.setBeepsOnly(false); settings.setRandomizePerCue(false); settings.setVoicePack(VoicePack.HOLLY); audio.playLetsGo() },
            Triple("Random", "A different voice each cue") { settings.setMuted(false); settings.setBeepsOnly(false); settings.setRandomizePerCue(true); audio.playLetsGo() },
            Triple("Beeps", "No voice, beeps on the count") { settings.setMuted(false); settings.setRandomizePerCue(false); settings.setBeepsOnly(true); audio.playLetsGo() },
            Triple("Silent", "Haptics only") { settings.setMuted(true) },
        )
        for ((name, detail, select) in choices) {
            item {
                ChoiceRow(name, detail, selected = current == name) { select(); version++ }
            }
        }
        item {
            ChoiceRow("Sound check", checkResult, selected = false, accent = Palette.primary) {
                checkResult = if (settings.muted) "Silent is on: haptics only" else { audio.playSoundCheck(); audio.outputDescription }
            }
        }
        item {
            Text(
                "Cues play through the watch speaker or your headphones. Hear nothing? Check the media volume.",
                color = Palette.label, fontSize = 11.sp, fontWeight = FontWeight.Medium,
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 6.dp),
            )
        }
    }
}

@Composable
private fun ChoiceRow(name: String, detail: String, selected: Boolean, accent: Color = Palette.primary, onClick: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(Palette.soft)
            .clickable(onClick = onClick)
            .semantics { contentDescription = "$name, $detail${if (selected) ", selected" else ""}" }
            .padding(horizontal = 14.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Text(name, color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold, maxLines = 1)
            Text(detail, color = Palette.label, fontSize = 11.sp, fontWeight = FontWeight.Medium, maxLines = 2)
        }
        if (selected) Text("✓", color = accent, fontSize = 15.sp, fontWeight = FontWeight.Bold)
    }
}

// MARK: Health

/** Health: the session that keeps the timer alive when the wrist drops. One switch, what it does, and where the permission stands. */
@Composable
fun HealthScreen(tracker: ExerciseTracker, requestPermissions: () -> Unit) {
    val state = rememberScalingLazyListState()
    var version by remember { mutableIntStateOf(0) }
    val enabled = run { version; tracker.enabled }
    val allowed = run { version; tracker.hasPermission }
    ScalingLazyColumn(state = state, modifier = Modifier.fillMaxSize().background(Color.Black)) {
        item { Caption("HEALTH", color = Palette.brand, size = 12.sp, modifier = Modifier.padding(top = 4.dp)) }
        item {
            Row(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(Palette.soft)
                    .clickable { tracker.setEnabled(!enabled); version++ }
                    .semantics { contentDescription = "Track workouts, ${if (enabled) "on" else "off"}" }
                    .padding(horizontal = 14.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f)) {
                    Text("Track workouts", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                    Text("Runs the timer as a workout", color = Palette.label, fontSize = 11.sp, fontWeight = FontWeight.Medium)
                }
                Box(
                    Modifier.size(width = 34.dp, height = 20.dp).clip(RoundedCornerShape(50))
                        .background(if (enabled) Palette.primary else Palette.wheelDim),
                    contentAlignment = if (enabled) Alignment.CenterEnd else Alignment.CenterStart,
                ) {
                    Box(Modifier.padding(2.dp).size(16.dp).clip(RoundedCornerShape(50)).background(Color.White))
                }
            }
        }
        item {
            Text(
                if (enabled) "Keeps the clock, beeps and taps going while your wrist is down, and shows the workout on the watch face."
                else "Off: the timer only runs while it is on screen, so cues stop when your wrist drops.",
                color = Palette.label, fontSize = 11.sp, fontWeight = FontWeight.Medium,
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            )
        }
        if (enabled) {
            item {
                Text(
                    if (allowed) "Activity and sensor access: allowed" else "Activity and sensor access: not allowed yet",
                    color = if (allowed) Palette.label else Palette.error, fontSize = 11.sp, fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
                )
            }
            if (!allowed) {
                item {
                    CapsuleButton("ALLOW", fill = Palette.primary, text = Color.Black, modifier = Modifier.fillMaxWidth().padding(top = 6.dp)) {
                        requestPermissions(); version++
                    }
                }
            }
        }
    }
}
