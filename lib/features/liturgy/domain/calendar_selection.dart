final class CalendarSelection {
  const CalendarSelection.generalRoman() : countryCode = null;

  factory CalendarSelection.country(String code) {
    final normalized = code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(normalized)) {
      throw ArgumentError.value(
        code,
        'code',
        'Debe ser un código ISO 3166-1 alpha-2',
      );
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

  @override
  String toString() => countryCode == null
      ? 'CalendarSelection.generalRoman()'
      : 'CalendarSelection.country($countryCode)';
}
