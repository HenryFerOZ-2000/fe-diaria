import '../bible/domain/bible_book_info.dart';

class BibleDeepLinkTarget {
  const BibleDeepLinkTarget({
    required this.bookId,
    required this.chapter,
    required this.verse,
  });

  final String bookId;
  final int chapter;
  final int verse;

  Uri toUri() => Uri(
    scheme: 'verbum',
    host: 'biblia',
    pathSegments: [bookId, '$chapter', '$verse'],
  );

  @override
  bool operator ==(Object other) =>
      other is BibleDeepLinkTarget &&
      other.bookId == bookId &&
      other.chapter == chapter &&
      other.verse == verse;

  @override
  int get hashCode => Object.hash(bookId, chapter, verse);
}

BibleDeepLinkTarget? parseBibleDeepLink(Uri uri) {
  if (uri.scheme != 'verbum' ||
      uri.host != 'biblia' ||
      uri.pathSegments.length != 3) {
    return null;
  }
  final bookId = uri.pathSegments[0];
  final chapter = int.tryParse(uri.pathSegments[1]);
  final verse = int.tryParse(uri.pathSegments[2]);
  if (bibleBookById(bookId) == null ||
      chapter == null ||
      chapter < 1 ||
      verse == null ||
      verse < 1) {
    return null;
  }
  return BibleDeepLinkTarget(bookId: bookId, chapter: chapter, verse: verse);
}
