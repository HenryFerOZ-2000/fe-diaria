# Widget de la Palabra diaria Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sustituir el widget Android simple por la familia visual editorial aprobada, alimentada sin conexión por el mismo versículo RV1909 que Verbum y capaz de abrir el pasaje exacto.

**Architecture:** Un generador determinista convertirá las referencias y la base RV1909 existentes en un catálogo Android versionado. Kotlin resolverá la fecha local, seleccionará el layout `RemoteViews` según el tamaño y atenderá el ciclo de vida sin depender de Flutter; el puente Flutter solo permitirá actualizar, consultar y solicitar la fijación. La navegación usará `verbum://biblia/<bookId>/<chapter>/<verse>` y una pantalla Flutter sencilla permitirá añadir el widget.

**Tech Stack:** Flutter 3.47/Dart 3.13, Kotlin/JVM 11, Android `AppWidgetProvider` + `RemoteViews`, MethodChannel, Python 3 `unittest` + `sqlite3`, JUnit 4.

**Spec:** `docs/superpowers/specs/2026-09-21-widget-palabra-diaria-design.md`

## Global Constraints

- La fuente bíblica es únicamente `assets/data/daily_verses_refs.json` + `assets/db/rv1909.sqlite`, identificada como `RV1909`.
- La selección diaria es `(año * 10000 + mes * 100 + día) % cantidad`, usando la fecha local del dispositivo.
- No añadir personalización por emoción, tradición, color, fuente o fondo.
- No añadir red, Firebase, WorkManager, alarmas exactas, anuncios, chat, oraciones ni datos privados al widget.
- Mantener `applicationId = "com.ozcorp.verbum"`, `versionCode = 10` y `versionName = 1.0.6`.
- No modificar la App Signing Key, la Upload Key ni `key.properties`.
- No ejecutar `flutter build appbundle --release`, no generar `app-release.aab` y no publicar en Google Play.
- Verificar solamente con pruebas, análisis y compilación APK de depuración.
- Los layouts nativos deben usar únicamente vistas compatibles con `RemoteViews`.

## Review Focus

- **Actualización con un widget ya instalado:** `MY_PACKAGE_REPLACED` debe redibujar las instancias para que el launcher no conserve recursos del APK anterior; Task 4 lo fija con prueba estructural y Task 8 con prueba manual.
- **Catálogo ausente, vacío o corrupto:** debe mostrarse el mensaje seguro y nunca un versículo anterior etiquetado como actual; Tasks 1, 2 y 4 lo prueban.
- **Medianoche, año bisiesto y cambio de zona horaria:** Flutter y Kotlin deben seleccionar el mismo índice de la fecha local; Tasks 1, 2 y 4 lo prueban.
- **Tamaño compacto y fuente del sistema al 200 %:** el widget y la pantalla de ayuda no deben desbordarse; Tasks 3 y 7 lo prueban.
- **Apertura fría, apertura en caliente y URI inválida:** el enlace válido abre el versículo exacto y el inválido cae en Biblia; Task 6 lo prueba.

---

## File Structure

### Generación y validación de datos

- Create: `tools/generate_android_widget_catalog.py` — genera el catálogo Android sin modificar las fuentes.
- Create: `tools/test_android_widget_catalog.py` — valida orden, determinismo, referencias y paridad con el archivo versionado.
- Create: `android/app/src/main/res/raw/daily_verses_rv1909.json` — catálogo empacado que Kotlin puede leer sin Flutter.

### Dominio y presentación nativa

- Create: `android/app/src/main/kotlin/com/ozcorp/verbum/widget/DailyVerseRecord.kt` — modelo nativo inmutable.
- Create: `android/app/src/main/kotlin/com/ozcorp/verbum/widget/DailyVerseResolver.kt` — fórmula diaria pura.
- Create: `android/app/src/main/kotlin/com/ozcorp/verbum/widget/DailyVerseCatalog.kt` — lectura validada de `res/raw`.
- Create: `android/app/src/main/kotlin/com/ozcorp/verbum/widget/WidgetLayoutSelector.kt` — selección pura de compacto, mediano o grande.
- Create: `android/app/src/main/kotlin/com/ozcorp/verbum/widget/VerseWidgetRenderer.kt` — construcción de `RemoteViews` y `PendingIntent`.
- Modify: `android/app/src/main/kotlin/com/ozcorp/verbum/VerseWidgetProvider.kt` — coordinación del ciclo de vida.
- Modify: `android/app/src/main/kotlin/com/ozcorp/verbum/MainActivity.kt` — métodos del puente Flutter.
- Modify: `android/app/src/main/AndroidManifest.xml` — deep link y eventos explícitos del widget.
- Modify: `android/app/src/main/res/xml/widget_info.xml` — dimensiones, período y categorías.
- Create: `android/app/src/main/res/layout/widget_compact.xml` — variante 2×1.
- Create: `android/app/src/main/res/layout/widget_medium.xml` — variante 4×2.
- Create: `android/app/src/main/res/layout/widget_large.xml` — variante 4×3.
- Delete: `android/app/src/main/res/layout/widget_layout.xml` — reemplazado después de que ningún recurso lo referencie.
- Create: `android/app/src/main/res/drawable/widget_background.xml` — superficie editorial redondeada.
- Create: `android/app/src/main/res/drawable/widget_seal_background.xml` — sello discreto de Verbum.
- Modify: `android/app/src/main/res/values/colors.xml` — paleta clara del widget.
- Create: `android/app/src/main/res/values-night/colors.xml` — paleta oscura.
- Modify: `android/app/src/main/res/values/strings.xml` — copias nativas en español.
- Modify: `android/app/build.gradle.kts` — JUnit 4 para lógica Kotlin pura.
- Create: `android/app/src/test/kotlin/com/ozcorp/verbum/widget/DailyVerseResolverTest.kt`.
- Create: `android/app/src/test/kotlin/com/ozcorp/verbum/widget/WidgetLayoutSelectorTest.kt`.
- Create: `tools/test_android_widget_resources.py` — contrato estructural del manifest y XML.

### Flutter

- Modify: `lib/services/widget_service.dart` — API de fijación, estado y redibujado.
- Create: `lib/services/bible_deep_link.dart` — modelo y parser puros de URI bíblica.
- Modify: `lib/services/deep_link_service.dart` — URI inicial, stream y navegación validada.
- Create: `lib/screens/daily_verse_widget_screen.dart` — vista previa e instrucciones.
- Create: `lib/widgets/daily_verse_widget_preview.dart` — representación Flutter de la familia visual.
- Modify: `lib/screens/settings_screen.dart` — acceso “Widget de la Palabra”.
- Modify: `lib/l10n/app_localizations.dart` — copias es/en/pt de la nueva pantalla.
- Modify: `lib/providers/app_provider.dart` — redibujado canónico, sin pasar contenido personalizado.
- Modify: `lib/main.dart` — inicialización del servicio y ruta de configuración.
- Create: `test/widget_service_test.dart`.
- Create: `test/bible_deep_link_test.dart`.
- Create: `test/daily_verse_widget_screen_test.dart`.

### Verificación

- Create: `docs/testing/widget-palabra-diaria-manual.md` — matriz y resultados de dispositivos.

---

### Task 1: Generar un catálogo Android determinista desde RV1909

**Files:**
- Create: `tools/generate_android_widget_catalog.py`
- Create: `tools/test_android_widget_catalog.py`
- Create: `android/app/src/main/res/raw/daily_verses_rv1909.json`

**Interfaces:**
- Consumes: `assets/data/daily_verses_refs.json`, `assets/db/rv1909.sqlite`, `lib/bible/domain/bible_book_info.dart`.
- Produces: `build_catalog(refs_path: Path, db_path: Path, books_path: Path) -> list[dict[str, object]]` y JSON UTF-8 ordenado para `DailyVerseCatalog.load(Context)`.

- [ ] **Step 1: Escribir pruebas fallidas de orden, validación y determinismo**

Crear `tools/test_android_widget_catalog.py` con fixtures temporales y estas aserciones:

```python
import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

from tools.generate_android_widget_catalog import build_catalog, encode_catalog


class AndroidWidgetCatalogTest(unittest.TestCase):
    def test_preserves_reference_order_and_exact_rv1909_text(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            refs = root / "refs.json"
            db = root / "rv.sqlite"
            books = root / "books.dart"
            refs.write_text(json.dumps([
                {"book": "PSA", "chapter": 23, "verse": 1},
                {"book": "JHN", "chapter": 3, "verse": 16},
            ]), encoding="utf-8")
            books.write_text(
                "BibleBookInfo(id: 'PSA', name: 'Salmos', section: 'x', testament: BibleTestament.old),\n"
                "BibleBookInfo(id: 'JHN', name: 'Juan', section: 'x', testament: BibleTestament.newTestament),",
                encoding="utf-8",
            )
            with sqlite3.connect(db) as connection:
                connection.execute("CREATE TABLE verses(book TEXT, chapter INTEGER, verse INTEGER, text TEXT)")
                connection.executemany(
                    "INSERT INTO verses VALUES (?, ?, ?, ?)",
                    [("PSA", 23, 1, "Jehová es mi pastor; nada me faltará."),
                     ("JHN", 3, 16, "Porque de tal manera amó Dios al mundo...")],
                )
            records = build_catalog(refs, db, books)
            repeated = build_catalog(refs, db, books)
            self.assertEqual([r["reference"] for r in records], ["Salmos 23:1", "Juan 3:16"])
            self.assertEqual(records[0]["text"], "Jehová es mi pastor; nada me faltará.")
            self.assertEqual(encode_catalog(records), encode_catalog(repeated))

    def test_rejects_a_reference_missing_from_rv1909(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "refs.json").write_text('[{"book":"JHN","chapter":3,"verse":16}]', encoding="utf-8")
            (root / "books.dart").write_text("BibleBookInfo(id: 'JHN', name: 'Juan',", encoding="utf-8")
            with sqlite3.connect(root / "rv.sqlite") as connection:
                connection.execute("CREATE TABLE verses(book TEXT, chapter INTEGER, verse INTEGER, text TEXT)")
            with self.assertRaisesRegex(ValueError, "JHN 3:16"):
                build_catalog(root / "refs.json", root / "rv.sqlite", root / "books.dart")

    def test_rejects_undeclared_duplicate_references(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            duplicate = {"book": "JHN", "chapter": 3, "verse": 16}
            (root / "refs.json").write_text(json.dumps([duplicate, duplicate]), encoding="utf-8")
            (root / "books.dart").write_text("BibleBookInfo(id: 'JHN', name: 'Juan',", encoding="utf-8")
            with sqlite3.connect(root / "rv.sqlite") as connection:
                connection.execute("CREATE TABLE verses(book TEXT, chapter INTEGER, verse INTEGER, text TEXT)")
                connection.execute("INSERT INTO verses VALUES ('JHN', 3, 16, 'Texto')")
            with self.assertRaisesRegex(ValueError, "duplicada"):
                build_catalog(root / "refs.json", root / "rv.sqlite", root / "books.dart")

    def test_preserves_the_known_psalm_121_8_repeat(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            repeated = {"book": "PSA", "chapter": 121, "verse": 8}
            (root / "refs.json").write_text(json.dumps([repeated, repeated]), encoding="utf-8")
            (root / "books.dart").write_text("BibleBookInfo(id: 'PSA', name: 'Salmos',", encoding="utf-8")
            with sqlite3.connect(root / "rv.sqlite") as connection:
                connection.execute("CREATE TABLE verses(book TEXT, chapter INTEGER, verse INTEGER, text TEXT)")
                connection.execute("INSERT INTO verses VALUES ('PSA', 121, 8, 'Jehová guardará tu salida.')")
            records = build_catalog(root / "refs.json", root / "rv.sqlite", root / "books.dart")
            self.assertEqual(len(records), 2)
            self.assertEqual([r["reference"] for r in records], ["Salmos 121:8", "Salmos 121:8"])
```

- [ ] **Step 2: Ejecutar la prueba y comprobar que falla por el módulo ausente**

Run:

```powershell
python -m unittest tools.test_android_widget_catalog -v
```

Expected: FAIL con `ModuleNotFoundError: No module named 'tools.generate_android_widget_catalog'`.

- [ ] **Step 3: Implementar el generador con validación estricta**

Crear `tools/generate_android_widget_catalog.py` con estas funciones y salida estable:

```python
from __future__ import annotations

import argparse
import json
import re
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_REFS = ROOT / "assets/data/daily_verses_refs.json"
DEFAULT_DB = ROOT / "assets/db/rv1909.sqlite"
DEFAULT_BOOKS = ROOT / "lib/bible/domain/bible_book_info.dart"
DEFAULT_OUTPUT = ROOT / "android/app/src/main/res/raw/daily_verses_rv1909.json"
ALLOWED_DUPLICATE_COUNTS = {("PSA", 121, 8): 2}


def _book_names(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    return dict(re.findall(r"id: '([^']+)',\s+name: '([^']+)'", text))


def build_catalog(refs_path: Path, db_path: Path, books_path: Path) -> list[dict[str, object]]:
    refs = json.loads(refs_path.read_text(encoding="utf-8"))
    names = _book_names(books_path)
    if not isinstance(refs, list) or not refs:
        raise ValueError("El catálogo diario está vacío")
    records: list[dict[str, object]] = []
    seen: dict[tuple[str, int, int], int] = {}
    with sqlite3.connect(f"file:{db_path.as_posix()}?mode=ro", uri=True) as connection:
        for position, ref in enumerate(refs):
            book = ref.get("book")
            chapter = ref.get("chapter")
            verse = ref.get("verse")
            if book not in names or not isinstance(chapter, int) or not isinstance(verse, int):
                raise ValueError(f"Referencia inválida en posición {position}: {ref}")
            key = (book, chapter, verse)
            seen[key] = seen.get(key, 0) + 1
            if seen[key] > ALLOWED_DUPLICATE_COUNTS.get(key, 1):
                raise ValueError(f"Referencia duplicada: {book} {chapter}:{verse}")
            row = connection.execute(
                "SELECT text FROM verses WHERE book = ? AND chapter = ? AND verse = ?",
                (book, chapter, verse),
            ).fetchone()
            if row is None or not str(row[0]).strip():
                raise ValueError(f"No existe texto RV1909 para {book} {chapter}:{verse}")
            text = re.sub(r"\s+", " ", str(row[0])).strip()
            records.append({
                "bookId": book,
                "bookName": names[book],
                "chapter": chapter,
                "verse": verse,
                "reference": f"{names[book]} {chapter}:{verse}",
                "text": text,
                "edition": "RV1909",
            })
    return records


def encode_catalog(records: list[dict[str, object]]) -> str:
    return json.dumps(records, ensure_ascii=False, separators=(",", ":")) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    records = build_catalog(DEFAULT_REFS, DEFAULT_DB, DEFAULT_BOOKS)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(encode_catalog(records), encoding="utf-8", newline="\n")
    print(f"Generated {len(records)} records at {args.output}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Generar el catálogo y añadir la prueba de paridad del archivo versionado**

Run:

```powershell
python tools/generate_android_widget_catalog.py
```

Añadir a la prueba:

```python
def test_committed_catalog_matches_current_sources(self):
    root = Path(__file__).resolve().parents[1]
    expected = encode_catalog(build_catalog(
        root / "assets/data/daily_verses_refs.json",
        root / "assets/db/rv1909.sqlite",
        root / "lib/bible/domain/bible_book_info.dart",
    ))
    actual = (root / "android/app/src/main/res/raw/daily_verses_rv1909.json").read_text(encoding="utf-8")
    self.assertEqual(actual, expected)
```

- [ ] **Step 5: Ejecutar las pruebas y confirmar el catálogo real**

Run:

```powershell
python -m unittest tools.test_android_widget_catalog -v
python tools/audit_bible_content.py
```

Expected: todas las pruebas PASS; la auditoría confirma que las referencias diarias resuelven en RV1909.

- [ ] **Step 6: Commit**

```powershell
git add tools/generate_android_widget_catalog.py tools/test_android_widget_catalog.py android/app/src/main/res/raw/daily_verses_rv1909.json
git commit -m "feat(widget): generate offline RV1909 catalog"
```

---

### Task 2: Resolver el versículo diario de forma nativa y comprobable

**Files:**
- Modify: `android/app/build.gradle.kts:93`
- Create: `android/app/src/main/kotlin/com/ozcorp/verbum/widget/DailyVerseRecord.kt`
- Create: `android/app/src/main/kotlin/com/ozcorp/verbum/widget/DailyVerseResolver.kt`
- Create: `android/app/src/main/kotlin/com/ozcorp/verbum/widget/DailyVerseCatalog.kt`
- Create: `android/app/src/test/kotlin/com/ozcorp/verbum/widget/DailyVerseResolverTest.kt`

**Interfaces:**
- Consumes: `R.raw.daily_verses_rv1909` de Task 1.
- Produces: `DailyVerseCatalog.load(context): List<DailyVerseRecord>` y `DailyVerseResolver.resolve(records, date): DailyVerseRecord?` para el renderer.

- [ ] **Step 1: Añadir JUnit y escribir las pruebas fallidas del resolvedor**

Agregar a `dependencies`:

```kotlin
testImplementation("junit:junit:4.13.2")
```

Crear `DailyVerseResolverTest.kt`:

```kotlin
package com.ozcorp.verbum.widget

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class DailyVerseResolverTest {
    private val records = listOf(
        DailyVerseRecord("PSA", "Salmos", 23, 1, "Salmos 23:1", "A", "RV1909"),
        DailyVerseRecord("JHN", "Juan", 3, 16, "Juan 3:16", "B", "RV1909"),
        DailyVerseRecord("ROM", "Romanos", 8, 28, "Romanos 8:28", "C", "RV1909"),
    )

    @Test fun usesTheSameYyyymmddModuloFormulaAsFlutter() {
        val date = LocalDate.of(2026, 9, 21)
        assertEquals(20260921 % records.size, DailyVerseResolver.indexFor(date, records.size))
        assertEquals(records[20260921 % records.size], DailyVerseResolver.resolve(records, date))
    }

    @Test fun handlesLeapDayAndYearBoundary() {
        assertEquals(20240229 % 3, DailyVerseResolver.indexFor(LocalDate.of(2024, 2, 29), 3))
        assertEquals(20270101 % 3, DailyVerseResolver.indexFor(LocalDate.of(2027, 1, 1), 3))
    }

    @Test fun returnsNullForAnEmptyOrInvalidCatalog() {
        assertNull(DailyVerseResolver.resolve(emptyList(), LocalDate.of(2026, 9, 21)))
        assertNull(DailyVerseResolver.resolve(
            listOf(records.first().copy(text = "")),
            LocalDate.of(2026, 9, 21),
        ))
    }
}
```

- [ ] **Step 2: Ejecutar la prueba y confirmar que faltan los tipos**

Run:

```powershell
cd android
.\gradlew.bat :app:testDebugUnitTest --tests "com.ozcorp.verbum.widget.DailyVerseResolverTest"
```

Expected: FAIL por `Unresolved reference: DailyVerseRecord` y `DailyVerseResolver`.

- [ ] **Step 3: Implementar modelo, fórmula y validación mínima**

Crear `DailyVerseRecord.kt`:

```kotlin
package com.ozcorp.verbum.widget

data class DailyVerseRecord(
    val bookId: String,
    val bookName: String,
    val chapter: Int,
    val verse: Int,
    val reference: String,
    val text: String,
    val edition: String,
) {
    val isValid: Boolean
        get() = bookId.isNotBlank() && bookName.isNotBlank() && chapter > 0 && verse > 0 &&
            reference.isNotBlank() && text.isNotBlank() && edition == "RV1909"
}
```

Crear `DailyVerseResolver.kt`:

```kotlin
package com.ozcorp.verbum.widget

import java.time.LocalDate

object DailyVerseResolver {
    fun indexFor(date: LocalDate, size: Int): Int {
        require(size > 0) { "Catalog size must be positive" }
        val key = date.year * 10000 + date.monthValue * 100 + date.dayOfMonth
        return key % size
    }

    fun resolve(records: List<DailyVerseRecord>, date: LocalDate): DailyVerseRecord? {
        if (records.isEmpty() || records.any { !it.isValid }) return null
        return records[indexFor(date, records.size)]
    }
}
```

- [ ] **Step 4: Implementar la carga del JSON empacado sin caché de contenido antiguo**

Crear `DailyVerseCatalog.kt`:

```kotlin
package com.ozcorp.verbum.widget

import android.content.Context
import com.ozcorp.verbum.R
import org.json.JSONArray

object DailyVerseCatalog {
    @Volatile private var cached: List<DailyVerseRecord>? = null

    fun load(context: Context): List<DailyVerseRecord> {
        cached?.let { return it }
        return runCatching {
            val raw = context.resources.openRawResource(R.raw.daily_verses_rv1909)
                .bufferedReader(Charsets.UTF_8).use { it.readText() }
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    val item = array.getJSONObject(index)
                    add(DailyVerseRecord(
                        bookId = item.getString("bookId"),
                        bookName = item.getString("bookName"),
                        chapter = item.getInt("chapter"),
                        verse = item.getInt("verse"),
                        reference = item.getString("reference"),
                        text = item.getString("text"),
                        edition = item.getString("edition"),
                    ))
                }
            }.also { records ->
                require(records.isNotEmpty() && records.all { it.isValid })
                cached = records
            }
        }.getOrElse { emptyList() }
    }
}
```

- [ ] **Step 5: Ejecutar la prueba del resolvedor**

Run:

```powershell
cd android
.\gradlew.bat :app:testDebugUnitTest --tests "com.ozcorp.verbum.widget.DailyVerseResolverTest"
```

Expected: PASS.

- [ ] **Step 6: Commit**

```powershell
git add android/app/build.gradle.kts android/app/src/main/kotlin/com/ozcorp/verbum/widget android/app/src/test/kotlin/com/ozcorp/verbum/widget/DailyVerseResolverTest.kt
git commit -m "feat(widget): resolve daily verse natively"
```

---

### Task 3: Construir la familia visual responsiva y sus temas

**Files:**
- Create: `android/app/src/main/kotlin/com/ozcorp/verbum/widget/WidgetLayoutSelector.kt`
- Create: `android/app/src/test/kotlin/com/ozcorp/verbum/widget/WidgetLayoutSelectorTest.kt`
- Create: `android/app/src/main/kotlin/com/ozcorp/verbum/widget/VerseWidgetRenderer.kt`
- Create: `android/app/src/main/res/layout/widget_compact.xml`
- Create: `android/app/src/main/res/layout/widget_medium.xml`
- Create: `android/app/src/main/res/layout/widget_large.xml`
- Create: `android/app/src/main/res/drawable/widget_background.xml`
- Create: `android/app/src/main/res/drawable/widget_seal_background.xml`
- Modify: `android/app/src/main/res/values/colors.xml`
- Create: `android/app/src/main/res/values-night/colors.xml`
- Modify: `android/app/src/main/res/values/strings.xml`
- Modify: `android/app/src/main/res/xml/widget_info.xml`
- Create: `tools/test_android_widget_resources.py`

**Interfaces:**
- Consumes: `DailyVerseRecord` de Task 2 y opciones `AppWidgetManager`.
- Produces: `WidgetLayoutSelector.select(minWidthDp, minHeightDp): WidgetLayoutSize` y `VerseWidgetRenderer.render(context, manager, widgetId, record)`.

- [ ] **Step 1: Escribir la prueba fallida de selección de tamaño**

Crear `WidgetLayoutSelectorTest.kt`:

```kotlin
package com.ozcorp.verbum.widget

import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetLayoutSelectorTest {
    @Test fun choosesCompactForSmallHosts() {
        assertEquals(WidgetLayoutSize.COMPACT, WidgetLayoutSelector.select(110, 60))
    }

    @Test fun choosesMediumForFourByTwoSpace() {
        assertEquals(WidgetLayoutSize.MEDIUM, WidgetLayoutSelector.select(250, 110))
    }

    @Test fun choosesLargeOnlyWhenHeightCanKeepMetadataVisible() {
        assertEquals(WidgetLayoutSize.LARGE, WidgetLayoutSelector.select(250, 180))
    }
}
```

- [ ] **Step 2: Ejecutar la prueba y comprobar el fallo por tipos ausentes**

Run:

```powershell
cd android
.\gradlew.bat :app:testDebugUnitTest --tests "com.ozcorp.verbum.widget.WidgetLayoutSelectorTest"
```

Expected: FAIL por `Unresolved reference: WidgetLayoutSize`.

- [ ] **Step 3: Implementar el selector puro**

Crear `WidgetLayoutSelector.kt`:

```kotlin
package com.ozcorp.verbum.widget

enum class WidgetLayoutSize { COMPACT, MEDIUM, LARGE }

object WidgetLayoutSelector {
    fun select(minWidthDp: Int, minHeightDp: Int): WidgetLayoutSize = when {
        minWidthDp >= 250 && minHeightDp >= 180 -> WidgetLayoutSize.LARGE
        minWidthDp >= 250 && minHeightDp >= 100 -> WidgetLayoutSize.MEDIUM
        else -> WidgetLayoutSize.COMPACT
    }
}
```

- [ ] **Step 4: Escribir el contrato estructural fallido de recursos**

Crear `tools/test_android_widget_resources.py` para exigir tres layouts, IDs comunes, paleta nocturna y categorías:

```python
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANDROID = "{http://schemas.android.com/apk/res/android}"


class AndroidWidgetResourcesTest(unittest.TestCase):
    def test_all_remote_views_layouts_use_supported_view_classes_and_common_ids(self):
        supported = {"FrameLayout", "LinearLayout", "RelativeLayout", "TextView", "ImageView", "Space"}
        required_ids = {"@+id/widget_root", "@+id/widget_seal", "@+id/widget_verse_text", "@+id/widget_reference", "@+id/widget_edition"}
        for name in ("widget_compact.xml", "widget_medium.xml", "widget_large.xml"):
            root = ET.parse(ROOT / "android/app/src/main/res/layout" / name).getroot()
            tags = {node.tag.split("}")[-1].split(".")[-1] for node in root.iter()}
            self.assertTrue(tags <= supported, (name, tags - supported))
            ids = {node.attrib.get(ANDROID + "id") for node in root.iter()}
            self.assertTrue(required_ids <= ids, (name, required_ids - ids))

    def test_provider_declares_home_keyguard_and_hourly_refresh(self):
        root = ET.parse(ROOT / "android/app/src/main/res/xml/widget_info.xml").getroot()
        self.assertEqual(root.attrib[ANDROID + "widgetCategory"], "home_screen|keyguard")
        self.assertEqual(root.attrib[ANDROID + "updatePeriodMillis"], "3600000")
        self.assertEqual(root.attrib[ANDROID + "initialLayout"], "@layout/widget_medium")
        self.assertEqual(root.attrib[ANDROID + "initialKeyguardLayout"], "@layout/widget_compact")
```

- [ ] **Step 5: Ejecutar ambos contratos y observar que faltan los recursos**

Run:

```powershell
python -m unittest tools.test_android_widget_resources -v
cd android
.\gradlew.bat :app:testDebugUnitTest --tests "com.ozcorp.verbum.widget.WidgetLayoutSelectorTest"
```

Expected: la prueba Python falla por layouts ausentes; la prueba Kotlin PASS después de Step 3.

- [ ] **Step 6: Crear los tres layouts con la jerarquía aprobada**

Usar el mismo contrato de IDs y variar solo densidad, líneas y metadatos. La estructura base de `widget_medium.xml` será:

```xml
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@drawable/widget_background"
    android:padding="18dp">

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:orientation="vertical">

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:gravity="center_vertical">
            <TextView
                android:id="@+id/widget_seal"
                android:layout_width="28dp"
                android:layout_height="28dp"
                android:layout_marginEnd="8dp"
                android:background="@drawable/widget_seal_background"
                android:gravity="center"
                android:text="V"
                android:textColor="@color/widget_accent"
                android:textSize="12sp"
                android:textStyle="bold" />
            <TextView
                android:id="@+id/widget_brand"
                android:layout_width="0dp"
                android:layout_height="wrap_content"
                android:layout_weight="1"
                android:text="@string/widget_brand"
                android:textColor="@color/widget_accent"
                android:textSize="11sp"
                android:textStyle="bold" />
            <TextView
                android:id="@+id/widget_date"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:textColor="@color/widget_muted"
                android:textSize="10sp" />
        </LinearLayout>

        <TextView
            android:id="@+id/widget_verse_text"
            android:layout_width="match_parent"
            android:layout_height="0dp"
            android:layout_weight="1"
            android:ellipsize="end"
            android:gravity="center_vertical"
            android:maxLines="4"
            android:textColor="@color/widget_text"
            android:textSize="16sp" />

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:gravity="center_vertical">
            <TextView
                android:id="@+id/widget_reference"
                android:layout_width="0dp"
                android:layout_height="wrap_content"
                android:layout_weight="1"
                android:textColor="@color/widget_accent"
                android:textSize="11sp"
                android:textStyle="bold" />
            <TextView
                android:id="@+id/widget_edition"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="@string/widget_edition"
                android:textColor="@color/widget_muted"
                android:textSize="9sp" />
            <TextView
                android:id="@+id/widget_open"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_marginStart="8dp"
                android:text="@string/widget_open"
                android:textColor="@color/widget_text"
                android:textSize="10sp" />
        </LinearLayout>
    </LinearLayout>
</FrameLayout>
```

`widget_compact.xml` usará `12dp`, 2 líneas y ocultará fecha/acción; `widget_large.xml` usará `22dp`, 7 líneas y mayor separación. Ningún layout tendrá alto fijo para el texto.

- [ ] **Step 7: Crear paletas clara/oscura y fondos nativos**

Definir en `values/colors.xml`:

```xml
<color name="widget_surface">#FFF8EE</color>
<color name="widget_text">#2C2332</color>
<color name="widget_muted">#746A72</color>
<color name="widget_accent">#8C5A37</color>
<color name="widget_border">#26A67C52</color>
<color name="widget_seal_surface">#1F8C5A37</color>
```

Definir en `values-night/colors.xml`:

```xml
<color name="widget_surface">#211B29</color>
<color name="widget_text">#FFF8EE</color>
<color name="widget_muted">#C7BBC8</color>
<color name="widget_accent">#E5BD7B</color>
<color name="widget_border">#40E5BD7B</color>
<color name="widget_seal_surface">#24E5BD7B</color>
```

`widget_background.xml` será un `shape` con `@color/widget_surface`, esquinas `24dp` y borde `1dp` `@color/widget_border`. `widget_seal_background.xml` será un `shape` ovalado relleno con `@color/widget_seal_surface`. Añadir las cadenas `Verbum`, `RV1909`, `Abrir en Verbum`, `Abre Verbum para recibir la Palabra de hoy` y descripciones accesibles.

- [ ] **Step 8: Actualizar metadata y crear el renderer**

Configurar `widget_info.xml`:

```xml
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="110dp"
    android:minHeight="60dp"
    android:minResizeWidth="110dp"
    android:minResizeHeight="60dp"
    android:updatePeriodMillis="3600000"
    android:initialLayout="@layout/widget_medium"
    android:initialKeyguardLayout="@layout/widget_compact"
    android:previewLayout="@layout/widget_medium"
    android:description="@string/widget_description"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen|keyguard"
    android:targetCellWidth="4"
    android:targetCellHeight="2" />
```

Implementar `VerseWidgetRenderer.render` para leer `OPTION_APPWIDGET_MIN_WIDTH/HEIGHT`, elegir `R.layout.widget_compact|medium|large`, asignar texto/fecha y enlazar `widget_root` a:

```kotlin
val uri = Uri.parse("verbum://biblia/${record.bookId}/${record.chapter}/${record.verse}")
val openIntent = Intent(Intent.ACTION_VIEW, uri, context, MainActivity::class.java).apply {
    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
}
val pendingIntent = PendingIntent.getActivity(
    context,
    appWidgetId,
    openIntent,
    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
)
views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
```

El método `renderFallback` usará el mismo layout y el mensaje seguro, con un intent que abre `MainActivity` sin atribuir una fecha a contenido antiguo.

- [ ] **Step 9: Ejecutar contratos, recursos y compilación**

Run:

```powershell
python -m unittest tools.test_android_widget_resources -v
cd android
.\gradlew.bat :app:testDebugUnitTest --tests "com.ozcorp.verbum.widget.WidgetLayoutSelectorTest"
.\gradlew.bat :app:assembleDebug
```

Expected: PASS y `BUILD SUCCESSFUL`.

- [ ] **Step 10: Commit**

```powershell
git add android/app/src/main/kotlin/com/ozcorp/verbum/widget android/app/src/test/kotlin/com/ozcorp/verbum/widget/WidgetLayoutSelectorTest.kt android/app/src/main/res tools/test_android_widget_resources.py
git commit -m "feat(widget): add responsive editorial layouts"
```

---

### Task 4: Hacer autónomo y resistente el ciclo de vida del proveedor

**Files:**
- Modify: `android/app/src/main/kotlin/com/ozcorp/verbum/VerseWidgetProvider.kt`
- Modify: `android/app/src/main/AndroidManifest.xml:70`
- Modify: `tools/test_android_widget_resources.py`
- Delete: `android/app/src/main/res/layout/widget_layout.xml`

**Interfaces:**
- Consumes: `DailyVerseCatalog`, `DailyVerseResolver` y `VerseWidgetRenderer`.
- Produces: `VerseWidgetProvider.updateWidgets(context)` para eventos del sistema y MethodChannel.

- [ ] **Step 1: Ampliar la prueba estructural para los eventos de recuperación**

Añadir a `tools/test_android_widget_resources.py`:

```python
def test_provider_receives_day_timezone_boot_and_package_replacement(self):
    manifest = ET.parse(ROOT / "android/app/src/main/AndroidManifest.xml").getroot()
    receiver = next(node for node in manifest.iter("receiver")
                    if node.attrib.get(ANDROID + "name") == ".VerseWidgetProvider")
    actions = {node.attrib[ANDROID + "name"] for node in receiver.iter("action")}
    self.assertTrue({
        "android.appwidget.action.APPWIDGET_UPDATE",
        "android.intent.action.DATE_CHANGED",
        "android.intent.action.TIME_SET",
        "android.intent.action.TIMEZONE_CHANGED",
        "android.intent.action.BOOT_COMPLETED",
        "android.intent.action.MY_PACKAGE_REPLACED",
        "com.ozcorp.verbum.UPDATE_WIDGET",
    } <= actions)
```

- [ ] **Step 2: Ejecutar la prueba y confirmar que faltan los eventos**

Run:

```powershell
python -m unittest tools.test_android_widget_resources.AndroidWidgetResourcesTest.test_provider_receives_day_timezone_boot_and_package_replacement -v
```

Expected: FAIL mostrando las acciones ausentes.

- [ ] **Step 3: Reescribir el proveedor como coordinador del contenido nativo**

Reemplazar el almacenamiento de texto en `SharedPreferences` por resolución local:

```kotlin
private fun updateAppWidget(context: Context, manager: AppWidgetManager, widgetId: Int) {
    val records = DailyVerseCatalog.load(context)
    val record = DailyVerseResolver.resolve(records, LocalDate.now())
    if (record == null) {
        VerseWidgetRenderer.renderFallback(context, manager, widgetId)
    } else {
        VerseWidgetRenderer.render(context, manager, widgetId, record)
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
```

`onUpdate`, `onEnabled` y los eventos aceptados por `onReceive` llamarán a `updateWidgets(context)`. El proveedor no reutilizará el texto de ayer si `DailyVerseCatalog.load` devuelve una lista vacía.

- [ ] **Step 4: Registrar eventos y conservar el permiso de reinicio existente**

Dentro del filtro del receiver añadir:

```xml
<action android:name="android.intent.action.DATE_CHANGED" />
<action android:name="android.intent.action.TIME_SET" />
<action android:name="android.intent.action.TIMEZONE_CHANGED" />
<action android:name="android.intent.action.BOOT_COMPLETED" />
<action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
```

Mantener `RECEIVE_BOOT_COMPLETED`. No añadir permisos de alarma.

- [ ] **Step 5: Ejecutar pruebas y eliminar el layout anterior cuando no tenga referencias**

Run:

```powershell
rg -n "widget_layout" android/app/src/main
python -m unittest tools.test_android_widget_resources -v
cd android
.\gradlew.bat :app:assembleDebug
```

Expected antes de eliminar: ninguna referencia a `@layout/widget_layout` fuera del archivo antiguo. Eliminar `widget_layout.xml`, repetir los comandos y obtener PASS / `BUILD SUCCESSFUL`.

- [ ] **Step 6: Commit**

```powershell
git add android/app/src/main/kotlin/com/ozcorp/verbum/VerseWidgetProvider.kt android/app/src/main/AndroidManifest.xml android/app/src/main/res/layout/widget_layout.xml tools/test_android_widget_resources.py
git commit -m "fix(widget): refresh content across lifecycle events"
```

---

### Task 5: Exponer fijación, estado y actualización mediante MethodChannel

**Files:**
- Modify: `android/app/src/main/kotlin/com/ozcorp/verbum/MainActivity.kt`
- Modify: `lib/services/widget_service.dart`
- Create: `test/widget_service_test.dart`

**Interfaces:**
- Produces Kotlin methods: `isPinWidgetSupported`, `requestPinWidget`, `hasWidgets`, `refreshWidget`.
- Produces Dart: `WidgetService.refreshWidget()`, `hasWidgets()`, `isPinningSupported()` y `requestPinWidget(): Future<WidgetPinRequestResult>`.

- [ ] **Step 1: Escribir pruebas Flutter fallidas del contrato del canal**

Crear `test/widget_service_test.dart` con un MethodChannel simulado:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/services/widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.ozcorp.verbum/widget-test');

  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  test('solicita fijación cuando Android la soporta', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'isPinWidgetSupported') return true;
      if (call.method == 'requestPinWidget') return true;
      return false;
    });
    final service = WidgetService.forTesting(channel: channel, isAndroid: true);
    expect(await service.requestPinWidget(), WidgetPinRequestResult.requested);
    expect(calls, ['isPinWidgetSupported', 'requestPinWidget']);
  });

  test('devuelve unsupported sin intentar fijar', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => false);
    final service = WidgetService.forTesting(channel: channel, isAndroid: true);
    expect(await service.requestPinWidget(), WidgetPinRequestResult.unsupported);
  });

  test('plataforma no Android no invoca el canal', () async {
    final service = WidgetService.forTesting(channel: channel, isAndroid: false);
    expect(await service.requestPinWidget(), WidgetPinRequestResult.unsupported);
    expect(await service.hasWidgets(), isFalse);
  });
}
```

- [ ] **Step 2: Ejecutar y comprobar el fallo por API ausente**

Run:

```powershell
flutter test test/widget_service_test.dart
```

Expected: FAIL por `WidgetService.forTesting` y `WidgetPinRequestResult` ausentes.

- [ ] **Step 3: Refactorizar el servicio Dart a instancia inyectable**

Conservar `com.ozcorp.verbum/widget` en producción y definir:

```dart
enum WidgetPinRequestResult { requested, unsupported, failed }

class WidgetService {
  WidgetService._(this._channel, this._isAndroid);
  static final WidgetService _instance = WidgetService._(
    const MethodChannel('com.ozcorp.verbum/widget'),
    defaultTargetPlatform == TargetPlatform.android,
  );
  factory WidgetService() => _instance;

  @visibleForTesting
  factory WidgetService.forTesting({
    required MethodChannel channel,
    required bool isAndroid,
  }) => WidgetService._(channel, isAndroid);

  final MethodChannel _channel;
  final bool _isAndroid;

  Future<bool> refreshWidget() async =>
      _isAndroid && (await _channel.invokeMethod<bool>('refreshWidget') ?? false);

  Future<bool> hasWidgets() async =>
      _isAndroid && (await _channel.invokeMethod<bool>('hasWidgets') ?? false);

  Future<bool> isPinningSupported() async =>
      _isAndroid && (await _channel.invokeMethod<bool>('isPinWidgetSupported') ?? false);

  Future<WidgetPinRequestResult> requestPinWidget() async {
    if (!await isPinningSupported()) return WidgetPinRequestResult.unsupported;
    try {
      final sent = await _channel.invokeMethod<bool>('requestPinWidget') ?? false;
      return sent ? WidgetPinRequestResult.requested : WidgetPinRequestResult.failed;
    } on PlatformException {
      return WidgetPinRequestResult.failed;
    }
  }

  Future<void> initialize() async { await refreshWidget(); }
}
```

- [ ] **Step 4: Implementar los cuatro métodos Android y conservar el alias antiguo**

En `MainActivity.kt` usar `AppWidgetManager` y `ComponentName`:

```kotlin
"isPinWidgetSupported" -> result.success(
    Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
        AppWidgetManager.getInstance(this).isRequestPinAppWidgetSupported
)
"requestPinWidget" -> {
    val manager = AppWidgetManager.getInstance(this)
    val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && manager.isRequestPinAppWidgetSupported
    result.success(supported && manager.requestPinAppWidget(
        ComponentName(this, VerseWidgetProvider::class.java), null, null
    ))
}
"hasWidgets" -> {
    val manager = AppWidgetManager.getInstance(this)
    val ids = manager.getAppWidgetIds(ComponentName(this, VerseWidgetProvider::class.java))
    result.success(ids.isNotEmpty())
}
"refreshWidget", "updateWidget" -> {
    VerseWidgetProvider.updateWidgets(applicationContext)
    result.success(true)
}
```

El alias `updateWidget` queda solo para que una instalación en actualización no falle durante la transición; el contenido enviado anteriormente deja de ser fuente del widget.

- [ ] **Step 5: Ejecutar pruebas y compilación nativa**

Run:

```powershell
flutter test test/widget_service_test.dart
cd android
.\gradlew.bat :app:assembleDebug
```

Expected: PASS y `BUILD SUCCESSFUL`.

- [ ] **Step 6: Commit**

```powershell
git add lib/services/widget_service.dart test/widget_service_test.dart android/app/src/main/kotlin/com/ozcorp/verbum/MainActivity.kt
git commit -m "feat(widget): expose native pin and status bridge"
```

---

### Task 6: Abrir el pasaje bíblico exacto en frío y en caliente

**Files:**
- Create: `lib/services/bible_deep_link.dart`
- Modify: `lib/services/deep_link_service.dart`
- Modify: `lib/main.dart:144`
- Modify: `android/app/src/main/AndroidManifest.xml:48`
- Create: `test/bible_deep_link_test.dart`

**Interfaces:**
- Consumes: `verbum://biblia/<bookId>/<chapter>/<verse>` creado por el renderer.
- Produces: `BibleDeepLinkTarget? parseBibleDeepLink(Uri)` y navegación a `BibleVersesScreen(initialVerse: ...)`.

- [ ] **Step 1: Escribir pruebas fallidas del parser y rutas inválidas**

Crear `test/bible_deep_link_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/services/bible_deep_link.dart';

void main() {
  test('analiza un enlace bíblico exacto', () {
    expect(
      parseBibleDeepLink(Uri.parse('verbum://biblia/JHN/3/16')),
      const BibleDeepLinkTarget(bookId: 'JHN', chapter: 3, verse: 16),
    );
  });

  test('rechaza host, libro o números inválidos', () {
    expect(parseBibleDeepLink(Uri.parse('verbum://camino/JHN/3/16')), isNull);
    expect(parseBibleDeepLink(Uri.parse('verbum://biblia/UNKNOWN/3/16')), isNull);
    expect(parseBibleDeepLink(Uri.parse('verbum://biblia/JHN/0/16')), isNull);
    expect(parseBibleDeepLink(Uri.parse('verbum://biblia/JHN/3/x')), isNull);
  });

  test('serializa con el mismo contrato del PendingIntent', () {
    const target = BibleDeepLinkTarget(bookId: 'PSA', chapter: 23, verse: 1);
    expect(target.toUri().toString(), 'verbum://biblia/PSA/23/1');
  });
}
```

- [ ] **Step 2: Ejecutar y confirmar el fallo por archivo ausente**

Run:

```powershell
flutter test test/bible_deep_link_test.dart
```

Expected: FAIL porque `bible_deep_link.dart` no existe.

- [ ] **Step 3: Implementar el contrato puro de URI**

Crear `lib/services/bible_deep_link.dart`:

```dart
import '../bible/domain/bible_book_info.dart';

class BibleDeepLinkTarget {
  final String bookId;
  final int chapter;
  final int verse;

  const BibleDeepLinkTarget({required this.bookId, required this.chapter, required this.verse});

  Uri toUri() => Uri(scheme: 'verbum', host: 'biblia', pathSegments: [bookId, '$chapter', '$verse']);

  @override
  bool operator ==(Object other) => other is BibleDeepLinkTarget &&
      other.bookId == bookId && other.chapter == chapter && other.verse == verse;

  @override
  int get hashCode => Object.hash(bookId, chapter, verse);
}

BibleDeepLinkTarget? parseBibleDeepLink(Uri uri) {
  if (uri.scheme != 'verbum' || uri.host != 'biblia' || uri.pathSegments.length != 3) return null;
  final chapter = int.tryParse(uri.pathSegments[1]);
  final verse = int.tryParse(uri.pathSegments[2]);
  final bookId = uri.pathSegments[0];
  if (bibleBookById(bookId) == null || chapter == null || verse == null || chapter < 1 || verse < 1) return null;
  return BibleDeepLinkTarget(bookId: bookId, chapter: chapter, verse: verse);
}
```

- [ ] **Step 4: Hacer que `DeepLinkService` procese URI inicial y stream por el mismo camino**

En `initialize`, obtener una sola vez el enlace inicial y después suscribirse:

```dart
Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
  if (_subscription != null) return;
  _navigatorKey = navigatorKey;
  final initial = await _appLinks.getInitialLink();
  if (initial != null) _handle(initial);
  _subscription = _appLinks.uriLinkStream.listen(_handle, onError: (_) {});
}
```

Como `initialize` pasa a ser asíncrono, en `main.dart` iniciar el servicio con `await DeepLinkService.instance.initialize(_navigatorKey);` después de `runApp`.

Ampliar `_handle` para reconocer primero `parseBibleDeepLink(uri)`. Validar existencia con `BibleDb.instance.getVerse`; si existe, abrir:

```dart
BibleVersesScreen(
  bookId: target.bookId,
  bookName: bibleBookById(target.bookId)!.name,
  chapter: target.chapter,
  initialVerse: target.verse,
)
```

Si el host es `biblia` pero el parser o la consulta fallan, navegar a `const BibleBooksScreen()`. Conservar intacto el flujo `verbum://camino/...`. Guardar la URI como pendiente si el navegador aún no existe y procesarla tras el primer frame.

- [ ] **Step 5: Registrar ambos hosts en Android**

Mantener el filtro de `camino` y añadir otro filtro completo:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="verbum" android:host="biblia" />
</intent-filter>
```

- [ ] **Step 6: Probar parser, enlace en frío y enlace en caliente en el Pixel conectado**

Run:

```powershell
flutter test test/bible_deep_link_test.dart
flutter run -d 801KPXV1373074 --debug
```

En otra terminal, con la app cerrada y luego abierta:

```powershell
$adb = 'C:\Users\Usuario\AppData\Local\Android\Sdk\platform-tools\adb.exe'
& $adb -s 801KPXV1373074 shell am force-stop com.ozcorp.verbum
& $adb -s 801KPXV1373074 shell am start -W -a android.intent.action.VIEW -d 'verbum://biblia/JHN/3/16' com.ozcorp.verbum
& $adb -s 801KPXV1373074 shell am start -W -a android.intent.action.VIEW -d 'verbum://biblia/PSA/23/1' com.ozcorp.verbum
& $adb -s 801KPXV1373074 shell am start -W -a android.intent.action.VIEW -d 'verbum://biblia/UNKNOWN/0/0' com.ozcorp.verbum
```

Expected: primer comando abre Juan 3:16, segundo cambia a Salmos 23:1 con la app activa y el tercero abre la Biblia sin cierre ni pantalla vacía.

- [ ] **Step 7: Commit**

```powershell
git add lib/services/bible_deep_link.dart lib/services/deep_link_service.dart test/bible_deep_link_test.dart android/app/src/main/AndroidManifest.xml
git add lib/main.dart
git commit -m "feat(widget): open exact Bible passage from widget"
```

---

### Task 7: Añadir la experiencia sencilla dentro de Configuración

**Files:**
- Create: `lib/widgets/daily_verse_widget_preview.dart`
- Create: `lib/screens/daily_verse_widget_screen.dart`
- Modify: `lib/screens/settings_screen.dart:452`
- Modify: `lib/l10n/app_localizations.dart`
- Modify: `lib/providers/app_provider.dart:150`
- Modify: `lib/main.dart:133,206`
- Create: `test/daily_verse_widget_screen_test.dart`

**Interfaces:**
- Consumes: `WidgetService` de Task 5 y `VerseService.getTodayVerse()`.
- Produces: ruta `/daily-verse-widget`, vista previa y resultado visible de fijación.

- [ ] **Step 1: Escribir pruebas fallidas de interfaz, fallback y accesibilidad**

Crear `daily_verse_widget_screen_test.dart` con un `WidgetService.forTesting` y MethodChannel simulado. Cubrir:

```dart
const channel = MethodChannel('com.ozcorp.verbum/widget-screen-test');

Future<Verse> loadVerse() async => Verse(
  id: 20260921,
  text: 'Jehová es mi pastor; nada me faltará.',
  reference: 'Salmos 23:1',
  book: 'PSA',
  chapter: 23,
  verse: 1,
);

tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .setMockMethodCallHandler(channel, null));

testWidgets('muestra la vista previa y solicita añadir a inicio', (tester) async {
  tester.view.physicalSize = const Size(360, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'hasWidgets') return false;
    if (call.method == 'isPinWidgetSupported') return true;
    if (call.method == 'requestPinWidget') return true;
    return false;
  });
  final service = WidgetService.forTesting(channel: channel, isAndroid: true);
  await tester.pumpWidget(MaterialApp(home: DailyVerseWidgetScreen(
    widgetService: service,
    loadVerse: loadVerse,
  )));
  await tester.pumpAndSettle();
  expect(find.text('Widget de la Palabra'), findsOneWidget);
  expect(find.text('Salmos 23:1'), findsOneWidget);
  await tester.tap(find.text('Añadir a inicio'));
  await tester.pumpAndSettle();
  expect(find.textContaining('solicitud enviada'), findsOneWidget);
});

testWidgets('explica instalación manual cuando el launcher no soporta fijación', (tester) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'hasWidgets') return false;
    if (call.method == 'isPinWidgetSupported') return false;
    return false;
  });
  final service = WidgetService.forTesting(channel: channel, isAndroid: true);
  await tester.pumpWidget(MaterialApp(home: DailyVerseWidgetScreen(
    widgetService: service,
    loadVerse: loadVerse,
  )));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Añadir a inicio'));
  await tester.pumpAndSettle();
  expect(find.textContaining('Mantén pulsada la pantalla de inicio'), findsOneWidget);
});

testWidgets('muestra el estado añadido cuando Android informa una instancia', (tester) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'hasWidgets') return true;
    return false;
  });
  final service = WidgetService.forTesting(channel: channel, isAndroid: true);
  await tester.pumpWidget(MaterialApp(home: DailyVerseWidgetScreen(
    widgetService: service,
    loadVerse: loadVerse,
  )));
  await tester.pumpAndSettle();
  expect(find.text('Widget añadido'), findsOneWidget);
});

testWidgets('no desborda a 320 px con texto al 200 por ciento', (tester) async {
  tester.view.physicalSize = const Size(320, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => false);
  final service = WidgetService.forTesting(channel: channel, isAndroid: true);
  await tester.pumpWidget(MediaQuery(
    data: const MediaQueryData(textScaler: TextScaler.linear(2)),
    child: MaterialApp(home: DailyVerseWidgetScreen(widgetService: service, loadVerse: loadVerse)),
  ));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
});
```

Ninguna prueba dependerá del canal Android real.

- [ ] **Step 2: Ejecutar y confirmar el fallo por widgets ausentes**

Run:

```powershell
flutter test test/daily_verse_widget_screen_test.dart
```

Expected: FAIL porque `DailyVerseWidgetScreen` no existe.

- [ ] **Step 3: Crear la vista previa Flutter equivalente al diseño nativo**

`DailyVerseWidgetPreview` recibirá `Verse verse` y usará `LayoutBuilder`, `FittedBox` solo para la etiqueta, `maxLines` y `TextOverflow.ellipsis`. La superficie será papel/ciruela/dorado con `Semantics(label: 'Versículo del día, ...')`. No tendrá controles de estilo.

La API será:

```dart
class DailyVerseWidgetPreview extends StatelessWidget {
  final Verse verse;
  const DailyVerseWidgetPreview({super.key, required this.verse});
}
```

- [ ] **Step 4: Crear la pantalla de ayuda con estados claros**

La pantalla aceptará dependencias inyectables:

```dart
class DailyVerseWidgetScreen extends StatefulWidget {
  final WidgetService widgetService;
  final Future<Verse> Function() loadVerse;

  DailyVerseWidgetScreen({
    super.key,
    WidgetService? widgetService,
    Future<Verse> Function()? loadVerse,
  }) : widgetService = widgetService ?? WidgetService(),
       loadVerse = loadVerse ?? VerseService().getTodayVerse;
}
```

Su estado implementará `WidgetsBindingObserver`, llamará a `hasWidgets()` en `initState` y volverá a consultarlo cuando `didChangeAppLifecycleState` reciba `AppLifecycleState.resumed`, para reflejar la fijación al regresar del launcher.

Mostrar vista previa, explicación breve, botón `Añadir a inicio`, estado `Widget añadido` cuando `hasWidgets()` sea true y la sección `Pantalla de bloqueo` con estos pasos:

1. Mantén pulsada la pantalla de bloqueo.
2. Abre la personalización o la sección de widgets.
3. Busca Verbum si tu dispositivo admite widgets en esa pantalla.

Ante `unsupported`, mostrar instrucciones manuales del selector del launcher; ante `failed`, un `SnackBar` con “No se pudo abrir el selector. Puedes añadirlo manualmente.”

- [ ] **Step 5: Añadir copias localizadas y el acceso desde Configuración**

Agregar getters es/en/pt a `AppLocalizations` para título, descripción, añadir, añadido, solicitud enviada, pasos manuales, bloqueo y compatibilidad. En `SettingsScreen`, después de Apariencia y antes de Notificaciones, añadir una sección `En tu pantalla` con un `ListTile` que navega a `DailyVerseWidgetScreen`.

Registrar también:

```dart
'/daily-verse-widget': (context) => DailyVerseWidgetScreen(),
```

- [ ] **Step 6: Separar el widget del versículo personalizado**

Cambiar las tres llamadas de `AppProvider` para no enviar `_todayVerse` ni oraciones:

```dart
await WidgetService().refreshWidget();
```

En `main.dart` cambiar inicialización a:

```dart
await WidgetService().initialize();
```

Esto garantiza que una emoción elegida en Verbum no cambie el versículo canónico del widget.

- [ ] **Step 7: Ejecutar pruebas de UI, servicio y análisis**

Run:

```powershell
flutter test test/daily_verse_widget_screen_test.dart test/widget_service_test.dart test/verse_service_test.dart
flutter analyze
```

Expected: todas las pruebas PASS y `No issues found!`.

- [ ] **Step 8: Commit**

```powershell
git add lib/widgets/daily_verse_widget_preview.dart lib/screens/daily_verse_widget_screen.dart lib/screens/settings_screen.dart lib/l10n/app_localizations.dart lib/providers/app_provider.dart lib/main.dart test/daily_verse_widget_screen_test.dart
git commit -m "feat(widget): add simple setup experience"
```

---

### Task 8: Verificación completa, actualización sobre instalación existente y documentación

**Files:**
- Create: `docs/testing/widget-palabra-diaria-manual.md`
- Modify only if a verification failure identifies a root cause: files owned by Tasks 1–7, with a failing test added first.

**Interfaces:**
- Consumes: entrega integrada de Tasks 1–7.
- Produces: evidencia de pruebas automáticas, APK debug instalado y matriz manual; no produce AAB.

- [ ] **Step 1: Ejecutar toda la suite automatizada**

Run:

```powershell
python -m unittest tools.test_android_widget_catalog tools.test_android_widget_resources -v
flutter analyze
flutter test
cd android
.\gradlew.bat :app:testDebugUnitTest
cd ..
```

Expected: Python PASS, `No issues found!`, todos los tests Flutter PASS y tests Kotlin PASS.

- [ ] **Step 2: Construir únicamente el APK debug**

Run:

```powershell
flutter build apk --debug
```

Expected: `build/app/outputs/flutter-apk/app-debug.apk` generado. Confirmar que no existe un AAB nuevo mediante:

```powershell
git status --short
Get-ChildItem -LiteralPath 'build\app\outputs\bundle' -Recurse -ErrorAction SilentlyContinue
```

- [ ] **Step 3: Probar actualización conservando el widget existente**

Con el widget ya colocado en el Pixel 2 XL:

```powershell
$adb = 'C:\Users\Usuario\AppData\Local\Android\Sdk\platform-tools\adb.exe'
& $adb -s 801KPXV1373074 install -r 'build\app\outputs\flutter-apk\app-debug.apk'
Start-Sleep -Seconds 3
& $adb -s 801KPXV1373074 logcat -d -v brief | Select-String -Pattern 'AppWidgetHostView|RemoteViews|ResourcesNotFound|com.ozcorp.verbum'
```

Expected: el widget existente se redibuja con el diseño nuevo y no aparecen `Resources$NotFoundException`, `Package name ... not found` ni “Problema para cargar widget”. No desinstalar la app, porque se necesita verificar el camino real de actualización.

- [ ] **Step 4: Ejecutar la matriz manual en el dispositivo disponible**

Crear `docs/testing/widget-palabra-diaria-manual.md` con fecha, dispositivo, Android, launcher y resultado para:

```markdown
| Caso | Resultado | Evidencia/nota |
| --- | --- | --- |
| Añadir desde Configuración |  |  |
| Añadir desde selector del launcher |  |  |
| Compacto 2×1 |  |  |
| Mediano 4×2 |  |  |
| Grande 4×3 |  |  |
| Claro y oscuro |  |  |
| Fuente del sistema grande |  |  |
| Sin conexión y app cerrada |  |  |
| Dos instancias |  |  |
| Reinicio |  |  |
| Cambio de fecha/zona horaria |  |  |
| Toque abre pasaje exacto |  |  |
| Actualización sobre APK existente |  |  |
| Pantalla de bloqueo compatible/no compatible |  |  |
```

Rellenar cada celda probada con `PASS`, `FAIL` o `NO DISPONIBLE`; `NO DISPONIBLE` debe explicar la limitación del dispositivo.

- [ ] **Step 5: Comprobar que no se alteraron restricciones de publicación**

Run:

```powershell
git diff d7b0876 -- pubspec.yaml android/app/build.gradle.kts android/key.properties android/app/src/main/AndroidManifest.xml
rg -n "applicationId|versionCode|versionName" android/app/build.gradle.kts pubspec.yaml
```

Expected: `applicationId` sigue siendo `com.ozcorp.verbum`, `versionCode` sigue en `10`, `versionName` sigue en `1.0.6`; `key.properties` no está versionado; no hay cambios de firma.

- [ ] **Step 6: Revisión final del diff y commit de evidencia**

Run:

```powershell
git diff --check
git status --short
git diff --stat
```

Tras confirmar que solo hay archivos del widget y su documentación:

```powershell
git add docs/testing/widget-palabra-diaria-manual.md
git commit -m "test(widget): document Android verification"
```

- [ ] **Step 7: Entrega al usuario**

Informar resultados automáticos, pruebas manuales completadas, limitaciones de pantalla de bloqueo, archivos principales y commits. Declarar expresamente: “No se generó ni publicó ningún AAB; no se cambió la versión, el package name ni la firma”. No hacer push hasta que el usuario lo solicite.
