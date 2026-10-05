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
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.rotary.onRotaryScrollEvent
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.Text
import app.mentalmetal.wharfwod.wear.application.TimerViewModel
import app.mentalmetal.wharfwod.wear.domain.TimerSession
import app.mentalmetal.wharfwod.wear.domain.TimerState
import app.mentalmetal.wharfwod.wear.domain.TimerType

/**
 * Live timer: one clock in the workout's colour, a phase word when there is
 * one, the round or the AMRAP score, the timeline filling, the actions as
 * bottom capsules. Tap above the capsules: skips get ready, counts an
 * AMRAP round. Stop needs a hold, on the paused screen and in get ready.
 */
@Composable
fun LiveScreen(vm: TimerViewModel, ambient: Boolean, onDone: () -> Unit) {
    val session = vm.session
    LaunchedEffect(vm.phase) { if (vm.phase == TimerState.READY) onDone() }
    if (session == null) {
        Box(Modifier.fillMaxSize().background(Color.Black))
        return
    }
    when (vm.phase) {
        TimerState.COMPLETED -> CompletedScreen(vm, session)
        TimerState.PAUSED -> LiveLayout(session, counted = true, paused = true, ambient = ambient, onCanvasTap = { vm.resume() }) {
            Row(horizontalArrangement = Arrangement.spacedBy(CapsuleGeometry.gap)) {
                HoldToStopCapsule(Modifier.weight(1f)) { vm.stop() }
                CapsuleButton("RESUME", fill = Palette.mode(session.workout.timerType), text = Color.Black, modifier = Modifier.weight(1f)) { vm.resume() }
            }
        }
        else -> LiveLayout(
            session, counted = vm.hasCountedRound, paused = false, ambient = ambient,
            onCanvasTap = {
                when (session.state) {
                    TimerState.PREPARING -> vm.skipPrep()
                    TimerState.RUNNING -> vm.countRound()
                    else -> {}
                }
            },
        ) {
            when {
                session.state == TimerState.PREPARING -> HoldToStopCapsule(Modifier.fillMaxWidth()) { vm.cancelPrep() }
                session.workout.timerType is TimerType.ForTime -> Row(horizontalArrangement = Arrangement.spacedBy(CapsuleGeometry.gap)) {
                    CapsuleButton("FINISH", fill = Color.White, text = Color.Black, modifier = Modifier.weight(1f)) { vm.finish() }
                    CapsuleButton("PAUSE", fill = Palette.soft, modifier = Modifier.weight(1f)) { vm.pause() }
                }
                else -> CapsuleButton("PAUSE", fill = Palette.soft, modifier = Modifier.fillMaxWidth()) { vm.pause() }
            }
        }
    }
}

@Composable
private fun LiveLayout(
    session: TimerSession,
    counted: Boolean,
    paused: Boolean,
    ambient: Boolean,
    onCanvasTap: () -> Unit,
    buttons: @Composable () -> Unit,
) {
    val color = if (ambient) Palette.paused else Palette.live(session)
    val type = session.workout.timerType
    val g = geometry()
    Box(Modifier.fillMaxSize().background(Color.Black)) {
        if (!ambient) {
            Box(
                Modifier.fillMaxSize().background(
                    Brush.radialGradient(listOf(color.copy(alpha = if (paused) 0.08f else 0.22f), Color.Black)),
                ),
            )
        }
        Column(
            Modifier
                .fillMaxSize()
                .padding(horizontal = g.sideMargin)
                .padding(top = 10.dp, bottom = g.bottomMargin),
        ) {
            Column(Modifier.weight(1f).fillMaxWidth().clickable(onClick = onCanvasTap), horizontalAlignment = Alignment.CenterHorizontally) {
                PhaseLine(session)
                BigClock(
                    text = LiveRules.clockText(session), reference = LiveRules.referenceClock(type), color = color.copy(alpha = if (paused) 0.45f else 1f),
                    modifier = Modifier.weight(1f).fillMaxWidth(),
                )
                ScoreSlot(session, counted)
                Spacer(Modifier.height(8.dp))
                TimelineBar(type.timelineParts, Palette.mode(type), height = 5.dp, elapsed = LiveRules.elapsedSeconds(session))
                Spacer(Modifier.height(8.dp))
            }
            Box(Modifier.height(g.capsuleHeight)) { buttons() }
        }
    }
}

/** The fixed-height phase line over the clock, blank when there is no phase to name, so the digits never jump. */
@Composable
private fun PhaseLine(session: TimerSession) {
    Box(Modifier.height(18.dp), contentAlignment = Alignment.Center) {
        LiveRules.phaseWord(session)?.let { word ->
            Text(word.text, color = Palette.tone(word.tone, session), fontSize = 13.sp, fontWeight = Heavy, letterSpacing = 1.5.sp, maxLines = 1)
        }
    }
}

/** The second line under the clock: the round, the AMRAP score, the cap, or a hint, in one fixed slot. */
@Composable
private fun ScoreSlot(session: TimerSession, counted: Boolean) {
    Box(Modifier.height(28.dp), contentAlignment = Alignment.Center) {
        val type = session.workout.timerType
        val total = session.totalRounds
        when {
            session.state == TimerState.PREPARING -> Caption("TAP TO SKIP", size = 12.sp)
            total != null -> Text("${session.currentRound}/$total", color = Color.White, fontSize = 24.sp, fontWeight = Heavy)
            type is TimerType.Amrap -> if (session.countedRounds == 0 && !counted && session.state == TimerState.RUNNING) {
                Caption("TAP TO COUNT", size = 12.sp)
            } else {
                Row(verticalAlignment = Alignment.Bottom) {
                    Text("${session.countedRounds}", color = Color.White, fontSize = 24.sp, fontWeight = Heavy)
                    Spacer(Modifier.padding(horizontal = 2.dp))
                    Caption("ROUNDS", size = 10.sp, modifier = Modifier.padding(bottom = 4.dp))
                }
            }
            type is TimerType.ForTime && type.countUp -> Caption("CAP ${type.timeCap.clock}", size = 13.sp)
            else -> {}
        }
    }
}

/**
 * End screen: the status word, the config line, the hero in the workout's
 * colour (For Time the time, EMOM / Tabata the rounds, AMRAP the count,
 * fixed with the rotary), the label, the timeline where it ended, then
 * AGAIN | DONE. A capped For Time shows no score.
 */
@Composable
private fun CompletedScreen(vm: TimerViewModel, session: TimerSession) {
    val type = session.workout.timerType
    val accent = Palette.mode(type)
    val summary = LiveRules.endSummary(session, vm.endedEarly, vm.endedAtTimeCap)
    var accumulated by remember { mutableStateOf(0f) }
    val focusRequester = remember { FocusRequester() }
    val adjustable = type is TimerType.Amrap
    val g = geometry()
    LaunchedEffect(adjustable) { if (adjustable) focusRequester.requestFocus() }
    Column(
        Modifier
            .fillMaxSize()
            .background(Color.Black)
            .then(
                if (adjustable) Modifier.onRotaryScrollEvent { e ->
                    accumulated += e.verticalScrollPixels
                    while (accumulated >= 40f) { vm.adjustRounds(1); accumulated -= 40f }
                    while (accumulated <= -40f) { vm.adjustRounds(-1); accumulated += 40f }
                    true
                }.focusRequester(focusRequester).focusable() else Modifier,
            )
            .padding(horizontal = g.sideMargin)
            .padding(top = 14.dp, bottom = g.bottomMargin),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(summary.word, color = Color.White, fontSize = 16.sp, fontWeight = Heavy, maxLines = 1)
        Caption(LiveRules.configLine(type), size = 10.sp)
        if (summary.hero != null) {
            BigClock(summary.hero, reference = "10:00", color = accent, modifier = Modifier.weight(1f).fillMaxWidth())
            Caption(summary.label, size = 10.sp)
            Spacer(Modifier.height(6.dp))
        } else {
            Spacer(Modifier.weight(1f))
        }
        TimelineBar(type.timelineParts, accent, height = 5.dp, elapsed = LiveRules.elapsedSeconds(session))
        Spacer(Modifier.height(if (summary.hero != null) 8.dp else 0.dp))
        if (summary.hero == null) Spacer(Modifier.weight(1f))
        Row(horizontalArrangement = Arrangement.spacedBy(CapsuleGeometry.gap)) {
            CapsuleButton("AGAIN", fill = accent, text = Color.Black, modifier = Modifier.weight(1f)) { vm.restart() }
            CapsuleButton("DONE", fill = Palette.soft, modifier = Modifier.weight(1f)) { vm.reset() }
        }
    }
}
