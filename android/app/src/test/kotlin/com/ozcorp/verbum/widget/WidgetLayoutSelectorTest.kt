package com.ozcorp.verbum.widget

import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetLayoutSelectorTest {
    @Test
    fun choosesCompactForSmallHosts() {
        assertEquals(WidgetLayoutSize.COMPACT, WidgetLayoutSelector.select(110, 60))
    }

    @Test
    fun choosesMediumForFourByTwoSpace() {
        assertEquals(WidgetLayoutSize.MEDIUM, WidgetLayoutSelector.select(250, 110))
    }

    @Test
    fun choosesLargeOnlyWhenHeightCanKeepMetadataVisible() {
        assertEquals(WidgetLayoutSize.LARGE, WidgetLayoutSelector.select(250, 180))
    }
}
