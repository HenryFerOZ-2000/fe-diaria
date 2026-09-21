package com.ozcorp.verbum.widget

data class DailyVerseRecord(
    val bookId: String,
    val bookName: String,
    val chapter: Int,
    val verse: Int,
    val reference: String,
    val text: String,
    val edition: String,
) {
    val isValid: Boolean
        get() =
            bookId.isNotBlank() &&
                bookName.isNotBlank() &&
                chapter > 0 &&
                verse > 0 &&
                reference.isNotBlank() &&
                text.isNotBlank() &&
                edition == "RV1909"
}
