# Verificación del compositor de tarjetas de Verbum

Fecha: 2026-09-22. Base de comparación: `backup/pre-share-composer-2026-09-22`.

## Evidencia automática

Las pruebas de Flutter verifican lógica, widgets y archivos PNG en el entorno de pruebas. No prueban por sí solas el comportamiento de WhatsApp, Instagram, MediaStore ni la hoja nativa instalada en un teléfono.

- [x] Las pruebas de paginación reconstruyen el texto completo, conservan el orden y verifican la numeración de varias páginas.
- [x] El render comprueba las dimensiones exactas de cada PNG. Las pruebas de tarjeta y captura cubren 1080 × 1080, 1080 × 1350 y 1080 × 1920.
- [x] Las pruebas de exportación verifican un conjunto de tres imágenes, el mensaje completo, cancelación y limpieza de temporales. Una llamada nativa con cero archivos también sería detectada por el contador explícito de llamadas; el fallo de render debe producir cero llamadas.
- [x] Las pruebas del compositor verifican progreso, bloqueo de acciones duplicadas, reintento, copia, cierre, estilo independiente del tema y exportación de todas las páginas.
- [x] Un fallo al enviar imágenes ofrece `Compartir como texto` con el mensaje completo. Las pruebas cubren éxito, cancelación silenciosa, fallo recuperable y reintento de texto; un fallo de render no muestra esa alternativa. La opción también se ejercita a 320 × 568 con texto al 200 %.
- [x] El gesto lento hacia la izquierda cambia de ambiente sin alterar texto ni referencia. La misión sin versículo disponible no habilita Compartir ni inventa una fuente RV1909.
- [x] Las entradas de contenido conservan cuerpo, referencia y metadatos. La fixture de AppProvider evita inicialización ajena de SQLite, notificaciones y widgets.
- [x] Los recursos de tarjeta se prueban con la red deshabilitada. La pantalla se prueba a 320 × 568 con texto al 200 % y a 390 × 844; esto no sustituye la inspección de un dispositivo grande.
- [x] No hay coincidencias en `lib`/`test` para las API antiguas de ShareService, `Share.shareXFiles` ni la búsqueda genérica de App Store. Tampoco quedan llamadas estáticas `Share.share(` en `lib`.
- [x] Las cinco llamadas excluidas del compositor (invitaciones/comunidad/publicaciones en vivo) usan `SharePlus.instance.share(ShareParams(...))`, conservando textos y asuntos.

Resultados finales en el código de `fda5109` (incluye `6d2f82e`):

| Comprobación | Resultado observado |
| --- | --- |
| `dart format --set-exit-if-changed lib test` | 249 archivos; cero cambios; salida 0. |
| `flutter analyze` | `No issues found!`; salida 0. |
| `flutter test --reporter expanded` | 167 pruebas aprobadas; cero fallos; salida 0. |
| `flutter build apk --debug` | APK creado correctamente; ejecución final incremental: 54,7 s; salida 0. |
| Metadatos del APK | `com.ozcorp.verbum`, código 10, versión 1.0.6, `debuggable=true`. |

APK local: `build/app/outputs/flutter-apk/app-debug.apk`. La compilación emite advertencias existentes de migración futura a Built-in Kotlin y avisa que no hay firma release configurada en este worktree; no son errores de esta compilación debug. La suite conserva mensajes diagnósticos esperados de las pruebas de liturgia y carga de datos, sin fallos.

## Recuperación de errores de galería

El gateway traduce los tipos reales de `gal 2.3.3` (`accessDenied`, `notEnoughSpace`, `notSupportedFormat`, `unexpected`) a causas propias. El coordinador muestra una explicación en español y mantiene el error nativo, sus detalles y su traza dentro de `ShareExportFailure.cause`; nunca los imprime en el mensaje visible. Las pruebas recorren el canal de Gal, el gateway y el coordinador, verificando permiso denegado durante la solicitud o el guardado, falta de espacio, formato no admitido y códigos desconocidos. También comprueban la limpieza de todas las páginas temporales y que después del fallo se puede iniciar otra exportación para compartir.

La detección de almacenamiento insuficiente depende de la señal tipada del plugin. En su implementación Android, Gal clasifica algunos `IOException` por el texto nativo `No space left on device`; en Apple usa el código de PhotoKit `3305`. Por tanto, un sistema que devuelva otro error puede quedar clasificado como desconocido. Verbum no añade comparaciones frágiles de mensajes: si Gal no proporciona una causa reconocible, ofrece reintentar o compartir con un mensaje seguro. Esta clasificación está verificada con respuestas del canal simuladas y aún requiere comprobar los permisos reales en dispositivo.

Después de esta corrección, `flutter test --reporter expanded` aprobó 174 pruebas y `flutter analyze` terminó sin incidencias. Las 41 pruebas focalizadas de coordinador/compositor también aprobaron. El reintento tras fallo de render se verifica tanto al guardar como al compartir, con cero llamadas a compartir texto. No se volvió a generar un APK en esta corrección.

## Comprobaciones en dispositivo

Estado de todas las casillas siguientes: **REQUIERE VALIDACIÓN MANUAL EN DISPOSITIVO**. No se ejecutaron en una aplicación física durante esta verificación.

Registrar antes de empezar: modelo, versión de Android, versión de WhatsApp/Instagram, tamaño de pantalla, escala de texto, fecha y persona que prueba. Usar únicamente el APK de depuración.

- [ ] **REQUIERE VALIDACIÓN MANUAL EN DISPOSITIVO** — Versículo breve: abrir Compartir desde la Biblia o favoritos, revisar texto y referencia completos, logo real y formato inicial 4:5. Cambiar los tres ambientes y los tres formatos; comprobar legibilidad, ausencia de recorte y coincidencia entre vista previa y archivo.
- [ ] **REQUIERE VALIDACIÓN MANUAL EN DISPOSITIVO** — Oración de tres páginas: elegir contenido que muestre `1 de 3`, recorrer las tres páginas y comparar el texto con el lector original. Confirmar continuidad, puntuación y numeración sin pérdida ni repetición.
- [ ] **REQUIERE VALIDACIÓN MANUAL EN DISPOSITIVO** — WhatsApp: enviar el conjunto anterior a un chat de prueba, comprobar tres imágenes en orden y texto acompañante con la URL real de Google Play. Revisar las imágenes recibidas a tamaño completo.
- [ ] **REQUIERE VALIDACIÓN MANUAL EN DISPOSITIVO** — Instagram: comprobar que aparece como destino, abrir una imagen 4:5 para publicación y una 9:16 para historia. Revisar que el selector respete las imágenes y que el contenido quede dentro del área visible. Registrar cualquier limitación de la aplicación receptora.
- [ ] **REQUIERE VALIDACIÓN MANUAL EN DISPOSITIVO** — Hoja genérica de Android: abrir desde Compartir, elegir otra aplicación y comprobar recepción, orden, texto y enlace. No debe aparecer un selector propio de redes.
- [ ] **REQUIERE VALIDACIÓN MANUAL EN DISPOSITIVO** — Guardar en galería: guardar un versículo y la oración completa, abrir las imágenes en la galería y confirmar dimensiones y contenido. Probar un dispositivo con Android 10 o posterior y, si se soporta, Android 9 para verificar la solicitud limitada de permiso de escritura.
- [ ] **REQUIERE VALIDACIÓN MANUAL EN DISPOSITIVO** — Copiar y pegar: pegar en una aplicación de notas y confirmar título, referencia cuando exista, cuerpo completo y enlace `https://play.google.com/store/apps/details?id=com.ozcorp.verbum`. El enlace no debe estar impreso dentro de la tarjeta.
- [ ] **REQUIERE VALIDACIÓN MANUAL EN DISPOSITIVO** — Cancelación: cancelar la hoja de imágenes y la alternativa de texto; comprobar que no aparece un error, se libera el progreso y el contenido original permanece intacto. Cerrar y volver a abrir el compositor.
- [ ] **REQUIERE VALIDACIÓN MANUAL EN DISPOSITIVO** — Recuperación: provocar un fallo del envío de imágenes, elegir `Compartir como texto` y verificar el mensaje completo. Cancelar esa alternativa y volver a intentar; un fallo de render debe ofrecer reintento de imagen. Denegar el permiso de galería cuando proceda y comprobar el mensaje y la posibilidad de seguir compartiendo.
- [ ] **REQUIERE VALIDACIÓN MANUAL EN DISPOSITIVO** — Modo avión: con contenido ya disponible, abrir el compositor, cambiar ambientes/formatos, generar todas las páginas y guardar. Confirmar fondos, fuentes y logo sin conexión; el envío remoto depende de la aplicación receptora.
- [ ] **REQUIERE VALIDACIÓN MANUAL EN DISPOSITIVO** — Pantalla equivalente a 320 px y dispositivo grande: repetir con escala normal y 200 %, comprobar controles alcanzables, navegación por páginas y ausencia de desbordamientos; revisar también la recuperación de errores.
- [ ] **REQUIERE VALIDACIÓN MANUAL EN DISPOSITIVO** — Modo claro y oscuro: revisar controles, contraste, lector de pantalla y objetivos táctiles; confirmar que el ambiente exportado conserva su apariencia al cambiar el tema del sistema.

Anotar junto a cada casilla: resultado observado, modelo, fecha y evidencia (captura o archivo). Mantener sin marcar cualquier caso no ejecutado.

## Integridad de versión, firma y publicación

- [x] `android/app/build.gradle.kts` no presenta cambios respecto a la etiqueta de respaldo: `applicationId = "com.ozcorp.verbum"`, `versionCode = 10`, `versionName = flutter.versionName`.
- [x] `pubspec.yaml` conserva `version: 1.0.6+10`; los cambios del módulo afectan dependencias y recursos locales, no la versión.
- [x] No se copió ni creó una configuración de firma de producción en este worktree. La compilación usa la variante debug.
- [x] `android/app/google-services.json` es un requisito local ignorado por Git y no se incluye en commits.
- [x] Los SHA-256 de `android/key.properties` y `release-key.keystore` del repositorio principal coinciden con la instantánea de esta verificación; también coincide el de `android/app/build.gradle.kts` del worktree.
- [x] El inventario de `build/` del worktree contenía cero AAB/APK release antes y después. El APK generado declara `debuggable=true`; no se generó un artefacto de producción.

No se ejecutó `flutter build appbundle` ni una compilación release. Esta lista no constituye validación para publicar en Google Play.
