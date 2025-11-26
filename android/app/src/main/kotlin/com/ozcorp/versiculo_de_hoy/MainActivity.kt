package com.ozcorp.versiculo_de_hoy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ozcorp.versiculo_de_hoy/widget"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    val verseText = call.argument<String>("verseText") ?: ""
                    val verseReference = call.argument<String>("verseReference") ?: ""
                    
                    try {
                        // Guardar datos en SharedPreferences
                        VerseWidgetProvider.saveVerseData(applicationContext, verseText, verseReference)
                        
                        // Actualizar widgets
                        VerseWidgetProvider.updateWidgets(applicationContext)
                        
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Error updating widget: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
