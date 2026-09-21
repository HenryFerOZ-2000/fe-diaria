package com.ozcorp.verbum

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import com.ozcorp.verbum.widget.DailyVerseCatalog
import com.ozcorp.verbum.widget.DailyVerseResolver
import com.ozcorp.verbum.widget.VerseWidgetRenderer
import java.time.LocalDate

class VerseWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val ACTION_UPDATE_WIDGET = "com.ozcorp.verbum.UPDATE_WIDGET"

        private val recoveryActions =
            setOf(
                ACTION_UPDATE_WIDGET,
                Intent.ACTION_DATE_CHANGED,
                Intent.ACTION_TIME_CHANGED,
                Intent.ACTION_TIMEZONE_CHANGED,
                Intent.ACTION_BOOT_COMPLETED,
                Intent.ACTION_MY_PACKAGE_REPLACED,
            )

        fun updateWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, VerseWidgetProvider::class.java)
            manager.getAppWidgetIds(component).forEach { widgetId ->
                updateAppWidget(context, manager, widgetId)
            }
        }

        private fun updateAppWidget(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int,
        ) {
            val date = LocalDate.now()
            val record = DailyVerseResolver.resolve(DailyVerseCatalog.load(context), date)
            if (record == null) {
                VerseWidgetRenderer.renderFallback(context, manager, widgetId)
            } else {
                VerseWidgetRenderer.render(context, manager, widgetId, record, date)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { widgetId ->
            updateAppWidget(context, appWidgetManager, widgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action in recoveryActions) {
            updateWidgets(context)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        updateWidgets(context)
    }
}
