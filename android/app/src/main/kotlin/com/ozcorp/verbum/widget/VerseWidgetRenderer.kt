package com.ozcorp.verbum.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import com.ozcorp.verbum.MainActivity
import com.ozcorp.verbum.R
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

object VerseWidgetRenderer {
    fun render(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        record: DailyVerseRecord,
        date: LocalDate = LocalDate.now(),
    ) {
        val layoutSize = layoutSize(manager, widgetId)
        val views = RemoteViews(context.packageName, layoutResource(layoutSize))
        views.setTextViewText(R.id.widget_verse_text, record.text)
        views.setTextViewText(R.id.widget_reference, record.reference)
        views.setTextViewText(R.id.widget_edition, record.edition)
        setDateIfPresent(views, layoutSize, date)
        views.setOnClickPendingIntent(
            R.id.widget_root,
            openVersePendingIntent(context, widgetId, record),
        )
        manager.updateAppWidget(widgetId, views)
    }

    fun renderFallback(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
    ) {
        val layoutSize = layoutSize(manager, widgetId)
        val views = RemoteViews(context.packageName, layoutResource(layoutSize))
        views.setTextViewText(R.id.widget_verse_text, context.getString(R.string.widget_default_verse))
        views.setTextViewText(R.id.widget_reference, context.getString(R.string.widget_brand))
        views.setTextViewText(R.id.widget_edition, "")
        setDateIfPresent(views, layoutSize, LocalDate.now())
        views.setOnClickPendingIntent(
            R.id.widget_root,
            openAppPendingIntent(context, widgetId),
        )
        manager.updateAppWidget(widgetId, views)
    }

    private fun layoutSize(manager: AppWidgetManager, widgetId: Int): WidgetLayoutSize {
        val options = manager.getAppWidgetOptions(widgetId)
        return WidgetLayoutSelector.select(
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH),
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT),
        )
    }

    private fun layoutResource(size: WidgetLayoutSize): Int =
        when (size) {
            WidgetLayoutSize.COMPACT -> R.layout.widget_compact
            WidgetLayoutSize.MEDIUM -> R.layout.widget_medium
            WidgetLayoutSize.LARGE -> R.layout.widget_large
        }

    private fun setDateIfPresent(
        views: RemoteViews,
        size: WidgetLayoutSize,
        date: LocalDate,
    ) {
        if (size == WidgetLayoutSize.COMPACT) return
        val formatter = DateTimeFormatter.ofPattern("d MMM", Locale.forLanguageTag("es-ES"))
        views.setTextViewText(R.id.widget_date, date.format(formatter))
    }

    private fun openVersePendingIntent(
        context: Context,
        widgetId: Int,
        record: DailyVerseRecord,
    ): PendingIntent {
        val uri =
            Uri.parse(
                "verbum://biblia/${record.bookId}/${record.chapter}/${record.verse}",
            )
        val intent = Intent(Intent.ACTION_VIEW, uri, context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            widgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun openAppPendingIntent(context: Context, widgetId: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            widgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
