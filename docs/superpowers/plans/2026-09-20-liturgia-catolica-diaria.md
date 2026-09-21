# Liturgia católica diaria Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Añadir a Verbum una experiencia litúrgica católica diaria, auditable y disponible sin conexión, con Calendario Romano General mundial y Ecuador como selección local opcional, sin mezclarla con las tradiciones evangélica/general.

**Architecture:** Un activo JSON base generado en desarrollo desde Romcal 3.0.0-dev.140 alimentará un repositorio local tipado que admite capas nacionales verificadas. `CalendarRegionResolver` propondrá Ecuador únicamente para usuarios católicos cuyo dispositivo use la región `EC`; `LiturgyService` resolverá la fecha civil local del dispositivo y hará fallback al Calendario Romano General cuando no exista un paquete ecuatoriano validado. Widgets aislados insertarán tarjeta, detalle y configuración sin trasladar lógica litúrgica a `home_screen.dart`.

**Tech Stack:** Flutter/Dart, Hive, JSON empaquetado, Node.js solo para generación, Romcal y `@romcal/calendar.general-roman` fijados a `3.0.0-dev.140`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-09-20-liturgia-catolica-diaria-design.md`

## Global Constraints

- La liturgia se muestra únicamente cuando `faithTraditionFromStorageString(...) == FaithTradition.catholic`.
- No usar contenido católico como fallback para `cristiana`, `general` o tradición inválida.
- El contenido editorial católico usa `Dios` o `Señor`; `Jehová` se conserva solo cuando forma parte literal de una traducción bíblica identificada, como RV1909.
- La primera entrega se identifica como `Calendario Romano General`; no afirma incluir todos los propios nacionales o diocesanos de Ecuador.
- Ecuador es una selección de calendario dentro del catolicismo, nunca un valor adicional de `FaithTradition`.
- En región `EC`, Ecuador se recomienda sin añadir otra pantalla de onboarding; el usuario puede elegir `Calendario Romano General` desde Configuración.
- No solicitar GPS ni permiso de ubicación. La región inicial procede de `PlatformDispatcher.instance.locale.countryCode` y el cambio de día de `DateTime.now().toLocal()`.
- Un paquete nacional solo se carga si figura en el manifiesto local como verificado; la ausencia de paquete debe usar el Calendario Romano General sin error.
- No reproducir textos completos del Misal, Leccionario o Liturgia de las Horas.
- No añadir llamadas de red al arranque ni depender de una API para mostrar el día.
- No modificar `applicationId`, App Signing Key, Upload Key, `versionCode` ni `versionName`.
- No ejecutar `flutter build appbundle --release` ni generar, publicar o subir un AAB.
- Mantener intactas las modificaciones no relacionadas presentes en el árbol de trabajo.
- No hacer commits intermedios; el commit y push se harán únicamente después de la revisión final solicitada por el usuario.

## Review Focus

- Una fecha cercana a medianoche debe resolverse como fecha civil local del dispositivo, tanto en Ecuador como en otras zonas horarias.
- Una tradición `cristiana`, `general`, vacía o desconocida nunca debe renderizar la tarjeta católica.
- Un activo ausente, fuera de rango o con esquema inválido no debe dejar la pantalla Hoy en blanco.
- Nombres largos, texto ampliado y el color litúrgico blanco no deben provocar overflow ni perder contraste.
- La selección Ecuador debe persistir durante viajes y hacer fallback general si su paquete local no está verificado.

---

## File map

### Crear

- `lib/features/liturgy/domain/liturgical_day.dart`: modelo inmutable y parseo estricto.
- `lib/features/liturgy/domain/liturgical_source.dart`: procedencia y alcance del calendario.
- `lib/features/liturgy/domain/calendar_selection.dart`: Calendario Romano General o país ISO seleccionado.
- `lib/features/liturgy/domain/calendar_profile.dart`: perfil resuelto de idioma, tradición, región, selección y zona horaria local.
- `lib/features/liturgy/data/liturgy_repository.dart`: contrato de lectura por fecha.
- `lib/features/liturgy/data/asset_liturgy_repository.dart`: carga y caché del activo JSON.
- `lib/features/liturgy/application/calendar_region_resolver.dart`: región inicial, persistencia y recomendación de Ecuador.
- `lib/features/liturgy/application/liturgy_service.dart`: fecha local del dispositivo y consulta del repositorio.
- `lib/features/liturgy/presentation/liturgical_palette.dart`: colores accesibles.
- `lib/features/liturgy/presentation/today_liturgy_card.dart`: tarjeta visual pura.
- `lib/features/liturgy/presentation/today_liturgy_section.dart`: tradición, carga, error y cambio de día.
- `lib/features/liturgy/presentation/liturgy_day_screen.dart`: detalle del día.
- `lib/features/liturgy/presentation/liturgy_source_sheet.dart`: fuente, alcance y licencia.
- `assets/liturgy/manifest.json`: paquetes nacionales verificados disponibles; inicialmente sin paquete ecuatoriano.
- `assets/liturgy/general_roman_es_2025_2035.json`: instantánea base internacional.
- `assets/licenses/romcal.txt`: licencia MIT incluida con la app.
- `tools/generate_liturgical_calendar/package.json`: dependencias fijadas del generador.
- `tools/generate_liturgical_calendar/package-lock.json`: hashes resueltos por npm.
- `tools/generate_liturgical_calendar/generate.mjs`: producción determinista del activo.
- `tools/generate_liturgical_calendar/audit.mjs`: auditoría estructural y de fechas.
- `test/features/liturgy/liturgical_day_test.dart`: parseo y validación.
- `test/features/liturgy/calendar_region_resolver_test.dart`: recomendación, persistencia y separación por tradición.
- `test/features/liturgy/asset_liturgy_repository_test.dart`: caché, rango y error.
- `test/features/liturgy/liturgy_service_test.dart`: zona horaria.
- `test/features/liturgy/today_liturgy_card_test.dart`: accesibilidad visual.
- `test/features/liturgy/today_liturgy_section_test.dart`: aislamiento por tradición y fallos.

### Modificar

- `pubspec.yaml`: registrar `assets/liturgy/` y `assets/licenses/`.
- `.gitignore`: excluir dependencias Node del generador sin alterar reglas de firma Android.
- `lib/faith/tradition_capabilities.dart`: añadir la capacidad `showDailyLiturgy` solo para catolicismo.
- `lib/services/storage_service.dart`: persistir la selección de calendario católico sin modificar la tradición.
- `lib/screens/home_screen.dart`: insertar `TodayLiturgySection` después de la racha.
- `lib/screens/settings_screen.dart`: mostrar `Calendario católico` únicamente para tradición católica.
- `lib/screens/content_sources_screen.dart`: documentar calendario, alcance, nombre divino y licencia.
- `test/content_and_bible_test.dart`: fijar terminología y ausencia de fallback entre tradiciones.
- `test/features/liturgy/catholic_calendar_settings_test.dart`: selección Ecuador/General, visibilidad y textos.
- `docs/plans/2026-09-20-contenido-biblia-revision.md`: registrar la nueva fuente y sus límites.

---

### Task 1: Dominio litúrgico tipado

**Files:**
- Create: `lib/features/liturgy/domain/liturgical_day.dart`
- Create: `lib/features/liturgy/domain/liturgical_source.dart`
- Create: `lib/features/liturgy/domain/calendar_selection.dart`
- Create: `lib/features/liturgy/domain/calendar_profile.dart`
- Test: `test/features/liturgy/liturgical_day_test.dart`

**Interfaces:**
- Consumes: mapas JSON generados con `schemaVersion == 1`.
- Produces: `LiturgicalDay.fromJson(Map<String, dynamic>, source: LiturgicalSource)`, `LiturgicalSource.fromJson(Map<String, dynamic>)`, `CalendarSelection.generalRoman()`, `CalendarSelection.country(String)`, `CalendarProfile` y enums `PreferenceOrigin`, `LiturgicalSeason`, `LiturgicalColor`, `LiturgicalRank` y `CalendarScope`.

- [ ] **Step 1: Escribir pruebas fallidas del modelo**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/liturgy/domain/liturgical_day.dart';
import 'package:verbum/features/liturgy/domain/liturgical_source.dart';
import 'package:verbum/features/liturgy/domain/calendar_selection.dart';

const testSource = LiturgicalSource(
  id: 'romcal-general-roman-es',
  name: 'Romcal — Calendario Romano General',
  url: 'https://github.com/romcal/romcal',
  license: 'MIT',
  revision: '6246bad8c548c1f2528916df40e433c1f7c97c6a',
  scope: CalendarScope.generalRoman,
  authorityStatus: 'openEcclesialSource',
  generatedAt: '2026-09-20T00:00:00.000Z',
  reviewedAt: '2026-09-20',
  reviewNotes: 'Calendario Romano General; propios de Ecuador no incluidos.',
);

void main() {
  test('parsea un día con celebración principal y memoria opcional', () {
    final day = LiturgicalDay.fromJson({
      'date': '2026-09-20',
      'primary': {
        'id': 'ordinary_time_25_sunday',
        'name': 'XXV Domingo del Tiempo Ordinario',
        'rank': 'sunday',
        'colors': ['green'],
      },
      'optional': [
        {
          'id': 'saint_example',
          'name': 'San Ejemplo',
          'rank': 'optionalMemorial',
          'colors': ['white'],
        },
      ],
      'season': 'ordinaryTime',
      'sundayCycle': 'C',
      'weekdayCycle': 'II',
      'psalterWeek': 1,
    }, source: testSource);

    expect(day.date, DateTime(2026, 9, 20));
    expect(day.primary.name, 'XXV Domingo del Tiempo Ordinario');
    expect(day.primary.colors, [LiturgicalColor.green]);
    expect(day.optional, hasLength(1));
    expect(day.sundayCycle, 'C');
  });

  test('rechaza fecha, rango o color desconocidos', () {
    expect(
      () => LiturgicalDay.fromJson({
        'date': '20-09-2026',
        'primary': {
          'id': 'x',
          'name': 'X',
          'rank': 'invented',
          'colors': ['blue'],
        },
        'optional': const [],
        'season': 'ordinaryTime',
      }, source: testSource),
      throwsFormatException,
    );
  });

  test('la selección de Ecuador no crea una tradición religiosa', () {
    final ecuador = CalendarSelection.country('EC');
    expect(ecuador.countryCode, 'EC');
    expect(ecuador.isGeneralRoman, isFalse);
    expect((const CalendarSelection.generalRoman()).isGeneralRoman, isTrue);
    expect(() => CalendarSelection.country('ecuador'), throwsArgumentError);
  });
}
```

- [ ] **Step 2: Ejecutar la prueba y confirmar que falla por tipos inexistentes**

Run: `flutter test test/features/liturgy/liturgical_day_test.dart`

Expected: FAIL por imports/clases no definidos.

- [ ] **Step 3: Implementar enums, modelos y parseo estricto**

```dart
enum LiturgicalSeason { advent, christmas, ordinaryTime, lent, triduum, easter }
enum LiturgicalColor { white, green, red, purple, rose, gold }
enum LiturgicalRank { solemnity, sunday, feast, memorial, optionalMemorial, weekday }
enum CalendarScope { generalRoman, americas, country, diocesan }

final class CalendarSelection {
  const CalendarSelection.generalRoman() : countryCode = null;

  factory CalendarSelection.country(String code) {
    final normalized = code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(normalized)) {
      throw ArgumentError.value(code, 'code', 'Debe ser ISO 3166-1 alpha-2');
    }
    return CalendarSelection._(normalized);
  }

  const CalendarSelection._(this.countryCode);

  final String? countryCode;
  bool get isGeneralRoman => countryCode == null;

  @override
  bool operator ==(Object other) =>
      other is CalendarSelection && other.countryCode == countryCode;

  @override
  int get hashCode => countryCode.hashCode;
}

enum PreferenceOrigin { deviceDefault, userSelected }

final class CalendarProfile {
  const CalendarProfile({
    required this.languageCode,
    required this.tradition,
    required this.deviceCountryCode,
    required this.selection,
    required this.selectionOrigin,
    required this.utcOffset,
  });

  final String languageCode;
  final FaithTradition tradition;
  final String? deviceCountryCode;
  final CalendarSelection selection;
  final PreferenceOrigin selectionOrigin;
  final Duration utcOffset;
}

final class LiturgicalCelebration {
  const LiturgicalCelebration({
    required this.id,
    required this.name,
    required this.rank,
    required this.colors,
  });

  final String id;
  final String name;
  final LiturgicalRank rank;
  final List<LiturgicalColor> colors;

  factory LiturgicalCelebration.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final colors = json['colors'];
    if (id is! String || id.isEmpty || name is! String || name.isEmpty || colors is! List) {
      throw const FormatException('Celebración litúrgica inválida');
    }
    try {
      return LiturgicalCelebration(
        id: id,
        name: name,
        rank: LiturgicalRank.values.byName(json['rank'] as String),
        colors: colors
            .map((value) => LiturgicalColor.values.byName(value as String))
            .toList(growable: false),
      );
    } on Object {
      throw const FormatException('Rango o color litúrgico desconocido');
    }
  }
}
```

`LiturgicalSource` tendrá exactamente los campos usados por `testSource`, constructor `const` y `fromJson` estricto. `LiturgicalDay.fromJson` validará `yyyy-MM-dd` mediante expresión regular antes de construir `DateTime`, conservará la fuente recibida, convertirá opcionales a lista inmutable y aceptará ciclos/salterio nulos. La lista de colores podrá estar vacía —caso de Sábado Santo— sin provocar una excepción.

- [ ] **Step 4: Ejecutar pruebas del dominio**

Run: `dart format lib/features/liturgy/domain test/features/liturgy/liturgical_day_test.dart; flutter test test/features/liturgy/liturgical_day_test.dart`

Expected: PASS.

- [ ] **Step 5: Registrar los archivos terminados sin hacer commit**

Run: `git status --short -- lib/features/liturgy/domain test/features/liturgy/liturgical_day_test.dart`

Expected: solo los archivos de esta tarea aparecen como nuevos.

---

### Task 2: Región, repositorio por capas y fecha local

**Files:**
- Create: `lib/features/liturgy/data/liturgy_repository.dart`
- Create: `lib/features/liturgy/data/asset_liturgy_repository.dart`
- Create: `lib/features/liturgy/application/calendar_region_resolver.dart`
- Create: `lib/features/liturgy/application/liturgy_service.dart`
- Modify: `lib/services/storage_service.dart`
- Test: `test/features/liturgy/calendar_region_resolver_test.dart`
- Test: `test/features/liturgy/asset_liturgy_repository_test.dart`
- Test: `test/features/liturgy/liturgy_service_test.dart`

**Interfaces:**
- Consumes: `CalendarSelection`, `FaithTradition`, `LiturgicalDay.fromJson` y documentos JSON `{schemaVersion, source, days}`.
- Produces: `CalendarProfile CalendarRegionResolver.resolve(FaithTradition)`, `LiturgyRepository.forDate(DateTime, {required CalendarSelection})`, `DailyLiturgyLoader` y `LiturgyService.today()`.

- [ ] **Step 1: Escribir pruebas fallidas de recomendación y persistencia**

```dart
test('recomienda Ecuador solo a católicos con región EC', () {
  final resolver = CalendarRegionResolver(
    readStoredCountry: () => null,
    deviceCountryCode: () => 'ec',
    deviceLanguageCode: () => 'es',
    localNow: () => DateTime(2026, 9, 20),
  );
  final catholic = resolver.resolve(FaithTradition.catholic);
  final evangelical = resolver.resolve(FaithTradition.evangelical);
  expect(catholic.selection, CalendarSelection.country('EC'));
  expect(catholic.selectionOrigin, PreferenceOrigin.deviceDefault);
  expect(catholic.languageCode, 'es');
  expect(evangelical.selection, const CalendarSelection.generalRoman());
});

test('la selección guardada no cambia durante un viaje', () {
  final resolver = CalendarRegionResolver(
    readStoredCountry: () => 'EC',
    deviceCountryCode: () => 'US',
    deviceLanguageCode: () => 'en',
    localNow: () => DateTime(2026, 9, 20),
  );
  final profile = resolver.resolve(FaithTradition.catholic);
  expect(profile.selection, CalendarSelection.country('EC'));
  expect(profile.selectionOrigin, PreferenceOrigin.userSelected);
  expect(profile.deviceCountryCode, 'US');
});

test('un valor persistido inválido cae al calendario general', () {
  final resolver = CalendarRegionResolver(
    readStoredCountry: () => 'ecuador',
    deviceCountryCode: () => null,
    deviceLanguageCode: () => 'es',
    localNow: () => DateTime(2026, 9, 20),
  );
  expect(
    resolver.resolve(FaithTradition.catholic).selection,
    const CalendarSelection.generalRoman(),
  );
});
```

- [ ] **Step 2: Añadir almacenamiento validado y resolver la región sin GPS**

En `StorageService` añadir la clave privada `_catholicCalendarCountryKey = 'catholicCalendarCountry'` y estos métodos:

```dart
String? getCatholicCalendarCountry() {
  final value = _settingsBox.get(_catholicCalendarCountryKey);
  if (value == null) return null;
  if (value is! String) return '';
  if (value == 'GENERAL') return value;
  if (!RegExp(r'^[A-Z]{2}$').hasMatch(value)) return '';
  return value;
}

Future<void> setCatholicCalendarSelection(CalendarSelection selection) {
  return selection.countryCode == null
      ? _settingsBox.put(_catholicCalendarCountryKey, 'GENERAL')
      : _settingsBox.put(
          _catholicCalendarCountryKey,
          selection.countryCode,
        );
}

ValueListenable<Box> faithPreferencesListenable() => _settingsBox.listenable(
      keys: const [
        _traditionalPrayersReligionKey,
        _catholicCalendarCountryKey,
      ],
    );
```

`CalendarRegionResolver` interpretará `GENERAL` como `CalendarSelection.generalRoman()`, un código ISO válido como país persistido y `null` como ausencia de decisión. Solo en ausencia de decisión consultará `PlatformDispatcher.instance.locale.countryCode`; recomendará `EC` únicamente para `FaithTradition.catholic`. Cualquier otra tradición producirá un perfil con `generalRoman` sin escribir preferencias. Los valores por defecto serán `PlatformDispatcher.instance.locale.languageCode` y `DateTime.now().toLocal()`; `utcOffset` se toma de ese reloj local. El resolver no duplica la traducción bíblica: esa preferencia continúa en `BibleReadingPreferences`.

```dart
CalendarProfile resolve(FaithTradition tradition) {
  final rawStored = readStoredCountry();
  final deviceCountry = deviceCountryCode()?.trim().toUpperCase();
  final storedSelection = rawStored == 'GENERAL'
      ? const CalendarSelection.generalRoman()
      : RegExp(r'^[A-Z]{2}$').hasMatch(rawStored ?? '')
          ? CalendarSelection.country(rawStored!)
          : null;
  final selection = tradition != FaithTradition.catholic
      ? const CalendarSelection.generalRoman()
      : storedSelection ??
          (deviceCountry == 'EC'
              ? CalendarSelection.country('EC')
              : const CalendarSelection.generalRoman());
  final now = localNow().toLocal();
  return CalendarProfile(
    languageCode: deviceLanguageCode(),
    tradition: tradition,
    deviceCountryCode: RegExp(r'^[A-Z]{2}$').hasMatch(deviceCountry ?? '')
        ? deviceCountry
        : null,
    selection: selection,
    selectionOrigin: storedSelection == null
        ? PreferenceOrigin.deviceDefault
        : PreferenceOrigin.userSelected,
    utcOffset: now.timeZoneOffset,
  );
}
```

- [ ] **Step 3: Ejecutar las pruebas de región**

Run: `flutter test test/features/liturgy/calendar_region_resolver_test.dart`

Expected: PASS; no se solicita permiso de ubicación ni se añade un plugin de geolocalización.

- [ ] **Step 4: Escribir pruebas fallidas del repositorio con fallback**

```dart
const validCalendarJson = '''
{
  "schemaVersion": 1,
  "source": {
    "id": "romcal-general-roman-es",
    "name": "Romcal — Calendario Romano General",
    "url": "https://github.com/romcal/romcal",
    "license": "MIT",
    "revision": "6246bad8c548c1f2528916df40e433c1f7c97c6a",
    "scope": "generalRoman",
    "authorityStatus": "openEcclesialSource",
    "generatedAt": "2026-09-20T00:00:00.000Z",
    "reviewedAt": "2026-09-20",
    "reviewNotes": "Calendario Romano General; propios nacionales no incluidos."
  },
  "days": {
    "2026-09-20": {
      "date": "2026-09-20",
      "primary": {
        "id": "ordinary_time_25_sunday",
        "name": "XXV Domingo del Tiempo Ordinario",
        "rank": "sunday",
        "colors": ["green"]
      },
      "optional": [],
      "season": "ordinaryTime",
      "sundayCycle": "C",
      "weekdayCycle": "II",
      "psalterWeek": 1
    }
  }
}
''';

const ecuadorCalendarJson = '''
{
  "schemaVersion": 1,
  "source": {
    "id": "ecuador-verified-test",
    "name": "Calendario nacional de prueba",
    "url": "https://example.invalid/test-fixture",
    "license": "test-only",
    "revision": "fixture-1",
    "scope": "country",
    "authorityStatus": "officialLicensed",
    "generatedAt": "2026-09-20T00:00:00.000Z",
    "reviewedAt": "2026-09-20",
    "reviewNotes": "Fixture; no se empaqueta en producción."
  },
  "days": {
    "2026-09-20": {
      "date": "2026-09-20",
      "primary": {
        "id": "ecuador_test_day",
        "name": "Celebración ecuatoriana de prueba",
        "rank": "memorial",
        "colors": ["white"]
      },
      "optional": [],
      "season": "ordinaryTime",
      "sundayCycle": "C",
      "weekdayCycle": "II",
      "psalterWeek": 1
    }
  }
}
''';

test('Ecuador sin paquete verificado devuelve el día general', () async {
  final repository = AssetLiturgyRepository(
    loadAsset: (path) async {
      if (path.endsWith('general_roman_es_2025_2035.json')) {
        return validCalendarJson;
      }
      throw FlutterError('No debe intentar cargar un paquete no verificado');
    },
    verifiedCountryAssets: const {},
  );

  final day = await repository.forDate(
    DateTime(2026, 9, 20),
    selection: CalendarSelection.country('EC'),
  );
  expect(day?.source.scope, CalendarScope.generalRoman);
});

test('documento base corrupto falla de forma controlada', () async {
  final repository = AssetLiturgyRepository(
    loadAsset: (_) async => '{bad',
    verifiedCountryAssets: const {},
  );
  expect(
    repository.forDate(
      DateTime(2026, 9, 20),
      selection: const CalendarSelection.generalRoman(),
    ),
    throwsFormatException,
  );
});

test('solo una ruta declarada puede superponer el calendario general', () async {
  const countryPath = 'assets/liturgy/countries/EC_es_2025_2035.json';
  final repository = AssetLiturgyRepository(
    loadAsset: (path) async =>
        path == countryPath ? ecuadorCalendarJson : validCalendarJson,
    verifiedCountryAssets: const {'EC': countryPath},
  );
  final day = await repository.forDate(
    DateTime(2026, 9, 20),
    selection: CalendarSelection.country('EC'),
  );
  expect(day?.primary.id, 'ecuador_test_day');
  expect(day?.source.scope, CalendarScope.country);
});
```

El fixture nacional es exclusivamente de prueba y nunca se copiará a `assets/`; demuestra la precedencia sin afirmar que hoy exista un calendario ecuatoriano autorizado.

- [ ] **Step 5: Implementar contrato y repositorio con capas verificadas**

```dart
abstract interface class LiturgyRepository {
  Future<LiturgicalDay?> forDate(
    DateTime date, {
    required CalendarSelection selection,
  });
}

final class AssetLiturgyRepository implements LiturgyRepository {
  AssetLiturgyRepository({
    AssetLoader? loadAsset,
    Map<String, String>? verifiedCountryAssets,
  })  : _loadAsset = loadAsset ?? rootBundle.loadString,
        _verifiedCountryAssetsOverride = verifiedCountryAssets;

  static const baseAsset =
      'assets/liturgy/general_roman_es_2025_2035.json';

  final AssetLoader _loadAsset;
  final Map<String, String>? _verifiedCountryAssetsOverride;
  final Map<String, Future<Map<String, LiturgicalDay>>> _cache = {};
  Future<Map<String, String>>? _manifestCache;

  @override
  Future<LiturgicalDay?> forDate(
    DateTime date, {
    required CalendarSelection selection,
  }) async {
    final key = _dateKey(date);
    final base = await _loadCalendar(baseAsset);
    final verifiedCountryAssets = await _countryAssets();
    final countryAsset = selection.countryCode == null
        ? null
        : verifiedCountryAssets[selection.countryCode];
    if (countryAsset == null) return base[key];
    final country = await _loadCalendar(countryAsset);
    return country[key] ?? base[key];
  }

  Future<Map<String, String>> _countryAssets() {
    final override = _verifiedCountryAssetsOverride;
    if (override != null) return Future.value(override);
    return _manifestCache ??= _loadManifest();
  }
}
```

Completar `_loadCalendar` con parseo estricto de `schemaVersion == 1`, una `LiturgicalSource` por documento, caché por ruta y clave `yyyy-MM-dd`. `_loadManifest` leerá `assets/liturgy/manifest.json`, exigirá `schemaVersion == 1`, `base == baseAsset` y un mapa `verifiedCountries` cuyas claves cumplan `^[A-Z]{2}$` y rutas comiencen por `assets/liturgy/countries/`. No se debe probar una ruta por convención si no figura allí.

- [ ] **Step 6: Escribir pruebas fallidas de fecha civil local**

```dart
final class FakeLiturgyRepository implements LiturgyRepository {
  DateTime? requestedDate;
  CalendarSelection? requestedSelection;

  @override
  Future<LiturgicalDay?> forDate(
    DateTime date, {
    required CalendarSelection selection,
  ) async {
    requestedDate = date;
    requestedSelection = selection;
    return null;
  }
}

test('today usa la fecha local inyectada y la selección Ecuador', () async {
  final repository = FakeLiturgyRepository();
  final service = LiturgyService(
    repository: repository,
    selection: CalendarSelection.country('EC'),
    localNow: () => DateTime(2026, 9, 19, 23, 30),
  );
  await service.today();
  expect(repository.requestedDate, DateTime(2026, 9, 19));
  expect(repository.requestedSelection, CalendarSelection.country('EC'));
});

test('calcula el siguiente cambio de día local', () {
  final service = LiturgyService(
    repository: FakeLiturgyRepository(),
    selection: const CalendarSelection.generalRoman(),
    localNow: () => DateTime(2026, 9, 20, 23, 59, 59),
  );
  expect(service.untilNextDay(), const Duration(seconds: 2));
});
```

- [ ] **Step 7: Implementar el servicio sin zona horaria fija**

```dart
abstract interface class DailyLiturgyLoader {
  Future<LiturgicalDay?> today();
  Duration untilNextDay();
}

final class LiturgyService implements DailyLiturgyLoader {
  LiturgyService({
    required this.repository,
    required this.selection,
    DateTime Function()? localNow,
  }) : _localNow = localNow ?? DateTime.now;

  final LiturgyRepository repository;
  final CalendarSelection selection;
  final DateTime Function() _localNow;

  @override
  Future<LiturgicalDay?> today() => forDate(_localNow().toLocal());

  @override
  Duration untilNextDay() {
    final now = _localNow().toLocal();
    return DateTime(now.year, now.month, now.day + 1).difference(now) +
        const Duration(seconds: 1);
  }

  Future<LiturgicalDay?> forDate(DateTime value) => repository.forDate(
        DateTime(value.year, value.month, value.day),
        selection: selection,
      );
}
```

- [ ] **Step 8: Ejecutar y formatear las pruebas de aplicación y datos**

Run: `dart format lib/features/liturgy lib/services/storage_service.dart test/features/liturgy; flutter test test/features/liturgy/calendar_region_resolver_test.dart test/features/liturgy/asset_liturgy_repository_test.dart test/features/liturgy/liturgy_service_test.dart`

Expected: PASS.

- [ ] **Step 9: Registrar cambios sin commit**

Run: `git status --short -- lib/features/liturgy lib/services/storage_service.dart test/features/liturgy`

Expected: dominio, datos, aplicación, almacenamiento y pruebas aparecen sin cambios ajenos.

---

### Task 3: Generador reproducible, activo y licencia

**Files:**
- Create: `tools/generate_liturgical_calendar/package.json`
- Create: `tools/generate_liturgical_calendar/package-lock.json`
- Create: `tools/generate_liturgical_calendar/generate.mjs`
- Create: `tools/generate_liturgical_calendar/audit.mjs`
- Create: `assets/liturgy/manifest.json`
- Create: `assets/liturgy/general_roman_es_2025_2035.json`
- Create: `assets/licenses/romcal.txt`
- Modify: `pubspec.yaml`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: `romcal@3.0.0-dev.140` y `@romcal/calendar.general-roman@3.0.0-dev.140`.
- Produces: JSON base `schemaVersion: 1` indexado por `yyyy-MM-dd` y manifiesto de países verificados compatible con `AssetLiturgyRepository`.

- [ ] **Step 1: Crear manifiesto con versiones exactas**

```json
{
  "name": "verbum-liturgical-calendar-generator",
  "private": true,
  "type": "module",
  "scripts": {
    "generate": "node generate.mjs",
    "audit": "node audit.mjs"
  },
  "dependencies": {
    "@romcal/calendar.general-roman": "3.0.0-dev.140",
    "romcal": "3.0.0-dev.140"
  }
}
```

- [ ] **Step 2: Generar `package-lock.json` y comprobar hashes**

Run: `npm install --package-lock-only --ignore-scripts`

Workdir: `tools/generate_liturgical_calendar`

Expected: lockfile v3 con ambas dependencias en `3.0.0-dev.140`.

- [ ] **Step 3: Escribir el generador determinista**

El script inicializará Romcal con `GeneralRoman_Es`, `scope: 'gregorian'`, Epifanía el 6 de enero, Ascensión en jueves y Corpus Christi en jueves. Estas opciones representan el Calendario Romano General estricto, no transferencias nacionales de Ecuador.

```javascript
import { writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { Romcal } from 'romcal';
import { GeneralRoman_Es } from '@romcal/calendar.general-roman';

const romcal = new Romcal({
  localizedCalendar: GeneralRoman_Es,
  scope: 'gregorian',
  epiphanyOnSunday: false,
  ascensionOnSunday: false,
  corpusChristiOnSunday: false,
});

const rankMap = {
  SOLEMNITY: 'solemnity',
  SUNDAY: 'sunday',
  FEAST: 'feast',
  MEMORIAL: 'memorial',
  OPTIONAL_MEMORIAL: 'optionalMemorial',
  WEEKDAY: 'weekday',
};
const colorMap = {
  WHITE: 'white',
  GREEN: 'green',
  RED: 'red',
  PURPLE: 'purple',
  ROSE: 'rose',
  GOLD: 'gold',
};
const seasonMap = {
  ADVENT: 'advent',
  CHRISTMAS_TIME: 'christmas',
  ORDINARY_TIME: 'ordinaryTime',
  LENT: 'lent',
  PASCHAL_TRIDUUM: 'triduum',
  EASTER_TIME: 'easter',
};

function requiredMap(map, value, field) {
  const normalized = map[value];
  if (!normalized) throw new Error(`Valor desconocido en ${field}: ${value}`);
  return normalized;
}

function normalizeCelebration(item) {
  return {
    id: item.id,
    name: item.name,
    rank: requiredMap(rankMap, item.rank, 'rank'),
    colors: item.colors.map((value) => requiredMap(colorMap, value, 'color')),
  };
}

function normalizeCycle(value, prefix) {
  if (value == null) return null;
  if (!value.startsWith(prefix)) throw new Error(`Ciclo desconocido: ${value}`);
  return value.slice(prefix.length);
}

function normalizeDay(date, primary, alternatives) {
  if (!primary) throw new Error(`No existe celebración principal para ${date}`);
  const sundayCycle = normalizeCycle(primary.cycles?.sundayCycle, 'YEAR_');
  const weekdayCycle = normalizeCycle(primary.cycles?.weekdayCycle, 'YEAR_');
  const psalterWeek = normalizeCycle(primary.cycles?.psalterWeek, 'WEEK_');
  if (sundayCycle != null && !['A', 'B', 'C'].includes(sundayCycle)) {
    throw new Error(`Ciclo dominical desconocido: ${sundayCycle}`);
  }
  if (weekdayCycle != null && !['1', '2'].includes(weekdayCycle)) {
    throw new Error(`Ciclo ferial desconocido: ${weekdayCycle}`);
  }
  if (psalterWeek != null && !['1', '2', '3', '4'].includes(psalterWeek)) {
    throw new Error(`Semana del salterio desconocida: ${psalterWeek}`);
  }
  return {
    date,
    primary: normalizeCelebration(primary),
    optional: alternatives.map(normalizeCelebration),
    season: requiredMap(seasonMap, primary.seasons[0], 'season'),
    sundayCycle,
    weekdayCycle: weekdayCycle == null ? null : weekdayCycle === '1' ? 'I' : 'II',
    psalterWeek: psalterWeek == null ? null : Number(psalterWeek),
  };
}

const days = {};
for (let year = 2025; year <= 2035; year += 1) {
  const calendar = await romcal.generateCalendar(year);
  for (const [date, celebrations] of Object.entries(calendar)) {
    const [primary, ...optional] = celebrations;
    days[date] = normalizeDay(date, primary, optional);
  }
}

const output = {
  schemaVersion: 1,
  source: {
    id: 'romcal-general-roman-es',
    name: 'Romcal — Calendario Romano General',
    url: 'https://github.com/romcal/romcal',
    license: 'MIT',
    revision: '6246bad8c548c1f2528916df40e433c1f7c97c6a',
    packageVersion: '3.0.0-dev.140',
    scope: 'generalRoman',
    authorityStatus: 'openEcclesialSource',
    generatedAt: process.env.SOURCE_DATE_EPOCH
      ? new Date(Number(process.env.SOURCE_DATE_EPOCH) * 1000).toISOString()
      : '2026-09-20T00:00:00.000Z',
    reviewedAt: '2026-09-20',
    reviewNotes: 'Calendario Romano General; propios de Ecuador no incluidos.',
  },
  days,
};

await writeFile(
  resolve('../../assets/liturgy/general_roman_es_2025_2035.json'),
  `${JSON.stringify(output)}\n`,
  'utf8',
);
```

Romcal ya devuelve la celebración principal seguida de las opciones válidas para la fecha. La versión npm fijada corresponde al commit Git `6246bad8c548c1f2528916df40e433c1f7c97c6a`; el lockfile conservará además los hashes de integridad. El generador detendrá la ejecución ante rangos, colores, temporadas o ciclos desconocidos.

- [ ] **Step 4: Escribir auditoría ejecutable**

```javascript
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import assert from 'node:assert/strict';

const path = resolve('../../assets/liturgy/general_roman_es_2025_2035.json');
const data = JSON.parse(await readFile(path, 'utf8'));
const manifest = JSON.parse(await readFile(
  resolve('../../assets/liturgy/manifest.json'),
  'utf8',
));
assert.equal(data.schemaVersion, 1);
assert.equal(manifest.schemaVersion, 1);
assert.equal(manifest.base, 'assets/liturgy/general_roman_es_2025_2035.json');
assert.deepEqual(manifest.verifiedCountries, {});
assert.equal(Object.keys(data.days).length, 4017);
assert.equal(data.days['2026-04-05'].primary.id, 'easter_sunday');
assert.equal(data.days['2026-02-18'].primary.id, 'ash_wednesday');
assert.equal(data.days['2026-11-29'].season, 'advent');
assert.equal(data.source.license, 'MIT');
assert.equal(data.source.revision, '6246bad8c548c1f2528916df40e433c1f7c97c6a');
assert.equal(data.source.reviewedAt, '2026-09-20');

for (const [date, day] of Object.entries(data.days)) {
  assert.match(date, /^\d{4}-\d{2}-\d{2}$/);
  assert.ok(day.primary.name.trim().length > 0);
  assert.doesNotMatch(day.primary.name, /Jehová|Yahvé|YHWH/i);
}

console.log('Calendario auditado: 2025-2035, 4017 fechas.');
```

Crear `assets/liturgy/manifest.json` con contenido exacto:

```json
{
  "schemaVersion": 1,
  "base": "assets/liturgy/general_roman_es_2025_2035.json",
  "verifiedCountries": {}
}
```

`verifiedCountries` comienza vacío porque Romcal solo aporta el Calendario Romano General y no se encontró un calendario ecuatoriano completo, estructurado y redistribuible. No añadir `EC` hasta disponer de fuente documentada y pasar la misma auditoría. La preferencia Ecuador seguirá funcionando mediante fallback base.

- [ ] **Step 5: Generar activo, copiar licencia y registrar assets**

Run: `npm ci --ignore-scripts; npm run generate; npm run audit`

Workdir: `tools/generate_liturgical_calendar`

Expected: auditoría informa 4017 fechas, valida que `manifest.json` no declare paquetes inexistentes y termina con código 0.

Copiar el texto MIT publicado por Romcal a `assets/licenses/romcal.txt`. Añadir a `pubspec.yaml`:

```yaml
    - assets/liturgy/
    - assets/licenses/
```

Añadir `**/node_modules/` a `.gitignore`, conservando las reglas existentes para `key.properties` y `*.jks`.

- [ ] **Step 6: Confirmar que Flutter empaqueta y parsea el activo**

Run: `flutter pub get; flutter test test/features/liturgy/asset_liturgy_repository_test.dart`

Expected: PASS sin advertencias de asset ausente.

- [ ] **Step 7: Registrar cambios sin commit**

Run: `git status --short -- tools/generate_liturgical_calendar assets/liturgy assets/licenses pubspec.yaml pubspec.lock`

Expected: generador, activo, licencia y manifiestos aparecen; no se crea AAB.

---

### Task 4: Tarjeta, detalle y fuente accesibles

**Files:**
- Create: `lib/features/liturgy/presentation/liturgical_palette.dart`
- Create: `lib/features/liturgy/presentation/today_liturgy_card.dart`
- Create: `lib/features/liturgy/presentation/liturgy_day_screen.dart`
- Create: `lib/features/liturgy/presentation/liturgy_source_sheet.dart`
- Test: `test/features/liturgy/today_liturgy_card_test.dart`

**Interfaces:**
- Consumes: `LiturgicalDay`, `LiturgicalSource` y `CalendarSelection`.
- Produces: `TodayLiturgyCard(day:, onTap:)`, `LiturgyDayScreen(day:, selection:)` y `showLiturgySourceSheet(day:, selection:)`; la fuente efectiva se lee desde `day.source` y la selección solicitada se conserva aparte.

- [ ] **Step 1: Escribir pruebas fallidas de layout y semántica**

```dart
const cardTestSource = LiturgicalSource(
  id: 'romcal-general-roman-es',
  name: 'Romcal',
  url: 'https://github.com/romcal/romcal',
  license: 'MIT',
  revision: '6246bad8c548c1f2528916df40e433c1f7c97c6a',
  scope: CalendarScope.generalRoman,
  authorityStatus: 'openEcclesialSource',
  generatedAt: '2026-09-20T00:00:00.000Z',
  reviewedAt: '2026-09-20',
  reviewNotes: 'Calendario Romano General; propios de Ecuador no incluidos.',
);

LiturgicalDay cardDay(String name, List<String> colors) {
  return LiturgicalDay.fromJson({
    'date': '2026-09-20',
    'primary': {
      'id': 'ordinary_time_25_sunday',
      'name': name,
      'rank': 'sunday',
      'colors': colors,
    },
    'optional': const [],
    'season': 'ordinaryTime',
    'sundayCycle': 'C',
    'weekdayCycle': 'II',
    'psalterWeek': 1,
  }, source: cardTestSource);
}

testWidgets('la tarjeta resiste 320 px y texto al 200 %', (tester) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: Scaffold(body: TodayLiturgyCard(
        day: cardDay('Domingo de nombre deliberadamente extenso para probar el diseño', ['green']),
        onTap: () {},
      )),
    ),
  ));

  expect(tester.takeException(), isNull);
  expect(find.text('HOY EN LA IGLESIA'), findsOneWidget);
  expect(find.text('Ver el día'), findsOneWidget);
});

testWidgets('el blanco litúrgico conserva borde y etiqueta textual', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: TodayLiturgyCard(
      day: cardDay('Solemnidad de prueba', ['white']),
      onTap: () {},
    )),
  ));
  expect(find.textContaining('Blanco'), findsOneWidget);
  final decoration = tester.widget<Container>(find.byKey(const Key('liturgical_color_marker'))).decoration as BoxDecoration;
  expect(decoration.border, isNotNull);
});

testWidgets('un día sin color usa un acento neutro seguro', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: TodayLiturgyCard(
      day: cardDay('Sábado Santo', const []),
      onTap: () {},
    )),
  ));
  expect(tester.takeException(), isNull);
  expect(find.textContaining('Sin color indicado'), findsOneWidget);
});

testWidgets('Ecuador elegido con fuente general explica el fallback', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) => TextButton(
      onPressed: () => showLiturgySourceSheet(
        context,
        day: cardDay('Domingo', ['green']),
        selection: CalendarSelection.country('EC'),
      ),
      child: const Text('Fuente'),
    )),
  ));
  await tester.tap(find.text('Fuente'));
  await tester.pumpAndSettle();
  expect(find.text('Calendario Romano General'), findsOneWidget);
  expect(find.textContaining('contenido local de Ecuador aún no está disponible'), findsOneWidget);
});
```

- [ ] **Step 2: Ejecutar pruebas y confirmar que fallan**

Run: `flutter test test/features/liturgy/today_liturgy_card_test.dart`

Expected: FAIL por widgets inexistentes.

- [ ] **Step 3: Implementar paleta y tarjeta compacta**

```dart
final class LiturgicalPalette {
  static Color accent(LiturgicalColor color, Brightness brightness) {
    return switch (color) {
      LiturgicalColor.white => brightness == Brightness.dark
          ? const Color(0xFFF2E9D8)
          : const Color(0xFFB59868),
      LiturgicalColor.green => const Color(0xFF4F7868),
      LiturgicalColor.red => const Color(0xFFA4514C),
      LiturgicalColor.purple => const Color(0xFF715987),
      LiturgicalColor.rose => const Color(0xFFB26F83),
      LiturgicalColor.gold => const Color(0xFFA98339),
    };
  }
}
```

La tarjeta usará `Semantics(button: true)`, nombre máximo de dos líneas, `AnimatedContainer` de 250 ms, marcador con clave `liturgical_color_marker`, texto del color y un fondo derivado de `colorScheme.surface`; el color litúrgico no será el único indicador.

- [ ] **Step 4: Implementar pantalla y hoja de fuente**

`LiturgyDayScreen` mostrará fecha, celebración, tiempo, rango, ciclos y memorias opcionales. El CTA devocional dirá exactamente `Oración devocional sugerida para hoy`; nunca `Colecta` ni `Oración oficial`. `LiturgySourceSheet` mostrará el alcance efectivo, revisión y enlace mediante `openSource`. Si `selection.countryCode == 'EC'` pero `day.source.scope == CalendarScope.generalRoman`, mostrará `El contenido local de Ecuador aún no está disponible; hoy se usa el Calendario Romano General`, sin afirmar que el calendario general sea el propio ecuatoriano.

- [ ] **Step 5: Ejecutar pruebas con modo claro y oscuro**

Run: `dart format lib/features/liturgy/presentation test/features/liturgy/today_liturgy_card_test.dart; flutter test test/features/liturgy/today_liturgy_card_test.dart`

Expected: PASS, sin overflow.

- [ ] **Step 6: Registrar cambios sin commit**

Run: `git status --short -- lib/features/liturgy/presentation test/features/liturgy/today_liturgy_card_test.dart`

Expected: cuatro archivos de presentación y su prueba.

---

### Task 5: Sección Hoy aislada por tradición y resistente a fallos

**Files:**
- Create: `lib/features/liturgy/presentation/today_liturgy_section.dart`
- Modify: `lib/screens/home_screen.dart:1-17`
- Modify: `lib/screens/home_screen.dart:479-488`
- Test: `test/features/liturgy/today_liturgy_section_test.dart`

**Interfaces:**
- Consumes: `DailyLiturgyLoader.today()`, tradición validada, `CalendarRegionResolver`, `CalendarSelection` y `TodayLiturgyCard`.
- Produces: `TodayLiturgySection(service:, tradition:, selection:, scheduleRefresh:)`, oculta fuera de catolicismo o ante error y conserva la selección al navegar al detalle.

- [ ] **Step 1: Escribir pruebas fallidas de aislamiento**

```dart
const sectionTestSource = LiturgicalSource(
  id: 'romcal-general-roman-es',
  name: 'Romcal — Calendario Romano General',
  url: 'https://github.com/romcal/romcal',
  license: 'MIT',
  revision: '6246bad8c548c1f2528916df40e433c1f7c97c6a',
  scope: CalendarScope.generalRoman,
  authorityStatus: 'openEcclesialSource',
  generatedAt: '2026-09-20T00:00:00.000Z',
  reviewedAt: '2026-09-20',
  reviewNotes: 'Calendario Romano General; propios de Ecuador no incluidos.',
);

final class FakeLiturgyService implements DailyLiturgyLoader {
  FakeLiturgyService({this.day, this.error});

  final LiturgicalDay? day;
  final Object? error;
  int calls = 0;

  @override
  Future<LiturgicalDay?> today() async {
    calls++;
    if (error != null) throw error!;
    return day;
  }

  @override
  Duration untilNextDay() => const Duration(hours: 12);
}

final catholicDay = LiturgicalDay.fromJson({
  'date': '2026-09-20',
  'primary': {
    'id': 'ordinary_time_25_sunday',
    'name': 'XXV Domingo del Tiempo Ordinario',
    'rank': 'sunday',
    'colors': ['green'],
  },
  'optional': const [],
  'season': 'ordinaryTime',
  'sundayCycle': 'C',
  'weekdayCycle': 'II',
  'psalterWeek': 1,
}, source: sectionTestSource);

testWidgets('no consulta ni muestra liturgia para tradición evangélica', (tester) async {
  final service = FakeLiturgyService(day: catholicDay);
  await tester.pumpWidget(MaterialApp(
    home: TodayLiturgySection(
      service: service,
      tradition: FaithTradition.evangelical,
      scheduleRefresh: false,
    ),
  ));
  await tester.pump();
  expect(service.calls, 0);
  expect(find.text('HOY EN LA IGLESIA'), findsNothing);
});

testWidgets('un fallo del repositorio no rompe la pantalla', (tester) async {
  final service = FakeLiturgyService(error: const FormatException('asset'));
  await tester.pumpWidget(MaterialApp(
    home: Column(children: [
      const Text('Hoy sigue visible'),
      TodayLiturgySection(
        service: service,
        tradition: FaithTradition.catholic,
        scheduleRefresh: false,
      ),
    ]),
  ));
  await tester.pumpAndSettle();
  expect(find.text('Hoy sigue visible'), findsOneWidget);
  expect(find.text('HOY EN LA IGLESIA'), findsNothing);
  expect(tester.takeException(), isNull);
});

testWidgets('católica carga y recarga al comenzar el día siguiente', (tester) async {
  final service = FakeLiturgyService(day: catholicDay);
  await tester.pumpWidget(MaterialApp(
    home: TodayLiturgySection(
      service: service,
      tradition: FaithTradition.catholic,
      scheduleRefresh: true,
    ),
  ));
  await tester.pump();
  expect(service.calls, 1);
  expect(find.text('HOY EN LA IGLESIA'), findsOneWidget);

  await tester.pump(const Duration(hours: 12));
  await tester.pump();
  expect(service.calls, 2);
});

testWidgets('la tarjeta católica abre el detalle del día', (tester) async {
  final service = FakeLiturgyService(day: catholicDay);
  await tester.pumpWidget(MaterialApp(
    home: TodayLiturgySection(
      service: service,
      tradition: FaithTradition.catholic,
      selection: CalendarSelection.country('EC'),
      scheduleRefresh: false,
    ),
  ));
  await tester.pump();
  await tester.tap(find.text('Ver el día'));
  await tester.pumpAndSettle();
  final screen = tester.widget<LiturgyDayScreen>(find.byType(LiturgyDayScreen));
  expect(screen.selection, CalendarSelection.country('EC'));
});
```

- [ ] **Step 2: Ejecutar pruebas y confirmar que fallan**

Run: `flutter test test/features/liturgy/today_liturgy_section_test.dart`

Expected: FAIL por sección inexistente.

- [ ] **Step 3: Implementar sección con carga, navegación y refresco**

`TodayLiturgySection` será un wrapper: cuando reciba `service` en pruebas construirá directamente `_TodayLiturgyContent`; en producción escuchará `StorageService().faithPreferencesListenable()` y creará el contenido con una clave que combine tradición y selección. Así, cambiar Ecuador/General o la tradición en Configuración recarga Hoy al volver, sin reiniciar la app.

```dart
return ValueListenableBuilder<Box>(
  valueListenable: StorageService().faithPreferencesListenable(),
  builder: (context, _, __) {
    final tradition = faithTraditionFromStorageString(
      StorageService().getValidatedTraditionalPrayersReligion(),
    );
    final profile = CalendarRegionResolver(
      readStoredCountry: StorageService().getCatholicCalendarCountry,
    ).resolve(tradition);
    return _TodayLiturgyContent(
      key: ValueKey(
        '${tradition.name}:${profile.selection.countryCode ?? 'GENERAL'}',
      ),
      tradition: tradition,
      selection: profile.selection,
      scheduleRefresh: scheduleRefresh,
    );
  },
);
```

El estado de `_TodayLiturgyContent` implementará la carga:

```dart
late final FaithTradition _tradition;
late final CalendarSelection _selection;
late final DailyLiturgyLoader _service;
Timer? _refreshTimer;
LiturgicalDay? _day;

@override
void initState() {
  super.initState();
  _tradition = widget.tradition ?? faithTraditionFromStorageString(
    StorageService().getValidatedTraditionalPrayersReligion(),
  );
  _selection = widget.selection ??
      CalendarRegionResolver(
        readStoredCountry: StorageService().getCatholicCalendarCountry,
      ).resolve(_tradition).selection;
  _service = widget.service ?? LiturgyService(
    repository: AssetLiturgyRepository(),
    selection: _selection,
  );
  if (_tradition == FaithTradition.catholic) {
    _load();
    if (widget.scheduleRefresh) _scheduleNextMidnight();
  }
}

Future<void> _load() async {
  try {
    final day = await _service.today();
    if (mounted) setState(() => _day = day);
  } on Object catch (error, stackTrace) {
    debugPrint('[TodayLiturgySection] $error\n$stackTrace');
    if (mounted) setState(() => _day = null);
  }
}

void _scheduleNextMidnight() {
  _refreshTimer?.cancel();
  _refreshTimer = Timer(_service.untilNextDay(), () async {
    await _load();
    if (mounted) _scheduleNextMidnight();
  });
}

@override
void dispose() {
  _refreshTimer?.cancel();
  super.dispose();
}
```

El temporizador calculará la próxima medianoche local del dispositivo, añadirá un segundo de tolerancia, recargará y se reprogramará. `dispose` cancelará el temporizador. La construcción de producción leerá `StorageService().getValidatedTraditionalPrayersReligion()`, resolverá la selección regional una sola vez y pasará `_selection` a `LiturgyDayScreen` y `LiturgySourceSheet`.

- [ ] **Step 4: Integrar una sola línea en Home**

Añadir import y, después de `StreakCardDuolingoStyle` y antes de `SpiritualPathTodayCard`:

```dart
const SizedBox(height: 16),
const TodayLiturgySection(),
const SpiritualPathTodayCard(),
```

`TodayLiturgySection` devolverá `SizedBox.shrink()` cuando no haya contenido. Cuando sí lo haya, añadirá internamente 16 px después de la tarjeta; así se conserva el único espacio original entre racha y camino para las otras tradiciones.

- [ ] **Step 5: Ejecutar pruebas de sección y pantalla existente**

Run: `dart format lib/features/liturgy/presentation/today_liturgy_section.dart lib/screens/home_screen.dart test/features/liturgy/today_liturgy_section_test.dart; flutter test test/features/liturgy/today_liturgy_section_test.dart test/verbum_bottom_navigation_test.dart`

Expected: PASS.

- [ ] **Step 6: Registrar cambios sin commit**

Run: `git diff --stat -- lib/screens/home_screen.dart lib/features/liturgy/presentation/today_liturgy_section.dart`

Expected: Home solo contiene import e inserción; la lógica vive en el módulo.

---

### Task 6: Preferencia católica Ecuador o Calendario Romano General

**Files:**
- Create: `lib/features/liturgy/presentation/catholic_calendar_settings_tile.dart`
- Modify: `lib/screens/settings_screen.dart`
- Test: `test/features/liturgy/catholic_calendar_settings_test.dart`

**Interfaces:**
- Consumes: `FaithTradition`, `CalendarSelection`, `CalendarRegionResolver` y `StorageService.setCatholicCalendarSelection(...)`.
- Produces: `CatholicCalendarSettingsTile(tradition:, selection:, onChanged:)`, visible solo para católicos y sin pantalla adicional de onboarding.

- [ ] **Step 1: Escribir pruebas fallidas de visibilidad y selección**

```dart
testWidgets('no muestra calendario católico a tradición evangélica', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: CatholicCalendarSettingsTile(
        tradition: FaithTradition.evangelical,
        selection: const CalendarSelection.generalRoman(),
        onChanged: (_) {},
      ),
    ),
  ));
  expect(find.text('Calendario católico'), findsNothing);
});

testWidgets('Ecuador explica el fallback y permite elegir General', (tester) async {
  CalendarSelection? changed;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: CatholicCalendarSettingsTile(
        tradition: FaithTradition.catholic,
        selection: CalendarSelection.country('EC'),
        onChanged: (value) => changed = value,
      ),
    ),
  ));
  expect(find.text('Ecuador · recomendado para ti'), findsOneWidget);
  expect(find.textContaining('se usa el Calendario Romano General'), findsOneWidget);
  await tester.tap(find.text('Calendario católico'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Calendario Romano General').last);
  await tester.pumpAndSettle();
  expect(changed, const CalendarSelection.generalRoman());
});
```

- [ ] **Step 2: Ejecutar las pruebas y confirmar que fallan**

Run: `flutter test test/features/liturgy/catholic_calendar_settings_test.dart`

Expected: FAIL por widget inexistente.

- [ ] **Step 3: Implementar una fila y una hoja de selección compactas**

```dart
@override
Widget build(BuildContext context) {
  if (tradition != FaithTradition.catholic) {
    return const SizedBox.shrink();
  }
  final isEcuador = selection.countryCode == 'EC';
  return ListTile(
    leading: Icon(Icons.public_rounded,
        color: Theme.of(context).colorScheme.primary),
    title: const Text('Calendario católico'),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isEcuador
            ? 'Ecuador · recomendado para ti'
            : 'Calendario Romano General'),
        if (isEcuador)
          const Text(
            'Contenido local aún no disponible; se usa el Calendario Romano General',
          ),
      ],
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => _showSelection(context),
  );
}
```

La hoja inferior mostrará solo dos opciones: `Ecuador` y `Calendario Romano General`. Bajo Ecuador dirá `Aplicaremos contenido ecuatoriano únicamente cuando esté verificado`. Al tocar una opción cerrará la hoja y llamará `onChanged` una sola vez. Usará `SafeArea`, objetivos táctiles mínimos de 48 px y semántica de selección.

- [ ] **Step 4: Integrar la fila debajo de Tradición cristiana**

En `SettingsScreen`, dentro de la tarjeta existente de `Oraciones Tradicionales`, resolver:

```dart
final storage = StorageService();
final tradition = faithTraditionFromStorageString(
  storage.getValidatedTraditionalPrayersReligion(),
);
final calendarProfile = CalendarRegionResolver(
  readStoredCountry: storage.getCatholicCalendarCountry,
).resolve(tradition);
```

Después del `ListTile` de tradición, añadir:

```dart
if (tradition == FaithTradition.catholic) const Divider(height: 1),
CatholicCalendarSettingsTile(
  tradition: tradition,
  selection: calendarProfile.selection,
  onChanged: (selection) async {
    await storage.setCatholicCalendarSelection(selection);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(selection.countryCode == 'EC'
          ? 'Usaremos Ecuador cuando haya contenido local verificado.'
          : 'Ahora usas el Calendario Romano General.'),
      behavior: SnackBarBehavior.floating,
    ));
  },
),
```

No modificar `TraditionalPrayersReligionSelectionScreen` ni añadir una etapa al onboarding.

- [ ] **Step 5: Probar textos largos, tradición y actualización reactiva**

Añadir estos casos al mismo archivo e inicializar Hive así:

```dart
late Directory hiveDirectory;

setUpAll(() async {
  hiveDirectory = await Directory.systemTemp.createTemp('verbum_liturgy_test_');
  Hive.init(hiveDirectory.path);
  await Hive.openBox('settings');
});

setUp(() async {
  await Hive.box('settings').clear();
});

tearDownAll(() async {
  await Hive.close();
  await hiveDirectory.delete(recursive: true);
});

testWidgets('la fila resiste 320 px y texto al 200 %', (tester) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: Scaffold(body: CatholicCalendarSettingsTile(
        tradition: FaithTradition.catholic,
        selection: CalendarSelection.country('EC'),
        onChanged: (_) {},
      )),
    ),
  ));
  expect(tester.takeException(), isNull);
});

testWidgets('guardar calendario notifica a Hoy una vez', (tester) async {
  final storage = StorageService();
  var notifications = 0;
  final listenable = storage.faithPreferencesListenable();
  void listener() => notifications++;
  listenable.addListener(listener);
  addTearDown(() => listenable.removeListener(listener));

  await storage.setCatholicCalendarSelection(
    CalendarSelection.country('EC'),
  );
  await tester.pump();
  expect(notifications, 1);
  expect(storage.getCatholicCalendarCountry(), 'EC');
});
```

Este segundo caso fija que `TodayLiturgySection` se reconstruye sin reiniciar la app.

Run: `dart format lib/features/liturgy/presentation/catholic_calendar_settings_tile.dart lib/screens/settings_screen.dart test/features/liturgy/catholic_calendar_settings_test.dart; flutter test test/features/liturgy/catholic_calendar_settings_test.dart test/features/liturgy/today_liturgy_section_test.dart`

Expected: PASS sin overflow y con la selección persistida.

- [ ] **Step 6: Registrar cambios sin commit**

Run: `git diff --check -- lib/features/liturgy/presentation/catholic_calendar_settings_tile.dart lib/screens/settings_screen.dart lib/services/storage_service.dart test/features/liturgy/catholic_calendar_settings_test.dart`

Expected: sin errores de whitespace ni cambios de onboarding.

---

### Task 7: Fuentes, terminología y fronteras doctrinales

**Files:**
- Modify: `lib/faith/tradition_capabilities.dart`
- Modify: `lib/features/liturgy/presentation/today_liturgy_section.dart`
- Modify: `lib/screens/content_sources_screen.dart`
- Modify: `test/content_and_bible_test.dart`
- Modify: `docs/plans/2026-09-20-contenido-biblia-revision.md`

**Interfaces:**
- Consumes: metadatos del activo y reglas de `FaithTradition`.
- Produces: explicación consultable y pruebas que impiden mezclar tradiciones o reescribir RV1909.

- [ ] **Step 1: Escribir pruebas fallidas de texto y frontera**

```dart
test('la liturgia católica no es capacidad evangélica ni general', () {
  expect(TraditionCapabilities.forTradition(FaithTradition.catholic).showDailyLiturgy, isTrue);
  expect(TraditionCapabilities.forTradition(FaithTradition.evangelical).showDailyLiturgy, isFalse);
  expect(TraditionCapabilities.forTradition(FaithTradition.general).showDailyLiturgy, isFalse);
  expect(TraditionCapabilities.forTradition(FaithTradition.unset).showDailyLiturgy, isFalse);
  expect(faithTraditionFromStorageString('desconocida'), FaithTradition.unset);
});

test('las citas RV1909 conservan literalmente Jehová', () {
  final texts = SpiritualPathsCatalog.paths
      .expand((path) => path.days)
      .map((day) => day.scripture);
  expect(texts.any((text) => text.contains('Jehová')), isTrue);
});

testWidgets('fuentes explica el alcance general y la convención católica', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: ContentSourcesScreen()));
  await tester.scrollUntilVisible(
    find.text('Calendario Romano General'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  expect(find.text('Calendario Romano General'), findsOneWidget);
  expect(find.textContaining('Dios o Señor'), findsOneWidget);
});
```

- [ ] **Step 2: Ejecutar pruebas y confirmar el fallo de la nueva capacidad/copy**

Run: `flutter test test/content_and_bible_test.dart`

Expected: FAIL porque `showDailyLiturgy` y las nuevas secciones aún no existen.

- [ ] **Step 3: Centralizar la capacidad litúrgica**

Añadir `showDailyLiturgy` a `TraditionCapabilities` y devolver `true` únicamente para `FaithTradition.catholic`; `unset` será `false`, ya que el flujo actual obliga a elegir una tradición antes de entrar.

```dart
final bool showDailyLiturgy;

factory TraditionCapabilities.forTradition(FaithTradition tradition) {
  return TraditionCapabilities(
    showRosaryGuide: tradition == FaithTradition.catholic,
    showSaintsOfDay: tradition == FaithTradition.catholic,
    showNovena: tradition == FaithTradition.catholic,
    showDailyLiturgy: tradition == FaithTradition.catholic,
  );
}
```

Actualizar `TodayLiturgySection` para consultar esta capacidad en lugar de repetir comparaciones de enums.

- [ ] **Step 4: Añadir fuente y convención a la pantalla**

La nueva sección dirá:

```text
Calendario Romano General
La información base del día se genera a partir de Romcal y se guarda para funcionar sin conexión. Ecuador puede elegirse como calendario local, pero mientras no exista un paquete nacional verificado Verbum utiliza el Calendario Romano General y no afirma incluir todos los propios nacionales o diocesanos.

Cómo nombramos a Dios
En el contenido católico usamos normalmente Dios o Señor. Las citas bíblicas conservan su traducción: por eso una cita de la Reina-Valera 1909 puede contener Jehová sin que Verbum altere el texto.
```

Incluir enlaces a Romcal y al Catecismo 206-209 mediante `SourceLink`/`openSource`.

- [ ] **Step 5: Documentar versión, licencia y limitaciones**

Registrar `Romcal 3.0.0-dev.140`, MIT, intervalo 2025-2035, fecha de generación, manifiesto de paquetes nacionales y ausencia del propio nacional completo de Ecuador en `docs/plans/2026-09-20-contenido-biblia-revision.md`.

- [ ] **Step 6: Ejecutar pruebas de contenido**

Run: `dart format lib/faith/tradition_capabilities.dart lib/screens/content_sources_screen.dart test/content_and_bible_test.dart; flutter test test/content_and_bible_test.dart`

Expected: PASS.

- [ ] **Step 7: Registrar cambios sin commit**

Run: `git diff --check -- lib/faith/tradition_capabilities.dart lib/screens/content_sources_screen.dart test/content_and_bible_test.dart docs/plans/2026-09-20-contenido-biblia-revision.md`

Expected: sin whitespace errors.

---

### Task 8: Verificación integral y revisión manual

**Files:**
- Verify: todos los archivos anteriores.
- No create: ningún AAB ni artefacto release.

**Interfaces:**
- Consumes: módulo completo.
- Produces: evidencia de análisis, pruebas, auditoría y funcionamiento visual.

- [ ] **Step 1: Ejecutar auditoría de calendario desde instalación limpia**

Run: `npm ci --ignore-scripts; npm run generate; npm run audit`

Workdir: `tools/generate_liturgical_calendar`

Expected: 4017 fechas, Pascua/Ceniza/Adviento correctos y código 0.

- [ ] **Step 2: Ejecutar análisis estático**

Run: `flutter analyze`

Expected: `No issues found!`.

- [ ] **Step 3: Ejecutar todas las pruebas**

Run: `flutter test`

Expected: todas las pruebas pasan, incluidas las nuevas de liturgia y las existentes de Biblia/contenido.

- [ ] **Step 4: Compilar únicamente APK debug para detectar problemas de assets**

Run: `flutter build apk --debug`

Expected: APK debug generado correctamente. No ejecutar build release ni appbundle.

- [ ] **Step 5: Realizar prueba manual en dispositivo/emulador**

Comprobar exactamente:

1. Tradición católica: tarjeta visible entre racha y camino espiritual.
2. Tradición evangélica y general: tarjeta ausente y sin hueco vertical.
3. Detalle: nombre, color, tiempo, rango, ciclos y fuente correctos.
4. Modo oscuro, 320 px y tamaño de fuente máximo: sin texto cortado ni bajo contraste.
5. Fecha del dispositivo próxima a medianoche: recarga al cambiar el día.
6. Modo avión: tarjeta y detalle siguen funcionando.
7. Asset alterado temporalmente en una prueba controlada: Hoy conserva racha y misiones.
8. Católico con región `EC`: Configuración muestra `Ecuador · recomendado para ti` sin otro onboarding.
9. Cambiar entre Ecuador y Calendario Romano General actualiza Hoy al regresar y conserva el progreso.
10. Evangélico/general: no aparece la fila `Calendario católico`.
11. Ecuador sin paquete verificado: el detalle identifica el Calendario Romano General y no inventa contenido local.
12. Simular un viaje cambiando la región del dispositivo después de guardar `EC`: la preferencia continúa en Ecuador.

- [ ] **Step 6: Revisar el diff completo y preservar cambios previos**

Run: `git diff --check; git status --short; git diff --stat`

Expected: sin errores de whitespace; `android/app/build.gradle.kts` y `android/app/proguard-rules.pro` permanecen sin modificaciones atribuibles a esta fase.

- [ ] **Step 7: Entregar resultado para revisión antes de Git**

Informar archivos modificados, comandos ejecutados, resultados, limitación del calendario nacional ecuatoriano y prueba manual pendiente. No hacer commit ni push hasta que el usuario confirme.

- [ ] **Step 8: Commit y push únicamente después de confirmación explícita**

Run after approval:

```powershell
git add -- .gitignore docs/superpowers/specs/2026-09-20-liturgia-catolica-diaria-design.md docs/superpowers/plans/2026-09-20-liturgia-catolica-diaria.md docs/plans/2026-09-20-contenido-biblia-revision.md assets/liturgy assets/licenses/romcal.txt tools/generate_liturgical_calendar lib/features/liturgy lib/faith/tradition_capabilities.dart lib/services/storage_service.dart lib/screens/home_screen.dart lib/screens/settings_screen.dart lib/screens/content_sources_screen.dart test/features/liturgy test/content_and_bible_test.dart pubspec.yaml pubspec.lock
git diff --cached --check
git commit -m "feat: add offline Catholic liturgical calendar"
git push
```

Expected: un commit revisado; no se incluyen contraseñas, `key.properties`, keystores, AAB ni archivos ajenos.
