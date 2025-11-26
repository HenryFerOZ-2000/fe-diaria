# Configuración de Widgets para Android e iOS

Esta aplicación incluye soporte para widgets de pantalla de inicio y pantalla de bloqueo. Para que los widgets funcionen completamente, necesitas configurar los widgets nativos en Android e iOS.

## Estado Actual

✅ **Código Flutter completado:**
- Servicio de widgets (`lib/services/widget_service.dart`)
- Integración con el provider para actualizar widgets automáticamente
- Datos preparados para widgets (versículo, oración de la mañana, oración de la noche)

⚠️ **Configuración nativa pendiente:**
- Widgets nativos de Android (Java/Kotlin)
- Widgets nativos de iOS (Swift)

## Datos Disponibles en los Widgets

Los siguientes datos están disponibles para los widgets:

- `verse_text`: Texto del versículo del día
- `verse_reference`: Referencia del versículo (ej: "Juan 3:16")
- `morning_prayer`: Oración de la mañana
- `evening_prayer`: Oración de la noche

## Configuración para Android

Para implementar widgets en Android, necesitas:

1. **Crear un AppWidgetProvider** en `android/app/src/main/java/com/ozcorp/versiculo_de_hoy/VersiculoWidgetProvider.kt`

2. **Registrar el widget** en `AndroidManifest.xml`:
```xml
<receiver android:name=".VersiculoWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/versiculo_widget_info" />
</receiver>
```

3. **Crear el layout del widget** en `android/app/src/main/res/xml/versiculo_widget_info.xml`

4. **Crear el layout visual** en `android/app/src/main/res/layout/versiculo_widget.xml`

## Configuración para iOS

Para implementar widgets en iOS, necesitas:

1. **Crear un Widget Extension** en Xcode:
   - File > New > Target
   - Seleccionar "Widget Extension"
   - Nombre: "VersiculoWidget"

2. **Configurar el App Group** en Capabilities:
   - Agregar App Group: `group.com.ozcorp.versiculo_de_hoy`

3. **Implementar el widget** en Swift usando `WidgetKit`

## Recursos

- [Documentación de home_widget](https://pub.dev/packages/home_widget)
- [Widgets de Android](https://developer.android.com/develop/ui/views/appwidgets)
- [Widgets de iOS (WidgetKit)](https://developer.apple.com/documentation/widgetkit)

## Nota

Los widgets se actualizan automáticamente cuando:
- Se carga el versículo del día
- Se cargan las oraciones del día
- La aplicación se inicia

El código Flutter ya está listo y funcionando. Solo necesitas implementar los widgets nativos según las instrucciones anteriores.

