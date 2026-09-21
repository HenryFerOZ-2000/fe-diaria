# Diseño: Widget de la Palabra diaria

Fecha: 2026-09-21

Estado: pendiente de revisión final del usuario

Producto: Verbum para Android

## 1. Propósito

Crear un widget nativo de Android que lleve la Palabra diaria de Verbum a la pantalla de inicio y, cuando el dispositivo lo permita, a la pantalla de bloqueo. Debe sentirse como una extensión cuidada de la aplicación: cálida, editorial, reconocible y fácil de usar.

El widget mostrará un versículo bíblico real de la edición Reina-Valera 1909 (RV1909), funcionará sin conexión y abrirá el pasaje exacto en el lector bíblico de Verbum. La misma fecha local debe producir el mismo versículo tanto en Flutter como en Android.

## 2. Alcance y criterios de éxito

La primera versión se considera correcta cuando:

- muestra un único versículo RV1909 canónico para el día, sin personalización por emoción o tradición;
- puede resolver el contenido sin abrir previamente la aplicación y sin conexión a Internet;
- mantiene el mismo resultado que `DailyVerseService` para cualquier fecha local;
- se adapta a tamaños compacto, mediano y grande sin desbordamientos ni texto ilegible;
- usa una apariencia clara u oscura automáticamente, sin una pantalla de personalización;
- permite solicitar al sistema que añada el widget a la pantalla de inicio;
- declara compatibilidad con `home_screen|keyguard`, sin prometer que todos los fabricantes acepten widgets en la pantalla de bloqueo;
- al tocarlo, abre el libro, capítulo y versículo exactos;
- se actualiza tras un cambio de día, fecha, hora o zona horaria, después de reiniciar el dispositivo y al abrir Verbum;
- continúa funcionando si el catálogo está temporalmente inaccesible, mediante un estado seguro que no inventa contenido;
- no altera compras, anuncios, autenticación, comunidades, firma Android, identificador de aplicación ni versión de publicación.

## 3. Fuera de alcance

Esta primera versión no incluirá:

- selección manual de colores, tipografías o fondos;
- varios versículos por día o contenido personalizado;
- oraciones, chat con IA, rachas, anuncios o información privada;
- actualización por red o sincronización con Firebase;
- alarmas exactas o tareas frecuentes que consuman batería;
- un proveedor independiente para la pantalla de bloqueo;
- publicación, generación del AAB, cambio de `versionCode` o cambio de `versionName`.

## 4. Decisiones de producto y diseño

### 4.1 Contenido

El widget usará la misma lista ordenada de referencias de `assets/data/daily_verses_refs.json` y los textos de `assets/db/rv1909.sqlite`. La edición siempre aparecerá identificada como `RV1909`.

La fórmula canónica seguirá siendo:

```text
clave = año * 10000 + mes * 100 + día
índice = clave módulo cantidad_de_referencias
```

La fecha se calculará en la zona horaria local del dispositivo. La fórmula y el orden del catálogo no se cambiarán en la implementación del widget, porque cualquier diferencia haría que Flutter y Android mostrasen versículos distintos.

### 4.2 Apariencia

La familia visual aprobada tendrá fondo cálido tipo papel, acentos ciruela y dorado, jerarquía editorial y una variante oscura de alto contraste. El versículo será el elemento principal; la marca, la fecha, la referencia y la edición tendrán menor peso visual.

Se usarán recursos nativos compatibles con `RemoteViews`. No se dependerá de Google Fonts en el widget: Android usará familias del sistema con una jerarquía equivalente y predecible en distintos fabricantes.

Comportamiento por tamaño:

| Tamaño | Contenido | Límites principales |
| --- | --- | --- |
| Compacto, aproximadamente 2×1 | sello de Verbum, versículo, referencia y RV1909 | máximo 2 líneas de versículo; sin texto “Abrir” |
| Mediano, aproximadamente 4×2 | fecha, versículo, referencia, RV1909 y acción discreta | máximo 4 líneas de versículo |
| Grande, aproximadamente 4×3 | fecha, versículo con mayor presencia, referencia, RV1909 y acción | más líneas, sin desplazar los metadatos fuera del área visible |

`onAppWidgetOptionsChanged` elegirá el diseño con base en el ancho y alto disponibles. Todos los contenedores tendrán márgenes seguros, texto truncable y contraste suficiente. El contenido esencial no dependerá de transparencias muy bajas.

### 4.3 Pantalla de bloqueo

El proveedor declarará las categorías `home_screen|keyguard`. Esto expresa compatibilidad, pero el host del sistema conserva la decisión final. Algunos teléfonos no ofrecen widgets de bloqueo o solo aceptan formatos propios.

Verbum no intentará fijar directamente un widget en la pantalla de bloqueo. La pantalla de ayuda explicará de forma breve cómo personalizarla y aclarará que la disponibilidad depende del dispositivo. Si no está disponible, el widget de inicio seguirá funcionando normalmente.

Referencias oficiales:

- [AppWidgetProviderInfo y categorías de widget](https://developer.android.com/reference/android/appwidget/AppWidgetProviderInfo)
- [Administración avanzada de widgets](https://developer.android.com/develop/ui/views/appwidgets/advanced)
- [Solicitud de fijación mediante AppWidgetManager](https://developer.android.com/reference/android/appwidget/AppWidgetManager)

## 5. Arquitectura

Se conservará el proveedor nativo basado en `AppWidgetProvider` y `RemoteViews`. Esta opción amplía lo que ya existe, mantiene bajo el peso de la aplicación y evita introducir Glance o un plugin de terceros para una primera versión que no los necesita.

El sistema se dividirá en cinco unidades:

1. **Generador de catálogo:** crea durante el desarrollo un archivo Android compacto a partir de las fuentes RV1909 existentes.
2. **Resolvedor diario nativo:** lee el catálogo y selecciona el registro de la fecha local.
3. **Renderizador del widget:** escoge el layout apropiado, aplica tema y enlaza los datos.
4. **Puente Flutter–Android:** solicita fijación, consulta si existen widgets y fuerza una actualización cuando Verbum está abierta.
5. **Enrutador de pasajes:** interpreta el enlace del widget y abre el lector en el versículo exacto.

Cada unidad tendrá una responsabilidad única. El proveedor coordinará las unidades, pero no contendrá la lógica de generación del catálogo ni la navegación Flutter.

## 6. Catálogo Android y flujo de datos

Se añadirá un script de desarrollo, previsto como `tools/generate_android_widget_catalog.py`, que:

1. lee `assets/data/daily_verses_refs.json` conservando estrictamente su orden;
2. busca cada referencia en `assets/db/rv1909.sqlite`;
3. obtiene el nombre visible desde el catálogo canónico de libros;
4. normaliza únicamente espacios y marcas técnicas, sin reescribir el texto bíblico;
5. falla si falta una referencia, hay duplicados inesperados, un campo es inválido o el texto está vacío;
6. genera de forma determinista `android/app/src/main/res/raw/daily_verses_rv1909.json`.

Cada registro generado tendrá esta forma estable:

```json
{
  "bookId": "JHN",
  "bookName": "Juan",
  "chapter": 3,
  "verse": 16,
  "reference": "Juan 3:16",
  "text": "...",
  "edition": "RV1909"
}
```

El archivo generado se versionará en Git para que Gradle pueda empaquetarlo sin depender de Python durante una compilación normal. Una prueba de paridad regenerará el catálogo en memoria y comprobará que el archivo versionado no esté desactualizado.

El flujo durante la ejecución será:

```text
evento Android → resolvedor de fecha local → catálogo RV1909
              → registro diario → selector de layout → RemoteViews
              → AppWidgetManager
```

Flutter puede solicitar un redibujado, pero Android será capaz de resolver el día y el contenido por sí mismo. `SharedPreferences` solo guardará metadatos útiles, como la última fecha renderizada; no será la fuente primaria del versículo.

## 7. Actualización y ciclo de vida

`widget_info.xml` usará una comprobación periódica ligera de una hora. Android puede agrupar o retrasar estas actualizaciones para ahorrar batería; por eso el proveedor también reaccionará a eventos relevantes permitidos por el sistema:

- actualización normal del widget;
- cambio de fecha;
- cambio de hora o zona horaria;
- cambio de configuración relevante, incluida la apariencia;
- reinicio o desbloqueo posterior al reinicio cuando corresponda;
- cambio de tamaño del widget;
- solicitud explícita desde Flutter al abrir o reanudar Verbum.

Antes de renderizar, el proveedor comparará la fecha local actual con la última fecha resuelta. Si no cambió el contenido ni las opciones visuales, evitará trabajo innecesario. No se solicitarán permisos de alarma exacta y no se añadirá WorkManager salvo que las pruebas reales demuestren una limitación que el ciclo de vida estándar no pueda resolver.

## 8. Experiencia para añadir el widget

En Configuración se añadirá una entrada llamada **Widget de la Palabra**. Su pantalla tendrá:

- una vista previa del tamaño mediano con el versículo del día;
- una explicación de una sola frase;
- el botón principal **Añadir a inicio**;
- un estado informativo **Widget añadido** cuando Android informe que hay al menos una instancia;
- una sección secundaria **Pantalla de bloqueo**, con dos o tres pasos y la aclaración de compatibilidad.

El botón principal usará `AppWidgetManager.requestPinAppWidget` cuando el launcher lo permita. Si la función no está disponible, Verbum mostrará instrucciones manuales: mantener pulsada la pantalla de inicio, abrir Widgets, buscar Verbum y arrastrar el widget.

No se mostrará una pantalla de personalización antes de añadirlo. Reducir decisiones es parte del objetivo de sencillez.

## 9. Apertura del pasaje exacto

El toque sobre cualquier zona accionable abrirá una URI interna con el formato:

```text
verbum://biblia/<bookId>/<chapter>/<verse>
```

Ejemplo:

```text
verbum://biblia/JHN/3/16
```

Se ampliará el filtro de intents de `MainActivity` para aceptar el host `biblia`. `DeepLinkService` distinguirá los enlaces de caminos espirituales de los bíblicos y validará:

- que `bookId` exista en el catálogo RV1909;
- que capítulo y versículo sean enteros positivos;
- que el pasaje exista en la base local antes de navegar.

El servicio procesará tanto la URI inicial que abrió una aplicación cerrada como las URI recibidas mientras Verbum está activa. Si Flutter todavía no tiene un `NavigatorState`, el enlace se conservará como pendiente y se procesará después del primer frame. La navegación abrirá directamente `BibleVersesScreen` con `initialVerse`, reutilizando el desplazamiento y resaltado inicial que el lector ya ofrece.

Cada instancia del widget usará un `PendingIntent` inmutable con datos únicos para evitar que Android recicle accidentalmente el enlace de otro versículo.

## 10. Manejo de errores

- **Catálogo ausente, vacío o ilegible:** mostrar “Abre Verbum para recibir la Palabra de hoy” y una acción que abra la aplicación. No etiquetar contenido antiguo como si fuera del día actual.
- **Referencia inexistente:** registrar el error en modo de desarrollo y usar el mismo estado seguro; nunca inventar ni reemplazar silenciosamente el versículo.
- **Fijación no compatible:** mostrar instrucciones manuales sin presentar el caso como un fallo.
- **Pantalla de bloqueo no compatible:** explicar la limitación del dispositivo y mantener disponible el widget de inicio.
- **Enlace inválido:** abrir la sección Biblia en lugar de cerrar la aplicación o dejar una pantalla vacía.
- **Flutter no disponible durante una actualización:** continuar con el resolvedor nativo y el catálogo empacado.

Los errores del widget no deben impedir el inicio de Verbum.

## 11. Accesibilidad, idioma y privacidad

- Los textos del widget y de la pantalla de ayuda se almacenarán en recursos traducibles.
- La primera entrega incluirá español, coherente con la interfaz actual; las claves quedarán preparadas para futuras traducciones.
- El contenido conservará legibilidad con texto ampliado, aunque el sistema pueda truncar antes en formatos pequeños.
- Las acciones táctiles ocuparán toda la superficie útil del widget.
- La variante oscura tendrá contraste alto y evitará texto blanco sobre fondos claros.
- No se recopilarán datos nuevos, no se añadirá seguimiento específico del contenido mostrado y no se expondrán datos del usuario.

## 12. Pruebas y verificación

### 12.1 Automatizadas

- paridad entre la fórmula Dart y la fórmula Kotlin para fechas representativas;
- cambio de año, año bisiesto y fechas alrededor de medianoche;
- integridad, orden y determinismo del catálogo generado;
- existencia de cada referencia en RV1909 y coincidencia exacta del texto;
- selección de layout compacto, mediano y grande según opciones del widget;
- construcción y validación de la URI del pasaje;
- apertura del enlace con Verbum cerrada y con Verbum ya activa;
- validación de enlaces correctos, libros inexistentes y números inválidos;
- comportamiento seguro ante catálogo vacío o corrupto;
- pruebas Flutter del nuevo servicio y de la pantalla de configuración;
- `flutter analyze`, `flutter test` y compilación Android de depuración.

### 12.2 Manuales

Probar, como mínimo:

- añadir el widget desde Verbum y desde el selector del launcher;
- cambiar entre tamaños disponibles y comprobar que no haya desbordamientos;
- modos claro y oscuro;
- escala de fuente normal y grande;
- funcionamiento sin conexión y tras cerrar forzosamente Verbum;
- reinicio del dispositivo;
- cambio manual de fecha y de zona horaria;
- dos instancias del widget;
- toque que abre exactamente el libro, capítulo y versículo mostrados;
- launcher que no admite fijación programática;
- pantalla de bloqueo en un dispositivo compatible y mensaje claro en uno no compatible.

Se recomienda validar al menos en Android 8, Android 12 y una versión reciente de Android, además de un equipo físico con capa de fabricante. La compatibilidad de pantalla de bloqueo se documentará con el resultado real de los dispositivos disponibles.

## 13. Archivos previstos

La implementación podrá crear o modificar únicamente archivos relacionados con esta función, entre ellos:

- `tools/generate_android_widget_catalog.py`;
- `android/app/src/main/res/raw/daily_verses_rv1909.json`;
- `android/app/src/main/kotlin/com/ozcorp/verbum/VerseWidgetProvider.kt`;
- nuevas clases Kotlin enfocadas en catálogo, resolución y renderizado;
- `android/app/src/main/kotlin/com/ozcorp/verbum/MainActivity.kt`;
- `android/app/src/main/AndroidManifest.xml`;
- `android/app/src/main/res/xml/widget_info.xml`;
- layouts y drawables del widget para tamaños y temas;
- recursos `values` y `values-night` del widget;
- `lib/services/widget_service.dart`;
- `lib/services/deep_link_service.dart`;
- una nueva pantalla Flutter de configuración del widget;
- `lib/screens/settings_screen.dart`;
- pruebas Dart, Python y Android enfocadas en la función.

Si durante la implementación se descubre que hace falta tocar una función ajena a este alcance, se detendrá esa ampliación y se explicará antes de realizarla.

## 14. Restricciones de publicación

Esta fase no generará `app-release.aab`, no ejecutará `flutter build appbundle --release`, no publicará contenido en Google Play y no cambiará:

- `applicationId` o package name;
- App Signing Key de Google Play;
- configuración de la nueva Upload Key ya preparada;
- `versionCode`;
- `versionName`.

La implementación se verificará con análisis, pruebas y, si es necesario, una compilación de depuración.

## 15. Entrega esperada

Al finalizar la implementación se entregará:

- el widget diario funcional y responsivo;
- la experiencia para añadirlo y las instrucciones de pantalla de bloqueo;
- navegación al pasaje exacto;
- catálogo RV1909 reproducible y sus pruebas de paridad;
- resultados de pruebas automáticas y lista de comprobaciones manuales pendientes;
- resumen de archivos modificados;
- confirmación explícita de que no se generó ni publicó un AAB.
