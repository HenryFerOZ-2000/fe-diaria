package com.ozcorp.verbum.widget

enum class WidgetLayoutSize { COMPACT, MEDIUM, LARGE }

object WidgetLayoutSelector {
    fun select(minWidthDp: Int, minHeightDp: Int): WidgetLayoutSize =
        when {
            minWidthDp >= 250 && minHeightDp >= 180 -> WidgetLayoutSize.LARGE
            minWidthDp >= 250 && minHeightDp >= 100 -> WidgetLayoutSize.MEDIUM
            else -> WidgetLayoutSize.COMPACT
        }
}
