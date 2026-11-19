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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.PlatformTextStyle
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.em
import androidx.wear.compose.foundation.lazy.AutoCenteringParams
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.ScalingLazyListScope
import androidx.wear.compose.foundation.lazy.ScalingLazyListState
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material.PositionIndicator
import androidx.wear.compose.material.Scaffold
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

/**
 * Home. The first page is the mark and all four timers at once, two by two
 * in the phone's order, each with its remembered workout and its timeline
 * (19 Nov 2026: Gareth wanted every option on the first screen; as a list a
 * round watch showed one and a half). Voice and Health are one scroll down.
 */
@Composable
fun HomeScreen(app: WodApp, onMode: (String) -> Unit, onVoice: () -> Unit, onHealth: () -> Unit) {
    val state = rememberScalingLazyListState(initialCenterItemIndex = 0)
    val memory = app.setupMemory
    ScrollingList(state, centreFirst = true) {
        item { ModeGrid(memory, onMode, Modifier.fillParentMaxHeight()) }
        item { SettingsRow("Voice", app.audio.settings.label, onVoice) }
        item { SettingsRow("Health", healthLabel(app.tracker), onHealth) }
    }
}

/**
 * Every list of the app: a scaling column with the scroll bar Wear expects
 * while a list moves (quality rule WO-V8; its absence was one of the three
 * findings of Google's Wear review on 19 Nov 2026), and the rotary
 * scrolling it.
 */
@Composable
private fun ScrollingList(state: ScalingLazyListState, centreFirst: Boolean = false, content: ScalingLazyListScope.() -> Unit) {
    Scaffold(
        modifier = Modifier.background(Color.Black),
        positionIndicator = { PositionIndicator(scalingLazyListState = state) },
    ) {
        ScalingLazyColumn(
            state = state,
            modifier = Modifier.fillMaxSize(),
            autoCentering = AutoCenteringParams(itemIndex = if (centreFirst) 0 else 1),
            content = content,
        )
    }
}

fun healthLabel(tracker: ExerciseTracker): String = when {
    !tracker.hasPermission -> "Not allowed"
    tracker.recordWorkout -> "Records"
    else -> "Timer only"
}

/**
 * The page is as high as the screen and sits on a [RoundColumn], so the
 * mark, both rows of tiles and the hint under them are each as wide as the
 * circle is at their height: on a 192dp watch and a 227dp one alike the
 * four tiles are whole.
 */
@Composable
private fun ModeGrid(memory: SetupMemory, onMode: (String) -> Unit, modifier: Modifier = Modifier) {
    val g = geometry()
    val rows = Palette.modeOrder.chunked(2)
    val names = Palette.modeOrder.map { Palette.title(it) }
    val summaries = Palette.modeOrder.map { memory.summary(it) }
    RoundColumn(top = g.topMargin, bottom = g.topMargin, modifier = modifier.fillMaxWidth()) {
        Slot(20.dp) { Wordmark() }
        Spacer(Modifier.height(GRID_GAP))
        rows.forEachIndexed { i, row ->
            if (i > 0) Spacer(Modifier.height(GRID_GAP))
            Row(Modifier.fill().fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(GRID_GAP)) {
                for (code in row) {
                    ModeTile(code, memory.summary(code), memory.shape(code), names, summaries, Modifier.weight(1f).fillMaxHeight()) { onMode(code) }
                }
            }
        }
        Spacer(Modifier.height(GRID_GAP))
        Slot(20.dp) { MoreBelow() }
    }
}

private val GRID_GAP = 5.dp

/** One line, coloured as the phone's mark. Artwork, so sized in dp (it does not follow the system font size), and fitted to the narrow top of the circle. */
@Composable
private fun Wordmark() {
    val size = with(LocalDensity.current) { 15.dp.toSp() }
    val mark = buildAnnotatedString {
        withStyle(SpanStyle(color = Color.White)) { append("WHARF ") }
        withStyle(SpanStyle(color = Palette.work)) { append("WOD") }
        withStyle(SpanStyle(color = Palette.rest)) { append(".") }
    }
    BasicText(
        text = mark,
        style = TextStyle(fontSize = size, fontWeight = Heavy, letterSpacing = 0.06.em, platformStyle = PlatformTextStyle(includeFontPadding = false)),
        maxLines = 1, softWrap = false,
        autoSize = TextAutoSize.StepBased(minFontSize = 5.sp, maxFontSize = size, stepSize = 0.25.sp),
        modifier = Modifier.semantics { contentDescription = "Wharf WOD" },
    )
}

/** A quiet chevron: Voice and Health are below. */
@Composable
private fun MoreBelow() {
    Canvas(Modifier.size(width = 14.dp, height = 6.dp)) {
        val stroke = 1.6.dp.toPx()
        drawLine(Palette.dim, Offset(0f, 0f), Offset(size.width / 2, size.height), stroke, StrokeCap.Round)
        drawLine(Palette.dim, Offset(size.width / 2, size.height), Offset(size.width, 0f), stroke, StrokeCap.Round)
    }
}

/**
 * A timer: its name in its colour, the remembered workout, the timeline.
 * The four names share one size and so do the four summaries: the largest
 * at which the longest of them fits a tile, so no tile reads bigger than
 * its neighbour and no word is cut at any font size.
 */
@Composable
private fun ModeTile(
    code: String,
    summary: String,
    shape: List<app.mentalmetal.wharfwod.wear.domain.TimelinePart>,
    names: List<String>,
    summaries: List<String>,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    val accent = Palette.mode(code)
    BoxWithConstraints(
        modifier
            .clip(RoundedCornerShape(12.dp))
            .background(Palette.soft)
            .clickable(onClick = onClick)
            .semantics { contentDescription = "${Palette.title(code)}, $summary" },
    ) {
        val inner = maxWidth - 14.dp
        val nameSize = sharedSize(names, 13.sp, Heavy, inner)
        val summarySize = sharedSize(summaries, 10.sp, FontWeight.SemiBold, inner)
        Column(Modifier.fillMaxSize().padding(horizontal = 7.dp, vertical = 6.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Box(Modifier.weight(1.25f), contentAlignment = Alignment.Center) {
                FitText(Palette.title(code), color = accent, size = nameSize)
            }
            Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                FitText(summary, color = Color.White.copy(alpha = 0.78f), size = summarySize, weight = FontWeight.SemiBold)
            }
            Spacer(Modifier.height(3.dp))
            TimelineBar(shape, accent, height = 3.dp)
        }
    }
}

/** The largest size up to [nominal] at which every one of [texts] fits [width] on one line. */
@Composable
private fun sharedSize(texts: List<String>, nominal: androidx.compose.ui.unit.TextUnit, weight: FontWeight, width: androidx.compose.ui.unit.Dp): androidx.compose.ui.unit.TextUnit {
    val measurer = rememberTextMeasurer()
    val density = LocalDensity.current
    return remember(texts, nominal, width, density) {
        val style = TextStyle(fontSize = nominal, fontWeight = weight, platformStyle = PlatformTextStyle(includeFontPadding = false))
        val widest = texts.maxOf { measurer.measure(it, style, maxLines = 1, softWrap = false).size.width }
        val room = with(density) { width.toPx() }
        if (widest <= room) nominal else nominal * (room / widest * 0.97f)
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
        Text(title, color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
        Spacer(Modifier.width(8.dp))
        Text(value, color = Palette.label, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.End)
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
 * Setup: the mode's values (Tabata's work and rest side by side), the
 * focused one white; the rotary (bezel or crown) moves it, a tap on
 * another value focuses it. Every change is remembered. START carries the
 * total. Laid out on a [RoundColumn], so nothing leaves the circle.
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
    val k = g.labelScale(
        chrome = g.topMargin.value + g.bottomMargin.value + g.startHeight.value,
        labels = SETUP_TITLE,
        heroMin = g.widthDp * 0.4f,
    )

    @Composable
    fun Cell(i: Int, size: androidx.compose.ui.unit.TextUnit, modifier: Modifier = Modifier) {
        val f = fields[i]
        // The label keeps its size; the value takes what the cell has left
        // and shrinks to it, so three values fit a 192dp watch and none is cut.
        Column(
            modifier.clickable { focused = i }.semantics { contentDescription = "${f.label} ${f.display(values[i])}" },
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Caption(f.label, color = f.color, size = 10.sp)
            FitText(f.display(values[i]), color = if (focused == i) Color.White else Color.White.copy(alpha = 0.45f), size = size)
        }
    }

    RoundColumn(
        top = g.topMargin, bottom = g.bottomMargin,
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .onRotaryScrollEvent { event ->
                accumulated += event.verticalScrollPixels
                while (accumulated >= 40f) { change(1); accumulated -= 40f }
                while (accumulated <= -40f) { change(-1); accumulated += 40f }
                true
            }
            .focusRequester(focusRequester)
            .focusable(),
    ) {
        Slot((SETUP_TITLE * k).dp) { Caption(Palette.title(code), color = Palette.mode(code), size = 12.sp) }
        Column(Modifier.fill().fillMaxWidth(), verticalArrangement = Arrangement.Center, horizontalAlignment = Alignment.CenterHorizontally) {
            when (fields.size) {
                1 -> Cell(0, 44.sp, Modifier.weight(1f, fill = false))
                2 -> {
                    Cell(0, 30.sp, Modifier.weight(1f, fill = false))
                    Cell(1, 30.sp, Modifier.weight(1f, fill = false))
                }
                // Tabata: work and rest side by side where the circle is
                // widest, rounds under them. Stacked three deep they pushed
                // START off a 192dp screen.
                else -> {
                    Row(Modifier.weight(1f, fill = false).fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
                        Cell(0, 30.sp, Modifier.weight(1f))
                        Cell(1, 30.sp, Modifier.weight(1f))
                    }
                    Cell(2, 30.sp, Modifier.weight(1f, fill = false))
                }
            }
            if (code == "fortime") {
                Caption(
                    if (countUp) "COUNTS UP" else "COUNTS DOWN", size = 10.sp,
                    modifier = Modifier.padding(top = 2.dp).clickable { countUp = !countUp; memory.save(type(code, values, countUp)) },
                )
            }
        }
        val subtitle = when (current) {
            is TimerType.Amrap -> null
            is TimerType.ForTime -> if (countUp) "up to the cap" else "down from the cap"
            else -> "${current.estimatedDuration.clock} total"
        }
        StartButton(subtitle, Modifier.capsule()) {
            memory.save(current)
            onStart(Workout.of(current))
        }
    }
}

private const val SETUP_TITLE = 16f

// MARK: Voice

/** One list, as on the phone: three voices, Random, Beeps only, Silent; choosing one plays a sample. Under them the sound check. */
@Composable
fun VoiceScreen(audio: WearAudioService) {
    val state = rememberScalingLazyListState()
    var version by remember { mutableIntStateOf(0) }
    var checkResult by remember { mutableStateOf("Plays a beep and a line") }
    val settings = audio.settings
    val current: String = run { version; settings.label }
    ScrollingList(state) {
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
                modifier = Modifier.padding(horizontal = 14.dp, vertical = 6.dp),
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
            Text(name, color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            Text(detail, color = Palette.label, fontSize = 11.sp, fontWeight = FontWeight.Medium)
        }
        if (selected) Text("✓", color = accent, fontSize = 15.sp, fontWeight = FontWeight.Bold)
    }
}

// MARK: Health

/**
 * Health (24 Oct 2026): the timer runs on its own by default and stays out
 * of the way of a workout another app is recording. One opt-in switch makes
 * the WOD the watch's recognised exercise, then where the permission stands
 * (the foreground service that keeps the timer alive needs it either way).
 */
@Composable
fun HealthScreen(tracker: ExerciseTracker, requestPermissions: () -> Unit) {
    val state = rememberScalingLazyListState()
    var version by remember { mutableIntStateOf(0) }
    val enabled = run { version; tracker.recordWorkout }
    val allowed = run { version; tracker.hasPermission }
    ScrollingList(state) {
        item { Caption("HEALTH", color = Palette.brand, size = 12.sp, modifier = Modifier.padding(top = 4.dp)) }
        item {
            Row(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(Palette.soft)
                    .clickable { tracker.setRecordWorkout(!enabled); version++ }
                    .semantics { contentDescription = "Record as workout, ${if (enabled) "on" else "off"}" }
                    .padding(horizontal = 14.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f)) {
                    Text("Record as workout", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                    Text("Off: timer only", color = Palette.label, fontSize = 11.sp, fontWeight = FontWeight.Medium)
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
                if (enabled) "GO starts an exercise, so the watch counts the WOD as a workout. Stays out of the way if another app is already recording one."
                else "The timer keeps going while your wrist is down, and a workout you are recording in another app keeps going too.",
                color = Palette.label, fontSize = 11.sp, fontWeight = FontWeight.Medium,
                modifier = Modifier.padding(horizontal = 14.dp, vertical = 4.dp),
            )
        }
        item {
            Text(
                if (allowed) "Activity access: allowed" else "Activity access: not allowed yet, so the timer stops when the wrist drops",
                color = if (allowed) Palette.label else Palette.error, fontSize = 11.sp, fontWeight = FontWeight.Medium,
                modifier = Modifier.padding(horizontal = 14.dp, vertical = 2.dp),
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
