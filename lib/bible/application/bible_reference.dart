import '../domain/bible_book_info.dart';

/// Referencia bíblica resuelta a un libro del catálogo.
final class BibleReference {
  const BibleReference({
    required this.book,
    required this.chapter,
    this.verse = 1,
  });

  final BibleBookInfo book;
  final int chapter;
  final int verse;
}

/// Minúsculas y sin tildes, para comparar nombres de libros.
String normalizeBookName(String input) => input
    .trim()
    .toLowerCase()
    .replaceAll(RegExp('[áàä]'), 'a')
    .replaceAll(RegExp('[éèë]'), 'e')
    .replaceAll(RegExp('[íìï]'), 'i')
    .replaceAll(RegExp('[óòö]'), 'o')
    .replaceAll(RegExp('[úùü]'), 'u');

/// Interpreta "Juan 3", "juan 3:16" o "1 Corintios 13:4"; `null` si el texto
/// no es una referencia a un libro conocido.
BibleReference? parseBibleReference(
  String raw, {
  List<BibleBookInfo> books = bibleBooks,
}) {
  final match = RegExp(r'^(.+?)\s+(\d+)(?::(\d+))?$').firstMatch(raw.trim());
  if (match == null) return null;
  final name = normalizeBookName(match.group(1)!);
  final book = books
      .where((b) => normalizeBookName(b.name) == name)
      .firstOrNull;
  if (book == null) return null;
  return BibleReference(
    book: book,
    chapter: int.tryParse(match.group(2)!) ?? 1,
    verse: int.tryParse(match.group(3) ?? '1') ?? 1,
  );
}

/// Libros de un testamento agrupados por sección, en orden canónico.
Map<String, List<BibleBookInfo>> booksBySection(
  BibleTestament testament, {
  List<BibleBookInfo> books = bibleBooks,
}) {
  final sections = <String, List<BibleBookInfo>>{};
  for (final book in books.where((b) => b.testament == testament)) {
    sections.putIfAbsent(book.section, () => []).add(book);
  }
  return sections;
}
