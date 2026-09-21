package com.ozcorp.verbum.widget

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class DailyVerseResolverTest {
    private val records = listOf(
        DailyVerseRecord(
            "PSA",
            "Salmos",
            23,
            1,
            "Salmos 23:1",
            "A",
            "RV1909",
        ),
        DailyVerseRecord(
            "JHN",
            "Juan",
            3,
            16,
            "Juan 3:16",
            "B",
            "RV1909",
        ),
        DailyVerseRecord(
            "ROM",
            "Romanos",
            8,
            28,
            "Romanos 8:28",
            "C",
            "RV1909",
        ),
    )

    @Test
    fun usesTheSameYyyymmddModuloFormulaAsFlutter() {
        val date = LocalDate.of(2026, 9, 21)

        assertEquals(
            20260921 % records.size,
            DailyVerseResolver.indexFor(date, records.size),
        )
        assertEquals(
            records[20260921 % records.size],
            DailyVerseResolver.resolve(records, date),
        )
    }

    @Test
    fun handlesLeapDayAndYearBoundary() {
        assertEquals(
            20240229 % 3,
            DailyVerseResolver.indexFor(LocalDate.of(2024, 2, 29), 3),
        )
        assertEquals(
            20270101 % 3,
            DailyVerseResolver.indexFor(LocalDate.of(2027, 1, 1), 3),
        )
    }

    @Test
    fun returnsNullForAnEmptyOrInvalidCatalog() {
        assertNull(
            DailyVerseResolver.resolve(
                emptyList(),
                LocalDate.of(2026, 9, 21),
            ),
        )
        assertNull(
            DailyVerseResolver.resolve(
                listOf(records.first().copy(text = "")),
                LocalDate.of(2026, 9, 21),
            ),
        )
    }
}
