package com.ozcorp.verbum.widget

import android.content.Context
import com.ozcorp.verbum.R
import org.json.JSONArray

object DailyVerseCatalog {
    @Volatile
    private var cached: List<DailyVerseRecord>? = null

    fun load(context: Context): List<DailyVerseRecord> {
        cached?.let { return it }
        return runCatching {
            val raw =
                context.resources
                    .openRawResource(R.raw.daily_verses_rv1909)
                    .bufferedReader(Charsets.UTF_8)
                    .use { it.readText() }
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    val item = array.getJSONObject(index)
                    add(
                        DailyVerseRecord(
                            bookId = item.getString("bookId"),
                            bookName = item.getString("bookName"),
                            chapter = item.getInt("chapter"),
                            verse = item.getInt("verse"),
                            reference = item.getString("reference"),
                            text = item.getString("text"),
                            edition = item.getString("edition"),
                        ),
                    )
                }
            }.also { records ->
                require(records.isNotEmpty() && records.all { it.isValid })
                cached = records
            }
        }.getOrElse { emptyList() }
    }
}
