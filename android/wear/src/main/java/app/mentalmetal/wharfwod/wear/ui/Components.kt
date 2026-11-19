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
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.layout.ParentDataModifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.em
import androidx.wear.compose.material.Text
import app.mentalmetal.wharfwod.wear.domain.TimelinePart
import app.mentalmetal.wharfwod.wear.domain.TimerType
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Where things may sit on a round screen, measured rather than eyeballed
 * (Google's Wear review, 19 Nov 2026: the bottom capsules' rounded ends
 * were cut by the edge on vc20004, and on a 192dp watch so were the phase
 * line and Tabata's START). Everything is in dp from the top-left of the
 * display. Nothing is drawn closer to the physical edge than [inset].
 */
data class Geometry(val widthDp: Float, val round: Boolean = true, val fontScale: Float = 1f) {
    private val radius: Float get() = widthDp / 2

    /** Half of Wear's 5.2% outer margin: the ring at the edge that stays empty. */
    val inset: Float = widthDp * 0.026f

    /** Where the first line starts: high enough to leave the clock its room, low enough that a short label fits the circle there. */
    val topMargin: Dp = (widthDp * 0.09f).dp

    /** Under the bottom capsules: at this height a row of two still has the width for its words. */
    val bottomMargin: Dp = (widthDp * 0.155f).dp
    val capsuleHeight: Dp = 38.dp
    val startHeight: Dp = 42.dp
    val gap: Dp = 6.dp

    /** The widest centred rectangle between [top] and [bottom] whose four corners stay inside the display. */
    fun rectWidth(top: Float, bottom: Float): Float {
        if (!round) return widthDp - 2 * inset
        val far = maxOf(kotlin.math.abs(top - radius), kotlin.math.abs(bottom - radius))
        val safe = radius - inset
        return if (far >= safe) 0f else 2 * kotlin.math.sqrt(safe * safe - far * far)
    }

    /**
     * The widest centred capsule in that band. Its ends are half circles,
     * so the point that reaches furthest is on the diagonal, not at a
     * corner: the old check tested the two tangent points and passed a
     * capsule that stuck out by 2dp.
     */
    fun capsuleWidth(top: Float, bottom: Float): Float {
        if (!round) return widthDp - 2 * inset
        val half = (bottom - top) / 2
        val centre = kotlin.math.abs((top + bottom) / 2 - radius)
        val reach = radius - inset - half
        return if (reach <= 0f || centre >= reach) 0f else 2 * (kotlin.math.sqrt(reach * reach - centre * centre) + half)
    }

    /** The width of the bottom row of capsules; the timeline over it is cut to the same width. */
    val bottomRowWidth: Float
        get() = capsuleWidth(widthDp - bottomMargin.value - capsuleHeight.value, widthDp - bottomMargin.value)

    /**
     * How far the label lines grow with the system font size: all the way,
     * unless that would squeeze the clock under [heroMin]. [chrome] is what
     * the screen spends on margins, bars and buttons, [labels] the label
     * lines at the default size. A line that cannot grow shrinks its text
     * to fit instead, so nothing is ever cut.
     */
    fun labelScale(chrome: Float, labels: Float, heroMin: Float): Float {
        val room = (widthDp - chrome - heroMin) / labels
        return fontScale.coerceAtMost(room).coerceAtLeast(1f)
    }
}

@Composable
fun geometry(): Geometry {
    val configuration = LocalConfiguration.current
    return Geometry(configuration.screenWidthDp.toFloat(), configuration.isScreenRound, LocalDensity.current.fontScale)
}

/** Kept for call sites that only need the gap. */
object CapsuleGeometry {
    val gap = 6.dp
}

private class RoundData(var weight: Float = 0f, var capsule: Boolean = false)

interface RoundColumnScope {
    /** Takes a share of the height the fixed children leave. */
    fun Modifier.fill(weight: Float = 1f): Modifier

    /** The child is a capsule (or a row of them), so it may be as wide as a capsule fits. */
    fun Modifier.capsule(): Modifier
}

private object RoundColumnScopeInstance : RoundColumnScope {
    override fun Modifier.fill(weight: Float): Modifier = this.then(object : ParentDataModifier {
        override fun Density.modifyParentData(parentData: Any?) = ((parentData as? RoundData) ?: RoundData()).also { it.weight = weight }
    })

    override fun Modifier.capsule(): Modifier = this.then(object : ParentDataModifier {
        override fun Density.modifyParentData(parentData: Any?) = ((parentData as? RoundData) ?: RoundData()).also { it.capsule = true }
    })
}

/**
 * A screen-high column for a round display: children run top to bottom,
 * centred, and each one is given no more width than the circle has at the
 * child's own height (see [Geometry.rectWidth], [Geometry.capsuleWidth]).
 * A child that fills its width therefore ends exactly where the screen
 * lets it, on a 192dp watch and a 240dp one alike. Children need a height
 * of their own (a slot, a spacer, a capsule) or a [RoundColumnScope.fill].
 */
@Composable
fun RoundColumn(top: Dp, bottom: Dp, modifier: Modifier = Modifier, content: @Composable RoundColumnScope.() -> Unit) {
    // The circle is the screen's, not the column's: a column inside a
    // padded list is narrower than the display it is centred on.
    val g = geometry()
    Layout(content = { RoundColumnScopeInstance.content() }, modifier = modifier) { measurables, constraints ->
        val w = constraints.maxWidth
        val h = constraints.maxHeight
        val data = measurables.map { it.parentData as? RoundData }
        val fixed = measurables.mapIndexed { i, m -> if ((data[i]?.weight ?: 0f) > 0f) 0 else m.minIntrinsicHeight(w) }
        val weights = data.sumOf { (it?.weight ?: 0f).toDouble() }.toFloat()
        val free = (h - top.roundToPx() - bottom.roundToPx() - fixed.sum()).coerceAtLeast(0)
        var y = top.roundToPx()
        val placed = measurables.mapIndexed { i, m ->
            val weight = data[i]?.weight ?: 0f
            val height = if (weight > 0f) (free * weight / weights).toInt() else fixed[i]
            val bandTop = y.toDp().value
            val bandBottom = (y + height).toDp().value
            val width = if (data[i]?.capsule == true) g.capsuleWidth(bandTop, bandBottom) else g.rectWidth(bandTop, bandBottom)
            val maxWidth = minOf(w, (width * density).toInt()).coerceAtLeast(0)
            val placeable = m.measure(Constraints(minWidth = 0, maxWidth = maxWidth, minHeight = height, maxHeight = height))
            val at = Triple(placeable, (w - placeable.width) / 2, y)
            y += height
            at
        }
        layout(w, h) { placed.forEach { (placeable, x, top) -> placeable.place(x, top) } }
    }
}

/** A line of the column with a height of its own, its content centred. */
@Composable
fun Slot(height: Dp, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Box(modifier.height(height).fillMaxWidth(), contentAlignment = Alignment.Center) { content() }
}

/**
 * Text that is never cut off: it is drawn at [size] (which follows the
 * system font size) when that fits the room it is given, and at the largest
 * smaller size when it does not. With [maxLines] above one it wraps first.
 */
@Composable
fun FitText(
    text: String,
    color: Color,
    size: TextUnit,
    modifier: Modifier = Modifier,
    weight: FontWeight = Heavy,
    letterSpacing: TextUnit = 0.em,
    maxLines: Int = 1,
) {
    BasicText(
        text = text,
        modifier = modifier,
        style = TextStyle(
            color = color,
            fontSize = size,
            fontWeight = weight,
            letterSpacing = letterSpacing,
            lineHeight = 1.15.em,
            textAlign = TextAlign.Center,
            platformStyle = PlatformTextStyle(includeFontPadding = false),
        ),
        maxLines = maxLines,
        softWrap = maxLines > 1,
        overflow = TextOverflow.Clip,
        autoSize = TextAutoSize.StepBased(minFontSize = 5.sp, maxFontSize = size, stepSize = 0.25.sp),
    )
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
        FitText(title, color = text, size = 13.sp, letterSpacing = 0.06.em, modifier = Modifier.padding(horizontal = 8.dp))
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
        // The two lines share the capsule's height, so a larger font size
        // grows them until they fill it and no further.
        Column(Modifier.fillMaxHeight().padding(horizontal = 14.dp, vertical = 3.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Box(Modifier.weight(if (subtitle != null) 1.5f else 1f), contentAlignment = if (subtitle != null) Alignment.BottomCenter else Alignment.Center) {
                FitText("START", color = Color.Black, size = 15.sp, letterSpacing = 0.065.em)
            }
            if (subtitle != null) {
                Box(Modifier.weight(1f), contentAlignment = Alignment.TopCenter) {
                    FitText(subtitle, color = Color.Black.copy(alpha = 0.7f), size = 10.sp, weight = FontWeight.Bold)
                }
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
        // Two lines where one will not fit (half the row on a small watch).
        FitText("HOLD TO STOP", color = Palette.error, size = 11.sp, letterSpacing = 0.055.em, maxLines = 2, modifier = Modifier.padding(horizontal = 8.dp))
    }
}

/** A small caps label in the muted grey. */
@Composable
fun Caption(text: String, color: Color = Palette.label, size: TextUnit = 11.sp, modifier: Modifier = Modifier) {
    FitText(text, color = color, size = size, weight = FontWeight.Bold, letterSpacing = 0.09.em, modifier = modifier)
}
