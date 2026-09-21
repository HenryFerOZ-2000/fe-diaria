import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/faith/faith_tradition.dart';
import 'package:verbum/features/liturgy/domain/calendar_profile.dart';
import 'package:verbum/features/liturgy/domain/calendar_selection.dart';
import 'package:verbum/features/liturgy/domain/liturgical_day.dart';
import 'package:verbum/features/liturgy/domain/liturgical_source.dart';

const testSource = LiturgicalSource(
  id: 'romcal-general-roman-es',
  name: 'Romcal — Calendario Romano General',
  url: 'https://github.com/romcal/romcal',
  license: 'MIT',
  revision: 'fixture-1',
  scope: CalendarScope.generalRoman,
  authorityStatus: AuthorityStatus.openEcclesialSource,
  generatedAt: '2026-09-20T00:00:00.000Z',
  reviewedAt: '2026-09-20',
  reviewNotes: 'Calendario Romano General; propios nacionales no incluidos.',
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

  test('rechaza fechas civiles imposibles', () {
    expect(
      () => LiturgicalDay.fromJson({
        'date': '2026-02-30',
        'primary': {
          'id': 'x',
          'name': 'X',
          'rank': 'weekday',
          'colors': ['green'],
        },
        'optional': const [],
        'season': 'ordinaryTime',
      }, source: testSource),
      throwsFormatException,
    );
  });

  test('rechaza rangos y colores desconocidos', () {
    expect(
      () => LiturgicalDay.fromJson({
        'date': '2026-09-20',
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

  test('acepta el negro litúrgico producido por el calendario general', () {
    final day = LiturgicalDay.fromJson({
      'date': '2026-11-02',
      'primary': {
        'id': 'commemoration_of_all_the_faithful_departed',
        'name': 'Conmemoración de todos los fieles difuntos',
        'rank': 'solemnity',
        'colors': ['black'],
      },
      'optional': const [],
      'season': 'ordinaryTime',
    }, source: testSource);

    expect(day.primary.colors, [LiturgicalColor.black]);
  });

  test('la selección regional no crea una tradición religiosa', () {
    final ecuador = CalendarSelection.country('ec');
    expect(ecuador.countryCode, 'EC');
    expect(ecuador.isGeneralRoman, isFalse);
    expect(const CalendarSelection.generalRoman().isGeneralRoman, isTrue);
    expect(() => CalendarSelection.country('ecuador'), throwsArgumentError);
  });

  test('el perfil conserva origen, región y zona horaria por separado', () {
    final profile = CalendarProfile(
      languageCode: 'es',
      tradition: FaithTradition.catholic,
      deviceCountryCode: 'EC',
      selection: CalendarSelection.country('EC'),
      selectionOrigin: PreferenceOrigin.deviceDefault,
      utcOffset: const Duration(hours: -5),
    );

    expect(profile.tradition, FaithTradition.catholic);
    expect(profile.selection.countryCode, 'EC');
    expect(profile.utcOffset, const Duration(hours: -5));
  });

  test('parsea la procedencia y rechaza alcances desconocidos', () {
    final source = LiturgicalSource.fromJson({
      'id': 'ecuador-test',
      'name': 'Calendario de prueba',
      'url': 'https://example.invalid',
      'license': 'test-only',
      'revision': '1',
      'scope': 'country',
      'authorityStatus': 'officialLicensed',
      'generatedAt': '2026-09-20T00:00:00.000Z',
      'reviewedAt': '2026-09-20',
      'reviewNotes': 'Fixture.',
    });
    expect(source.scope, CalendarScope.country);
    expect(source.authorityStatus, AuthorityStatus.officialLicensed);

    expect(
      () => LiturgicalSource.fromJson({
        'id': 'x',
        'name': 'X',
        'url': 'https://example.invalid',
        'license': 'x',
        'revision': 'x',
        'scope': 'planet',
        'authorityStatus': 'openEcclesialSource',
        'generatedAt': '2026-09-20',
        'reviewedAt': '2026-09-20',
        'reviewNotes': 'x',
      }),
      throwsFormatException,
    );
  });
}
