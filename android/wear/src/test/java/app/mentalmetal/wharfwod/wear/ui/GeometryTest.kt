package app.mentalmetal.wharfwod.wear.ui

import kotlin.math.sqrt
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The round-screen rules behind Google's Wear review of 19 Nov 2026
 * (vc20004 rejected: "text or controls are cut off by the screen edges").
 * The old check tested a capsule's two tangent points and passed one whose
 * rounded end stuck out of the circle; these test every point of the shape.
 */
class GeometryTest {
    // Small round 192dp (Pixel Watch 41mm, Galaxy Watch 40mm), 205, 213, large round 227, extra large 240.
    private val sizes = listOf(192f, 205f, 213f, 225f, 227f, 240f)

    /** Whether the point is inside the display, [by] dp clear of the edge. */
    private fun Geometry.holds(x: Float, y: Float, by: Float = inset - 0.01f): Boolean {
        val r = widthDp / 2
        return sqrt((x - r) * (x - r) + (y - r) * (y - r)) <= r - by
    }

    /** Samples the outline of a centred capsule of that band and width. */
    private fun capsuleOutline(g: Geometry, top: Float, bottom: Float, width: Float): List<Pair<Float, Float>> {
        val half = (bottom - top) / 2
        val cy = (top + bottom) / 2
        val cx = g.widthDp / 2
        val points = mutableListOf<Pair<Float, Float>>()
        for (side in listOf(-1f, 1f)) {
            val ex = cx + side * (width / 2 - half)
            for (step in 0..180) {
                val a = Math.toRadians(step.toDouble() - 90)
                points += Pair(ex + side * half * Math.cos(a).toFloat(), cy + half * Math.sin(a).toFloat())
            }
        }
        return points
    }

    @Test fun `the bottom row of capsules is inside the circle at every point, on every round size`() {
        for (width in sizes) {
            val g = Geometry(width)
            val bottom = width - g.bottomMargin.value
            val top = bottom - g.capsuleHeight.value
            val row = g.capsuleWidth(top, bottom)
            assertEquals(row, g.bottomRowWidth, 0.001f)
            assertTrue("width $width", capsuleOutline(g, top, bottom, row).all { (x, y) -> g.holds(x, y) })
        }
    }

    @Test fun `the START capsule is inside the circle at every point, on every round size`() {
        for (width in sizes) {
            val g = Geometry(width)
            val bottom = width - g.bottomMargin.value
            val top = bottom - g.startHeight.value
            assertTrue("width $width", capsuleOutline(g, top, bottom, g.capsuleWidth(top, bottom)).all { (x, y) -> g.holds(x, y) })
        }
    }

    @Test fun `the capsules of vc20004 were not inside the circle`() {
        // What shipped: 10_5 percent side margins, 12_5 percent under the capsule, 38dp (42dp for START) high.
        fun shipped(width: Float, height: Float): List<Pair<Float, Float>> {
            val bottom = width - width * 0.125f
            return capsuleOutline(Geometry(width), bottom - height, bottom, width - 2 * width * 0.105f)
        }
        // On the large round watch of Google's screenshots both stuck out of the display.
        for (height in listOf(38f, 42f)) {
            assertTrue("227 x $height", shipped(227f, height).any { (x, y) -> !Geometry(227f).holds(x, y, by = 0f) })
        }
        // On the small one the row of two stuck out and START sat on the edge itself.
        assertTrue(shipped(192f, 38f).any { (x, y) -> !Geometry(192f).holds(x, y, by = 0f) })
        assertTrue(shipped(192f, 42f).any { (x, y) -> !Geometry(192f).holds(x, y, by = 0.5f) })
    }

    @Test fun `a row of two capsules keeps the width for its words`() {
        // HOLD TO STOP wraps to two lines under about 72dp; RESUME at 13sp needs about 56dp.
        for (width in sizes) {
            val g = Geometry(width)
            val each = (g.bottomRowWidth - g.gap.value) / 2
            assertTrue("width $width: $each", each >= 68f)
        }
    }

    @Test fun `a rectangle is as wide as the circle is at its far edge`() {
        val g = Geometry(192f)
        val r = 96f
        val safe = r - g.inset
        // Across the middle: the full safe diameter.
        assertEquals(2 * safe, g.rectWidth(r, r), 0.001f)
        // A band near the top is narrow, and its corners are inside.
        val top = g.topMargin.value
        val width = g.rectWidth(top, top + 18f)
        assertTrue(width in 60f..100f)
        for (x in listOf(r - width / 2, r + width / 2)) for (y in listOf(top, top + 18f)) assertTrue(g.holds(x, y))
        // The same band mirrored at the bottom has the same width.
        assertEquals(width, g.rectWidth(192f - top - 18f, 192f - top), 0.001f)
        // Outside the safe circle there is no room at all.
        assertEquals(0f, g.rectWidth(0f, 10f), 0f)
    }

    @Test fun `a square screen gives the full width less the margins`() {
        val g = Geometry(200f, round = false)
        assertEquals(200f - 2 * g.inset, g.rectWidth(0f, 20f), 0.001f)
        assertEquals(200f - 2 * g.inset, g.capsuleWidth(150f, 188f), 0.001f)
    }

    @Test fun `margins scale with the screen, the capsule does not`() {
        val small = Geometry(192f)
        val large = Geometry(227f)
        assertTrue(small.topMargin < large.topMargin)
        assertTrue(small.bottomMargin < large.bottomMargin)
        assertTrue(small.capsuleHeight == large.capsuleHeight)
    }

    @Test fun `labels grow with the font size until the clock would be squeezed`() {
        val chrome = { g: Geometry -> g.topMargin.value + g.bottomMargin.value + g.capsuleHeight.value + 17f }
        // Default size: no growth, on any screen.
        for (width in sizes) assertEquals(1f, Geometry(width).let { it.labelScale(chrome(it), 46f, width * 0.2f) }, 0f)
        // A large watch has the room for the largest Wear font size (1_24).
        val large = Geometry(227f, fontScale = 1.24f)
        assertEquals(1.24f, large.labelScale(chrome(large), 46f, 227f * 0.2f), 0.001f)
        // A small one grows the labels part of the way and keeps a fifth of its height for the clock.
        val small = Geometry(192f, fontScale = 1.24f)
        val k = small.labelScale(chrome(small), 46f, 192f * 0.2f)
        assertTrue(k > 1f && k < 1.24f)
        assertTrue(192f - chrome(small) - 46f * k >= 192f * 0.2f - 0.01f)
        // A smaller font size never shrinks the lines.
        assertEquals(1f, Geometry(227f, fontScale = 0.94f).let { it.labelScale(chrome(it), 46f, 45f) }, 0f)
    }
}
