package com.ozcorp.versiculo_de_hoy

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews

/**
 * Provider del widget nativo de Android para mostrar versículos diarios
 * Usa SharedPreferences para comunicación con Flutter mediante MethodChannel
 */
class VerseWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val PREFS_NAME = "versiculo_widget_prefs"
        private const val KEY_VERSE_TEXT = "verse_text"
        private const val KEY_VERSE_REFERENCE = "verse_reference"
        private const val ACTION_UPDATE_WIDGET = "com.ozcorp.versiculo_de_hoy.UPDATE_WIDGET"
        
        /**
         * Guarda los datos del versículo en SharedPreferences
         */
        fun saveVerseData(context: Context, text: String, reference: String) {
            val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putString(KEY_VERSE_TEXT, text)
                .putString(KEY_VERSE_REFERENCE, reference)
                .apply()
        }
        
        /**
         * Actualiza todos los widgets instalados
         */
        fun updateWidgets(context: Context) {
            val intent = Intent(context, VerseWidgetProvider::class.java)
            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            
            val widgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, VerseWidgetProvider::class.java)
            val widgetIds = widgetManager.getAppWidgetIds(componentName)
            
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
            context.sendBroadcast(intent)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Actualizar todos los widgets
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        // Manejar actualización manual desde Flutter
        if (intent.action == ACTION_UPDATE_WIDGET || 
            intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, VerseWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }

    override fun onEnabled(context: Context) {
        // Se llama cuando se crea el primer widget
        super.onEnabled(context)
    }

    override fun onDisabled(context: Context) {
        // Se llama cuando se elimina el último widget
        super.onDisabled(context)
    }

    /**
     * Actualiza un widget específico con los datos del versículo
     */
    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        // Obtener datos guardados
        val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val verseText = prefs.getString(KEY_VERSE_TEXT, context.getString(R.string.widget_default_verse))
            ?: context.getString(R.string.widget_default_verse)
        val verseReference = prefs.getString(KEY_VERSE_REFERENCE, context.getString(R.string.widget_default_reference))
            ?: context.getString(R.string.widget_default_reference)

        // Crear RemoteViews con el layout del widget
        val views = RemoteViews(context.packageName, R.layout.widget_layout)
        
        // Actualizar textos
        views.setTextViewText(R.id.widget_verse_text, verseText)
        views.setTextViewText(R.id.widget_verse_reference, verseReference)
        
        // Configurar click para abrir la app
        val intent = Intent(context, MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_verse_text, pendingIntent)
        views.setOnClickPendingIntent(R.id.widget_verse_reference, pendingIntent)
        
        // Actualizar el widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}

