import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/bible/ui/reader/chapter_nav_bar.dart';
import 'package:verbum/bible/ui/reader/verse_tile.dart';
import 'package:verbum/design_system/design_system.dart';

void main() {
  Widget app(Widget child, {Widget? bottom}) => MaterialApp(
    theme: buildVerbumTheme(brightness: Brightness.light),
    home: Scaffold(body: child, bottomNavigationBar: bottom),
  );

  testWidgets('la barra de capítulos no invade el contenido', (tester) async {
    int? opened;
    await tester.pumpWidget(
      app(
        const SizedBox.expand(),
        bottom: ChapterNavBar(
          chapter: 1,
          lastChapter: 3,
          onOpen: (c) => opened = c,
        ),
      ),
    );
    expect(tester.getSize(find.byType(ChapterNavBar)).height, lessThan(90));

    await tester.tap(find.text('Siguiente'));
    expect(opened, 2);
    await tester.tap(find.text('Anterior'));
    expect(opened, 2, reason: 'no hay capítulo anterior al 1');
  });

  testWidgets('el versículo 1 abre con capitular y el resto con número', (
    tester,
  ) async {
    Widget tile(int n) => VerseTile(
      number: n,
      text: 'En el principio era el Verbo.',
      fontSize: 18,
      lineHeight: 1.6,
      textColor: Colors.black,
      selected: false,
      highlighted: false,
      onTap: () {},
    );
    await tester.pumpWidget(app(Column(children: [tile(1), tile(2)])));

    expect(find.byType(VDropCapText), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.textSpan?.toPlainText() == '2  En el principio era el Verbo.',
      ),
      findsOneWidget,
    );
  });
}
