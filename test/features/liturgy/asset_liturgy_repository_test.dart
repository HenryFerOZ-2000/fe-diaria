import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/features/liturgy/data/asset_liturgy_repository.dart';
import 'package:verbum/features/liturgy/domain/calendar_selection.dart';
import 'package:verbum/features/liturgy/domain/liturgical_source.dart';

const validCalendarJson = '''
{
  "schemaVersion": 1,
  "source": {
    "id": "romcal-general-roman-es",
    "name": "Romcal — Calendario Romano General",
    "url": "https://github.com/romcal/romcal",
    "license": "MIT",
    "revision": "fixture-1",
    "scope": "generalRoman",
    "authorityStatus": "openEcclesialSource",
    "generatedAt": "2026-09-20T00:00:00.000Z",
    "reviewedAt": "2026-09-20",
    "reviewNotes": "Calendario Romano General."
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
    "reviewNotes": "Fixture no distribuido."
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

const emptyEcuadorCalendarJson = '''
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
    "reviewNotes": "Fixture no distribuido."
  },
  "days": {}
}
''';

void main() {
  test('Ecuador sin paquete verificado devuelve el día general', () async {
    final repository = AssetLiturgyRepository(
      loadAsset: (path) async {
        if (path == AssetLiturgyRepository.baseAsset) {
          return validCalendarJson;
        }
        throw StateError('No debe cargar un paquete no verificado');
      },
      verifiedCountryAssets: const {},
    );

    final day = await repository.forDate(
      DateTime(2026, 9, 20),
      selection: CalendarSelection.country('EC'),
    );

    expect(day?.primary.id, 'ordinary_time_25_sunday');
    expect(day?.source.scope, CalendarScope.generalRoman);
  });

  test(
    'solo una ruta declarada puede superponer el calendario general',
    () async {
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
    },
  );

  test('una capa nacional incompleta conserva el día general', () async {
    const countryPath = 'assets/liturgy/countries/EC_es_2025_2035.json';
    final repository = AssetLiturgyRepository(
      loadAsset: (path) async =>
          path == countryPath ? emptyEcuadorCalendarJson : validCalendarJson,
      verifiedCountryAssets: const {'EC': countryPath},
    );

    final day = await repository.forDate(
      DateTime(2026, 9, 20),
      selection: CalendarSelection.country('EC'),
    );

    expect(day?.primary.id, 'ordinary_time_25_sunday');
  });

  test('un documento base corrupto falla de forma controlada', () async {
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

  test('una capa nacional corrupta cae al calendario general', () async {
    const countryPath = 'assets/liturgy/countries/EC_es_2025_2035.json';
    final repository = AssetLiturgyRepository(
      loadAsset: (path) async =>
          path == countryPath ? '{bad' : validCalendarJson,
      verifiedCountryAssets: const {'EC': countryPath},
    );

    final day = await repository.forDate(
      DateTime(2026, 9, 20),
      selection: CalendarSelection.country('EC'),
    );

    expect(day?.primary.id, 'ordinary_time_25_sunday');
    expect(day?.source.scope, CalendarScope.generalRoman);
  });

  test('carga una ruta solo una vez aunque se consulte varias veces', () async {
    var loads = 0;
    final repository = AssetLiturgyRepository(
      loadAsset: (_) async {
        loads++;
        return validCalendarJson;
      },
      verifiedCountryAssets: const {},
    );

    await repository.forDate(
      DateTime(2026, 9, 20),
      selection: const CalendarSelection.generalRoman(),
    );
    await repository.forDate(
      DateTime(2040, 1, 1),
      selection: const CalendarSelection.generalRoman(),
    );

    expect(loads, 1);
  });
}
