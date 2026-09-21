enum CalendarScope { generalRoman, americas, country, diocesan }

enum AuthorityStatus { openEcclesialSource, officialLicensed, pendingReview }

final class LiturgicalSource {
  const LiturgicalSource({
    required this.id,
    required this.name,
    required this.url,
    required this.license,
    required this.revision,
    required this.scope,
    required this.authorityStatus,
    required this.generatedAt,
    required this.reviewedAt,
    required this.reviewNotes,
  });

  final String id;
  final String name;
  final String url;
  final String license;
  final String revision;
  final CalendarScope scope;
  final AuthorityStatus authorityStatus;
  final String generatedAt;
  final String reviewedAt;
  final String reviewNotes;

  factory LiturgicalSource.fromJson(Map<String, dynamic> json) {
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Fuente litúrgica inválida: $key');
      }
      return value;
    }

    try {
      return LiturgicalSource(
        id: requiredString('id'),
        name: requiredString('name'),
        url: requiredString('url'),
        license: requiredString('license'),
        revision: requiredString('revision'),
        scope: CalendarScope.values.byName(requiredString('scope')),
        authorityStatus: AuthorityStatus.values.byName(
          requiredString('authorityStatus'),
        ),
        generatedAt: requiredString('generatedAt'),
        reviewedAt: requiredString('reviewedAt'),
        reviewNotes: requiredString('reviewNotes'),
      );
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('Alcance o autoridad litúrgica desconocida');
    }
  }
}
