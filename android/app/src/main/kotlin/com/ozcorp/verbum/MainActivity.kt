package com.ozcorp.verbum

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.ozcorp.verbum/widget"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "isPinWidgetSupported" -> {
                    val manager = AppWidgetManager.getInstance(this)
                    val supported =
                        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                            manager.isRequestPinAppWidgetSupported
                    result.success(supported)
                }
                "requestPinWidget" -> {
                    val manager = AppWidgetManager.getInstance(this)
                    val supported =
                        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                            manager.isRequestPinAppWidgetSupported
                    val requested =
                        supported &&
                            manager.requestPinAppWidget(
                                ComponentName(this, VerseWidgetProvider::class.java),
                                null,
                                null,
                            )
                    result.success(requested)
                }
                "hasWidgets" -> {
                    val manager = AppWidgetManager.getInstance(this)
                    val component = ComponentName(this, VerseWidgetProvider::class.java)
                    result.success(manager.getAppWidgetIds(component).isNotEmpty())
                }
                "refreshWidget", "updateWidget" -> {
                    VerseWidgetProvider.updateWidgets(applicationContext)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
