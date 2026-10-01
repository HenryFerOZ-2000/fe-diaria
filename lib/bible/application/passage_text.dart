import '../domain/verse.dart';

/// Quita las marcas de la fuente (números Strong, `\w`, barras) y normaliza
/// espacios. Única implementación para toda la app.
String sanitizeVerseText(String text) => text
    .replaceAll(RegExp(r'strong="[^"]+"'), '')
    .replaceAll(RegExp(r"strong='[^']+'"), '')
    .replaceAll(RegExp(r'\\w\*?'), '')
    .replaceAll('|', ' ')
    .replaceAll(RegExp(r'\s{2,}'), ' ')
    .trim();

/// La RV1909 abre cada capítulo en versales ("Y ACONTECIÓ en…"); para una
/// vista previa se pasa a minúsculas: "Y aconteció en…".
String softenOpeningCaps(String text) => text.replaceFirstMapped(
  RegExp(r'^([¿¡«"]*)((?:[A-ZÁÉÍÓÚÑÜ]+[\s,;:.]*)+)(?=[a-záéíóúñü]|$)'),
  (m) {
    final lower = m[2]!.toLowerCase();
    return '${m[1]}${lower[0].toUpperCase()}${lower.substring(1)}';
  },
);

/// Versículos seleccionados, en orden de lectura.
List<Verse> selectedInOrder(List<Verse> verses, Set<int> selected) =>
    verses.where((v) => selected.contains(v.verse)).toList()
      ..sort((a, b) => a.verse.compareTo(b.verse));

/// "Juan 3", "Juan 3:16" o "Juan 3:16-18" (del primero al último elegido).
String passageReference(String bookName, int chapter, List<Verse> selection) {
  if (selection.isEmpty) return '$bookName $chapter';
  final first = selection.first.verse;
  final last = selection.last.verse;
  return '$bookName $chapter:$first${last == first ? '' : '-$last'}';
}

/// Texto del pasaje con cada versículo numerado, uno por línea.
String passageBody(List<Verse> selection, {String separator = '\n'}) =>
    selection
        .map((v) => '${v.verse}. ${sanitizeVerseText(v.text)}')
        .join(separator);
