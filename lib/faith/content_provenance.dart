/// Provenance is explicit: a doctrinal reference is not a reproduction license
/// or evidence that the stored wording matches a published liturgical edition.
class ContentProvenance {
  final String kind;
  final String description;
  final String? sourceTitle;
  final String? sourceUrl;
  final String licenseStatus;
  final String reviewStatus;
  final String? translation;
  final String editorialVersion;

  const ContentProvenance({
    required this.kind,
    required this.description,
    this.sourceTitle,
    this.sourceUrl,
    required this.licenseStatus,
    required this.reviewStatus,
    this.translation,
    this.editorialVersion = '2026-09-20',
  });

  static const unverified = ContentProvenance(
    kind: 'Oración del catálogo',
    description:
        'La procedencia y la redacción de este texto todavía no están documentadas. No se presenta como texto litúrgico oficial ni como cita bíblica literal.',
    licenseStatus: 'Por documentar',
    reviewStatus: 'Pendiente de revisión editorial',
  );

  static const bible = ContentProvenance(
    kind: 'Texto bíblico',
    description:
        'Pasaje de la edición Reina-Valera 1909 disponible sin conexión en Verbum. Conserva la redacción de esta edición histórica.',
    sourceTitle: 'Reina-Valera 1909 · eBible.org',
    sourceUrl: 'https://ebible.org/spaRV1909/copyright.htm',
    licenseStatus: 'Edición de dominio público',
    reviewStatus: 'Referencia vinculada a la Biblia local',
    translation: 'Reina-Valera 1909',
  );

  static const original = ContentProvenance(
    kind: 'Oración de Verbum',
    description:
        'Redacción devocional creada para Verbum. No es una cita bíblica ni una oración oficial del calendario litúrgico.',
    licenseStatus: 'Redacción propia de esta edición de Verbum',
    reviewStatus: 'Identificada como composición devocional',
  );

  /// Applies only to the bundled devotional corpus whose generation method
  /// was confirmed by the project owner, not arbitrary or user-supplied text.
  static const aiGenerated = ContentProvenance(
    kind: 'Oración devocional de Verbum',
    description:
        'Composición devocional del catálogo de Verbum. No es una cita bíblica literal ni una oración litúrgica oficial.',
    licenseStatus: 'Contenido editorial del catálogo de Verbum',
    reviewStatus: 'Pendiente de revisión editorial y doctrinal',
  );

  static ContentProvenance forBundledPrayer(String title) {
    final known = forPrayer(title);
    if (!identical(known, unverified)) return known;
    // Recognizable received formulas are not original AI compositions. Their
    // exact wording still needs collation; do not invent an official source.
    if (title == 'Oración a San Miguel Arcángel' ||
        title == 'Oración de Protección') {
      return const ContentProvenance(
        kind: 'Oración tradicional',
        description:
            'Fórmula tradicional conservada por Verbum. Puede tener variantes y no se presenta como una edición litúrgica oficial.',
        licenseStatus: 'Derechos de la versión por documentar',
        reviewStatus: 'Pendiente de cotejo de la fórmula tradicional',
      );
    }
    // Attribution to RV1909 must happen only after resolving the actual text.
    if (title.startsWith('Salmo ') || title.startsWith('Promesas ')) {
      return unverified;
    }
    return aiGenerated;
  }

  static ContentProvenance forPrayer(String title) {
    const traditional = {
      'Padre Nuestro',
      'Ave María',
      'Gloria',
      'Credo',
      'Ven Espíritu Santo',
      'Acto de Contrición',
    };
    if (!traditional.contains(title)) return unverified;
    return const ContentProvenance(
      kind: 'Oración tradicional',
      description:
          'Fórmula de la tradición cristiana en la versión conservada por Verbum. La fuente permite consultar la tradición católica; no certifica que esta redacción coincida literalmente con una edición litúrgica.',
      sourceTitle: 'Compendio del Catecismo · Santa Sede',
      sourceUrl:
          'https://www.vatican.va/archive/compendium_ccc/documents/archive_2005_compendium-ccc_sp.html',
      licenseStatus:
          'Redacción heredada: derechos de la versión por documentar',
      reviewStatus:
          'Referencia doctrinal identificada; cotejo literal pendiente',
    );
  }
}
