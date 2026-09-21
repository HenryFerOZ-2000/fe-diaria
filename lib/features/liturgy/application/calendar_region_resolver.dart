import 'dart:ui';

import '../../../faith/faith_tradition.dart';
import '../domain/calendar_profile.dart';
import '../domain/calendar_selection.dart';

typedef OptionalStringReader = String? Function();
typedef StringReader = String Function();
typedef LocalClock = DateTime Function();

final class CalendarRegionResolver {
  CalendarRegionResolver({
    required this.readStoredCountry,
    OptionalStringReader? deviceCountryCode,
    StringReader? deviceLanguageCode,
    LocalClock? localNow,
  }) : _deviceCountryCode =
           deviceCountryCode ??
           (() => PlatformDispatcher.instance.locale.countryCode),
       _deviceLanguageCode =
           deviceLanguageCode ??
           (() => PlatformDispatcher.instance.locale.languageCode),
       _localNow = localNow ?? DateTime.now;

  final OptionalStringReader readStoredCountry;
  final OptionalStringReader _deviceCountryCode;
  final StringReader _deviceLanguageCode;
  final LocalClock _localNow;

  CalendarProfile resolve(FaithTradition tradition) {
    final rawStored = readStoredCountry();
    final deviceCountry = _normalizedCountry(_deviceCountryCode());
    final storedSelection = _storedSelection(rawStored);

    final selection = tradition != FaithTradition.catholic
        ? const CalendarSelection.generalRoman()
        : storedSelection ??
              (deviceCountry == 'EC'
                  ? CalendarSelection.country('EC')
                  : const CalendarSelection.generalRoman());
    final now = _localNow().toLocal();

    return CalendarProfile(
      languageCode: _deviceLanguageCode(),
      tradition: tradition,
      deviceCountryCode: deviceCountry,
      selection: selection,
      selectionOrigin: rawStored == null
          ? PreferenceOrigin.deviceDefault
          : PreferenceOrigin.userSelected,
      utcOffset: now.timeZoneOffset,
    );
  }

  static CalendarSelection? _storedSelection(String? raw) {
    if (raw == null) return null;
    if (raw == 'GENERAL') return const CalendarSelection.generalRoman();
    final country = _normalizedCountry(raw);
    return country == null
        ? const CalendarSelection.generalRoman()
        : CalendarSelection.country(country);
  }

  static String? _normalizedCountry(String? value) {
    final normalized = value?.trim().toUpperCase();
    if (normalized == null || !RegExp(r'^[A-Z]{2}$').hasMatch(normalized)) {
      return null;
    }
    return normalized;
  }
}
