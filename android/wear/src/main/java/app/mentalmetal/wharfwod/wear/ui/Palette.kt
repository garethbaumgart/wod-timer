package app.mentalmetal.wharfwod.wear.ui

import androidx.compose.ui.graphics.Color
import app.mentalmetal.wharfwod.wear.domain.TimerSession
import app.mentalmetal.wharfwod.wear.domain.TimerState
import app.mentalmetal.wharfwod.wear.domain.TimerType

/** The 2.0 palette, one meaning per colour, shared with the phone and the Apple Watch app. */
object Palette {
    val prepare = Color.White
    val work = Color(0xFF00FF88)
    val rest = Color(0xFFFF0088)
    val paused = Color(0xFF8A8A93)
    val label = Color(0xFF9A9AA2)
    val dim = Color(0xFF6A6A72)
    val wheelDim = Color(0xFF3A3D58)
    val error = Color(0xFFFF4444)
    val primary = Color(0xFF00FF88)
    val brand = Color(0xFFFF6B1A)
    val track = Color(0xFF24253A)
    val soft = Color(0xFF16172A)
    val stopInk = Color(0xFF1A0E14)
    val ink = Color(0xFF050510)

    val modeOrder = listOf("fortime", "emom", "amrap", "tabata")

    fun mode(code: String): Color = when (code) {
        "fortime" -> Color(0xFFFF6B1A)
        "emom" -> Color(0xFFFF0088)
        "amrap" -> Color(0xFF00AAFF)
        else -> Color(0xFF00FF88)
    }

    fun mode(type: TimerType): Color = mode(type.typeCode)

    /** White in get ready, Tabata work green / rest pink, otherwise the workout's colour. */
    fun live(session: TimerSession): Color {
        val phase = LiveRules.effectivePhase(session)
        if (phase == TimerState.PREPARING) return prepare
        if (session.workout.timerType is TimerType.Tabata) return if (phase == TimerState.RESTING) rest else work
        return mode(session.workout.timerType)
    }

    fun tone(tone: LiveRules.Tone, session: TimerSession): Color = when (tone) {
        LiveRules.Tone.PREPARE -> prepare
        LiveRules.Tone.WORK -> work
        LiveRules.Tone.REST -> rest
        LiveRules.Tone.PAUSED -> paused
        LiveRules.Tone.MODE -> mode(session.workout.timerType)
    }

    fun title(code: String): String = when (code) {
        "fortime" -> "FOR TIME"
        "emom" -> "EMOM"
        "amrap" -> "AMRAP"
        else -> "TABATA"
    }
}
