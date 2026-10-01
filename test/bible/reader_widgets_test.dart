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

  testWidgets('el capítulo abre con capitular y cada versículo se toca', (
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

    // El versículo 1 abre con capitular; los demás llevan número volado,
    // unido a su texto por un espacio que no se corta.
    expect(find.text('E'), findsOneWidget);
    expect(find.textContaining('1\u202F'), findsNothing);
    expect(find.textContaining('2\u202FEste era'), findsOneWidget);
    await tester.tapOnText(find.textRange.ofSubstring('con Dios'));
    expect(tapped, [2]);
  });

  testWidgets('un versículo partido por la capitular sigue siendo uno', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final tapped = <int>[];
    await tester.pumpWidget(
      app(
        ChapterText(
          verses: const [
            (
              number: 1,
              text:
                  'Y juntando a sus doce discípulos, les dio virtud y potestad '
                  'sobre todos los demonios, y que sanasen enfermedades.',
            ),
            (number: 2, text: 'Y los envió a predicar el reino de Dios.'),
          ],
          fontSize: 18,
          lineHeight: 1.6,
          textColor: Colors.black,
          selected: const {},
          highlighted: const {},
          onTap: tapped.add,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    // La cola del versículo 1 queda en el párrafo de abajo.
    await tester.tapOnText(find.textRange.ofSubstring('enfermedades'));
    await tester.tapOnText(find.textRange.ofSubstring('predicar'));
    expect(tapped, [1, 2]);
  });
}
