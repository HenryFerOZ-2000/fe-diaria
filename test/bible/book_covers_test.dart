import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/bible/domain/bible_book_info.dart';
import 'package:verbum/bible/ui/book_covers.dart';
import 'package:verbum/design_system/design_system.dart';

void main() {
  test('cada sección de la Biblia tiene su propia portada', () {
    final sections = bibleBooks.map((b) => b.section).toSet();
    final styles = sections.map(coverStyleFor).toSet();
    expect(styles.length, sections.length);
  });

  testWidgets('la portada abre su libro y no se desborda con nombres largos', (
    tester,
  ) async {
    var opened = false;
    final book = bibleBooks.firstWhere((b) => b.name.length > 12);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVerbumTheme(brightness: Brightness.light),
        home: Scaffold(
          body: Center(
            child: BibleBookCover(
              book: book,
              width: 76,
              onTap: () => opened = true,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.bySemanticsLabel(RegExp(book.name)));
    expect(opened, isTrue);
  });
}
