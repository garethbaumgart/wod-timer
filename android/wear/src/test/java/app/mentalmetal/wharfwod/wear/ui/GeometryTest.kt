package app.mentalmetal.wharfwod.wear.ui

import org.junit.Assert.assertTrue
import org.junit.Test

class GeometryTest {
    @Test fun `the bottom capsules sit inside the circle on every round Wear size`() {
        // Small round 192dp, large round 227dp, extra large 240dp (dp at the common 2x density).
        for (width in listOf(192f, 213f, 227f, 240f)) {
            val g = Geometry(width)
            assertTrue("width $width", g.fitsCircle())
        }
    }

    @Test fun `margins scale with the screen, the capsule does not`() {
        val small = Geometry(192f)
        val large = Geometry(227f)
        assertTrue(small.sideMargin < large.sideMargin)
        assertTrue(small.capsuleHeight == large.capsuleHeight)
    }
}
