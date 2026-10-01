import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/bible/application/bible_reference.dart';
import 'package:verbum/bible/domain/bible_book_info.dart';

void main() {
  test('interpreta referencias sin importar tildes ni mayúsculas', () {
    final r = parseBibleReference('juan 3:16')!;
    expect(r.book.id, 'JHN');
    expect(r.chapter, 3);
    expect(r.verse, 16);

    final g = parseBibleReference('  Génesis 1 ')!;
    expect(g.book.name, 'Génesis');
    expect(g.verse, 1);
    expect(parseBibleReference('genesis 1')?.book.id, g.book.id);
  });

  test('libros con número y texto que no es referencia', () {
    final first = bibleBooks.firstWhere(
      (b) => RegExp(r'^\d ').hasMatch(b.name),
    );
    expect(parseBibleReference('${first.name} 2:1')?.book.id, first.id);
    expect(parseBibleReference('esperanza'), isNull);
    expect(parseBibleReference('Libro Inventado 3'), isNull);
  });

  test('agrupa por sección y cubre todo el testamento', () {
    final old = booksBySection(BibleTestament.old);
    final nt = booksBySection(BibleTestament.newTestament);
    expect(old.values.expand((b) => b).length, 39);
    expect(nt.values.expand((b) => b).length, 27);
    expect(nt.values.first.first.id, 'MAT');
  });
}
