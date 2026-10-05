package app.mentalmetal.wharfwod.wear.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.PlatformTextStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.waitForUpOrCancellation
import androidx.wear.compose.material.Text
import app.mentalmetal.wharfwod.wear.domain.TimelinePart
import app.mentalmetal.wharfwod.wear.domain.TimerType
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Bottom capsule geometry for a round screen, measured rather than eyeballed:
 * a capsule of height [capsuleHeight] sitting [bottomMargin] above the edge
 * with [sideMargin] each side has both its rounded ends and its straight
 * sides inside the circle on every Wear size (see GeometryTest). Margins
 * are fractions of the screen width, so a 192dp and a 227dp watch both fit.
 */
data class Geometry(val widthDp: Float) {
    val sideMargin: Dp = (widthDp * 0.105f).dp
    val bottomMargin: Dp = (widthDp * 0.125f).dp
    val capsuleHeight: Dp = 38.dp
    val startHeight: Dp = 42.dp
    val gap: Dp = 6.dp

    /** Whether a bottom capsule's extreme points fall inside the circle. */
    fun fitsCircle(): Boolean {
        val r = widthDp / 2
        val s = widthDp * 0.105f
        val b = widthDp * 0.125f
        val h = 38f
        fun inside(dx: Float, dy: Float) = dx * dx + dy * dy <= r * r
        return inside(r - s - h / 2, r - b) && inside(r - s, r - b - h / 2)
    }
}

@Composable
fun geometry(): Geometry = Geometry(LocalConfiguration.current.screenWidthDp.toFloat())

/** Kept for call sites that only need the gap. */
object CapsuleGeometry {
    val gap = 6.dp
}

val Heavy = FontWeight.Black

/**
 * The giant clock: as big as the space allows, sized once from `reference`
 * (the longest value the workout can show) so it never refits as it counts.
 */
@Composable
fun BigClock(text: String, reference: String?, color: Color, modifier: Modifier = Modifier) {
    BoxWithConstraints(modifier, contentAlignment = Alignment.Center) {
        val density = LocalDensity.current
        val ref = reference ?: text
        // The line box is trimmed to one em (no font padding), so the text
        // never spills into the slots above and below; a slash reaches
        // further than digits, so it gets a taller allowance.
        val heightEm = if (ref.contains("/")) 1.05f else 0.95f
        val wPx = with(density) { maxWidth.toPx() }
        val hPx = with(density) { maxHeight.toPx() }
        val sizePx = minOf(wPx / maxOf(ems(ref), 0.6f), hPx / heightEm).coerceAtLeast(12f)
        val fontSize: TextUnit = with(density) { sizePx.toSp() }
        Text(
            text = text,
            style = TextStyle(
                fontSize = fontSize,
                lineHeight = fontSize,
                fontWeight = Heavy,
                color = color,
                letterSpacing = (-0.02).em(fontSize),
                platformStyle = PlatformTextStyle(includeFontPadding = false),
                lineHeightStyle = LineHeightStyle(LineHeightStyle.Alignment.Center, LineHeightStyle.Trim.Both),
            ),
            maxLines = 1,
            softWrap = false,
            overflow = TextOverflow.Visible,
            modifier = Modifier.semantics { contentDescription = text },
        )
    }
}

private fun Double.em(size: TextUnit): TextUnit = (size.value * this).sp

/** Advance widths of the heavy sans digits, in ems (tabular). */
fun ems(text: String): Float = text.fold(0f) { acc, c ->
    acc + when (c) {
        ':' -> 0.3f
        '/' -> 0.42f
        else -> 0.6f
    }
}

/** The workout drawn as blocks, widths by seconds; rest pink, the rest in the accent. */
@Composable
fun TimelineBar(
    parts: List<TimelinePart>,
    accent: Color,
    height: androidx.compose.ui.unit.Dp = 6.dp,
    elapsed: Double? = null,
    modifier: Modifier = Modifier,
) {
    Canvas(modifier.fillMaxWidth().height(height)) {
        val gapPx = (if (parts.size > 12) 1.5f else 2f) * density
        val total = maxOf(1, parts.sumOf { it.seconds }).toFloat()
        val free = size.width - gapPx * maxOf(0, parts.size - 1)
        val fractions = if (elapsed == null) parts.map { 1.0 } else TimerType.fillFractions(parts, elapsed)
        var x = 0f
        val radius = CornerRadius(size.height / 3)
        parts.forEachIndexed { i, part ->
            val w = maxOf(1f, free * part.seconds / total)
            drawRoundRect(Palette.track, Offset(x, 0f), Size(w, size.height), radius)
            val fill = (w * fractions[i]).toFloat()
            if (fill > 0f) {
                drawRoundRect(if (part.isRest) Palette.rest else accent, Offset(x, 0f), Size(fill, size.height), radius)
            }
            x += w + gapPx
        }
    }
}

/** One full-width capsule: PAUSE, FINISH, RESUME, AGAIN, DONE. */
@Composable
fun CapsuleButton(
    title: String,
    fill: Color,
    text: Color = Color.White,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    val height = geometry().capsuleHeight
    Box(
        modifier
            .height(height)
            .clip(RoundedCornerShape(50))
            .background(fill)
            .clickable(onClick = onClick)
            .semantics { contentDescription = title },
        contentAlignment = Alignment.Center,
    ) {
        Text(title, color = text, fontSize = 13.sp, fontWeight = Heavy, letterSpacing = 0.8.sp, maxLines = 1)
    }
}

/** The green START, with the workout's total inside it. */
@Composable
fun StartButton(subtitle: String?, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Box(
        modifier
            .fillMaxWidth()
            .height(geometry().startHeight)
            .clip(RoundedCornerShape(50))
            .background(Palette.primary)
            .clickable(onClick = onClick)
            .semantics { contentDescription = if (subtitle != null) "Start, $subtitle" else "Start" },
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text("START", color = Color.Black, fontSize = 15.sp, fontWeight = Heavy, letterSpacing = 1.sp)
            if (subtitle != null) {
                Text(subtitle, color = Color.Black.copy(alpha = 0.7f), fontSize = 10.sp, fontWeight = FontWeight.Bold, maxLines = 1)
            }
        }
    }
}

/** End control that must be held (0.8s): the capsule fills red while the finger stays down. */
@Composable
fun HoldToStopCapsule(modifier: Modifier = Modifier, onConfirmed: () -> Unit) {
    val fill = remember { Animatable(0f) }
    val scope = rememberCoroutineScope()
    var confirmed by remember { mutableStateOf(false) }
    val height = geometry().capsuleHeight
    Box(
        modifier
            .height(height)
            .clip(RoundedCornerShape(50))
            .background(Palette.stopInk)
            .semantics { contentDescription = "Stop workout. Hold to confirm." }
            .pointerInput(Unit) {
                awaitEachGesture {
                    awaitFirstDown()
                    confirmed = false
                    val job = scope.launch {
                        fill.animateTo(1f, tween(800))
                        confirmed = true
                        onConfirmed()
                    }
                    waitForUpOrCancellation()
                    if (!confirmed) {
                        job.cancel()
                        scope.launch { fill.animateTo(0f, tween(150)) }
                    }
                }
            },
        contentAlignment = Alignment.Center,
    ) {
        Box(
            Modifier
                .fillMaxWidth(fill.value)
                .height(height)
                .align(Alignment.CenterStart)
                .background(Palette.error.copy(alpha = 0.35f)),
        )
        Text("HOLD TO STOP", color = Palette.error, fontSize = 11.sp, fontWeight = Heavy, letterSpacing = 0.6.sp, maxLines = 1)
    }
}

/** A small caps label in the muted grey. */
@Composable
fun Caption(text: String, color: Color = Palette.label, size: TextUnit = 11.sp, modifier: Modifier = Modifier) {
    Text(text, color = color, fontSize = size, fontWeight = FontWeight.Bold, letterSpacing = 1.sp, maxLines = 1, modifier = modifier)
}
