import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/faith/faith_tradition.dart';
import 'package:verbum/features/liturgy/application/calendar_region_resolver.dart';
import 'package:verbum/features/liturgy/domain/calendar_profile.dart';
import 'package:verbum/features/liturgy/domain/calendar_selection.dart';

void main() {
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

  test('GENERAL guardado vence a la recomendación regional', () {
    final resolver = CalendarRegionResolver(
      readStoredCountry: () => 'GENERAL',
      deviceCountryCode: () => 'EC',
      deviceLanguageCode: () => 'es',
      localNow: () => DateTime(2026, 9, 20),
    );

    expect(
      resolver.resolve(FaithTradition.catholic).selection,
      const CalendarSelection.generalRoman(),
    );
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
}
