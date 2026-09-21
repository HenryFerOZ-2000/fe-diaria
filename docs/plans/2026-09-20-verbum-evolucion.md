# Verbum: plan de evolución y revisión de Firebase

Estado: propuesta de producto y entregas para revisión; las funciones nuevas aún no están implementadas. La actualización de Firebase sí está autorizada por el usuario.

## Objetivo y límites

Crear una experiencia diaria confiable, fiel a la tradición elegida y fácil de compartir; mejorar el chat y definir una suscripción sostenible. Prioridad Android, aplicación ya publicada. Conservar cuentas, favoritos, progreso y compras anteriores.

- No generar AAB ni publicar en Google Play durante esta etapa.
- Mantener `com.ozcorp.verbum`, firma y versión actual `1.0.6+10`.
- Commit y push después de implementar los cambios acordados y verificar su funcionamiento, como solicitó el usuario.
- Credenciales fuera del cliente y Git. No desplegar servicios ni modificar ajustes de consolas durante la planificación.
- País litúrgico inicial: selección pendiente del usuario; diseñar el país como dato configurable, sin inferirlo del idioma.

## Lo que ya existe

1. `firebase_app_check 0.3.2+10` incorporaba `firebase-appcheck-safetynet:16.1.2` y `play-services-safetynet:18.0.0`, aunque `lib/main.dart` seleccionaba Play Integrity para producción.
2. `WidgetService`, `VerseWidgetProvider.kt` y `widget_info.xml` implementan un widget de inicio. El método de bloqueo es un alias y el proveedor muestra el último texto guardado; refrescarlo no selecciona necesariamente el versículo del nuevo día.
3. `BibleBooksScreen` ya separa Antiguo/Nuevo Testamento. El catálogo tiene 39 y 27 libros, y `BibleDb` usa `rv1909.sqlite` para todas las tradiciones. No equivale a una Biblia católica completa.
4. Tradiciones persistidas: `catolica`, `cristiana` y `general`. Hay varios catálogos de oraciones y el modelo `TraditionalPrayer` no guarda procedencia ni licencia. La selección vacía conserva comportamiento católico heredado.
5. `ShareService` ya genera PNG vertical y mensajes con enlaces, pero no hay llamadas al generador de imagen desde las pantallas revisadas. Varias pantallas comparten directamente texto. Existe un enlace de búsqueda de App Store que no corresponde a una ficha concreta.
6. El chat usa la función `chatWithGroq` y el modelo fijo `llama-3.3-70b-versatile`. Requiere usuario autenticado, importa un secreto de archivo local y consume cuota antes de validar la solicitud. Admite historial del cliente sin filtrar roles ni tamaño. El prompt católico se presenta como sacerdote. No se verificó el servicio desplegado ni se efectuaron llamadas facturables.
7. `PurchaseService` es una compra única `remove_ads`, desactivada en el arranque y basada en un indicador local. No implementa suscripciones mensuales ni validación de derechos en servidor.

## Estrategia recomendada

Trabajar por entregas pequeñas: contenido y Biblia → compartir → widgets → chat → suscripción. Así el mismo contenido validado alimenta la lectura, las tarjetas, los widgets y las respuestas de IA.

Alternativas consideradas: hacer todo de una vez dificultaría detectar regresiones; añadir primero más diseño conservaría inconsistencias de contenido. La entrega gradual permite verificar resultados y ajustar el alcance antes de invertir en la siguiente fase.

## Entrega 0: retirar SafetyNet

Archivos: `pubspec.yaml`, `pubspec.lock`, `lib/main.dart`.

- Actualizar App Check a `0.4.8` y la familia Firebase a versiones compatibles con Firebase Core 4.
- Migrar la activación a `providerAndroid` y `providerApple`, conservando debug en desarrollo y Play Integrity en producción.
- Verificar `releaseRuntimeClasspath` sin ninguna dependencia SafetyNet, analizar Flutter, ejecutar pruebas existentes y compilar APK de desarrollo.
- Validación manual antes de publicar: autenticación, Firestore, Storage, notificaciones y token App Check en instalación desde una pista de prueba de Play. El registro de App Check debe usar el certificado de firma de aplicación de Google Play, no confundirlo con la Upload Key.
- Compatibilidad adicional: Firebase Core 4.15 exige iOS 15 según su podspec, mientras el proyecto iOS conserva target 13. Esta actualización se valida en Android; una entrega iOS requiere adaptar y compilar el proyecto en macOS.

Resultado de la revisión del 20 de septiembre de 2026: `flutter analyze` sin incidencias; `flutter test` con 6 pruebas aprobadas; `flutter build apk --debug` completado; `:app:dependencyInsight --configuration releaseRuntimeClasspath --dependency safetynet` no encuentra dependencias. No se generó AAB ni se probó la emisión de tokens contra Firebase en un dispositivo. El aviso del artefacto antiguo en Play Console no se elimina modificando el código local. Se añadió también `android/.kotlin/` a `.gitignore` para excluir cachés y registros de compilación.

## Entrega 1: contenido por tradición y Biblia

Archivos base: `lib/faith/`, `lib/models/traditional_prayer.dart`, `lib/repositories/traditional_prayer_repository.dart`, `lib/services/traditional_prayers_service.dart`, `assets/oraciones/`, `assets/traditions/`, `lib/bible/domain/bible_book_info.dart`, `lib/bible/data/bible_db.dart`, `lib/bible/ui/`.

- Etiquetas públicas: «Católica», «Evangélica / protestante» y «Cristiana general». Preservar identificadores de almacenamiento para no perder preferencias. Explicar que son tradiciones cristianas; la opción general no representa una denominación concreta.
- Inventariar cada texto e incorporar `sourceTitle`, `sourceUrl`, `tradition`, `contentKind`, `translation`, `licenseStatus`, `reviewStatus` y versión editorial. Distinguir texto bíblico, oración tradicional, texto litúrgico, devoción popular y reflexión original de Verbum.
- No certificar automáticamente todas las oraciones como oficiales. La publicación de un texto como litúrgico requiere fuente verificable y revisión editorial; si no existe procedencia, presentarlo como texto de Verbum cuando corresponda o dejarlo fuera del catálogo verificado.
- Mantener los dos testamentos y mejorar visibilidad, cantidades de libros, búsqueda y continuidad de lectura. Catálogo y lectura deben depender de la edición seleccionada.
- Para RV1909: 39 libros del Antiguo y 27 del Nuevo. Para una edición católica completa: 46 y 27, incluidas las secciones deuterocanónicas pertinentes. Añadir siete nombres sin sus textos no resuelve la diferencia.
- Obtener una edición católica con permiso de distribución comprobado. Hasta entonces mostrar claramente «Reina-Valera 1909»; no renombrar el texto existente como Biblia católica ni rellenar pasajes con IA.
- Conservar favoritos mediante identificadores estables y edición explícita; evitar que un cambio de canon altere índices o abra otro libro.

Aceptación: pruebas del catálogo por edición, lectura de extremos de cada testamento, búsqueda, favoritos antiguos, cambio de tradición y ausencia de textos exclusivamente católicos en recomendaciones evangélicas. Auditoría editorial de los textos publicados y de sus derechos de uso.

## Entrega 2: liturgia católica del día

Crear `lib/features/liturgy/` con modelo, repositorio, caché y presentación; conectar con Hoy y Oraciones después de validar el catálogo.

- No hay una única oración semanal universal para todos los católicos. Diferenciar la oración colecta de la misa, las lecturas litúrgicas y la Liturgia de las Horas; son contenidos relacionados, pero distintos.
- Primera versión: celebración del día, tiempo litúrgico, referencias de las lecturas y oración colecta cuando se disponga de texto autorizado. Presentar fuente, fecha y calendario nacional.
- Segunda versión: Laudes y Vísperas; tratar su calendario, salterio y textos como una ampliación independiente. Mantener rosario y novenas como devociones, sin etiquetarlos como la oración oficial única del día.
- Clave de contenido: fecha local + país/calendario + idioma. Contemplar solemnidades trasladadas, fiestas locales, años A/B/C y ciclo de lecturas feriales donde corresponda.
- Consumir una fuente con permiso de reutilización o un catálogo editorial autorizado. Un calendario público sirve para contrastar fechas, pero no prueba autorización para redistribuir el Misal o el Leccionario.
- Preparar varios días de caché. Si falta el contenido de hoy, indicar la fecha real del disponible; no presentar ayer como hoy ni sustituir una colecta por texto generado.

Aceptación: muestras contrastadas con calendario oficial para Navidad, Semana Santa/Pascua, domingos y fiestas nacionales; cambios de zona horaria, modo sin conexión y contenido ausente. La selección de proveedor y licencia precede a importar textos completos.

## Entrega 3: compartir tarjetas

Base: `lib/services/share_service.dart`; nuevo compositor y vista previa bajo `lib/features/sharing/`; migrar las acciones de compartir de Biblia, Hoy, favoritos y lectores de oraciones.

- Flujo: Compartir → vista previa → formato y estilo → compartir/guardar/copiar texto o enlace.
- Formatos de exportación propuestos: 1080×1080, 1080×1350 y 1080×1920. Son formatos de diseño, no garantía de publicación idéntica en todas las redes.
- Tres estilos iniciales coherentes con Verbum: papel claro, noche y color litúrgico cuando proceda. Texto de alto contraste, referencia/autor, edición y marca discreta.
- El texto largo se pagina o el usuario elige un fragmento identificado. No recortar oraciones silenciosamente ni reducir la letra hasta que resulte ilegible.
- Incluir el enlace real de Google Play en la leyenda: `https://play.google.com/store/apps/details?id=com.ozcorp.verbum`. Retirar el enlace genérico de búsqueda de App Store del mensaje; incorporarlo cuando exista ficha real.
- Botón «Copiar enlace» siempre disponible. Algunas aplicaciones receptoras omiten el texto que acompaña una imagen; el PNG no puede contener un enlace pulsable. Valorar un QR discreto opcional, especialmente para publicaciones, y probar su lectura tras compresión.
- Para una fase posterior, usar un dominio propio con Android App Links verificados y página web que abra el contenido o lleve a la tienda. No depender de Firebase Dynamic Links. Restringir los hosts aceptados en el servicio de enlaces.
- Render local, fuentes disponibles sin red y limpieza de temporales sin borrar el archivo antes de que el receptor termine de leerlo.

Aceptación: tarjetas cortas y largas, signos/accentos, fondo claro/oscuro, modo avión, cancelación; pruebas reales en WhatsApp, Instagram y selector Android. En iPad, si se habilita iOS, proporcionar origen de la hoja de compartir.

## Entrega 4: widgets diarios

Base: `lib/services/widget_service.dart`, `android/app/src/main/kotlin/com/ozcorp/verbum/VerseWidgetProvider.kt`, `android/app/src/main/res/xml/widget_info.xml`, `android/app/src/main/res/layout/widget_layout.xml` y canal de `MainActivity`.

- Mejorar el widget nativo existente, con variantes compacta y amplia. Mostrar versículo, referencia y fecha, con buen contraste y tamaños adaptables.
- Preparar la compatibilidad con hosts de bloqueo que la admitan. La disponibilidad depende del sistema y fabricante; una app no puede habilitarla universalmente.
- Actualizar desde un calendario local precargado, incluso si no se abrió Flutter ese día. Recalcular al recibir actualizaciones del sistema, abrir la app, reiniciar o cambiar fecha/zona horaria; usar trabajo diferible sin prometer ejecución exacta a medianoche.
- Tap abre el pasaje concreto respetando el desbloqueo. No colocar historial de chat, intenciones privadas ni anuncios en el bloqueo.
- Pantalla «Añadir widget» con instrucciones y alternativas: widget de inicio y notificación diaria voluntaria en equipos sin soporte de bloqueo.

Aceptación: pantalla pequeña/grande, redimensionado, dos widgets simultáneos, día nuevo sin abrir app, reinicio, ahorro de batería, sin conexión y apertura desde dispositivo bloqueado. Probar bloqueo en equipo compatible, no inferirlo de que funcione en el launcher.

## Entrega 5: chat IA confiable

Base: `api/src/index.ts`, `api/src/groqConfig.ts`, `api/src/chat.interfaces.ts`, `lib/services/groq_chat_service.dart` y pantallas de chat. Extraer la lógica nueva a `api/src/chat/` sin reestructurar otras funciones.

- Mantener la llamada desde Flutter a Cloud Functions. Migrar el secreto importado a Firebase Secret Manager con `defineSecret`, vinculado solo a la función. Modelo y límites configurables en servidor.
- Verificar acceso real de la cuenta al modelo antes de seleccionarlo: el catálogo consultado lista el actual Llama 3.3 70B como Enterprise. Evaluar un modelo de producción disponible para la cuenta, con pruebas de español, citas, tradición, latencia y coste; no cambiarlo solo por tamaño o nombre.
- Como candidatos iniciales dentro del proveedor ya integrado, evaluar los modelos de producción GPT-OSS 20B y 120B que figuran en su catálogo. Elegir después de pruebas y permisos efectivos; no habilitar herramientas web ni ejecución de código si el producto no las necesita.
- Presentación: «Asistente de Verbum». No fingir ser sacerdote, pastor, sacramento ni portavoz oficial de una iglesia. Ajustar explicaciones a la tradición elegida, y etiquetar interpretaciones y textos generados.
- Validar entrada antes de reservar cuota: texto máximo inicial 4.000 caracteres, historial máximo 12 mensajes y 24.000 caracteres totales, roles exclusivamente `user`/`assistant`; rechazar mensajes `system` aportados por el cliente. Valores iniciales sujetos a la evaluación de costes.
- Autenticación y App Check; habilitar exigencia en servidor después de verificar compatibilidad de los clientes ya publicados. Limitar simultaneidad, longitud de salida, tiempo de espera y reintentos.
- Reserva de cuota transaccional con identificador idempotente; no cobrar al usuario por solicitudes inválidas o respuestas fallidas del proveedor. Bloqueo antiabuso separado para fallos repetidos.
- Recuperar pasajes desde fuentes validadas. Comprobar citas, no inventar libros/versículos y expresar incertidumbre. No usar oraciones generadas como texto oficial del día.
- Pruebas de instrucciones maliciosas, manipulación de historial, datos de otras cuentas, error 429, timeout, cambio de modelo y agotamiento de cuota. Respuestas cuidadosas ante sufrimiento, sin sustituir apoyo profesional o pastoral.
- Medir tokens, latencia y errores sin registrar conversaciones sensibles. Documentar tratamiento y borrado de datos.

Aceptación: evaluación de 30 casos en español repartidos por tradición y preguntas de referencia verificable; cero citas inventadas aceptadas en la batería; pruebas automáticas del contrato y límites; prueba real de extremo a extremo con credenciales del servidor antes de declarar el chat operativo.

## Entrega 6: suscripción mensual

Propuesta de producto, aún sin fijar precio ni cuotas comerciales:

| Gratis | Verbum Plus mensual |
| --- | --- |
| Biblia, versículo y oraciones esenciales | Sin anuncios |
| Contenido litúrgico básico disponible | Itinerarios y audios adicionales cuando existan |
| Un widget y tarjetas básicas para compartir | Más estilos y personalización de widgets/tarjetas |
| Cuota pequeña de IA | Cuota mayor, explícita y medida |

No vender acceso a la fe ni bloquear la función básica de compartir. No prometer IA ilimitada, fuentes religiosas más «verdaderas» en Plus ni prestaciones que aún no existen.

- Calcular precio a partir de coste por respuesta y consumo mensual alto (p95), comisión de tienda, infraestructura, derechos de contenido, soporte e impuestos aplicables. Confirmar tarifas del proveedor y condiciones de la cuenta; no tomar los precios de un modelo Enterprise como tarifa pública garantizada.
- Sustituir el indicador local por derechos de acceso verificados en servidor, restauración y gestión desde Google Play. Validar tokens mediante Google Play Developer API y procesar RTDN con idempotencia.
- Cubrir pendiente, compra, renovación, cancelación con acceso hasta vencimiento, gracia, suspensión, expiración, reembolso y restauración en otro dispositivo.
- Conservar derechos de quienes hubieran comprado `remove_ads`; no convertir su compra histórica en una obligación mensual.
- Proteger los derechos y cuotas con reglas de Firestore. No confiar en `isPremium` enviado por Flutter.

Aceptación: compras con cuentas de prueba, notificaciones repetidas/desordenadas, reinstalación, dos dispositivos, pérdida de red, expiración y restauración. Precios visibles obtenidos de Play, no fijados en textos de Flutter.

## Cierre y Git

Cada entrega se verifica de forma independiente. Antes de commit/push conjunto: análisis, pruebas relevantes, compilación de desarrollo y regresión manual de ingreso, Hoy, Biblia, oraciones, comunidad, compartir y notificaciones. Revisar el diff completo, preservar cambios previos y excluir claves, contraseñas y artefactos. La compilación de producción y publicación quedan para una confirmación posterior.

## Fuentes consultadas

- [Firebase App Check: versiones y cambios](https://pub.dev/packages/firebase_app_check/changelog).
- [Android: widgets en bloqueo y limitaciones del host](https://android-developers.googleblog.com/2025/03/widgets-on-lock-screen-faq.html).
- [Catecismo, canon de las Escrituras, n. 120](https://www.vatican.va/archive/catechism_sp/p1s1c2a3_sp.html).
- [Calendario litúrgico 2025–2026 de la CEE: referencia de España, no calendario universal por país](https://www.conferenciaepiscopal.es/wp-content/uploads/2025/12/calendario-liturgico-25-26.pdf).
- [Firebase: secretos para Cloud Functions](https://firebase.google.com/docs/functions/config-env).
- [Groq: modelos disponibles, acceso y precios publicados](https://console.groq.com/docs/models).
- [Google Play: servidor y ciclo de compras](https://developer.android.com/google/play/billing/backend).
