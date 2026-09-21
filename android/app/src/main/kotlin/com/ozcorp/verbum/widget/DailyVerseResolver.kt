package com.ozcorp.verbum.widget

import java.time.LocalDate

object DailyVerseResolver {
    fun indexFor(date: LocalDate, size: Int): Int {
        require(size > 0) { "Catalog size must be positive" }
        val key = date.year * 10000 + date.monthValue * 100 + date.dayOfMonth
        return key % size
    }

    fun resolve(
        records: List<DailyVerseRecord>,
        date: LocalDate,
    ): DailyVerseRecord? {
        if (records.isEmpty() || records.any { !it.isValid }) return null
        return records[indexFor(date, records.size)]
    }
}
