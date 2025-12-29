class Verse {
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final String? tag;

  Verse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    this.tag,
  });
}
