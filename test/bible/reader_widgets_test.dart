import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verbum/bible/ui/reader/chapter_nav_bar.dart';
import 'package:verbum/bible/ui/reader/chapter_text.dart';
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

  testWidgets('el capítulo es texto corrido y cada versículo se toca', (
    tester,
  ) async {
    final tapped = <int>[];
    await tester.pumpWidget(
      app(
        ChapterText(
          verses: const [
            (number: 1, text: 'En el principio era el Verbo.'),
            (number: 2, text: 'Este era en el principio con Dios.'),
          ],
          fontSize: 18,
          lineHeight: 1.6,
          textColor: Colors.black,
          selected: const {},
          highlighted: const {2},
          onTap: tapped.add,
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.tapOnText(find.textRange.ofSubstring('con Dios'));
    expect(tapped, [2]);
  });
}
