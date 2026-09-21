import 'liturgical_source.dart';

enum LiturgicalSeason { advent, christmas, ordinaryTime, lent, triduum, easter }

enum LiturgicalColor { white, green, red, purple, rose, gold, black }

enum LiturgicalRank {
  solemnity,
  sunday,
  feast,
  memorial,
  optionalMemorial,
  weekday,
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
    final rank = json['rank'];
    final colors = json['colors'];
    if (id is! String ||
        id.trim().isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        rank is! String ||
        colors is! List) {
      throw const FormatException('Celebración litúrgica inválida');
    }
    try {
      return LiturgicalCelebration(
        id: id,
        name: name,
        rank: LiturgicalRank.values.byName(rank),
        colors: List.unmodifiable(
          colors.map((value) => LiturgicalColor.values.byName(value as String)),
        ),
      );
    } on Object {
      throw const FormatException('Rango o color litúrgico desconocido');
    }
  }
}

final class LiturgicalDay {
  const LiturgicalDay({
    required this.date,
    required this.primary,
    required this.optional,
    required this.season,
    this.sundayCycle,
    this.weekdayCycle,
    this.psalterWeek,
    required this.source,
  });

  final DateTime date;
  final LiturgicalCelebration primary;
  final List<LiturgicalCelebration> optional;
  final LiturgicalSeason season;
  final String? sundayCycle;
  final String? weekdayCycle;
  final int? psalterWeek;
  final LiturgicalSource source;

  factory LiturgicalDay.fromJson(
    Map<String, dynamic> json, {
    required LiturgicalSource source,
  }) {
    final rawDate = json['date'];
    final primary = json['primary'];
    final optional = json['optional'];
    final season = json['season'];
    if (rawDate is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawDate) ||
        primary is! Map ||
        optional is! List ||
        season is! String) {
      throw const FormatException('Día litúrgico inválido');
    }

    final parsedDate = DateTime.tryParse(rawDate);
    if (parsedDate == null || _dateKey(parsedDate) != rawDate) {
      throw const FormatException('Fecha litúrgica inválida');
    }

    final sundayCycle = _optionalString(json, 'sundayCycle');
    final weekdayCycle = _optionalString(json, 'weekdayCycle');
    final psalterWeek = json['psalterWeek'];
    if (sundayCycle != null && !const {'A', 'B', 'C'}.contains(sundayCycle)) {
      throw const FormatException('Ciclo dominical inválido');
    }
    if (weekdayCycle != null && !const {'I', 'II'}.contains(weekdayCycle)) {
      throw const FormatException('Ciclo ferial inválido');
    }
    if (psalterWeek != null &&
        (psalterWeek is! int || psalterWeek < 1 || psalterWeek > 4)) {
      throw const FormatException('Semana del salterio inválida');
    }

    try {
      return LiturgicalDay(
        date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
        primary: LiturgicalCelebration.fromJson(
          Map<String, dynamic>.from(primary),
        ),
        optional: List.unmodifiable(
          optional.map(
            (value) => LiturgicalCelebration.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          ),
        ),
        season: LiturgicalSeason.values.byName(season),
        sundayCycle: sundayCycle,
        weekdayCycle: weekdayCycle,
        psalterWeek: psalterWeek as int?,
        source: source,
      );
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('Contenido del día litúrgico inválido');
    }
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String || value.isEmpty) {
      throw FormatException('Campo litúrgico inválido: $key');
    }
    return value;
  }

  static String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
