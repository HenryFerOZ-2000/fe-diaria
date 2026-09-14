# Plan: incorporar tradición cristiana evangélica sin romper la app

Este documento define fases, archivos y decisiones para convivencia **católica + cristiana evangélica** (valores de almacenamiento actuales: `catolica` | `cristiana`). Ninguna fase elimina funcionalidades para usuarios católicos o sin preferencia guardada.

## Principios

1. **Una sola preferencia** en Hive (`traditionalPrayersReligion`) actúa como **tradición de la app** para contenido y tono, además del catálogo de oraciones tradicionales ampliadas.
2. **Sin duplicar pantallas** por tradición: la UI comparte widgets; cambian datos, visibilidad y textos.
3. **Valores vacíos (`''`)** = usuario sin elección explícita: se trata como **unset** (misma experiencia católica completa que hoy: rosario, santos, novena, etiquetas actuales, prompt católico en chat).

## Línea base ya implementada en el repo

| Elemento | Ubicación |
|----------|-----------|
| Enum y parse desde storage | `lib/faith/faith_tradition.dart` |
| Qué módulos mostrar / copy comunidad | `lib/faith/tradition_capabilities.dart` |
| Categorías: ocultar rosario, santos, novena si `cristiana` | `lib/screens/categories_screen.dart` |
| Etiquetas comunidad (sacerdote vs pastor) | `lib/screens/community_screen.dart` |
| Chat: envío de `faithTradition` y prompt en servidor | `lib/services/groq_chat_service.dart`, `api/src/index.ts`, `api/src/groqConfig.ts` (`CHAT_PROMPT_EVANGELICAL`), `api/src/chat.interfaces.ts` |
| Documentación de la clave Hive | comentario en `lib/services/storage_service.dart` |

**Despliegue:** tras actualizar el cliente, ejecuta deploy de Cloud Functions (`api/`) para que `chatWithGroq` aplique el prompt evangélico cuando `faithTradition === "cristiana"`. Clientes antiguos que no envían el campo siguen usando solo el prompt católico hasta que actualicen.

## Fase A — Contenido diario y atajos (alta prioridad)

**Objetivo:** coherencia en “Hoy” y pestaña Oraciones.

- `DailyContentService` / `assets/data/morning_prayers.json`, `night_prayers.json`: ramificar por tradición (segundo set en `assets/traditions/evangelical/` o claves en JSON) y cargar según `FaithTradition`.
- `PrayersScreen` + `traditional_prayers.json` / `TraditionalPrayerScreen`: atajos actuales (Ave María, credo católico, etc.) deben ser **católicos solo si** tradición católica/unset; para evangélicos, lista distinta o enlace al flujo `oraciones.json` → `cristiana`.

**Riesgo si se omite:** usuario evangélico sigue viendo oraciones marcadamente católicas en la pestaña principal.

## Fase B — Onboarding / primera ejecución

**Objetivo:** elegir tradición al inicio sin romper usuarios existentes.

- Tras bienvenida u onboarding, pantalla única de elección que llama a `StorageService.setTraditionalPrayersReligion`.
- Usuarios con `onboardingCompleted == true` y religión vacía: opcional “preguntar una vez” en actualización, o mantener unset (comportamiento actual).

## Fase C — Assets y descubrimiento

**Objetivo:** saber “dónde está cada cosa”.

- Mover gradualmente JSON por tradición a `assets/traditions/catholic/` y `assets/traditions/evangelical/` (o un solo JSON con raíz por clave, documentado).
- Un servicio tipo `PrayerCatalogRepository` que reciba `FaithTradition` y resuelva rutas.

## Fase D — Producto y backend opcional

- Ajustar textos legales / FAQ si mencionan solo catolicismo.
- Si el chat crece: versionar prompts, telemetría por tradición, límites separados (opcional).

## Checklist de regresión manual

- [ ] Religión vacía: categorías muestran rosario, santos, novena; chat tono católico.
- [ ] `catolica`: igual que arriba.
- [ ] `cristiana`: sin rosario/santos/novena en categorías; etiquetas comunidad “Pastor”; chat tono evangélico (tras deploy API).
- [ ] Oraciones tradicionales ampliadas siguen usando `oraciones.json` por rama.

## Notas

- Los católicos son cristianos; en producto conviene usar etiquetas claras (“Católica”, “Cristiana evangélica”) como ya hace la pantalla de selección.
- Este plan se puede cerrar por fases sin reescribir toda la app de una vez.
