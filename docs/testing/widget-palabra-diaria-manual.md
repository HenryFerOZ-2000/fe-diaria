# Verificación manual — Widget Palabra del día

- Fecha: 2026-09-21
- Dispositivo previsto: Pixel 2 XL (`801KPXV1373074`)
- Android: 11 (API 30)
- Launcher: no confirmado durante esta sesión
- APK: `build/app/outputs/flutter-apk/app-debug.apk`
- Estado del dispositivo: se detectó inicialmente, pero se desconectó durante `adb install`; al cierre solo apareció un emulador offline.

## Evidencia automática previa

- Catálogo y recursos Android: 8/8 pruebas Python.
- Flutter: 74/74 pruebas, incluida adaptación a 320 px con texto al 200 %.
- Kotlin/JUnit: 6/6 pruebas.
- `flutter analyze`: sin incidencias.
- `flutter build apk --debug`: completado.
- No existe `build/app/outputs/bundle`; no se generó un AAB.

## Matriz física

`NO DISPONIBLE` no equivale a fallo funcional: indica que el teléfono dejó de estar accesible por ADB antes de poder observar el resultado.

| Caso | Resultado | Evidencia/nota |
| --- | --- | --- |
| Añadir desde Configuración | NO DISPONIBLE | Flujo cubierto por prueba de widget; falta confirmar el diálogo real del launcher. |
| Añadir desde selector del launcher | NO DISPONIBLE | Requiere interacción física con el launcher. |
| Compacto 2×1 | NO DISPONIBLE | Selector de tamaño cubierto por JUnit; falta revisión visual nativa. |
| Mediano 4×2 | NO DISPONIBLE | Selector de tamaño cubierto por JUnit; falta revisión visual nativa. |
| Grande 4×3 | NO DISPONIBLE | Selector de tamaño cubierto por JUnit; falta revisión visual nativa. |
| Claro y oscuro | NO DISPONIBLE | Paletas y recursos nocturnos validados estructuralmente; falta inspección física. |
| Fuente del sistema grande | NO DISPONIBLE | La vista Flutter pasa a 320 px/200 %; falta inspeccionar RemoteViews en el launcher. |
| Sin conexión y app cerrada | NO DISPONIBLE | El catálogo RV1909 está empaquetado y el proveedor es autónomo; falta prueba física. |
| Dos instancias | NO DISPONIBLE | Requiere dos widgets instalados en el dispositivo. |
| Reinicio | NO DISPONIBLE | `BOOT_COMPLETED` está registrado y probado estructuralmente; falta reinicio físico. |
| Cambio de fecha/zona horaria | NO DISPONIBLE | Eventos registrados y probados estructuralmente; falta cambio físico. |
| Toque abre pasaje exacto | NO DISPONIBLE | Parser 3/3 y APK debug correctos; el teléfono se desconectó antes del ensayo frío/caliente. |
| Actualización sobre APK existente | NO DISPONIBLE | `adb install -r` no pudo ejecutarse porque desapareció el dispositivo. No se desinstaló la app. |
| Pantalla de bloqueo compatible/no compatible | NO DISPONIBLE | Depende del soporte del sistema/launcher; Android 11 no garantiza widgets de bloqueo. |

## Pasos al reconectar el dispositivo

1. Mantener instalada la versión actual y ejecutar `adb install -r build/app/outputs/flutter-apk/app-debug.apk`.
2. Revisar que el widget existente se redibuje y que no aparezca “Problema para cargar widget”.
3. Completar los tamaños 2×1, 4×2 y 4×3, temas claro/oscuro, fuente grande y dos instancias.
4. Probar en frío `verbum://biblia/JHN/3/16`, en caliente `verbum://biblia/PSA/23/1` y el fallback inválido.
5. Verificar la opción de pantalla de bloqueo; si el launcher no la ofrece, conservar el resultado como no compatible.
